import 'dart:async';
import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:gtdoro/core/utils/change_detector.dart';
import 'package:gtdoro/core/utils/list_extensions.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/local/oracle_serialization.dart';
import 'package:gtdoro/data/repositories/recurring_action_repository.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/providers/recurring_action_generator.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';
import 'package:gtdoro/features/todo/providers/sync_trigger_mixin.dart';

class RecurringProvider with ChangeNotifier, SyncTriggerMixin {
  final RecurringActionRepository _repository;
  SyncProvider? _syncProvider;
  List<RecurringAction> _actions = [];
  final RecurringActionGenerator _actionGenerator;
  late StreamSubscription<List<RecurringAction>> _subscription;
  static const _uuid = Uuid();

  bool _isDisposed = false;
  bool _isGenerating = false; // 무한 루프 방지: 실행 중 플래그
  DateTime? _lastGenerationTime; // 마지막 생성 시간 추적

  RecurringProvider({
    required ActionProvider actionProvider,
    required RecurringActionRepository repository,
  })  : _repository = repository,
        _actionGenerator =
            RecurringActionGenerator(actionProvider, repository) {
    _subscription = _repository.watchAllRecurringActions().listen(
      (actions) {
        if (_isDisposed) return; // Prevent execution after dispose
        if (_isGenerating) {
          dev.log('RecurringProvider: generateActions가 이미 실행 중이므로 건너뜀 (무한 루프 방지)');
          // 실행 중일 때는 _actions만 업데이트하고 generateActions는 호출하지 않음
          _actions = actions;
          return;
        }
        
        // Actions가 실제로 변경되었는지 확인 (불필요한 처리 방지)
        // currentCount와 nextRunDate도 포함하여 generateActions로 인한 업데이트를 감지
        final actionsChanged = ChangeDetector.hasRecurringActionListChanged(
          _actions,
          actions,
          (a) => a.id,
          (a) => a.updatedAt,
          (a) => a.currentCount,
          (a) => a.nextRunDate,
        );
        
        if (!actionsChanged && _actions.isNotEmpty) {
          // 변경사항이 없으면 건너뜀 (성능 최적화)
          return;
        }
        
        // 너무 자주 실행되는 것을 방지 (최소 2초 간격)
        final now = DateTime.now();
        if (_lastGenerationTime != null && 
            now.difference(_lastGenerationTime!).inSeconds < 2) {
          dev.log('RecurringProvider: 너무 자주 실행되어 건너뜀 (최소 2초 간격)');
          _actions = actions; // 상태만 업데이트
          return;
        }
        
        _isGenerating = true;
        _lastGenerationTime = now;
        _actions = actions;
        
        // generateActions를 비동기로 실행하되, 메인 스레드를 블로킹하지 않음
        // 성능 최적화: await하지 않고 fire-and-forget으로 처리
        _handleActionGeneration();
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log('RecurringProvider: Stream error', error: error, stackTrace: stackTrace);
      },
    );
  }

