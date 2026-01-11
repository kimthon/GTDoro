import 'dart:developer' as dev;
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';

/// Oracle DB 동시성 제어 및 충돌 해결 유틸리티
class OracleConflictResolver {
  /// 충돌 감지: rev(revision)과 updated_at을 모두 고려하여 정확한 충돌 감지
  /// 여러 기기에서 동시 편집 시 정확한 충돌 감지를 위해 rev 필드 우선 확인
  static bool hasConflict(
    Map<String, dynamic> localDoc,
    Map<String, dynamic> remoteDoc,
  ) {
    final localRev = _getRev(localDoc);
    final remoteRev = _getRev(remoteDoc);
    
    // rev 필드가 있으면 이를 우선적으로 비교 (더 정확한 충돌 감지)
    if (localRev != null && remoteRev != null) {
      // rev가 다르면 충돌 가능성이 높음
      if (localRev != remoteRev) {
        final localUpdatedAt = _getUpdatedAt(localDoc);
        final remoteUpdatedAt = _getUpdatedAt(remoteDoc);
        
        // 둘 다 수정되었고, 어느 것도 다른 것의 후속 버전이 아닌 경우 충돌
        if (localUpdatedAt != null && remoteUpdatedAt != null) {
          // updatedAt이 같거나 매우 가까우면 동시 편집 가능
          final timeDiff = (localUpdatedAt.difference(remoteUpdatedAt).abs()).inSeconds;
          // 1초 이내의 차이는 동시 편집으로 간주하여 충돌로 처리
          if (timeDiff < 2) {
            return true;
          }
          // 둘 다 최근에 수정되었지만 시간차가 있으면 더 최신 버전 확인
          return localUpdatedAt.isAfter(remoteUpdatedAt) || 
                 remoteUpdatedAt.isAfter(localUpdatedAt);
        }
        return true; // rev가 다르고 updatedAt 정보가 없으면 충돌로 간주
      }
      // rev가 같으면 같은 버전이므로 충돌 없음
      return false;
    }
    
    // rev가 없으면 updatedAt 기반으로 확인 (하위 호환성)
    final localUpdatedAt = _getUpdatedAt(localDoc);
    final remoteUpdatedAt = _getUpdatedAt(remoteDoc);
    
    if (localUpdatedAt == null || remoteUpdatedAt == null) {
      return false; // 타임스탬프가 없으면 충돌로 간주하지 않음
    }
    
    // 둘 다 수정되었고, 어느 것도 다른 것의 후속 버전이 아닌 경우 충돌
    final timeDiff = (localUpdatedAt.difference(remoteUpdatedAt).abs()).inSeconds;
    // 1초 이내의 차이는 동시 편집으로 간주하여 충돌로 처리
    if (timeDiff < 2) {
      return true;
    }
    return localUpdatedAt.isAfter(remoteUpdatedAt) || 
           remoteUpdatedAt.isAfter(localUpdatedAt);
  }
  
  /// rev 필드 추출
  static String? _getRev(Map<String, dynamic> doc) {
    return doc['_rev'] as String? ?? doc['rev'] as String?;
  }

  /// Last-Write-Wins 전략: 더 최신 버전 선택 (여러 기기 동시 사용 고려)
  static Map<String, dynamic> resolveLastWriteWins(
    Map<String, dynamic> localDoc,
    Map<String, dynamic> remoteDoc,
  ) {
    final localRev = _getRev(localDoc);
    final remoteRev = _getRev(remoteDoc);
    final localUpdatedAt = _getUpdatedAt(localDoc);
    final remoteUpdatedAt = _getUpdatedAt(remoteDoc);
    
    // rev 필드가 있으면 이를 우선적으로 사용 (더 정확한 충돌 해결, 오버플로우 안전)
    if (localRev != null && remoteRev != null) {
      final comparison = RevHelper.compareRev(localRev, remoteRev);
      
      if (comparison < 0) {
        // remote가 더 최신
        dev.log('OracleConflictResolver: Remote rev ($remoteRev) is newer than local ($localRev), using remote');
        return remoteDoc;
      } else if (comparison > 0) {
        // local이 더 최신
        dev.log('OracleConflictResolver: Local rev ($localRev) is newer than remote ($remoteRev), using local');
        return localDoc;
      }
      // rev가 같으면 updatedAt 비교
    }
    
    // rev가 없거나 같으면 updatedAt 비교
    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      dev.log('OracleConflictResolver: No timestamps available, using local');
      return localDoc;
    }
    
    if (localUpdatedAt == null) {
      dev.log('OracleConflictResolver: Local has no timestamp, using remote');
      return remoteDoc;
    }
    
