import 'dart:developer' as dev;
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/sync/oracle/data/document_helper.dart';

/// Oracle 문서를 Drift Companion으로 변환하는 팩토리
/// 타입별 Companion 생성 로직 중복 제거
class OracleCompanionFactory {
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
    dev.log('OracleCompanionFactory: Invalid contextIds type: ${value.runtimeType}');
    return <String>[];
  }
  /// Todo 문서를 ActionsCompanion으로 변환
  static ActionsCompanion? createActionCompanion(Map<String, dynamic> doc) {
    try {
      final id = doc['_id'] as String? ?? doc['id'] as String?;
      if (id == null) {
        debugPrint('OracleCompanionFactory: ❌ Missing ID in document. Keys: ${doc.keys.join(", ")}');
        dev.log('OracleCompanionFactory: Missing ID in document. Keys: ${doc.keys.join(", ")}');
        return null;
      }
      
      debugPrint('OracleCompanionFactory: Processing todo document - ID: $id');
      debugPrint('OracleCompanionFactory: Document keys: ${doc.keys.join(", ")}');
      debugPrint('OracleCompanionFactory: title: ${doc['title']}, status: ${doc['status']}, createdAt: ${doc['createdAt']}');

      // 필수 필드 검증
      if (doc['title'] == null || doc['status'] == null || doc['createdAt'] == null) {
        debugPrint('OracleCompanionFactory: ❌ Invalid todo document, missing required fields:');
        debugPrint('  - ID: $id');
        debugPrint('  - title: ${doc['title']} (${doc['title']?.runtimeType})');
        debugPrint('  - status: ${doc['status']} (${doc['status']?.runtimeType})');
        debugPrint('  - createdAt: ${doc['createdAt']} (${doc['createdAt']?.runtimeType})');
        dev.log('OracleCompanionFactory: Invalid todo document, missing required fields: $id');
        return null;
      }

      final rev = OracleDocumentHelper.extractOrGenerateRev(doc);
      final updatedAt = OracleDocumentHelper.parseUpdatedAt(doc);
      final createdAt = OracleDocumentHelper.parseDateField(doc['createdAt']);
      
      if (createdAt == null) {
        dev.log('OracleCompanionFactory: Invalid createdAt for todo $id');
        return null;
      }

      // 상태 검증 (안정성 강화: 타입 안전성)
      final statusValue = doc['status'];
      if (statusValue == null || statusValue is! String) {
        dev.log('OracleCompanionFactory: Invalid status type for todo $id, using inbox');
        return null;
      }
      
      GTDStatus status;
      try {
        status = GTDStatus.values.byName(statusValue);
      } catch (e) {
        dev.log('OracleCompanionFactory: Invalid status "$statusValue" for todo $id, using inbox', error: e);
        status = GTDStatus.inbox;
      }

      // title 타입 검증 (안정성 강화)
      final titleValue = doc['title'];
      if (titleValue == null || titleValue is! String) {
        dev.log('OracleCompanionFactory: Invalid title type for todo $id');
        return null;
      }

      return ActionsCompanion.insert(
        id: id,
        rev: Value(rev),
        title: titleValue,
        description: Value(doc['description'] as String?),
        waitingFor: Value(doc['waitingFor'] as String?),
        isDone: Value(doc['isDone'] as bool? ?? false),
        status: Value(status),
        energyLevel: Value(doc['energyLevel'] as int?),
        duration: Value(doc['duration'] as int?),
        createdAt: createdAt,
        dueDate: Value(OracleDocumentHelper.parseDateField(doc['dueDate'])),
        completedAt: Value(OracleDocumentHelper.parseDateField(doc['completedAt'])),
        isDeleted: Value(doc['isDeleted'] as bool? ?? false),
        updatedAt: Value(updatedAt ?? DateTime.now()),
        pomodorosCompleted: Value(doc['pomodorosCompleted'] as int? ?? 0),
        totalPomodoroTime: Value(doc['totalPomodoroTime'] as int?),
      );
    } catch (e, stackTrace) {
      dev.log('OracleCompanionFactory: Error creating ActionCompanion', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Context 문서를 ContextsCompanion으로 변환
  static ContextsCompanion? createContextCompanion(Map<String, dynamic> doc) {
    try {
      final id = doc['_id'] as String? ?? doc['id'] as String?;
      if (id == null) return null;

      // 필수 필드 검증
      if (doc['name'] == null || doc['typeCategory'] == null || doc['colorValue'] == null) {
        dev.log('OracleCompanionFactory: Invalid context document, missing required fields: $id');
        return null;
      }

      final rev = OracleDocumentHelper.extractOrGenerateRev(doc);
      final updatedAt = OracleDocumentHelper.parseUpdatedAt(doc);

      // 타입 검증 (안정성 강화: 타입 안전성)
      final typeCategoryValue = doc['typeCategory'];
      if (typeCategoryValue == null || typeCategoryValue is! String) {
        dev.log('OracleCompanionFactory: Invalid typeCategory type for context $id, using etc');
        return null;
      }
      
      ContextType typeCategory;
      try {
        typeCategory = ContextType.values.byName(typeCategoryValue);
      } catch (e) {
        dev.log('OracleCompanionFactory: Invalid typeCategory "$typeCategoryValue" for context $id, using etc', error: e);
        typeCategory = ContextType.etc;
      }

      // name 타입 검증 (안정성 강화)
      final nameValue = doc['name'];
      if (nameValue == null || nameValue is! String) {
        dev.log('OracleCompanionFactory: Invalid name type for context $id');
        return null;
      }

      // colorValue 타입 검증 (안정성 강화)
      final colorValue = doc['colorValue'];
      if (colorValue == null || colorValue is! int) {
        dev.log('OracleCompanionFactory: Invalid colorValue type for context $id');
        return null;
      }

      return ContextsCompanion.insert(
        id: id,
        rev: Value(rev),
        name: nameValue,
        category: Value(doc['category'] as String?),
        typeCategory: typeCategory,
        colorValue: colorValue,
        isDeleted: Value(doc['isDeleted'] as bool? ?? false),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
    } catch (e, stackTrace) {
      dev.log('OracleCompanionFactory: Error creating ContextCompanion', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// RecurringAction 문서를 RecurringActionsCompanion으로 변환
  static RecurringActionsCompanion? createRecurringActionCompanion(Map<String, dynamic> doc) {
    try {
      final id = doc['_id'] as String? ?? doc['id'] as String?;
      if (id == null) return null;

      // 필수 필드 검증
      if (doc['title'] == null || doc['recurrenceType'] == null || doc['nextRunDate'] == null) {
        dev.log('OracleCompanionFactory: Invalid recurring document, missing required fields: $id');
        return null;
      }

      final rev = OracleDocumentHelper.extractOrGenerateRev(doc);
      final updatedAt = OracleDocumentHelper.parseUpdatedAt(doc);

      // 타입 검증 (안정성 강화: 타입 안전성)
      final recurrenceTypeValue = doc['recurrenceType'];
      if (recurrenceTypeValue == null || recurrenceTypeValue is! String) {
        dev.log('OracleCompanionFactory: Invalid recurrenceType type for recurring $id');
        return null;
      }
      
      RecurrenceType recurrenceType;
      try {
        recurrenceType = RecurrenceType.values.byName(recurrenceTypeValue);
      } catch (e) {
        dev.log('OracleCompanionFactory: Invalid recurrenceType "$recurrenceTypeValue" for recurring $id', error: e);
        return null;
      }

      // 날짜 파싱
      final nextRunDate = OracleDocumentHelper.parseDateField(doc['nextRunDate']);
      if (nextRunDate == null) {
        dev.log('OracleCompanionFactory: Invalid nextRunDate for recurring $id');
        return null;
      }

      // title 타입 검증 (안정성 강화)
      final titleValue = doc['title'];
      if (titleValue == null || titleValue is! String) {
        dev.log('OracleCompanionFactory: Invalid title type for recurring $id');
        return null;
      }

      return RecurringActionsCompanion.insert(
        id: id,
        rev: Value(rev),
        title: titleValue,
        description: Value(doc['description'] as String?),
        type: recurrenceType,
        interval: Value(doc['interval'] as int? ?? 1),
        totalCount: Value(doc['totalCount'] as int? ?? 0),
        currentCount: Value(doc['currentCount'] as int? ?? 0),
        nextRunDate: nextRunDate,
        energyLevel: Value(doc['energyLevel'] as int? ?? 3),
        duration: Value(doc['duration'] as int? ?? 10),
        advanceDays: Value(doc['advanceDays'] as int? ?? 0),
        skipHolidays: Value(doc['skipHolidays'] as bool? ?? false),
        contextIds: Value(_parseContextIds(doc['contextIds'])),
        isDeleted: Value(doc['isDeleted'] as bool? ?? false),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
    } catch (e, stackTrace) {
      dev.log('OracleCompanionFactory: Error creating RecurringActionCompanion', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// ScheduledAction 문서를 ScheduledActionsCompanion으로 변환
  static ScheduledActionsCompanion? createScheduledActionCompanion(Map<String, dynamic> doc) {
    try {
      final id = doc['_id'] as String? ?? doc['id'] as String?;
      if (id == null) return null;

      // 필수 필드 검증
      if (doc['title'] == null || doc['startDate'] == null) {
        dev.log('OracleCompanionFactory: Invalid scheduled document, missing required fields: $id');
        return null;
      }

      final rev = OracleDocumentHelper.extractOrGenerateRev(doc);
      final updatedAt = OracleDocumentHelper.parseUpdatedAt(doc);

      // 날짜 파싱
      final startDate = OracleDocumentHelper.parseDateField(doc['startDate']);
      if (startDate == null) {
        dev.log('OracleCompanionFactory: Invalid startDate for scheduled $id');
        return null;
      }

      // title 타입 검증 (안정성 강화)
      final titleValue = doc['title'];
      if (titleValue == null || titleValue is! String) {
        dev.log('OracleCompanionFactory: Invalid title type for scheduled $id');
        return null;
      }

      return ScheduledActionsCompanion.insert(
        id: id,
        rev: Value(rev),
        title: titleValue,
        description: Value(doc['description'] as String?),
        startDate: startDate,
        energyLevel: Value(doc['energyLevel'] as int? ?? 3),
        duration: Value(doc['duration'] as int? ?? 10),
        advanceDays: Value(doc['advanceDays'] as int? ?? 0),
        skipHolidays: Value(doc['skipHolidays'] as bool? ?? false),
        isCreated: Value(doc['isCreated'] as bool? ?? false),
        contextIds: Value(_parseContextIds(doc['contextIds'])),
        isDeleted: Value(doc['isDeleted'] as bool? ?? false),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
    } catch (e, stackTrace) {
      dev.log('OracleCompanionFactory: Error creating ScheduledActionCompanion', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
