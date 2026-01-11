import 'dart:developer' as dev;
import 'package:gtdoro/data/sync/models/sync_config.dart';

/// Oracle 동기화 캐시 매니저
/// 연결 정보, 메타데이터, 응답 데이터를 캐싱하여 성능 최적화
class OracleCacheManager {
  static final OracleCacheManager _instance = OracleCacheManager._internal();
  factory OracleCacheManager() => _instance;
  OracleCacheManager._internal();

  // 연결 정보 캐시
  final Map<String, bool> _connectionCache = {};
  final Map<String, DateTime> _connectionCacheTime = {};
  static const Duration _connectionCacheDuration = Duration(minutes: 5);

  // 메타데이터 캐시 (컬렉션 정보 등, AJD)
  final Map<String, Map<String, dynamic>> _metadataCache = {};
  final Map<String, DateTime> _metadataCacheTime = {};
  static const Duration _metadataCacheDuration = Duration(hours: 1);

  // 응답 데이터 캐시 (읽기 전용 데이터)
  final Map<String, List<Map<String, dynamic>>> _responseCache = {};
  final Map<String, DateTime> _responseCacheTime = {};
  static const Duration _responseCacheDuration = Duration(minutes: 10);

  // 캐시 키 생성
  String _getConnectionCacheKey(SyncConfig config) {
    return 'connection_${config.url}_${config.dbName}_${config.username}';
  }

  String _getMetadataCacheKey(SyncConfig config, String table) {
    return 'metadata_${config.url}_${config.dbName}_$table';
  }

  String _getResponseCacheKey(SyncConfig config, String table, {String? query}) {
    final queryStr = query ?? 'all';
    return 'response_${config.url}_${config.dbName}_${table}_$queryStr';
  }

  /// 연결 상태 캐시 확인
  bool? getCachedConnectionStatus(SyncConfig config) {
    final key = _getConnectionCacheKey(config);
    final cachedTime = _connectionCacheTime[key];
    
    if (cachedTime == null) return null;
    
    final now = DateTime.now();
    if (now.difference(cachedTime) > _connectionCacheDuration) {
      // 캐시 만료
      _connectionCache.remove(key);
      _connectionCacheTime.remove(key);
      return null;
    }
    
    return _connectionCache[key];
  }

  /// 연결 상태 캐시 저장
  void cacheConnectionStatus(SyncConfig config, bool status) {
    final key = _getConnectionCacheKey(config);
    _connectionCache[key] = status;
    _connectionCacheTime[key] = DateTime.now();
    dev.log('OracleCacheManager: Cached connection status for $key: $status');
  }

  /// 연결 상태 캐시 무효화
  void invalidateConnectionCache(SyncConfig config) {
    final key = _getConnectionCacheKey(config);
    _connectionCache.remove(key);
    _connectionCacheTime.remove(key);
    dev.log('OracleCacheManager: Invalidated connection cache for $key');
  }

  /// 메타데이터 캐시 확인
  Map<String, dynamic>? getCachedMetadata(SyncConfig config, String table) {
    final key = _getMetadataCacheKey(config, table);
    final cachedTime = _metadataCacheTime[key];
    
    if (cachedTime == null) return null;
    
    final now = DateTime.now();
    if (now.difference(cachedTime) > _metadataCacheDuration) {
      // 캐시 만료
      _metadataCache.remove(key);
      _metadataCacheTime.remove(key);
      return null;
    }
    
    return _metadataCache[key];
  }

  /// 메타데이터 캐시 저장
  void cacheMetadata(SyncConfig config, String table, Map<String, dynamic> metadata) {
    final key = _getMetadataCacheKey(config, table);
    _metadataCache[key] = Map<String, dynamic>.from(metadata);
    _metadataCacheTime[key] = DateTime.now();
    dev.log('OracleCacheManager: Cached metadata for $key');
  }

  /// 메타데이터 캐시 무효화
  void invalidateMetadataCache(SyncConfig config, {String? table}) {
    if (table != null) {
      final key = _getMetadataCacheKey(config, table);
      _metadataCache.remove(key);
      _metadataCacheTime.remove(key);
      dev.log('OracleCacheManager: Invalidated metadata cache for $key');
    } else {
      // 모든 메타데이터 캐시 무효화
      final keysToRemove = _metadataCache.keys
          .where((k) => k.contains('${config.url}_${config.dbName}'))
          .toList();
      for (final key in keysToRemove) {
        _metadataCache.remove(key);
        _metadataCacheTime.remove(key);
      }
      dev.log('OracleCacheManager: Invalidated all metadata cache for ${config.dbName}');
    }
  }

