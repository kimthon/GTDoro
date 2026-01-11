/// Oracle API Gateway 쿼리 파라미터 헬퍼
/// URL에 쿼리 파라미터만 추가 (경로 조립 불필요 - 게이트웨이에서 이미 매핑됨)
class OracleUrlHelper {
  /// URL에 쿼리 파라미터 추가
  static String addQueryParams(String url, {
    int? limit,
    int? offset,
    DateTime? sinceDate,
    String? type,
    String? orderBy, // 정렬 필드 (예: "_rev", "-_rev" 또는 "{\"$orderby\":\"_rev\",\"$desc\":true}")
  }) {
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    if (offset != null) {
      queryParams['offset'] = offset.toString();
    }
    
    // 정렬 파라미터 (Oracle SODA API 형식: JSON 또는 단순 필드명)
    if (orderBy != null && orderBy.isNotEmpty) {
      // "-"로 시작하면 내림차순
      if (orderBy.startsWith('-')) {
        final field = orderBy.substring(1);
        // Oracle SODA API 형식: {"$orderby":[{"$orderby":"_rev","$desc":true}]}
        queryParams['orderby'] = '[{"\$orderby":"$field","\$desc":true}]';
      } else {
        // 오름차순
        queryParams['orderby'] = '[{"\$orderby":"$orderBy"}]';
      }
    }
    
    // 날짜 필터 (updatedAt 기준)
    if (sinceDate != null) {
      final sinceStr = sinceDate.toIso8601String();
      final existingQuery = queryParams['q'];
      if (existingQuery != null) {
        // 기존 쿼리와 AND 조건으로 결합
        queryParams['q'] = '{"\$and":[$existingQuery,{"updatedAt":{"\$gt":"$sinceStr"}}]}';
      } else {
        queryParams['q'] = '{"updatedAt":{"\$gt":"$sinceStr"}}';
      }
    }
    
    // 타입 필터 (단일 컬렉션 사용 시)
    if (type != null && type.isNotEmpty) {
      final existingQuery = queryParams['q'];
      if (existingQuery != null) {
        // 기존 쿼리와 AND 조건으로 결합
        queryParams['q'] = '{"\$and":[{"type":"$type"},$existingQuery]}';
      } else {
        queryParams['q'] = '{"type":"$type"}';
      }
    }
    
    return uri.replace(queryParameters: queryParams).toString();
  }
}
