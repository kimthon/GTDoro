import 'package:gtdoro/data/local/app_database.dart';

/// Extension methods for converting data models to Oracle JSON format
extension ActionWithContextsOracleExtension on ActionWithContexts {
  Map<String, dynamic> toOracleJson() {
    return {
      '_id': action.id,
      if (action.rev != null) '_rev': action.rev,
      'type': 'todo',
      'title': action.title,
      if (action.description != null) 'description': action.description,
      if (action.waitingFor != null) 'waitingFor': action.waitingFor,
      'isDone': action.isDone,
      'status': action.status.name,
      if (action.energyLevel != null) 'energyLevel': action.energyLevel,
      if (action.duration != null) 'duration': action.duration,
      'createdAt': action.createdAt.toIso8601String(),
      if (action.dueDate != null) 'dueDate': action.dueDate!.toIso8601String(),
      if (action.completedAt != null) 'completedAt': action.completedAt!.toIso8601String(),
      'isDeleted': action.isDeleted,
      if (action.updatedAt != null) 'updatedAt': action.updatedAt!.toIso8601String(),
      if (action.pomodorosCompleted != null) 'pomodorosCompleted': action.pomodorosCompleted,
      if (action.totalPomodoroTime != null) 'totalPomodoroTime': action.totalPomodoroTime,
      'contextIds': contextIds,
    };
  }
}

extension ContextOracleExtension on Context {
  Map<String, dynamic> toOracleJson() {
    return {
      '_id': id,
      if (rev != null) '_rev': rev,
      'type': 'context',
      'name': name,
      if (category != null) 'category': category,
      'typeCategory': typeCategory.name,
      'colorValue': colorValue,
      'isDeleted': isDeleted,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

extension RecurringActionOracleExtension on RecurringAction {
  Map<String, dynamic> toOracleJson() {
    return {
      '_id': id,
      if (rev != null) '_rev': rev,
      'type': 'recurring',
      'title': title,
      if (description != null) 'description': description,
      'recurrenceType': type.name,
      'interval': interval,
      'totalCount': totalCount,
      'currentCount': currentCount,
      'nextRunDate': nextRunDate.toIso8601String(),
      'energyLevel': energyLevel,
      'duration': duration,
      'advanceDays': advanceDays,
      'skipHolidays': skipHolidays,
      'contextIds': contextIds,
      'isDeleted': isDeleted,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

extension ScheduledActionOracleExtension on ScheduledAction {
  Map<String, dynamic> toOracleJson() {
    return {
      '_id': id,
      if (rev != null) '_rev': rev,
      'type': 'scheduled',
      'title': title,
      if (description != null) 'description': description,
      'startDate': startDate.toIso8601String(),
      'energyLevel': energyLevel,
      'duration': duration,
      'advanceDays': advanceDays,
      'skipHolidays': skipHolidays,
      'isCreated': isCreated,
      'contextIds': contextIds,
      'isDeleted': isDeleted,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
