import 'package:intl/intl.dart';
import 'package:gtdoro/data/local/app_database.dart';

/// Common action grouping utility
class ActionGroupingHelper {
  // 성능 최적화: DateFormat 캐싱 (반복 생성 방지)
  static final _dateFormatter = DateFormat('yyyy-MM-dd (E)');
  
  /// Group actions by date
  static Map<String, List<ActionWithContexts>> groupActionsByDate(
    List<ActionWithContexts> actions,
    DateTime? Function(ActionWithContexts actionWithContexts) getDate,
    String noDateKey,
  ) {
    final Map<String, List<ActionWithContexts>> grouped = {};
    for (var actionWithContexts in actions) {
      final date = getDate(actionWithContexts);
      if (date == null) {
        grouped.putIfAbsent(noDateKey, () => []).add(actionWithContexts);
      } else {
        // 성능 최적화: 캐시된 DateFormat 사용
        final dateStr = _dateFormatter.format(date);
        grouped.putIfAbsent(dateStr, () => []).add(actionWithContexts);
      }
    }
    return grouped;
  }

  /// Group actions by date with overdue separation
  /// Returns a map with 'Overdue' key for past due dates and date strings for others
  /// 성능 최적화: today 파라미터 추가로 DateTime.now() 중복 호출 방지
  static Map<String, List<ActionWithContexts>> groupActionsByDateWithOverdue(
    List<ActionWithContexts> actions,
    DateTime? Function(ActionWithContexts actionWithContexts) getDate,
    String noDateKey, [
    DateTime? today,
  ]) {
    // 성능 최적화: today가 제공되지 않으면 한 번만 계산
    final todayDate = today ?? () {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }();
    
    final Map<String, List<ActionWithContexts>> grouped = {};
    final List<ActionWithContexts> overdue = [];
    
    for (var actionWithContexts in actions) {
      final date = getDate(actionWithContexts);
      if (date == null) {
        grouped.putIfAbsent(noDateKey, () => []).add(actionWithContexts);
      } else {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isBefore(todayDate)) {
          // Past due date - add to overdue
          overdue.add(actionWithContexts);
        } else {
          // Future or today - group by date
          // 성능 최적화: 캐시된 DateFormat 사용
          final dateStr = _dateFormatter.format(date);
          grouped.putIfAbsent(dateStr, () => []).add(actionWithContexts);
        }
      }
    }
    
    // Add overdue section at the beginning if there are any
    if (overdue.isNotEmpty) {
      grouped['⚠️ 마감일 지남'] = overdue;
    }
    
    return grouped;
  }

  /// Check if an action is overdue
  /// 성능 최적화: today 파라미터 추가로 DateTime.now() 중복 호출 방지
  static bool isOverdue(Action action, [DateTime? today]) {
    if (action.dueDate == null) return false;
    
    // 성능 최적화: today가 제공되지 않으면 한 번만 계산
    final todayDate = today ?? () {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }();
    
    final dueDateOnly = DateTime(action.dueDate!.year, action.dueDate!.month, action.dueDate!.day);
    return dueDateOnly.isBefore(todayDate);
  }
}