  /// Handle action generation asynchronously (fire-and-forget)
  void _handleActionGeneration() async {
    try {
      final changed = await _actionGenerator.generateActions(_actions);
      // generateActions가 변경사항을 만들었고, 이것이 stream을 다시 트리거할 수 있음
      // 하지만 _isGenerating 플래그로 인해 재진입은 방지됨
      if (changed) {
        dev.log('RecurringProvider: generateActions created changes');
      }
      // generateActions의 결과는 stream이 이미 새로운 상태를 emit하므로
      // notifyListeners()는 최소화 (stream이 이미 UI를 업데이트함)
      // 성능 최적화: 불필요한 notifyListeners() 호출 제거
    } catch (e, stackTrace) {
      dev.log('RecurringProvider: Action generation error', error: e, stackTrace: stackTrace);
      dev.log('  - Error type: ${e.runtimeType}');
      dev.log('  - Error message: $e');
      dev.log('  - RecurringActions count: ${_actions.length}');
    } finally {
      _isGenerating = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription.cancel();
    super.dispose();
  }

  void setSyncProvider(SyncProvider provider) {
    _syncProvider = provider;
  }

  @override
  SyncProvider? get syncProvider => _syncProvider;

  List<RecurringAction> get actions =>
      _actions.where((a) => !a.isDeleted).toList();

  Future<void> updateAction(
    String id, {
    String? title,
    String? description,
    RecurrenceType? type,
    int? interval,
    int? totalCount,
    int? currentCount,
    DateTime? nextRunDate,
    int? energyLevel,
    int? duration,
    int? advanceDays,
    bool? skipHolidays,
    List<String>? contextIds,
  }) async {
    try {
      // 기존 action 찾기 (rev 갱신을 위해)
      final existing = _actions.firstWhereOrNull((a) => a.id == id);
      if (existing == null) {
        throw StateError('Recurring action not found: $id');
      }
      
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(previousRev: existing.rev); // rev 갱신 (오버플로우 안전)
      
      final companion = RecurringActionsCompanion(
        id: Value(id),
        title: title != null ? Value(title) : const Value.absent(),
        description:
            description != null ? Value(description) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        interval: interval != null ? Value(interval) : const Value.absent(),
        totalCount: totalCount != null ? Value(totalCount) : const Value.absent(),
        currentCount:
            currentCount != null ? Value(currentCount) : const Value.absent(),
        nextRunDate:
            nextRunDate != null ? Value(nextRunDate) : const Value.absent(),
        energyLevel:
            energyLevel != null ? Value(energyLevel) : const Value.absent(),
        duration: duration != null ? Value(duration) : const Value.absent(),
        advanceDays: advanceDays != null ? Value(advanceDays) : const Value.absent(),
        skipHolidays: skipHolidays != null ? Value(skipHolidays) : const Value.absent(),
        contextIds: contextIds != null ? Value(contextIds) : const Value.absent(),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      await _repository.saveRecurringAction(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedAction = await _repository.getRecurringActionById(id);
        if (savedAction != null && _syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('RecurringProvider: Single recurring action uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('RecurringProvider: Error uploading single recurring action (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('RecurringProvider: Error in updateAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> addAction({
    required String title,
    String? description,
    required RecurrenceType type,
    int interval = 1,
    int totalCount = 0,
    DateTime? startDate,
    int energyLevel = 3,
    int duration = 10,
    int advanceDays = 0, // Days before start date to create action
    bool skipHolidays = false, // Skip holidays when scheduling
    List<String> contextIds = const [],
  }) async {
    try {
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(); // rev 생성 (오버플로우 안전)
      
      final companion = RecurringActionsCompanion.insert(
        id: _uuid.v4(),
        title: title,
        description: Value(description),
        type: type,
        interval: Value(interval),
        totalCount: Value(totalCount),
        currentCount: const Value(0),
        nextRunDate: startDate ?? now,
        energyLevel: Value(energyLevel),
        duration: Value(duration),
        advanceDays: Value(advanceDays),
        skipHolidays: Value(skipHolidays),
        contextIds: Value(contextIds),
        rev: Value(newRev), // rev 생성 (오버플로우 안전)
        updatedAt: Value(now),
      );
      final actionId = companion.id.value!;
      await _repository.saveRecurringAction(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedAction = await _repository.getRecurringActionById(actionId);
        if (savedAction != null && _syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('RecurringProvider: Single recurring action uploaded immediately (ID: $actionId)');
        }
      } catch (e, stackTrace) {
        dev.log('RecurringProvider: Error uploading single recurring action (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('RecurringProvider: Error in addAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> removeAction(String id) async {
    try {
      // 기존 action 찾기 (rev 갱신을 위해)
      final existing = _actions.firstWhereOrNull((a) => a.id == id);
      if (existing == null) {
        throw StateError('Recurring action not found: $id');
      }
      
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(previousRev: existing.rev); // rev 갱신 (오버플로우 안전)
      
      final companion = RecurringActionsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      await _repository.saveRecurringAction(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드 (삭제 마킹)
      try {
        final savedAction = await _repository.getRecurringActionById(id);
        if (savedAction != null && _syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('RecurringProvider: Single recurring action (deleted) uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('RecurringProvider: Error uploading single recurring action (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('RecurringProvider: Error in removeAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
