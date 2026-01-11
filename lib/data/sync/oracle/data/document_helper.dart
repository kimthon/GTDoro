import 'dart:convert';
import 'dart:developer' as dev;
import 'package:gtdoro/data/sync/oracle/conflict/resolver.dart';

/// Oracle 문서 처리 헬퍼 유틸리티
/// 문서 변환, 검증, rev 생성 등 공통 로직 제공
class OracleDocumentHelper {
  /// 문서에서 rev 값 추출 (여러 기기 동시 사용 고려)
  /// 원격 rev가 없으면 updatedAt 기반으로 생성
  static String extractOrGenerateRev(Map<String, dynamic> doc) {
    final rev = doc['_rev'] as String?;
    if (rev != null && rev.isNotEmpty) {
      return rev;
    }

    // rev가 없으면 updatedAt 기반으로 생성
    final updatedAt = OracleConflictResolver.getUpdatedAt(doc);
    if (updatedAt != null) {
      return '${updatedAt.millisecondsSinceEpoch}';
    }

    // updatedAt도 없으면 현재 시간 기반으로 생성
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 문서에서 updatedAt 추출 및 파싱
  static DateTime? parseUpdatedAt(Map<String, dynamic> doc) {
    final updatedAtValue = doc['updatedAt'] ?? doc['updated_at'];
    if (updatedAtValue == null) return null;
    
    if (updatedAtValue is DateTime) return updatedAtValue;
    if (updatedAtValue is String) {
      try {
        return DateTime.parse(updatedAtValue);
      } catch (e) {
        dev.log('OracleDocumentHelper: Failed to parse updatedAt: $updatedAtValue', error: e);
        return null;
      }
    }
    return null;
  }

  /// 문서에서 날짜 필드 안전하게 파싱
  static DateTime? parseDateField(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        dev.log('OracleDocumentHelper: Failed to parse date: $value', error: e);
        return null;
      }
    }
    return null;
  }

  /// 문서 유효성 검증 (필수 필드 확인)
  static bool isValidDocument(Map<String, dynamic> doc) {
    final id = doc['_id'] ?? doc['id'];
    final type = doc['type'];

    if (id == null || type == null) {
      return false;
    }

    if (id is! String || type is! String) {
      return false;
    }

    if (!['todo', 'context', 'recurring', 'scheduled'].contains(type)) {
      return false;
    }

    return true;
  }

  /// 문서에서 필수 필드 추출
  static Map<String, dynamic>? extractRequiredFields(
    Map<String, dynamic> doc,
    List<String> requiredFields,
  ) {
    final result = <String, dynamic>{};
    for (final field in requiredFields) {
      if (!doc.containsKey(field) || doc[field] == null) {
        return null;
      }
      result[field] = doc[field];
    }
    return result;
  }

  /// 문서 크기 추정 (JSON 직렬화 크기)
  static int estimateDocumentSize(Map<String, dynamic> doc) {
    try {
      final jsonString = jsonEncode(doc);
      return utf8.encode(jsonString).length;
    } catch (e) {
      dev.log('OracleDocumentHelper: Error estimating document size', error: e);
      return 0;
    }
  }

  /// 문서 타입별 필수 필드 목록
  static List<String> getRequiredFieldsForType(String type) {
    switch (type) {
      case 'todo':
        return ['_id', 'type', 'title', 'status', 'createdAt'];
      case 'context':
        return ['_id', 'type', 'name', 'typeCategory', 'colorValue'];
      case 'recurring':
        return ['_id', 'type', 'title', 'recurrenceType', 'nextRunDate'];
      case 'scheduled':
        return ['_id', 'type', 'title', 'startDate'];
      default:
        return ['_id', 'type'];
    }
  }
}
