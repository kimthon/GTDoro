import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import 'package:gtdoro/core/constants/sync_constants.dart';
import 'package:gtdoro/data/local/oracle_serialization.dart';
import 'package:gtdoro/data/repositories/action_repository.dart';
import 'package:gtdoro/data/repositories/context_repository.dart';
import 'package:gtdoro/data/repositories/recurring_action_repository.dart';
import 'package:gtdoro/data/repositories/scheduled_action_repository.dart';
import 'package:gtdoro/data/sync/oracle/data/companion_factory.dart';
import 'package:gtdoro/data/sync/oracle/conflict/resolver.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';

class SyncDataMerger {
  final ActionRepository _actionRepo;
  final ContextRepository _contextRepo;
  final RecurringActionRepository _recurringRepo;
  final ScheduledActionRepository _scheduledRepo;
  ConflictResolutionStrategy _conflictStrategy = ConflictResolutionStrategy.lastWriteWins;
  
  ConflictResolutionStrategy get conflictStrategy => _conflictStrategy;
  
  // 로컬 문서 캐시 (성능 최적화)
  Map<String, Map<String, dynamic>>? _localDocsCache;

  SyncDataMerger(this._actionRepo, this._contextRepo, this._recurringRepo, this._scheduledRepo);
  
  void setConflictStrategy(ConflictResolutionStrategy strategy) {
    _conflictStrategy = strategy;
  }
  
  /// 로컬 문서 캐시 설정 (동기화 시작 전에 호출)
  void setLocalDocsCache(Map<String, Map<String, dynamic>> cache) {
    _localDocsCache = cache;
  }
  
  /// 캐시 클리어
  void clearCache() {
    _localDocsCache = null;
  }

  Future<Map<String, int>> mergeRemoteData(List<Map<String, dynamic>> docs) async {
    int successCount = 0;
    int failureCount = 0;
    int conflictCount = 0;
    final List<String> failedIds = [];
    final List<String> conflictIds = [];

    // 안정성 강화: 배치 크기 제한으로 메모리 보호
    final batchSize = SyncConstants.maxBatchDocuments;
    final batches = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < docs.length; i += batchSize) {
      batches.add(docs.skip(i).take(batchSize).toList());
    }

    for (final batch in batches) {
      for (var doc in batch) {
        final type = doc['type'] as String?;
        final id = doc['_id'] as String?;
        if (type == null || id == null) {
          failureCount++;
          failedIds.add(id ?? 'unknown');
          dev.log('SyncDataMerger: Document missing type or id, skipping');
          continue;
        }

        final bool isDeletedOnServer =
            (doc['_deleted'] as bool? ?? false) || (doc['isDeleted'] as bool? ?? false);

        try {
          // 충돌 감지 및 해결 (삭제가 아닌 경우만)
          Map<String, dynamic>? resolvedDoc = doc;
          if (!isDeletedOnServer) {
            resolvedDoc = await _detectAndResolveConflict(type, id, doc, conflictIds);
            
            // 충돌 해결 결과가 null이면 로컬 삭제 상태를 유지 (업서트 스킵)
            if (resolvedDoc == null) {
              dev.log('SyncDataMerger: Skipping upsert for $type:$id (local is deleted and newer)');
              successCount++; // 로컬 삭제 상태 유지 = 성공
              continue; // 다음 문서로
            }
            
            // 충돌이 있었는지 확인 (conflictIds에 추가되었는지)
            if (conflictIds.contains(id)) {
              conflictCount++;
            }
          }

          // 삭제 또는 업서트 처리
          if (isDeletedOnServer) {
            await _handleDeletion(type, id);
            successCount++;
          } else {
            // resolvedDoc이 null이 아니면 업서트 처리
            if (resolvedDoc != null) {
              final upsertSuccess = await _handleUpsert(type, resolvedDoc, id);
              if (upsertSuccess) {
                successCount++;
              } else {
                failureCount++;
                failedIds.add(id);
              }
            } else {
              // resolvedDoc이 null이면 이미 처리됨 (로컬 삭제 상태 유지)
              successCount++;
            }
          }
        } catch (e, stackTrace) {
          failureCount++;
          final docId = doc['_id']?.toString() ?? 'unknown';
          failedIds.add(docId);
          debugPrint('SyncDataMerger: ❌ Merge error (ID: $docId, Type: $type): $e');
          dev.log('SyncDataMerger: Merge error (ID: $docId, Type: $type)', error: e, stackTrace: stackTrace);
          
          // 첫 번째 실패 문서의 상세 정보 출력
          if (failedIds.length == 1) {
            debugPrint('SyncDataMerger: First failed document details:');
            debugPrint('  - ID: $docId');
            debugPrint('  - Type: $type');
            debugPrint('  - Keys: ${doc.keys.join(", ")}');
            debugPrint('  - Error: $e');
            dev.log('SyncDataMerger: First failed document - ID: $docId, Type: $type, Keys: ${doc.keys.join(", ")}');
          }
        }
      }
    }