    if (remoteUpdatedAt == null) {
      dev.log('OracleConflictResolver: Remote has no timestamp, using local');
      return localDoc;
    }
    
    // 더 최신 버전 선택 (밀리초 단위 비교)
    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      dev.log('OracleConflictResolver: Remote updatedAt ($remoteUpdatedAt) is newer than local ($localUpdatedAt), using remote');
      return remoteDoc;
    } else {
      dev.log('OracleConflictResolver: Local updatedAt ($localUpdatedAt) is newer than remote ($remoteUpdatedAt), using local');
      return localDoc;
    }
  }

  /// 병합 전략: 필드별로 더 최신 값 선택 (스마트 병합)
  /// 여러 기기에서 동시 편집 시 필드별로 독립적으로 병합
  static Map<String, dynamic> resolveMerge(
    Map<String, dynamic> localDoc,
    Map<String, dynamic> remoteDoc,
  ) {
    final merged = Map<String, dynamic>.from(localDoc);
    
    // ID는 로컬 유지
    final localId = localDoc['_id'] ?? localDoc['id'];
    if (localId != null) {
      merged['_id'] = localId;
      merged['id'] = localId;
    }
    
    final localUpdatedAt = _getUpdatedAt(localDoc);
    final remoteUpdatedAt = _getUpdatedAt(remoteDoc);
    
    // 각 필드를 비교하여 더 최신 값 선택 (필드별 독립 병합)
    for (final entry in remoteDoc.entries) {
      final key = entry.key;
      
      // 시스템 필드는 건너뛰기
      if (key == '_id' || key == 'id' || key == 'type' || key == '_rev' || key == 'rev') {
        continue;
      }
      
      final localValue = localDoc[key];
      final remoteValue = entry.value;
      
      // 타임스탬프 필드는 더 최신 값 선택
      if (_isTimestampField(key)) {
        final localTime = _parseTimestamp(localValue);
        final remoteTime = _parseTimestamp(remoteValue);
        
        if (remoteTime != null && 
            (localTime == null || remoteTime.isAfter(localTime))) {
          merged[key] = remoteValue;
        }
        // localTime이 더 최신이면 유지
      } 
      // Boolean 필드는 더 최신 값을 사용 (rev 또는 updatedAt 비교)
      else if (_isBooleanField(key)) {
        // isDeleted 필드는 특별 처리: 로컬이 삭제된 경우 삭제 상태 우선 유지
        if (key == 'isDeleted' || key == 'is_deleted') {
          final localIsDeleted = localValue as bool? ?? false;
          final remoteIsDeleted = remoteValue as bool? ?? false;
          
          // 로컬이 삭제된 경우 삭제 상태 우선 유지 (원격이 더 최신이어도)
          // 삭제는 명시적인 사용자 액션이므로 우선순위가 높음
          if (localIsDeleted) {
            merged[key] = true;
            dev.log('OracleConflictResolver: isDeleted field using local value (true) - deletion takes priority');
          } else if (remoteIsDeleted) {
            // 원격만 삭제된 경우 원격 값 사용
            merged[key] = true;
            dev.log('OracleConflictResolver: isDeleted field using remote value (true)');
          } else {
            // 둘 다 삭제되지 않은 경우 rev 비교
            final localRev = _getRev(localDoc);
            final remoteRev = _getRev(remoteDoc);
            
            bool useRemote = false;
            if (localRev != null && remoteRev != null) {
              final revComparison = RevHelper.compareRev(localRev, remoteRev);
              useRemote = revComparison < 0; // remote가 더 최신
            } else {
              if (remoteUpdatedAt != null && 
                  (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
                useRemote = true;
              }
            }
            
            merged[key] = useRemote ? remoteValue : localValue;
          }
        } else {
          // isDeleted 외의 Boolean 필드는 일반적인 처리
          final localRev = _getRev(localDoc);
          final remoteRev = _getRev(remoteDoc);
          
          bool useRemote = false;
          if (localRev != null && remoteRev != null) {
            // rev 비교: remote가 더 최신이면 remote 값 사용
            final revComparison = RevHelper.compareRev(localRev, remoteRev);
            useRemote = revComparison < 0; // remote가 더 최신
          } else {
            // rev가 없으면 updatedAt 비교
            if (remoteUpdatedAt != null && 
                (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
              useRemote = true;
            }
          }
          
          if (useRemote) {
            merged[key] = remoteValue;
            dev.log('OracleConflictResolver: Boolean field $key using remote value: $remoteValue (remote is newer)');
          } else {
            // 로컬이 더 최신이거나 같으면 로컬 값 유지
            merged[key] = localValue;
            dev.log('OracleConflictResolver: Boolean field $key using local value: $localValue (local is newer or equal)');
          }
        }
      }
      // 문자열 필드 (title, description 등)는 더 최신 값 사용
      else if (key == 'title' || key == 'description' || key == 'waitingFor' || 
               key == 'name' || key == 'category') {
        // 원격이 더 최신이면 원격 값 사용, 아니면 로컬 유지
        if (remoteUpdatedAt != null && 
            (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
          merged[key] = remoteValue;
        }
        // 값이 같으면 유지 (불필요한 변경 방지)
        else if (localValue == remoteValue) {
          merged[key] = localValue;
        }
      }
      // 숫자 필드나 배열 필드는 더 최신 값 사용
      else {
        if (remoteUpdatedAt != null && 
            (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
          merged[key] = remoteValue;
        }
      }
    }
    
    // updated_at을 더 최신 시간으로 업데이트 (병합 후 시간)
    final now = DateTime.now();
    merged['updatedAt'] = now.toIso8601String();
    merged['updated_at'] = now.toIso8601String();
    
    // rev 필드는 새로운 값으로 업데이트 (병합 버전)
    merged['_rev'] = _generateNewRev(localDoc, remoteDoc);
    
    dev.log('OracleConflictResolver: Smart merged documents (field-level merge)');
    return merged;
  }
  
  /// 새로운 rev 값 생성 (병합 버전, 오버플로우 안전)
  static String _generateNewRev(
    Map<String, dynamic> localDoc,
    Map<String, dynamic> remoteDoc,
  ) {
    // 로컬과 원격 중 더 최신 rev를 기반으로 새 rev 생성
    final localRev = _getRev(localDoc);
    final remoteRev = _getRev(remoteDoc);
    
    // 더 최신 rev 선택
    final baseRev = RevHelper.compareRev(localRev, remoteRev) >= 0 ? localRev : remoteRev;
    
    // 오버플로우 안전하게 새 rev 생성
    return RevHelper.generateNewRev(previousRev: baseRev);
  }

  /// updated_at 필드 추출
  static DateTime? _getUpdatedAt(Map<String, dynamic> doc) {
    final updatedAt = doc['updatedAt'] ?? doc['updated_at'] ?? doc['UPDATED_AT'];
    return _parseTimestamp(updatedAt);
  }

  /// 타임스탬프 파싱
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 타임스탬프 필드인지 확인
  static bool _isTimestampField(String fieldName) {
    final timestampFields = [
      'createdAt', 'updatedAt', 'dueDate', 'completedAt',
      'nextRunDate', 'startDate',
      'created_at', 'updated_at', 'due_date', 'completed_at',
      'next_run_date', 'start_date',
    ];
    return timestampFields.any((field) => 
      fieldName.toLowerCase().contains(field.toLowerCase())
    );
  }

  /// Boolean 필드인지 확인
  static bool _isBooleanField(String fieldName) {
    final boolFields = [
      'isDone', 'isDeleted', 'isCreated', 'skipHolidays',
      'is_done', 'is_deleted', 'is_created', 'skip_holidays',
    ];
    return boolFields.contains(fieldName.toLowerCase());
  }

  /// 전략에 따라 충돌 해결
  static Map<String, dynamic> resolve(
    Map<String, dynamic> localDoc,
    Map<String, dynamic> remoteDoc,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return resolveLastWriteWins(localDoc, remoteDoc);
      case ConflictResolutionStrategy.localWins:
        // 로컬 우선이지만 rev는 업데이트하여 동기화 상태 유지 (오버플로우 안전)
        final result = Map<String, dynamic>.from(localDoc);
        final now = DateTime.now();
        result['updatedAt'] = now.toIso8601String();
        result['updated_at'] = now.toIso8601String();
        final localRev = _getRev(localDoc);
        result['_rev'] = RevHelper.generateNewRev(previousRev: localRev);
        return result;
      case ConflictResolutionStrategy.remoteWins:
        return remoteDoc; // 원격이 우선이므로 그대로 반환
      case ConflictResolutionStrategy.merge:
        return resolveMerge(localDoc, remoteDoc);
    }
  }
  
  /// rev 필드 추출 (public 헬퍼)
  static String? getRev(Map<String, dynamic> doc) {
    return _getRev(doc);
  }
  
  /// updatedAt 필드 추출 (public 헬퍼)
  static DateTime? getUpdatedAt(Map<String, dynamic> doc) {
    return _getUpdatedAt(doc);
  }
}

/// 충돌 해결 전략 열거형
enum ConflictResolutionStrategy {
  lastWriteWins,  // 마지막 쓰기 우선
  localWins,      // 로컬 우선
  remoteWins,     // 원격 우선
  merge,          // 병합
}
