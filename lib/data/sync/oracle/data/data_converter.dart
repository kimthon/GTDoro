import 'package:flutter/material.dart';

/// Oracle API Gateway 응답을 앱 형식으로 변환하는 유틸리티
/// (업로드 시에는 toOracleJson() 사용, 변환 불필요)
class OracleDataConverter {
  /// snake_case를 camelCase로 변환
  static String _snakeToCamel(String snake) {
    final parts = snake.split('_');
    if (parts.isEmpty) return snake;
    
    final result = StringBuffer(parts[0].toLowerCase());
    for (int i = 1; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      result.write(part[0].toUpperCase());
      if (part.length > 1) {
        result.write(part.substring(1).toLowerCase());
      }
    }
    return result.toString();
  }

  /// Oracle 응답을 앱 형식으로 변환 (다운로드 시 사용)
  /// Oracle SODA API 응답 형식 처리: {"id": "...", "etag": "...", "value": {...}}
  /// 델타 동기화 응답 형식 처리: {"data": {...}}
  static Map<String, dynamic> convertFromOracle(Map<String, dynamic> oracleDoc) {
    debugPrint('OracleDataConverter: Converting Oracle document - Original keys: ${oracleDoc.keys.join(", ")}');
    
    // 데이터 봉투 풀기: data -> value -> 직접 문서 형식 순서로 체크
    Map<String, dynamic> actualDoc;
    if (oracleDoc.containsKey('data') && oracleDoc['data'] is Map<String, dynamic>) {
      // 델타 동기화 응답 형식: data 필드 안에 실제 데이터가 있음
      actualDoc = oracleDoc['data'] as Map<String, dynamic>;
      debugPrint('OracleDataConverter: Found delta sync format - extracting data from "data" field');
    } else if (oracleDoc.containsKey('value') && oracleDoc['value'] is Map<String, dynamic>) {
      // Oracle SODA API 응답 형식: value 필드 안에 실제 데이터가 있음
      actualDoc = oracleDoc['value'] as Map<String, dynamic>;
      debugPrint('OracleDataConverter: Found SODA API format - extracting data from "value" field');
    } else {
      // 직접 문서 형식 (data, value 필드 없음)
      actualDoc = oracleDoc;
      debugPrint('OracleDataConverter: Direct document format - processing top-level fields');
    }
    
    final appDoc = <String, dynamic>{};
    
    // RESID 필드가 있으면 _id로 변환 (Oracle DB의 기본 동작)
    if (actualDoc.containsKey('RESID')) {
      appDoc['_id'] = actualDoc['RESID'].toString();
      appDoc['id'] = actualDoc['RESID'].toString();
      debugPrint('OracleDataConverter: Found RESID field: ${actualDoc['RESID']}');
    }
    
    for (final entry in actualDoc.entries) {
      final key = entry.key;
      var value = entry.value;
      
      // RESID는 이미 처리했으므로 건너뜀
      if (key == 'RESID') continue;
      
      // 필드명 변환: snake_case 또는 UPPER_SNAKE_CASE -> camelCase
      // _로 시작하는 필드(_id, _rev 등)는 그대로 유지
      final appKey = key.startsWith('_')
          ? key  // _id, _rev 등은 그대로 유지
          : key.contains('_') 
              ? _snakeToCamel(key)
              : (key.isNotEmpty && key[0] == key[0].toUpperCase())
                  ? key[0].toLowerCase() + (key.length > 1 ? key.substring(1) : '')
                  : key;
      
      // _id 또는 id 필드 처리
      if (appKey == '_id' || appKey == 'id') {
        if (value is String) {
          // 이미 UUID 형식이면 그대로 사용
          if (_isValidUuid(value)) {
            appDoc['_id'] = value;
            appDoc['id'] = value;
            debugPrint('OracleDataConverter: ID field (UUID format): $value');
          } else {
            // 16진수 인코딩된 경우 디코딩 시도
            value = _decodeHexId(value);
            appDoc['_id'] = value;
            appDoc['id'] = value;
            debugPrint('OracleDataConverter: ID field converted - Original: ${entry.value}, Converted: $value');
          }
        } else {
          appDoc['_id'] = value?.toString();
          appDoc['id'] = value?.toString();
        }
        continue;
      }
      
      // 값 변환
      if (value != null) {
        if (_isBooleanField(appKey)) {
          value = _oracleBoolToDart(value);
        } else if (_isDateTimeField(appKey) && value is String) {
          value = _parseOracleTimestamp(value);
        }
      }
      
      appDoc[appKey] = value;
    }
    
    // _id가 없으면 id를 _id로 복사
    if (!appDoc.containsKey('_id') || appDoc['_id'] == null) {
      if (appDoc.containsKey('id') && appDoc['id'] != null) {
        appDoc['_id'] = appDoc['id'];
      } else {
        debugPrint('OracleDataConverter: ⚠️ Warning - No _id or id field found in document');
      }
    }
    
    // _id와 id 모두 설정 (일관성 유지)
    if (appDoc.containsKey('_id') && appDoc['_id'] != null) {
      appDoc['id'] = appDoc['_id'];
    }
    
    debugPrint('OracleDataConverter: Converted document - Keys: ${appDoc.keys.join(", ")}, _id: ${appDoc['_id'] ?? 'missing'}');
    
    return appDoc;
  }
  