  /// 응답 데이터 캐시 확인
  List<Map<String, dynamic>>? getCachedResponse(
    SyncConfig config,
    String table, {
    String? query,
  }) {
    final key = _getResponseCacheKey(config, table, query: query);
    final cachedTime = _responseCacheTime[key];
    
    if (cachedTime == null) return null;
    
    final now = DateTime.now();
    if (now.difference(cachedTime) > _responseCacheDuration) {
      // 캐시 만료
      _responseCache.remove(key);
      _responseCacheTime.remove(key);
      return null;
    }
    
    return _responseCache[key]?.map((doc) => Map<String, dynamic>.from(doc)).toList();
  }

  /// 응답 데이터 캐시 저장
  void cacheResponse(
    SyncConfig config,
    String table,
    List<Map<String, dynamic>> data, {
    String? query,
  }) {
    final key = _getResponseCacheKey(config, table, query: query);
    _responseCache[key] = data.map((doc) => Map<String, dynamic>.from(doc)).toList();
    _responseCacheTime[key] = DateTime.now();
    dev.log('OracleCacheManager: Cached response for $key (${data.length} items)');
  }

  /// 응답 데이터 캐시 무효화
  void invalidateResponseCache(SyncConfig config, {String? table}) {
    if (table != null) {
      // 특정 테이블의 모든 응답 캐시 무효화
      final keysToRemove = _responseCache.keys
          .where((k) => k.contains('${config.url}_${config.dbName}_$table'))
          .toList();
      for (final key in keysToRemove) {
        _responseCache.remove(key);
        _responseCacheTime.remove(key);
      }
      dev.log('OracleCacheManager: Invalidated response cache for ${config.dbName}.$table');
    } else {
      // 모든 응답 캐시 무효화
      final keysToRemove = _responseCache.keys
          .where((k) => k.contains('${config.url}_${config.dbName}'))
          .toList();
      for (final key in keysToRemove) {
        _responseCache.remove(key);
        _responseCacheTime.remove(key);
      }
      dev.log('OracleCacheManager: Invalidated all response cache for ${config.dbName}');
    }
  }

  /// 모든 캐시 무효화 (설정 변경 시)
  void invalidateAllCache(SyncConfig config) {
    invalidateConnectionCache(config);
    invalidateMetadataCache(config);
    invalidateResponseCache(config);
    dev.log('OracleCacheManager: Invalidated all cache for ${config.dbName}');
  }

  /// 캐시 통계
  Map<String, dynamic> getCacheStats() {
    return {
      'connection_cache_size': _connectionCache.length,
      'metadata_cache_size': _metadataCache.length,
      'response_cache_size': _responseCache.length,
      'total_cache_entries': _connectionCache.length + _metadataCache.length + _responseCache.length,
    };
  }

  /// 캐시 정리 (만료된 항목 제거)
  void cleanupExpiredCache() {
    final now = DateTime.now();
    int cleaned = 0;

    // 연결 캐시 정리
    final connectionKeysToRemove = _connectionCacheTime.entries
        .where((e) => now.difference(e.value) > _connectionCacheDuration)
        .map((e) => e.key)
        .toList();
    for (final key in connectionKeysToRemove) {
      _connectionCache.remove(key);
      _connectionCacheTime.remove(key);
      cleaned++;
    }

    // 메타데이터 캐시 정리
    final metadataKeysToRemove = _metadataCacheTime.entries
        .where((e) => now.difference(e.value) > _metadataCacheDuration)
        .map((e) => e.key)
        .toList();
    for (final key in metadataKeysToRemove) {
      _metadataCache.remove(key);
      _metadataCacheTime.remove(key);
      cleaned++;
    }

    // 응답 캐시 정리
    final responseKeysToRemove = _responseCacheTime.entries
        .where((e) => now.difference(e.value) > _responseCacheDuration)
        .map((e) => e.key)
        .toList();
    for (final key in responseKeysToRemove) {
      _responseCache.remove(key);
      _responseCacheTime.remove(key);
      cleaned++;
    }

    if (cleaned > 0) {
      dev.log('OracleCacheManager: Cleaned up $cleaned expired cache entries');
    }
  }
}
