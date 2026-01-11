import 'dart:async';
import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:gtdoro/core/utils/change_detector.dart';
import 'package:gtdoro/core/utils/list_extensions.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/local/oracle_serialization.dart';
import 'package:gtdoro/data/repositories/scheduled_action_repository.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/providers/scheduled_action_generator.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';
import 'package:gtdoro/features/todo/providers/sync_trigger_mixin.dart';

class ScheduledProvider with ChangeNotifier, SyncTriggerMixin {
  final ScheduledActionRepository _repository;
  final ScheduledActionGenerator _actionGenerator;
  List<ScheduledAction> _actions = [];
  late StreamSubscription<List<ScheduledAction>> _subscription;
  bool _isDisposed = false;
  static const _uuid = Uuid();
  
  @override
  SyncProvider? get syncProvider => _syncProvider;
  
  SyncProvider? _syncProvider;
  
  void setSyncProvider(SyncProvider provider) {
    _syncProvider = provider;
  }

  ScheduledProvider({
    required ScheduledActionRepository repository,
    required ActionProvider actionProvider,
  })  : _repository = repository,
        _actionGenerator = ScheduledActionGenerator(actionProvider, repository) {
    dev.log('ScheduledProvider: Initializing stream subscription');
    _subscription = _repository.watchAllScheduledActions().listen(
      (actions) async {
        if (_isDisposed) return; // Prevent execution after dispose
        
        // Actions가 실제로 변경되었는지 확인 (불필요한 리빌드 방지)
        final actionsChanged = ChangeDetector.hasContextListChanged(
          _actions,
          actions,
          (a) => a.id,
          (a) => a.updatedAt,
        );
        
        if (!actionsChanged && _actions.isNotEmpty) {
          // 변경사항이 없으면 건너뜀 (성능 최적화)
          return;
        }
        
        dev.log('ScheduledProvider: Stream update received, ${actions.length} actions');
        _actions = actions;
        
        // Generate actions from scheduled actions (throttle 적용)
        if (!_isDisposed && actions.isNotEmpty) {
          // generateActions는 비동기이므로 await하지 않고 fire-and-forget
          // 이렇게 하면 메인 스레드를 블로킹하지 않음
          _handleActionGeneration(actions);
        }
        
        if (!_isDisposed) {
          dev.log('ScheduledProvider: Notifying listeners');
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log('ScheduledProvider: Stream error', error: error, stackTrace: stackTrace);
      },
    );
  }

  /// Handle action generation asynchronously (fire-and-forget)
  void _handleActionGeneration(List<ScheduledAction> actions) async {
    try {
      await _actionGenerator.generateActions(actions);
    } catch (e, stackTrace) {
      dev.log('ScheduledProvider: Error generating actions', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription.cancel();
    super.dispose();
  }

  // --- Getters ---
  List<ScheduledAction> get actions =>
      _actions.where((a) => !a.isDeleted).toList();

  // --- CRUD Operations ---
  Future<void> addAction({
    required String title,
    String? description,
    required DateTime startDate,
    int energyLevel = 3,
    int duration = 10,
    int advanceDays = 0,
    bool skipHolidays = false,
    List<String> contextIds = const [],
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(); // rev 생성 (오버플로우 안전)
      
      final companion = ScheduledActionsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        startDate: startDate,
        energyLevel: Value(energyLevel),
        duration: Value(duration),
        advanceDays: Value(advanceDays),
        skipHolidays: Value(skipHolidays),
        isCreated: Value(false),
        contextIds: Value(contextIds),
        rev: Value(newRev), // rev 생성 (오버플로우 안전)
        updatedAt: Value(now),
        isDeleted: Value(false),
      );
      
      await _repository.saveScheduledAction(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedAction = await _repository.getScheduledActionById(id);
        if (savedAction != null && _syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ScheduledProvider: Single scheduled action uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('ScheduledProvider: Error uploading single scheduled action (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('ScheduledProvider: Error in addAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateAction({
    required String id,
    String? title,
    String? description,
    DateTime? startDate,
    int? energyLevel,
    int? duration,
    int? advanceDays,
    bool? skipHolidays,
    List<String>? contextIds,
  }) async {
    try {
      // 안정성 강화: null-safe 처리
      final existing = _actions.firstWhereOrNull((a) => a.id == id);
      if (existing == null) {
        throw StateError('Scheduled action not found: $id');
      }
      
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(previousRev: existing.rev); // rev 갱신 (오버플로우 안전)
      
      final companion = ScheduledActionsCompanion(
        id: Value(id),
        title: title != null ? Value(title) : const Value.absent(),
        description: description != null ? Value(description) : Value(existing.description),
        startDate: startDate != null ? Value(startDate) : const Value.absent(),
        energyLevel: energyLevel != null ? Value(energyLevel) : const Value.absent(),
        duration: duration != null ? Value(duration) : const Value.absent(),
        advanceDays: advanceDays != null ? Value(advanceDays) : const Value.absent(),
        skipHolidays: skipHolidays != null ? Value(skipHolidays) : const Value.absent(),
        contextIds: contextIds != null ? Value(contextIds) : const Value.absent(),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      
      await _repository.saveScheduledAction(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedAction = await _repository.getScheduledActionById(id);
        if (savedAction != null && _syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ScheduledProvider: Single scheduled action uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('ScheduledProvider: Error uploading single scheduled action (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('ScheduledProvider: Error in updateAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> removeAction(String id) async {
    try {
      // 기존 action 찾기 (rev 갱신을 위해)
      final existing = _actions.firstWhereOrNull((a) => a.id == id);
      if (existing == null) {
        throw StateError('Scheduled action not found: $id');
      }
      
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(previousRev: existing.rev); // rev 갱신 (오버플로우 안전)
      
      // 모든 필드를 명시적으로 설정하여 insertOnConflictUpdate가 제대로 작동하도록 함
      final companion = ScheduledActionsCompanion(
        id: Value(id),
        title: Value(existing.title), // 기존 값 유지
        description: Value(existing.description),
        startDate: Value(existing.startDate),
        energyLevel: Value(existing.energyLevel),
        duration: Value(existing.duration),
        advanceDays: Value(existing.advanceDays),
        skipHolidays: Value(existing.skipHolidays),
        isCreated: Value(existing.isCreated),
        contextIds: Value(existing.contextIds),
        isDeleted: const Value(true), // 삭제 마킹
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      
      await _repository.saveScheduledAction(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드 (삭제 마킹)
      try {
        final savedAction = await _repository.getScheduledActionById(id);
        if (savedAction != null && _syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ScheduledProvider: Single scheduled action (deleted) uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('ScheduledProvider: Error uploading single scheduled action (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
      dev.log('ScheduledProvider: removeAction completed for ID: $id, rev: $newRev');
    } catch (e, stackTrace) {
      dev.log('ScheduledProvider: Error in removeAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> markAsCreated(String id) async {
    try {
      // 기존 action 찾기 (rev 갱신을 위해)
      final existing = _actions.firstWhereOrNull((a) => a.id == id);
      if (existing == null) {
        throw StateError('Scheduled action not found: $id');
      }
      
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(previousRev: existing.rev); // rev 갱신 (오버플로우 안전)
      
      final companion = ScheduledActionsCompanion(
        id: Value(id),
        isCreated: Value(true),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      
      await _repository.saveScheduledAction(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedAction = await _repository.getScheduledActionById(id);
        if (savedAction != null && _syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ScheduledProvider: Single scheduled action uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('ScheduledProvider: Error uploading single scheduled action (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('ScheduledProvider: Error in markAsCreated', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
