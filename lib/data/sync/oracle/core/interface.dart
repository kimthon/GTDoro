import 'package:gtdoro/data/sync/models/sync_config.dart';

/// Common interface for sync services
/// Oracle sync service implements this interface
abstract class SyncServiceInterface {
  /// Check connection to the server
  Future<bool> checkConnection(SyncConfig config);

  /// Download all documents (initial sync)
  Future<List<Map<String, dynamic>>> downloadAllDocs(SyncConfig config);

  /// Download changed documents (delta sync)
  Future<Map<String, dynamic>> downloadChangedDocs(
    SyncConfig config,
    String? lastSeq,
  );

  /// Download maximum _rev value for each type (optimized metadata fetch)
  /// Returns a map of type -> (_id, _rev) for the document with the highest _rev
  Future<Map<String, Map<String, String>>> downloadMaxRevMetadata(SyncConfig config);

  /// Upload documents
  Future<void> uploadDocs(
    SyncConfig config,
    List<Map<String, dynamic>> docs,
  );

  /// Delete a document
  Future<void> deleteDoc(SyncConfig config, String id, String rev);

  /// SQL 쿼리 실행 (ORDS SQL 엔드포인트 사용)
  /// Oracle REST Data Services를 통해 직접 SQL을 실행하여 최대 rev 값 조회
  /// 예: SELECT MAX(JSON_VALUE(json_document, '$._rev' RETURNING NUMBER)) AS max_rev FROM GTDORO;
  Future<Map<String, dynamic>?> executeSqlQuery(String sql);
}
