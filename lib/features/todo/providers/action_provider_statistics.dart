import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';

/// Helper class for statistics calculations
class ActionProviderStatistics {
  /// Helper method to filter recent completed actions (last 7 days)
  /// Optimized: Extract common filtering logic to avoid duplication
  static List<ActionWithContexts> _getRecentCompletedActions(
    List<ActionWithContexts> actions,
    DateTime sevenDaysAgo,
  ) {
    return actions.where((actionWithContexts) {
      final completedAt = actionWithContexts.action.completedAt;
      return actionWithContexts.action.isDone &&
          completedAt != null &&
          !completedAt.isBefore(sevenDaysAgo);
    }).toList();
  }

  /// Calculate completed tasks count for the last 7 days
  /// Optimized: Accept optional DateTime to avoid duplicate calls
  static Map<int, int> completedTasksLast7Days(
    List<ActionWithContexts> actions, [
    DateTime? referenceTime,
  ]) {
    final Map<int, int> weeklyStats = {for (var i = 0; i < 7; i++) i: 0};
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final recentCompleted = _getRecentCompletedActions(actions, sevenDaysAgo);

    for (var actionWithContexts in recentCompleted) {
      final dayIndex = actionWithContexts.action.completedAt!.difference(sevenDaysAgo).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        weeklyStats.update(dayIndex, (value) => value + 1);
      }
    }
    return weeklyStats;
  }

  /// Calculate weekly focus statistics (time and pomodoros)
  /// Optimized: Accept optional DateTime to avoid duplicate calls
  static Map<String, dynamic> weeklyFocusStats(
    List<ActionWithContexts> actions, [
    DateTime? referenceTime,
  ]) {
    final now = referenceTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final recentCompleted = _getRecentCompletedActions(actions, sevenDaysAgo);

    int totalTimeInSeconds = 0;
    int totalPomodoros = 0;

    for (var actionWithContexts in recentCompleted) {
      totalTimeInSeconds += (actionWithContexts.action.totalPomodoroTime ?? 0).toInt();
      totalPomodoros += (actionWithContexts.action.pomodorosCompleted ?? 0).toInt();
    }

    return {
      'totalTime': Duration(seconds: totalTimeInSeconds),
      'totalPomodoros': totalPomodoros,
    };
  }

  /// Calculate completed tasks count by context
  static Map<String, int> completedTasksByContextCount(
    List<ActionWithContexts> actions,
    ContextProvider? contextProvider,
  ) {
    if (contextProvider == null) return {};

    final Map<String, int> counts = {};
    final contextMap = {
      for (var c in contextProvider.availableContexts) 
        c.id: ContextProvider.formatContextName(c)
    };

    // 성능 최적화: 불필요한 초기화 제거 (0인 값은 나중에 제거하므로)
    // for (var name in contextMap.values) {
    //   counts[name] = 0;
    // }

    final completedActions = actions.where((a) => a.action.isDone).toList();

    for (var actionWithContexts in completedActions) {
      if (actionWithContexts.contextIds.isNotEmpty) {
        // Use Set to avoid duplicate counting if action has duplicate contextIds
        final contextIdsSet = actionWithContexts.contextIds.toSet();
        for (var contextId in contextIdsSet) {
          final contextName = contextMap[contextId];
          if (contextName != null) {
            counts[contextName] = (counts[contextName] ?? 0) + 1;
          }
        }
      }
    }

    counts.removeWhere((key, value) => value == 0);
    return counts;
  }
}
