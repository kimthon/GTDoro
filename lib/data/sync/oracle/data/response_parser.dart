import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import 'package:gtdoro/data/sync/oracle/data/data_converter.dart';
import 'package:gtdoro/data/sync/oracle/data/data_validator.dart';

/// Oracle Autonomous JSON Database (AJD) 응답 파싱 유틸리티
/// SODA REST API 또는 Oracle API Gateway 응답 처리
class OracleResponseParser {
  /// AJD SODA REST API 응답에서 items 추출
  /// 응답 형식: {"items": [...], "hasMore": true/false, "count": N}
  static List<dynamic> extractItems(Map<String, dynamic> responseData) {
    // AJD 응답 형식 확인
    if (responseData.containsKey('items')) {
      return responseData['items'] as List? ?? [];
    }
    return [];
  }

  /// 응답 데이터에서 문서 목록 파싱 (AJD)
  static List<Map<String, dynamic>> parseDocuments(
    Map<String, dynamic> responseData,
    String collectionName,
    String expectedType, {
    bool enableValidation = true,
  }) {
    final items = extractItems(responseData);
    return items
        .cast<Map<String, dynamic>>()
        .map((doc) => _convertDocument(doc, collectionName, expectedType, enableValidation))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// 단일 문서 변환 (AJD JSON 문서)
  static Map<String, dynamic>? _convertDocument(
    Map<String, dynamic> oracleDoc,
    String collectionName,
    String expectedType,
    bool enableValidation,
  ) {
    try {
      dev.log('OracleResponseParser: Converting document - Original keys: ${oracleDoc.keys.join(", ")}, Original _id: ${oracleDoc['_id'] ?? oracleDoc['id'] ?? "missing"}');
      
      final appDoc = OracleDataConverter.convertFromOracle(oracleDoc);
      appDoc['type'] = expectedType;

      // _id 필드 확인 및 정규화
      final docId = appDoc['_id'] as String? ?? appDoc['id'] as String?;
      if (docId != null) {
        appDoc['_id'] = docId;
        appDoc['id'] = docId;
        dev.log('OracleResponseParser: Document converted - ID: $docId, Type: $expectedType, Keys: ${appDoc.keys.join(", ")}');
      } else {
        dev.log('OracleResponseParser: ⚠️ Warning - Document missing ID field, skipping');
        debugPrint('OracleResponseParser: ⚠️ Warning - Document missing ID field, keys: ${appDoc.keys.join(", ")}');
        return null;
      }

      if (enableValidation) {
        final validation = OracleDataValidator.validateDocument(appDoc, expectedType);
        if (!validation.isValid) {
          dev.log('OracleResponseParser: Validation failed for $docId: ${validation.errors.join(', ')}');
          debugPrint('OracleResponseParser: ⚠️ Validation failed for $docId: ${validation.errors.join(', ')}');
        }
      }

      return appDoc;
    } catch (e, stackTrace) {
      dev.log('OracleResponseParser: Error converting document', error: e, stackTrace: stackTrace);
      debugPrint('OracleResponseParser: ❌ Error converting document: $e');
      return null;
    }
  }

  /// JSON 응답 파싱
  static Map<String, dynamic> parseJsonResponse(String responseBody) {
    try {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      dev.log('OracleResponseParser: Failed to parse JSON response', error: e);
      rethrow;
    }
  }

  /// 페이징 정보 추출
  static PagingInfo extractPagingInfo(Map<String, dynamic> responseData) {
    return PagingInfo(
      hasMore: responseData['hasMore'] as bool? ?? false,
      count: responseData['count'] as int?,
      limit: responseData['limit'] as int?,
      offset: responseData['offset'] as int?,
    );
  }
}

/// 페이징 정보
class PagingInfo {
  final bool hasMore;
  final int? count;
  final int? limit;
  final int? offset;

  PagingInfo({
    required this.hasMore,
    this.count,
    this.limit,
    this.offset,
  });
}
