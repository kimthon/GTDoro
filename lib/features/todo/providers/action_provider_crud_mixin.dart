import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:uuid/uuid.dart';

import 'package:gtdoro/core/constants/app_strings.dart';
import 'package:gtdoro/core/utils/list_extensions.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/local/oracle_serialization.dart';
import 'package:gtdoro/data/repositories/action_repository.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';

mixin ActionProviderCrudMixin {
  // Required dependencies
  ActionRepository get repository;
  List<ActionWithContexts> get allActions;
  void triggerSync();
  SyncProvider? get syncProvider;

  // Logbook dependencies (from ActionProviderLogbookMixin)
  String get logbookSearchQuery;
  // Return type is Future<void> to match ActionProviderLogbookMixin
  Future<void> searchLogbook(String query);
  Future<void> fetchInitialLogbook();

  // State
  // Store Context ID lists keyed by deleted item IDs
  final Map<String, List<String>> _deletedContextsMap = {};
  final _uuid = const Uuid();

  // --- Helpers ---

  /// Get action by ID with null-safe handling
  ActionWithContexts? _getActionByIdOrNull(String id) {
    return allActions.firstWhereOrNull((a) => a.action.id == id);
  }

  /// Get action by ID, throws if not found
  ActionWithContexts _getActionById(String id) {
    final action = _getActionByIdOrNull(id);
    if (action == null) {
      throw StateError(AppStrings.errorActionNotFound.replaceAll('%s', id));
    }
    return action;
  }
  
  /// Helper to create Value from nullable field
  Value<T> _valueFromNullable<T>(T? value) {
    return value != null ? Value(value) : const Value.absent();
  }

  Future<void> _saveAndSync(
      ActionsCompanion companion, List<String> contextIds) async {
    dev.log('ActionProviderCrudMixin: _saveAndSync called with action ID: ${companion.id.value}, contextIds: $contextIds');
    try {
      await repository.saveAction(companion, contextIds);
      dev.log('ActionProviderCrudMixin: repository.saveAction completed');
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final actionId = companion.id.value;
        if (actionId != null) {
          final savedAction = await repository.getActionById(actionId);
          if (savedAction != null) {
            final oracleJson = savedAction.toOracleJson();
            if (syncProvider != null) {
              await syncProvider!.uploadSingleItem(oracleJson);
              dev.log('ActionProviderCrudMixin: Single item uploaded immediately (ID: $actionId)');
            }
          }
        }
      } catch (e, stackTrace) {
        dev.log('ActionProviderCrudMixin: Error uploading single item (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      // 전체 동기화도 트리거 (다른 변경사항이 있을 수 있으므로)
      triggerSync();
      dev.log('ActionProviderCrudMixin: triggerSync called');
    } catch (e, stackTrace) {
      dev.log('ActionProviderCrudMixin: Error in _saveAndSync', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create ActionsCompanion from existing action with optional updates
  /// rev 필드 갱신 (오버플로우 안전 처리)
  ActionsCompanion _createCompanionFromAction(
    Action action, {
    bool? isDeleted,
    GTDStatus? status,
    bool? isDone,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    final now = updatedAt ?? DateTime.now();
    // 이전 rev를 기반으로 새 rev 생성 (오버플로우 안전)
    final newRev = RevHelper.generateNewRev(previousRev: action.rev);
    
    return ActionsCompanion(
      id: Value(action.id),
      title: Value(action.title),
      createdAt: Value(action.createdAt),
      isDeleted: isDeleted != null ? Value(isDeleted) : Value(action.isDeleted),
      updatedAt: Value(now),
      status: status != null ? Value(status) : Value(action.status),
      isDone: isDone != null ? Value(isDone) : Value(action.isDone),
      completedAt: _valueFromNullable(completedAt ?? action.completedAt),
      description: _valueFromNullable(action.description),
      waitingFor: _valueFromNullable(action.waitingFor),
      energyLevel: _valueFromNullable(action.energyLevel),
      duration: _valueFromNullable(action.duration),
      dueDate: _valueFromNullable(action.dueDate),
      rev: Value(newRev), // rev 갱신 (오버플로우 안전)
      pomodorosCompleted: _valueFromNullable(action.pomodorosCompleted),
      totalPomodoroTime: _valueFromNullable(action.totalPomodoroTime),
    );
  }

  // --- CRUD Methods ---

  Future<void> updateActionStatus(String id, GTDStatus newStatus) async {
    try {
      final actionWithContexts = _getActionById(id);
      final currentStatus = actionWithContexts.action.status;
      
      // Scheduled는 독립적으로 관리 - 다른 상태와 전환 불가
      if (currentStatus == GTDStatus.scheduled && newStatus != GTDStatus.scheduled) {
        throw ArgumentError(AppStrings.errorScheduledCannotChangeStatus);
      }
      if (currentStatus != GTDStatus.scheduled && newStatus == GTDStatus.scheduled) {
        throw ArgumentError(AppStrings.errorCannotChangeToScheduled);
      }
      
      final companion = _createCompanionFromAction(actionWithContexts.action, status: newStatus);
      await _saveAndSync(companion, actionWithContexts.contextIds);
    } catch (e, stackTrace) {
      dev.log('ActionProviderCrudMixin: Error in updateActionStatus', error: e, stackTrace: stackTrace);
      if (e is StateError || e is ArgumentError) {
        rethrow;
      }
      throw Exception('${AppStrings.errorStatusChangeFailed}: ${e.toString()}');
    }
  }

  Future<void> processInboxItem(String id, {required GTDStatus to}) async {
    final actionWithContexts = _getActionById(id);
    final companion = _createCompanionFromAction(actionWithContexts.action, status: to);
    await _saveAndSync(companion, actionWithContexts.contextIds);
  }

  Future<void> addAction({
    required String title,
    String? description,
    String? waitingFor,
    GTDStatus status = GTDStatus.inbox,
    DateTime? dueDate,
    int? energyLevel,
    int? duration,
    List<String>? contextIds,
  }) async {
    dev.log('ActionProviderCrudMixin: addAction called with title: "$title", status: $status');
    
    if (title.trim().isEmpty) {
      dev.log('ActionProviderCrudMixin: 생성 실패 - 제목이 비어있음');
      throw ArgumentError('제목을 입력해주세요.');
    }

    // Waiting For 화면에서는 waitingFor 필드가 필수
    if (status == GTDStatus.waiting) {
      final waitingForTrimmed = waitingFor?.trim() ?? '';
      if (waitingForTrimmed.isEmpty) {
        dev.log('ActionProviderCrudMixin: 생성 실패 - Waiting For 필드가 비어있음 (status: $status)');
        throw ArgumentError(AppStrings.errorWaitingForRequired);
      }
    }

    final actionId = _uuid.v4();
    dev.log('ActionProviderCrudMixin: Generated action ID: $actionId');

    final now = DateTime.now();
    // rev 필드 생성 (오버플로우 안전)
    final newRev = RevHelper.generateNewRev();
    
    final companion = ActionsCompanion.insert(
      id: actionId,
      title: title,
      description: Value(description),
      waitingFor: Value(waitingFor),
      status: Value(status),
      createdAt: now,
      updatedAt: Value(now),
      rev: Value(newRev), // rev 필드 생성 (오버플로우 안전)
      dueDate: Value(dueDate),
      isDone: Value(false),
      isDeleted: const Value(false),
      energyLevel: Value(energyLevel),
      duration: Value(duration),
    );

    dev.log('ActionProviderCrudMixin: Calling _saveAndSync with contextIds: ${contextIds ?? []}');
    try {
      await _saveAndSync(companion, contextIds ?? []);
      dev.log('ActionProviderCrudMixin: Action 생성 완료 - ID: $actionId, 제목: "$title"');
    } catch (e, stackTrace) {
      dev.log('ActionProviderCrudMixin: Action 생성 실패', error: e, stackTrace: stackTrace);
      dev.log('  - 제목: "$title"');
      dev.log('  - 상태: $status');
      dev.log('  - 에러 타입: ${e.runtimeType}');
      dev.log('  - 에러 메시지: $e');
      throw Exception('할 일 생성 실패: ${e.toString()}');
    }
  }

  Future<void> updateAction(
    String id, {
    String? title,
    String? description,
    String? waitingFor,
    GTDStatus? status,
    int? energyLevel,
    int? duration,
    List<String>? contextIds,
    DateTime? dueDate,
  }) async {
    try {
      final actionWithContexts = _getActionById(id);
      final action = actionWithContexts.action;
      
      // Scheduled는 독립적으로 관리 - 다른 상태와 전환 불가
      if (status != null) {
        if (action.status == GTDStatus.scheduled && status != GTDStatus.scheduled) {
          throw ArgumentError(AppStrings.errorScheduledCannotChangeStatus);
        }
        if (action.status != GTDStatus.scheduled && status == GTDStatus.scheduled) {
          throw ArgumentError(AppStrings.errorCannotChangeToScheduled);
        }
      }
    
      // Create companion with all required fields, updating only specified ones
      final companion = _createCompanionFromAction(
        action,
        status: status,
        updatedAt: DateTime.now(),
      );
      
      // Override specific fields if provided
      // rev 필드 갱신 (오버플로우 안전 처리)
      final currentRev = companion.rev.value;
      final newRev = currentRev != null 
          ? RevHelper.generateNewRev(previousRev: currentRev)
          : RevHelper.generateNewRev();
      
      final updatedCompanion = ActionsCompanion(
        id: companion.id,
        title: title != null ? Value(title) : companion.title,
        createdAt: companion.createdAt,
        description: description != null ? Value(description) : companion.description,
        waitingFor: waitingFor != null ? Value(waitingFor) : companion.waitingFor,
        isDone: companion.isDone,
        status: status != null ? Value(status) : companion.status,
        energyLevel: energyLevel != null ? Value(energyLevel) : companion.energyLevel,
        duration: duration != null ? Value(duration) : companion.duration,
        dueDate: dueDate != null ? Value(dueDate) : companion.dueDate,
        completedAt: companion.completedAt,
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(DateTime.now()),
        isDeleted: companion.isDeleted,
        pomodorosCompleted: companion.pomodorosCompleted,
        totalPomodoroTime: companion.totalPomodoroTime,
      );

      await _saveAndSync(
          updatedCompanion, contextIds ?? actionWithContexts.contextIds);
    } catch (e, stackTrace) {
      dev.log('ActionProviderCrudMixin: Error in updateAction', error: e, stackTrace: stackTrace);
      if (e is StateError || e is ArgumentError) {
        rethrow;
      }
      throw Exception('${AppStrings.errorActionUpdateFailed}: ${e.toString()}');
    }
  }

  Future<void> toggleDone(String id) async {
    try {
      final actionWithContexts = _getActionById(id);
      final action = actionWithContexts.action;
      final isDone = !action.isDone;
      
      // Scheduled는 독립적으로 관리 - 완료 시에도 상태 유지
      final newStatus = action.status == GTDStatus.scheduled
          ? action.status // Scheduled는 상태 유지
          : ((!isDone && action.status == GTDStatus.completed)
              ? GTDStatus.inbox
              : action.status);

      final companion = _createCompanionFromAction(
        action,
        isDone: isDone,
        status: newStatus,
        completedAt: isDone ? DateTime.now() : null,
      );

      await _saveAndSync(companion, actionWithContexts.contextIds);

      if (isDone) {
        try {
          if (logbookSearchQuery.isNotEmpty) {
            await searchLogbook(logbookSearchQuery);
          } else {
            await fetchInitialLogbook();
          }
        } catch (e) {
          dev.log('ActionProviderCrudMixin: Error fetching logbook after toggle', error: e);
          // Don't rethrow - main action is already saved
        }
      }
    } catch (e, stackTrace) {
      dev.log('ActionProviderCrudMixin: Error in toggleDone', error: e, stackTrace: stackTrace);
      if (e is StateError) {
        rethrow;
      }
      throw Exception('${AppStrings.errorStatusChangeFailed}: ${e.toString()}');
    }
  }

  Future<void> removeAction(String id) async {
    try {
      final actionWithContexts = _getActionById(id);
      final action = actionWithContexts.action;

      // Store Context IDs of deleted items in Map
      _deletedContextsMap[id] = actionWithContexts.contextIds;

      // Include all required fields for insertOnConflictUpdate
      final companion = _createCompanionFromAction(action, isDeleted: true);
      await _saveAndSync(companion, actionWithContexts.contextIds);
    } catch (e, stackTrace) {
      dev.log('ActionProviderCrudMixin: Error in removeAction', error: e, stackTrace: stackTrace);
      if (e is StateError) {
        rethrow;
      }
      throw Exception('${AppStrings.errorActionDeleteFailed}: ${e.toString()}');
    }
  }

  Future<void> restoreAction(String id) async {
    final actionWithContexts = _getActionByIdOrNull(id);
    if (actionWithContexts == null) {
      throw StateError(AppStrings.errorActionNotFound.replaceAll('%s', id));
    }
    
    final action = actionWithContexts.action;
    final newRev = RevHelper.generateNewRev(previousRev: action.rev);
    
    final companion = ActionsCompanion(
      id: Value(id),
      isDeleted: const Value(false),
      rev: Value(newRev), // rev 갱신 (오버플로우 안전)
      updatedAt: Value(DateTime.now()),
    );

    // Get Context list for the ID from Map and remove item
    final contextIds = _deletedContextsMap.remove(id) ?? [];

    await _saveAndSync(companion, contextIds);
  }

  Future<void> addActionFromBlueprint({
    required String title,
    String? description,
    required DateTime dueDate,
    int? energyLevel,
    int? duration,
    List<String>? contextIds,
    bool triggerSync = true,
    GTDStatus status = GTDStatus.next, // 기본값은 next, Scheduled 생성 시 scheduled로 설정
  }) async {
    final actionId = "gen_${_uuid.v4()}";
    dev.log('ActionProviderCrudMixin: addActionFromBlueprint called');
    dev.log('  - 제목: "$title"');
    dev.log('  - 상태: $status');
    // 날짜 문자열 변환 (시간 부분 제거)
    final dateStr = dueDate.toString().split(' ')[0];
    dev.log('  - 시작일: $dateStr');
    dev.log('  - Action ID: $actionId');
    
    try {
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(); // rev 생성 (오버플로우 안전)
      
      final companion = ActionsCompanion.insert(
        id: actionId,
        title: title,
        description: Value(description),
        status: Value(status),
        dueDate: Value(dueDate),
        energyLevel: Value(energyLevel),
        duration: Value(duration),
        createdAt: now,
        updatedAt: Value(now),
        rev: Value(newRev), // rev 생성 (오버플로우 안전)
        isDeleted: const Value(false),
      );
      
      await repository.saveAction(companion, contextIds ?? []);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedAction = await repository.getActionById(actionId);
        if (savedAction != null && syncProvider != null) {
          final oracleJson = savedAction.toOracleJson();
          await syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ActionProviderCrudMixin: Single item uploaded immediately (ID: $actionId)');
        }
      } catch (e, stackTrace) {
        dev.log('ActionProviderCrudMixin: Error uploading single item (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      dev.log('ActionProviderCrudMixin: Action from blueprint 생성 완료 - ID: $actionId');
      
      if (triggerSync) {
        this.triggerSync();
      }
    } catch (e, stackTrace) {
      dev.log('ActionProviderCrudMixin: Action from blueprint 생성 실패', error: e, stackTrace: stackTrace);
      dev.log('  - 제목: "$title"');
      dev.log('  - 상태: $status');
      final dateStr = dueDate.toString().split(' ')[0];
      dev.log('  - 시작일: $dateStr');
      dev.log('  - 에러 타입: ${e.runtimeType}');
      dev.log('  - 에러 메시지: $e');
      throw Exception('할 일 생성 실패: ${e.toString()}');
    }
  }

  Future<void> removeContextIdFromAllActions(String id) async {
    await repository.removeContextFromAllActionsAtomic(id);
    triggerSync();
  }

  Future<void> updatePomodoroData(
      String actionId, int pomodorosCompleted, Duration totalPomodoroTime) async {
    final actionWithContexts = _getActionById(actionId);
    final action = actionWithContexts.action;
    final newRev = RevHelper.generateNewRev(previousRev: action.rev);
    
    final companion = ActionsCompanion(
      id: Value(actionId),
      pomodorosCompleted: Value(pomodorosCompleted),
      totalPomodoroTime: Value(totalPomodoroTime.inSeconds),
      rev: Value(newRev), // rev 갱신 (오버플로우 안전)
      updatedAt: Value(DateTime.now()),
    );
    await _saveAndSync(companion, actionWithContexts.contextIds);
  }

  /// Archive old completed actions (optimized with batch processing)
  Future<void> archiveOldCompletedActions() async {
    final now = DateTime.now();

    final actionsToArchive = allActions.where((actionWithContexts) {
      final action = actionWithContexts.action;
      return !action.isDeleted &&
          action.isDone &&
          action.status != GTDStatus.completed &&
          action.completedAt != null &&
          !DateUtils.isSameDay(action.completedAt!, now);
    }).toList();

    if (actionsToArchive.isEmpty) return;

    int successCount = 0;
    int failureCount = 0;
    final nowTimestamp = DateTime.now();

    // Process each action using _saveAndSync for consistent sync behavior
    for (final actionWithContexts in actionsToArchive) {
      try {
        final action = actionWithContexts.action;
        final companion = _createCompanionFromAction(
          action,
          status: GTDStatus.completed,
          updatedAt: nowTimestamp,
        );
        await _saveAndSync(companion, actionWithContexts.contextIds);
        successCount++;
      } catch (e) {
        failureCount++;
        dev.log('ActionProviderCrudMixin: archiveOldCompletedActions failed (ID: ${actionWithContexts.action.id})', error: e);
        // Continue processing (handle remaining items even if some fail)
      }
    }
    
    if (successCount > 0) {
      dev.log('ActionProviderCrudMixin: archiveOldCompletedActions - $successCount succeeded, $failureCount failed');
      // _saveAndSync에서 이미 triggerSync()를 호출하므로 여기서는 호출 불필요
    }
  }
}
