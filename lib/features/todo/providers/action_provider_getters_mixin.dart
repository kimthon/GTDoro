import 'package:flutter/material.dart';

import 'package:gtdoro/core/utils/action_grouping_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/action_provider_statistics.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';

mixin ActionProviderGettersMixin {
  // Required dependencies
  List<ActionWithContexts> get allActions;
  ContextProvider? get contextProvider;

  // --- Basic Getters ---
  // Note: actions getter is kept simple as it's used as base for other getters
  // Caching here would complicate invalidation logic
  List<ActionWithContexts> get actions =>
      allActions.where((t) => !t.action.isDeleted).toList();

  List<ActionWithContexts> get activeActions {
    final activeFilterIds = contextProvider?.activeFilterIds;
    // Optimize: early return for common case (no filters)
    if (activeFilterIds == null || activeFilterIds.isEmpty) {
      return allActions.where((t) => !t.action.isDone && !t.action.isDeleted).toList();
    }
    
    // 성능 최적화: activeFilterIds를 Set으로 변환 (한 번만)
    final activeFilterIdsSet = activeFilterIds.toSet();
    
    // Use Set for O(1) lookup when checking filter matches
    return allActions.where((t) {
      if (t.action.isDone || t.action.isDeleted) return false;
      // Check if action has all required context IDs
      // 성능 최적화: contextIds가 비어있으면 조기 종료
      final contextIds = t.contextIds;
      if (contextIds.isEmpty) return false;
      // 성능 최적화: contextIds가 작으면 List.contains가 더 빠를 수 있지만,
      // activeFilterIdsSet이 작은 경우 Set 변환이 유리하므로 유지
      // 일반적으로 Set 변환이 더 안정적인 성능을 제공
      final actionContextIds = contextIds.length > 2 ? contextIds.toSet() : contextIds;
      return activeFilterIdsSet.every((filterId) => actionContextIds.contains(filterId));
    }).toList();
  }

  List<ActionWithContexts> get todayCompletedActions {
    final now = DateTime.now();
    return allActions.where((t) {
      final a = t.action;
      if (!a.isDone || a.completedAt == null || a.isDeleted) {
        return false;
      }

      final isToday = DateUtils.isSameDay(a.completedAt!, now);

      return isToday && a.status != GTDStatus.completed;
    }).toList();
  }

  // --- Statistics ---

  Map<int, int> get completedTasksLast7Days =>
      ActionProviderStatistics.completedTasksLast7Days(allActions);

  Map<String, dynamic> get weeklyFocusStats =>
      ActionProviderStatistics.weeklyFocusStats(allActions);

  Map<String, int> get completedTasksByContextCount =>
      ActionProviderStatistics.completedTasksByContextCount(
          allActions, contextProvider);

  // --- Grouping ---

  Map<String, List<ActionWithContexts>> get groupedNextActions =>
      _groupNextActions();

  Map<String, List<ActionWithContexts>> _groupNextActions() {
    // Filter: status must be next AND waitingFor must be null/empty
    // activeActions는 이미 isDone == false && isDeleted == false로 필터링됨
    // 성능 최적화: 불필요한 이중 체크 제거
    final nextActions = activeActions.where((t) {
      final action = t.action;
      // status가 next이고 waitingFor가 null/empty인 것만
      return action.status == GTDStatus.next &&
          (action.waitingFor == null || action.waitingFor!.isEmpty);
    }).toList();
    
    // 성능 최적화: today를 한 번만 계산하여 전달
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return ActionGroupingHelper.groupActionsByDateWithOverdue(
      nextActions,
      (actionWithContexts) => actionWithContexts.action.dueDate,
      '마감일 없음',
      today,
    );
  }

  /// Check if an action with the given title and dueDate already exists
  /// 성능 최적화: 빠른 조기 종료를 위해 title 비교를 먼저 수행
  bool hasActionWithTitleAndDueDate(String title, DateTime dueDate) {
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    // 성능 최적화: title이 일치하는 action만 필터링한 후 dueDate 비교
    return allActions.any((actionWithContexts) {
      final action = actionWithContexts.action;
      if (action.isDeleted) return false;
      // title 비교를 먼저 수행 (더 빠른 조기 종료)
      if (action.title != title) return false;
      if (action.dueDate == null) return false;
      final actionDueDateOnly = DateTime(
        action.dueDate!.year,
        action.dueDate!.month,
        action.dueDate!.day,
      );
      return actionDueDateOnly == dueDateOnly;
    });
  }
}