  /// 16진수로 인코딩된 ID를 디코딩
  /// Oracle DB에서 ID를 16진수로 인코딩하는 경우 처리
  /// 예: "0431356464333235642D..." -> "15dd325d-3741-4cda-b7e4-d85f85113b3c"
  static String _decodeHexId(String encodedId) {
    // UUID 형식이면 그대로 반환 (이미 디코딩됨)
    if (_isValidUuid(encodedId)) {
      return encodedId;
    }
    
    // 16진수 인코딩된 것으로 보이는 경우 디코딩 시도
    if (encodedId.length > 10 && encodedId[0] == '0') {
      try {
        // 첫 번째 '0' 제거
        final hexString = encodedId.substring(1);
        
        // 2자리씩 16진수로 파싱하여 ASCII 문자로 변환
        final decoded = StringBuffer();
        for (int i = 0; i < hexString.length; i += 2) {
          if (i + 1 < hexString.length) {
            final hexPair = hexString.substring(i, i + 2);
            final charCode = int.parse(hexPair, radix: 16);
            decoded.writeCharCode(charCode);
          }
        }
        
        final decodedId = decoded.toString();
        
        // 디코딩 결과가 유효한 UUID인지 확인
        if (_isValidUuid(decodedId)) {
          return decodedId;
        }
      } catch (e) {
        // 디코딩 실패 시 원본 반환
      }
    }
    
    // 디코딩할 수 없으면 원본 반환
    return encodedId;
  }
  
  /// UUID 형식인지 확인
  static bool _isValidUuid(String id) {
    // UUID v4 형식: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidPattern.hasMatch(id);
  }

  /// Oracle Boolean (NUMBER(1,0))을 Dart bool로 변환
  static bool _oracleBoolToDart(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'y';
    }
    return false;
  }

  /// Oracle 타임스탬프 문자열을 DateTime으로 파싱
  static DateTime? _parseOracleTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is! String) return null;
    
    try {
      return DateTime.parse(value);
    } catch (_) {
      // Oracle TIMESTAMP 형식 시도 (YYYY-MM-DD HH24:MI:SS.FF)
      try {
        return DateTime.parse(value.replaceAll(' ', 'T'));
      } catch (_) {
        return null;
      }
    }
  }

  /// Boolean 필드인지 확인
  static bool _isBooleanField(String fieldName) {
    final boolFields = [
      'isDone', 'isDeleted', 'isCreated', 'skipHolidays',
      'is_done', 'is_deleted', 'is_created', 'skip_holidays',
    ];
    return boolFields.contains(fieldName.toLowerCase());
  }

  /// DateTime 필드인지 확인
  static bool _isDateTimeField(String fieldName) {
    final dateFields = [
      'createdAt', 'updatedAt', 'dueDate', 'completedAt',
      'nextRunDate', 'startDate',
      'created_at', 'updated_at', 'due_date', 'completed_at',
      'next_run_date', 'start_date',
    ];
    return dateFields.any((field) => fieldName.toLowerCase().contains(field.toLowerCase()));
  }
}