    if (failureCount > 0 || conflictCount > 0) {
      dev.log('SyncDataMerger: $successCount succeeded, $failureCount failed, $conflictCount conflicts resolved');
      if (failedIds.isNotEmpty) {
        dev.log('SyncDataMerger: Failed document IDs: ${failedIds.take(10).join(", ")}${failedIds.length > 10 ? "..." : ""}');
      }
      if (conflictIds.isNotEmpty) {
        dev.log('SyncDataMerger: Conflicts resolved for: ${conflictIds.take(10).join(", ")}${conflictIds.length > 10 ? "..." : ""}');
      }
    } else {
      dev.log('SyncDataMerger: All documents merged successfully ($successCount items)');
    }
    
    return {
      'success': successCount,
      'failed': failureCount,
      'conflicts': conflictCount,
    };
  }

  /// 충돌 감지 및 해결 (리팩토링: 로직 분리)
  /// 반환값: null이면 로컬 삭제 상태 유지 (업서트 스킵), 그 외는 처리할 문서
  Future<Map<String, dynamic>?> _detectAndResolveConflict(
    String type,
    String id,
    Map<String, dynamic> doc,
    List<String> conflictIds,
  ) async {
    final localDoc = await _getLocalDocument(type, id);
    if (localDoc == null) {
      return doc; // 로컬에 없으면 충돌 없음, 원격 문서 반환
    }

    final localRev = OracleConflictResolver.getRev(localDoc);
    final remoteRev = OracleConflictResolver.getRev(doc);
    final localUpdatedAt = OracleConflictResolver.getUpdatedAt(localDoc);
    final remoteUpdatedAt = OracleConflictResolver.getUpdatedAt(doc);

    // 로컬 문서가 삭제된 경우 확인
    final localIsDeleted = localDoc['isDeleted'] as bool? ?? localDoc['is_deleted'] as bool? ?? false;
    
    // rev 기반 충돌 감지 (더 정확함)
    bool hasConflict = false;
    if (localRev != null && remoteRev != null && localRev != remoteRev) {
      // rev 비교를 통해 어느 쪽이 더 최신인지 확인 (오버플로우 안전 비교)
      final revComparison = RevHelper.compareRev(localRev, remoteRev);
      
      if (revComparison > 0) {
        // 로컬이 더 최신: 충돌 없음, 로컬 유지
        // 로컬이 더 최신이면 서버에 업로드해야 하므로 다운로드할 필요 없음
        dev.log(
            'SyncDataMerger: Local rev ($localRev) is newer than remote ($remoteRev) for $type:$id, skipping download (local is newer, isDeleted: $localIsDeleted)');
        
        // 로컬이 삭제된 경우: 삭제 상태를 유지하기 위해 null 반환 (업서트 스킵)
        // 삭제도 rev로 관리되므로, 로컬 rev가 더 최신이면 로컬 삭제 상태 유지
        if (localIsDeleted) {
          dev.log('SyncDataMerger: Local document is deleted (rev: $localRev), skipping upsert to preserve deletion');
          return null; // null 반환하여 업서트 스킵 (삭제 상태 유지)
        }
        
        // 로컬이 삭제되지 않은 경우: 원격 문서를 업데이트할 필요 없으므로 null 반환 (업서트 스킵)
        // 업로드는 별도로 처리되므로 여기서는 다운로드를 스킵하면 됨
        return null; // null 반환하여 업서트 스킵 (로컬이 더 최신이므로)
      } else if (revComparison < 0) {
        // 원격이 더 최신: rev 기반 동기화 원칙에 따라 원격 상태 사용
        // 삭제 상태도 rev로 관리되므로, 원격 rev가 더 최신이면 원격 상태를 따름
        dev.log(
            'SyncDataMerger: Remote rev ($remoteRev) is newer than local ($localRev) for $type:$id, using remote (local isDeleted: $localIsDeleted)');
        return doc; // 원격 문서 반환 (원격이 더 최신이므로)
      }
      
      // rev가 같으면 (compareRev == 0) 충돌 없음
      // 하지만 rev가 다른데 compareRev가 0이면 파싱 오류 가능성
      // 이 경우 updatedAt 기반으로 확인
      if (localUpdatedAt != null && remoteUpdatedAt != null) {
        final timeDiff = (localUpdatedAt.difference(remoteUpdatedAt).abs()).inSeconds;
        // 2초 이내의 차이는 동시 편집으로 간주하여 충돌로 처리
        hasConflict = timeDiff < 2 ||
            (localUpdatedAt.isAfter(remoteUpdatedAt) &&
                remoteUpdatedAt.isAfter(localUpdatedAt.subtract(const Duration(seconds: 2))));
      } else {
        // 타임스탬프가 없으면 rev 파싱 오류 가능성이 있으므로 로컬 우선
        // 로컬이 삭제된 경우 null 반환하여 업서트 스킵
        if (localIsDeleted) {
          dev.log(
              'SyncDataMerger: Rev parsing issue for $type:$id (localRev: $localRev, remoteRev: $remoteRev), local is deleted, skipping upsert');
          return null;
        }
        dev.log(
            'SyncDataMerger: Rev parsing issue for $type:$id (localRev: $localRev, remoteRev: $remoteRev), keeping local');
        return localDoc;
      }
    } else {
      // rev가 없거나 같으면 updatedAt 기반 충돌 감지
      hasConflict = OracleConflictResolver.hasConflict(localDoc, doc);
    }

    if (hasConflict) {
      conflictIds.add(id);
      dev.log(
          'SyncDataMerger: Conflict detected for $type:$id (localRev: $localRev, remoteRev: $remoteRev), resolving with ${_conflictStrategy.name}');
      // 충돌 해결 전략에 따라 해결
      return OracleConflictResolver.resolve(localDoc, doc, _conflictStrategy);
    }

    return doc; // 충돌 없음, 원격 문서 사용
  }

  /// 삭제 처리 (리팩토링: 로직 분리)
  /// 모든 타입은 soft delete 사용 (동기화를 위해)
  /// Repository의 remove 메서드들이 모두 soft delete를 사용하도록 변경됨
  Future<void> _handleDeletion(String type, String id) async {
    dev.log('SyncDataMerger: Handling deletion for type: $type, id: $id');
    try {
      switch (type) {
        case 'todo':
          await _actionRepo.removeAction(id); // Soft delete 사용
          break;
        case 'context':
          await _contextRepo.removeContext(id); // Soft delete 사용
          break;
        case 'recurring':
          await _recurringRepo.removeRecurringAction(id); // Soft delete 사용
          break;
        case 'scheduled':
          await _scheduledRepo.removeScheduledAction(id); // Soft delete 사용
          break;
        default:
          dev.log('SyncDataMerger: Unknown type deletion attempt (ID: $id, Type: $type)');
          throw Exception('Unknown type for deletion: $type');
      }
      dev.log('SyncDataMerger: Deletion completed successfully for type: $type, id: $id');
    } catch (e, stackTrace) {
      dev.log('SyncDataMerger: Error handling deletion for type: $type, id: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 업서트 처리 (리팩토링: Companion Factory 사용)
  Future<bool> _handleUpsert(String type, Map<String, dynamic> doc, String id) async {
    try {
      switch (type) {
        case 'todo':
          dev.log('SyncDataMerger: Processing todo document - ID: $id, Keys: ${doc.keys.join(", ")}');
          final companion = OracleCompanionFactory.createActionCompanion(doc);
          if (companion == null) {
            dev.log('SyncDataMerger: ❌ Failed to create ActionCompanion for $id - Document data: ${doc.toString().substring(0, 200)}');
            debugPrint('SyncDataMerger: ❌ Failed to create ActionCompanion for $id');
            return false;
          }
          // contextIds 타입 안전성 강화 (리팩토링: 공통 메서드 사용)
          final contextIds = _parseContextIds(doc['contextIds']);
          dev.log('SyncDataMerger: Saving todo - ID: $id, contextIds: $contextIds');
          await _actionRepo.saveAction(companion, contextIds);
          dev.log('SyncDataMerger: ✅ Successfully saved todo - ID: $id');
          return true;

        case 'context':
          dev.log('SyncDataMerger: Processing context document - ID: $id');
          final companion = OracleCompanionFactory.createContextCompanion(doc);
          if (companion == null) {
            dev.log('SyncDataMerger: ❌ Failed to create ContextCompanion for $id');
            debugPrint('SyncDataMerger: ❌ Failed to create ContextCompanion for $id');
            return false;
          }
          await _contextRepo.saveContext(companion);
          dev.log('SyncDataMerger: ✅ Successfully saved context - ID: $id');
          return true;

        case 'recurring':
          dev.log('SyncDataMerger: Processing recurring document - ID: $id');
          final companion = OracleCompanionFactory.createRecurringActionCompanion(doc);
          if (companion == null) {
            dev.log('SyncDataMerger: ❌ Failed to create RecurringActionCompanion for $id');
            debugPrint('SyncDataMerger: ❌ Failed to create RecurringActionCompanion for $id');
            return false;
          }
          await _recurringRepo.saveRecurringAction(companion);
          dev.log('SyncDataMerger: ✅ Successfully saved recurring - ID: $id');
          return true;

        case 'scheduled':
          dev.log('SyncDataMerger: Processing scheduled document - ID: $id');
          final companion = OracleCompanionFactory.createScheduledActionCompanion(doc);
          if (companion == null) {
            dev.log('SyncDataMerger: ❌ Failed to create ScheduledActionCompanion for $id');
            debugPrint('SyncDataMerger: ❌ Failed to create ScheduledActionCompanion for $id');
            return false;
          }
          await _scheduledRepo.saveScheduledAction(companion);
          dev.log('SyncDataMerger: ✅ Successfully saved scheduled - ID: $id');
          return true;

        default:
          dev.log('SyncDataMerger: ❌ Unknown type (ID: $id, Type: $type)');
          debugPrint('SyncDataMerger: ❌ Unknown type (ID: $id, Type: $type)');
          return false;
      }
    } catch (e, stackTrace) {
      dev.log('SyncDataMerger: ❌ Error in _handleUpsert (ID: $id, Type: $type)', error: e, stackTrace: stackTrace);
      debugPrint('SyncDataMerger: ❌ Error in _handleUpsert (ID: $id, Type: $type): $e');
      rethrow; // 예외를 다시 던져서 상위에서 처리하도록 함
    }
  }

  /// contextIds 파싱 (안정성 강화: 타입 안전성)
  static List<String> _parseContextIds(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value
          .map((e) => e?.toString())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (value is String) {
      return value.isEmpty ? <String>[] : [value];
    }
    dev.log('SyncDataMerger: Invalid contextIds type: ${value.runtimeType}');
    return <String>[];
  }

  /// 로컬 문서 가져오기 (충돌 감지용, 캐시 우선 사용)
  /// 삭제된 항목도 포함하여 조회 (동기화를 위해 필요)
  Future<Map<String, dynamic>?> _getLocalDocument(String type, String id) async {
    // 캐시에서 먼저 확인
    final cacheKey = '$type:$id';
    if (_localDocsCache != null && _localDocsCache!.containsKey(cacheKey)) {
      return _localDocsCache![cacheKey];
    }
    
    // 캐시에 없으면 DB에서 ID로 직접 조회 (삭제된 항목 포함)
    try {
      switch (type) {
        case 'todo':
          final actionWithContexts = await _actionRepo.getActionById(id);
          return actionWithContexts?.toOracleJson();
        case 'context':
          final context = await _contextRepo.getContextById(id);
          return context?.toOracleJson();
        case 'recurring':
          final recurring = await _recurringRepo.getRecurringActionById(id);
          return recurring?.toOracleJson();
        case 'scheduled':
          final scheduled = await _scheduledRepo.getScheduledActionById(id);
          return scheduled?.toOracleJson();
        default:
          return null; // 알 수 없는 타입
      }
    } catch (e, stackTrace) {
      // 문서가 없으면 null 반환 (새 문서로 처리)
      dev.log('SyncDataMerger: Error fetching local document (ID: $id, Type: $type)', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> purgeDeletedLocalData() async {
    try {
      // 안정성 강화: 각 타입별로 독립적인 에러 처리
      try {
        final actions = await _actionRepo.getAllActions();
        for (var a in [...actions]) {
          if (a.action.isDeleted) {
            try {
              await _actionRepo.removeAction(a.action.id);
            } catch (e, stackTrace) {
              dev.log('SyncDataMerger: Error removing deleted action ${a.action.id}', error: e, stackTrace: stackTrace);
              // 개별 항목 실패는 계속 진행
            }
          }
        }
      } catch (e, stackTrace) {
        dev.log('SyncDataMerger: Error fetching actions for purge', error: e, stackTrace: stackTrace);
      }

      try {
        final contexts = await _contextRepo.getAllContexts();
        for (var c in [...contexts]) {
          if (c.isDeleted) {
            try {
              await _contextRepo.removeContext(c.id);
            } catch (e, stackTrace) {
              dev.log('SyncDataMerger: Error removing deleted context $c.id', error: e, stackTrace: stackTrace);
              // 개별 항목 실패는 계속 진행
            }
          }
        }
      } catch (e, stackTrace) {
        dev.log('SyncDataMerger: Error fetching contexts for purge', error: e, stackTrace: stackTrace);
      }

      try {
        final recurrings = await _recurringRepo.getAllRecurringActions();
        for (var r in [...recurrings]) {
          if (r.isDeleted) {
            try {
              await _recurringRepo.removeRecurringAction(r.id);
            } catch (e, stackTrace) {
              dev.log('SyncDataMerger: Error removing deleted recurring action $r.id', error: e, stackTrace: stackTrace);
              // 개별 항목 실패는 계속 진행
            }
          }
        }
      } catch (e, stackTrace) {
        dev.log('SyncDataMerger: Error fetching recurring actions for purge', error: e, stackTrace: stackTrace);
      }

      try {
        final scheduleds = await _scheduledRepo.getAllScheduledActions();
        for (var s in scheduleds) {
          if (s.isDeleted) {
            try {
              await _scheduledRepo.removeScheduledAction(s.id);
            } catch (e, stackTrace) {
              dev.log('SyncDataMerger: Error removing deleted scheduled action $s.id', error: e, stackTrace: stackTrace);
              // 개별 항목 실패는 계속 진행
            }
          }
        }
      } catch (e, stackTrace) {
        dev.log('SyncDataMerger: Error fetching scheduled actions for purge', error: e, stackTrace: stackTrace);
      }

      dev.log('SyncDataMerger: Local physical deletion completed');
    } catch (e, stackTrace) {
      dev.log('SyncDataMerger: Unexpected error in purgeDeletedLocalData', error: e, stackTrace: stackTrace);
    }
  }
}
