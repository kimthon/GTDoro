import 'dart:developer' as dev;
import 'package:flutter/material.dart';

/// Oracle SODA API 응답에서 메타데이터(_id, _rev)만 추출하는 유틸리티
/// 전체 문서 대신 메타데이터만 사용하여 동기화 효율성 향상
class OracleMetadataExtractor {
  /// 서버 응답에서 메타데이터(_id, _rev)만 추출
  /// 서버 API 표준 1.0: /metadata 엔드포인트 응답 형식 (snake_case: id, rev, type, updated_at)
  /// 반환: {_id: _rev} 맵 (앱 형식으로 변환: id -> _id, rev -> _rev)
  static Map<String, String> extractMetadataFromResponse(
    Map<String, dynamic> responseData,
  ) {
    final metadata = <String, String>{};
    
    try {
      final items = responseData['items'] as List? ?? [];
      
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        
        // 서버 API 표준 1.0: /metadata 엔드포인트 응답 형식
        // {"id": "...", "rev": "...", "type": "...", "updated_at": "..."}
        // snake_case를 앱 형식(camelCase)으로 변환: id -> _id, rev -> _rev
        final serverId = item['id'] as String?;
        final serverRev = item['rev'] as String?;
        
        if (serverId != null && serverId.isNotEmpty) {
          // 앱 형식으로 변환: _id 키 사용
          metadata[serverId] = serverRev ?? '';
        }
      }
      
      debugPrint('OracleMetadataExtractor: Extracted ${metadata.length} metadata entries from response');
    } catch (e, stackTrace) {
      dev.log('OracleMetadataExtractor: Error extracting metadata', error: e, stackTrace: stackTrace);
      debugPrint('OracleMetadataExtractor: ❌ Error extracting metadata: $e');
    }
    
    return metadata;
  }
  
  /// 전체 문서 목록에서 메타데이터만 추출
  /// 이미 파싱된 문서 목록에서 _id와 _rev만 추출
  /// 주의: OracleDataConverter가 _rev를 변환할 수 있으므로 여러 가능한 키를 확인
  static Map<String, String> extractMetadataFromDocs(
    List<Map<String, dynamic>> docs,
  ) {
    final metadata = <String, String>{};
    
    for (final doc in docs) {
      // ID 추출: _id 우선, 없으면 id, 없으면 Id
      final id = doc['_id'] as String? ?? 
                 doc['id'] as String? ?? 
                 doc['Id'] as String?;
      
      // Rev 추출: _rev 우선, 없으면 rev, 없으면 Rev (OracleDataConverter 변환 결과 대응)
      final rev = doc['_rev'] as String? ?? 
                  doc['rev'] as String? ?? 
                  doc['Rev'] as String?;
      
      if (id != null) {
        // _rev가 없어도 메타데이터에 포함 (서버에 존재하는 것으로 표시)
        // 빈 문자열('')로 표시하여 서버에 존재하지만 _rev가 없음을 나타냄
        metadata[id] = rev ?? '';
        if (rev != null && rev.isNotEmpty) {
          debugPrint('OracleMetadataExtractor: Extracted metadata for $id: rev=$rev');
        } else {
          // _rev가 없는 경우도 로그에 기록 (기존 데이터일 수 있음)
          debugPrint('OracleMetadataExtractor: Extracted metadata for $id: rev=null (existing data without rev)');
        }
      }
    }
    
    debugPrint('OracleMetadataExtractor: Extracted ${metadata.length} metadata entries from ${docs.length} documents');
    return metadata;
  }
}
