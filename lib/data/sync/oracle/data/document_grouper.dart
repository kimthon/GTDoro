/// Oracle Autonomous JSON Database (AJD) 문서 그룹화 유틸리티
class OracleDocumentGrouper {
  /// 문서를 컬렉션별로 그룹화 (이미 toOracleJson()으로 변환된 데이터를 받음)
  /// AJD: 단일 컬렉션에 모든 타입 저장
  static Map<String, List<Map<String, dynamic>>> groupByTable(
    List<Map<String, dynamic>> docs,
    String Function(String type) getCollectionFromType,
  ) {
    final groupedDocs = <String, List<Map<String, dynamic>>>{};
    
    for (final doc in docs) {
      final type = doc['type'] as String? ?? 'todo';
      final collection = getCollectionFromType(type);
      groupedDocs.putIfAbsent(collection, () => []);
      // 이미 toOracleJson()으로 변환된 데이터이므로 그대로 사용
      groupedDocs[collection]!.add(doc);
    }
    
    return groupedDocs;
  }
}
