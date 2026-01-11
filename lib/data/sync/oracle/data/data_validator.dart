/// Oracle 데이터 검증 유틸리티
class OracleDataValidator {
  /// 문서(document) 유효성 검증
  static ValidationResult validateDocument(
    Map<String, dynamic> doc,
    String expectedType,
  ) {
    final errors = <String>[];

    // 필수 필드 확인
    final id = doc['_id'] ?? doc['id'];
    if (id == null || id.toString().isEmpty) {
      errors.add('ID가 없습니다');
    }

    // 타입 확인
    final type = doc['type'] as String?;
    if (type != expectedType) {
      errors.add('예상 타입: $expectedType, 실제 타입: $type');
    }

    // 타입별 검증
    switch (expectedType) {
      case 'todo':
        errors.addAll(_validateAction(doc));
        break;
      case 'context':
        errors.addAll(_validateContext(doc));
        break;
      case 'recurring':
        errors.addAll(_validateRecurringAction(doc));
        break;
      case 'scheduled':
        errors.addAll(_validateScheduledAction(doc));
        break;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Action 문서(document) 검증
  static List<String> _validateAction(Map<String, dynamic> doc) {
    final errors = <String>[];

    // 필수 필드
    if (doc['title'] == null || doc['title'].toString().isEmpty) {
      errors.add('title이 없습니다');
    }

    // 날짜 필드 검증
    if (doc['createdAt'] != null) {
      if (!_isValidDateTime(doc['createdAt'])) {
        errors.add('createdAt 형식이 올바르지 않습니다');
      }
    }

    if (doc['dueDate'] != null) {
      if (!_isValidDateTime(doc['dueDate'])) {
        errors.add('dueDate 형식이 올바르지 않습니다');
      }
    }

    // Boolean 필드 검증
    if (doc['isDone'] != null && !_isValidBoolean(doc['isDone'])) {
      errors.add('isDone이 올바른 boolean 값이 아닙니다');
    }

    if (doc['isDeleted'] != null && !_isValidBoolean(doc['isDeleted'])) {
      errors.add('isDeleted가 올바른 boolean 값이 아닙니다');
    }

    // Enum 검증
    if (doc['status'] != null) {
      final status = doc['status'].toString();
      final validStatuses = ['inbox', 'next', 'waiting', 'scheduled', 'someday', 'completed'];
      if (!validStatuses.contains(status)) {
        errors.add('status가 올바른 값이 아닙니다: $status');
      }
    }

    return errors;
  }

  /// Context 문서(document) 검증
  static List<String> _validateContext(Map<String, dynamic> doc) {
    final errors = <String>[];

    // 필수 필드
    if (doc['name'] == null || doc['name'].toString().isEmpty) {
      errors.add('name이 없습니다');
    }

    if (doc['colorValue'] == null) {
      errors.add('colorValue가 없습니다');
    } else if (doc['colorValue'] is! int) {
      errors.add('colorValue가 정수가 아닙니다');
    }

    // Enum 검증
    if (doc['typeCategory'] != null) {
      final typeCategory = doc['typeCategory'].toString();
      final validTypes = ['location', 'tool', 'person', 'etc'];
      if (!validTypes.contains(typeCategory)) {
        errors.add('typeCategory가 올바른 값이 아닙니다: $typeCategory');
      }
    }

    return errors;
  }

  /// RecurringAction 문서(document) 검증
  static List<String> _validateRecurringAction(Map<String, dynamic> doc) {
    final errors = <String>[];

    // 필수 필드
    if (doc['title'] == null || doc['title'].toString().isEmpty) {
      errors.add('title이 없습니다');
    }

    if (doc['nextRunDate'] != null) {
      if (!_isValidDateTime(doc['nextRunDate'])) {
        errors.add('nextRunDate 형식이 올바르지 않습니다');
      }
    }

    // Enum 검증
    if (doc['recurrenceType'] != null) {
      final recurrenceType = doc['recurrenceType'].toString();
      final validTypes = ['daily', 'weekly', 'monthly'];
      if (!validTypes.contains(recurrenceType)) {
        errors.add('recurrenceType이 올바른 값이 아닙니다: $recurrenceType');
      }
    }

    // 숫자 필드 검증
    if (doc['interval'] != null && doc['interval'] is! int) {
      errors.add('interval이 정수가 아닙니다');
    }

    return errors;
  }

  /// ScheduledAction 문서(document) 검증
  static List<String> _validateScheduledAction(Map<String, dynamic> doc) {
    final errors = <String>[];

    // 필수 필드
    if (doc['title'] == null || doc['title'].toString().isEmpty) {
      errors.add('title이 없습니다');
    }

    if (doc['startDate'] != null) {
      if (!_isValidDateTime(doc['startDate'])) {
        errors.add('startDate 형식이 올바르지 않습니다');
      }
    }

    return errors;
  }

  /// DateTime 유효성 검증
  static bool _isValidDateTime(dynamic value) {
    if (value == null) return false;
    if (value is DateTime) return true;
    if (value is String) {
      try {
        DateTime.parse(value);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Boolean 유효성 검증
  static bool _isValidBoolean(dynamic value) {
    if (value is bool) return true;
    if (value is int) return value == 0 || value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == 'false' || lower == '1' || lower == '0';
    }
    return false;
  }

  /// 배치 문서(document) 검증
  static List<ValidationResult> validateBatch(
    List<Map<String, dynamic>> docs,
    String expectedType,
  ) {
    return docs.map((doc) => validateDocument(doc, expectedType)).toList();
  }

  /// 검증 결과 요약
  static ValidationSummary summarizeValidation(
    List<ValidationResult> results,
  ) {
    final validCount = results.where((r) => r.isValid).length;
    final invalidCount = results.length - validCount;
    final allErrors = results
        .where((r) => !r.isValid)
        .expand((r) => r.errors)
        .toList();

    return ValidationSummary(
      total: results.length,
      valid: validCount,
      invalid: invalidCount,
      allErrors: allErrors,
    );
  }
}

/// 검증 결과
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });

  @override
  String toString() {
    if (isValid) {
      return 'Valid';
    }
    return 'Invalid: ${errors.join(', ')}';
  }
}

/// 검증 요약
class ValidationSummary {
  final int total;
  final int valid;
  final int invalid;
  final List<String> allErrors;

  ValidationSummary({
    required this.total,
    required this.valid,
    required this.invalid,
    required this.allErrors,
  });

  double get successRate => total > 0 ? valid / total : 0.0;

  @override
  String toString() {
    return 'Total: $total, Valid: $valid, Invalid: $invalid, Success Rate: ${(successRate * 100).toStringAsFixed(1)}%';
  }
}
