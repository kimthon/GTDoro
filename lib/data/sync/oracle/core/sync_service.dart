import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import 'package:gtdoro/core/config/app_config.dart';
import 'package:gtdoro/core/constants/sync_constants.dart';
import 'package:gtdoro/data/sync/oracle/cache/manager.dart';
import 'package:gtdoro/data/sync/oracle/core/constants.dart';
import 'package:gtdoro/data/sync/oracle/data/document_grouper.dart';
import 'package:gtdoro/data/sync/oracle/error/handler.dart';
import 'package:gtdoro/data/sync/oracle/network/network_monitor.dart';
import 'package:gtdoro/data/sync/oracle/monitor/performance_monitor.dart';
import 'package:gtdoro/data/sync/oracle/data/response_parser.dart';
import 'package:gtdoro/data/sync/oracle/data/data_converter.dart';
import 'package:gtdoro/data/sync/oracle/data/data_validator.dart';
import 'package:gtdoro/data/sync/oracle/core/metadata_extractor.dart';
import 'package:gtdoro/data/sync/oracle/utils/url_helper.dart';
import 'package:gtdoro/data/sync/oracle/core/interface.dart';
import 'package:gtdoro/data/sync/models/sync_config.dart';

/// Oracle Autonomous JSON Database (AJD) 동기화 서비스
/// SODA REST API 또는 Oracle API Gateway를 통해 AJD에 접근하여 데이터 동기화
/// 단일 컬렉션에 모든 타입의 JSON 문서 저장 (type 필드로 구분)
/// 성능 최적화: 캐싱, 페이징, 벌크 업로드 지원
/// 동시성 제어: 충돌 감지 및 해결
class OracleSyncService implements SyncServiceInterface {
  final OracleCacheManager _cacheManager = OracleCacheManager();
  final OraclePerformanceMonitor _performanceMonitor = OraclePerformanceMonitor();
  final OracleNetworkMonitor _networkMonitor = OracleNetworkMonitor();
  
  bool _enableValidation = true;
  
  // OAuth2 토큰 캐싱
  String? _cachedAccessToken;
  DateTime? _tokenExpiresAt;
  static const Duration _tokenRefreshBuffer = Duration(minutes: 5); // 토큰 만료 5분 전에 갱신
  
  bool get isValidationEnabled => _enableValidation;
  
  void setValidationEnabled(bool enabled) {
    _enableValidation = enabled;
    dev.log('OracleSyncService: Data validation ${enabled ? "enabled" : "disabled"}');
  }
  
  /// 네트워크 모니터 가져오기
  OracleNetworkMonitor get networkMonitor => _networkMonitor;
  
  /// OAuth2 토큰 발급 (Client Credentials Flow)
  /// Python 코드와 동일한 방식으로 토큰 발급
  Future<String?> _getAccessToken() async {
    // 캐시된 토큰이 있고 아직 만료되지 않았으면 재사용
    if (_cachedAccessToken != null && _tokenExpiresAt != null) {
      final now = DateTime.now();
      final timeUntilExpiry = _tokenExpiresAt!.difference(now);
      if (timeUntilExpiry > _tokenRefreshBuffer) {
        // 캐시된 토큰 사용 시 로그 제거 (너무 자주 출력됨)
        return _cachedAccessToken;
      }
      dev.log('OracleSyncService: Cached token expired or expiring soon, refreshing...');
    }
    
    final clientId = AppConfig.oracleDbClientId;
    final clientSecret = AppConfig.oracleDbClientSecret;
    final tokenUrl = AppConfig.oracleDbTokenUrl;
    
    if (clientId == null || clientSecret == null || 
        clientId.isEmpty || clientSecret.isEmpty) {
      final msg = 'OracleSyncService: ERROR - OAuth2 credentials not configured';
      debugPrint(msg);
      dev.log(msg);
      return null;
    }
    
    dev.log('OracleSyncService: Requesting OAuth2 token');
    
    try {
      // OAuth2 Client Credentials Flow
      // Python의 requests.post(..., auth=(CLIENT_ID, CLIENT_SECRET))와 동일
      final basicAuth = base64Encode(utf8.encode('$clientId:$clientSecret'));
      final headers = <String, String>{
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      
      final body = 'grant_type=client_credentials';
      
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body) as Map<String, dynamic>;
        final accessToken = tokenData['access_token'] as String?;
        final expiresIn = tokenData['expires_in'] as int?;
        
        if (accessToken != null && accessToken.isNotEmpty) {
          _cachedAccessToken = accessToken;
          // expires_in은 초 단위이므로 DateTime으로 변환 (기본 3600초 = 1시간)
          _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn ?? 3600));
          
          dev.log('OracleSyncService: OAuth2 token obtained (expires in ${expiresIn ?? 3600}s)');
          
          return accessToken;
        } else {
          dev.log('OracleSyncService: ERROR - Access token not found in response', error: response.body);
        }
      } else {
        dev.log('OracleSyncService: ERROR - Token request failed with status ${response.statusCode}', error: response.body);
      }
    } catch (e, stackTrace) {
      dev.log('OracleSyncService: ERROR - Failed to obtain OAuth2 token', error: e, stackTrace: stackTrace);
      
      // 토큰 발급 실패 시 캐시 클리어
      _cachedAccessToken = null;
      _tokenExpiresAt = null;
    }
    
    return null;
  }
  /// URL 검증
  /// Oracle API Gateway는 HTTPS만 지원
  void _validateUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') {
      throw ArgumentError(
        'Oracle API Gateway는 HTTPS만 지원합니다.',
      );
    }
  }

  /// 재시도 로직이 포함된 HTTP 요청 (성능 모니터링 포함, 안정성 강화)
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request, {
    String? operation,
  }) async {
    final requestStartTime = DateTime.now();
    int attempts = 0;
    Exception? lastException;
    http.Response? lastResponse; // 디버깅을 위한 마지막 응답 저장 (안정성 강화)

    while (attempts < SyncConstants.maxRetries) {
      try {
        // 네트워크 상태 확인 (안정성 강화)
        if (_networkMonitor.isStatusStale) {
          await _networkMonitor.checkNetworkStatus();
        }
        
        if (_networkMonitor.isOffline && attempts == 0) {
          throw Exception('Network is offline');
        }
        
        final response = await request().timeout(
          SyncConstants.requestTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Request timeout after ${SyncConstants.requestTimeout.inSeconds}s',
              SyncConstants.requestTimeout,
            );
          },
        );
        
        final duration = DateTime.now().difference(requestStartTime);
        lastResponse = response; // 디버깅을 위해 저장
        
        // 성능 모니터링 기록
        _performanceMonitor.recordRequest(
          operation ?? 'unknown',
          duration,
          success: OracleConstants.isSuccessStatusCode(response.statusCode),
          statusCode: response.statusCode,
          responseSize: response.bodyBytes.length,
          error: null,
        );
        
        if (OracleConstants.isSuccessStatusCode(response.statusCode)) {
          // 성공 시 네트워크 상태 업데이트
          _networkMonitor.updateStatus(true);
          return response;
        }
        
        // 401 Unauthorized 오류는 토큰이 만료되었을 수 있으므로 토큰 갱신 후 재시도
        if (response.statusCode == 401 && attempts < SyncConstants.maxRetries - 1) {
          dev.log('OracleSyncService: 401 Unauthorized, clearing token cache and retrying...');
          _cachedAccessToken = null;
          _tokenExpiresAt = null;
          // 다음 시도에서 새 토큰을 발급받도록 함
          // 주의: _requestWithRetry는 이미 생성된 request 함수를 받으므로,
          // 401 에러가 발생하면 호출부에서 새 토큰을 발급받아야 함
        }
        
        // 4xx 오류는 재시도하지 않음 (인증/권한 문제 등, 401은 위에서 처리)
        if (OracleConstants.isClientError(response.statusCode) && response.statusCode != 401) {
          dev.log('OracleSyncService: Client error ${response.statusCode}, not retrying');
          return response;
        }
        
        // 401 에러이고 마지막 시도이면 응답 반환
        if (response.statusCode == 401 && attempts >= SyncConstants.maxRetries - 1) {
          dev.log('OracleSyncService: 401 Unauthorized after all retries, returning response');
          return response;
        }
        
        // 5xx 오류는 재시도 가능
        lastException = Exception('Server error: ${response.statusCode}');
        dev.log('OracleSyncService: Server error ${response.statusCode}, will retry (attempt ${attempts + 1}/${SyncConstants.maxRetries})');
        
      } catch (e, stackTrace) {
        final duration = DateTime.now().difference(requestStartTime);
        _performanceMonitor.recordRequest(
          operation ?? 'unknown',
          duration,
          success: false,
          error: e.toString(),
        );
        
        // 네트워크 에러인 경우 상태 업데이트
        if (e is TimeoutException || 
            e.toString().toLowerCase().contains('timeout') ||
            e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('connection')) {
          _networkMonitor.updateStatus(false);
        }
        
        lastException = e is Exception ? e : Exception(e.toString());
        dev.log('OracleSyncService: Request failed (attempt ${attempts + 1}/${SyncConstants.maxRetries}): $e', error: e, stackTrace: stackTrace);
        
        // 재시도 불가능한 에러인지 확인
        if (!OracleErrorHandler.isRetryableError(e)) {
          dev.log('OracleSyncService: Non-retryable error, aborting retries', error: e, stackTrace: stackTrace);
          rethrow;
        }
      }

      attempts++;
      if (attempts < SyncConstants.maxRetries) {
        // 지수 백오프 계산 (최대 지연 시간 제한)
        final calculatedDelay = Duration(
          milliseconds: (SyncConstants.baseRetryDelay.inMilliseconds * 
                        (SyncConstants.backoffMultiplier * attempts)).round(),
        );
        final delay = calculatedDelay > SyncConstants.maxRetryDelay 
            ? SyncConstants.maxRetryDelay 
            : calculatedDelay;
        dev.log('${operation ?? "Request"} failed (attempt $attempts/${SyncConstants.maxRetries}), retrying in ${delay.inSeconds}s...');
        await Future<void>.delayed(delay);
      }
    }

    throw lastException ?? Exception(
      'Request failed after ${SyncConstants.maxRetries} attempts${lastResponse != null ? ' (last status: ${lastResponse.statusCode})' : ''}',
    );
  }

  /// Oracle REST API 헤더 생성 (OAuth2 Bearer 토큰 사용)
  /// Python 코드와 동일하게 Bearer 토큰 방식 사용
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // OAuth2 Bearer 토큰 획득 (Python과 동일한 방식)
    final accessToken = await _getAccessToken();
    
    if (accessToken != null && accessToken.isNotEmpty) {
      // Bearer 토큰 사용 (Python의 Authorization: Bearer {access_token}과 동일)
      headers['Authorization'] = 'Bearer $accessToken';
      dev.log('OracleSyncService: Using Bearer token authentication');
    } else {
      dev.log('OracleSyncService: WARNING - No access token available, request may fail');
      // 토큰이 없으면 Basic 인증으로 폴백 (호환성을 위해)
      final clientId = AppConfig.oracleDbClientId;
      final clientSecret = AppConfig.oracleDbClientSecret;
      
      if (clientId != null && clientSecret != null && 
          clientId.isNotEmpty && clientSecret.isNotEmpty) {
        final auth = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';
        headers['Authorization'] = auth;
        dev.log('OracleSyncService: Falling back to Basic authentication');
      }
    }
    
    return headers;
  }


  /// 연결 확인 (캐싱 및 네트워크 모니터링 적용)
  @override
  Future<bool> checkConnection(SyncConfig config) async {
    final apiUrl = AppConfig.oracleDbApiUrl;
    
    dev.log('OracleSyncService: ========== Connection Check Start ==========');
    dev.log('OracleSyncService: API URL: $apiUrl');
    
    // API URL 확인
    if (apiUrl.isEmpty) {
      dev.log('OracleSyncService: ERROR - API URL is empty! Please check .env file or AppConfig');
      return false;
    }
    
    // 먼저 기본 네트워크 연결 확인
    try {
      final networkStatus = await _networkMonitor.checkNetworkStatus();
      dev.log('OracleSyncService: Basic network status: $networkStatus');
      
      if (!networkStatus) {
        dev.log('OracleSyncService: ERROR - Basic network check failed (no internet connection)');
        return false;
      }
    } catch (e) {
      dev.log('OracleSyncService: ERROR - Basic network check failed', error: e);
      return false;
    }

    // OAuth2 인증 정보 확인 (연결 전에 확인)
    final clientId = AppConfig.oracleDbClientId;
    final clientSecret = AppConfig.oracleDbClientSecret;
    final hasAuth = clientId != null && 
                   clientSecret != null &&
                   clientId.isNotEmpty && 
                   clientSecret.isNotEmpty;
    
    dev.log('OracleSyncService: OAuth2 Client ID configured: ${clientId != null && clientId.isNotEmpty}');
    dev.log('OracleSyncService: OAuth2 Client Secret configured: ${clientSecret != null && clientSecret.isNotEmpty}');
    
    if (!hasAuth) {
      dev.log('OracleSyncService: WARNING - OAuth2 credentials not configured. Connection may fail.');
      dev.log('OracleSyncService: Please set ORACLE_DB_CLIENT_ID and ORACLE_DB_CLIENT_SECRET in .env file');
    }

    try {
      // URL 유효성 검증
      _validateUrl(apiUrl);
      final headers = await _getHeaders();
      
      dev.log('OracleSyncService: Request headers: ${headers.keys.join(", ")}');
      if (headers.containsKey('Authorization')) {
        dev.log('OracleSyncService: Authorization header present (length: ${headers['Authorization']?.length ?? 0})');
      } else {
        dev.log('OracleSyncService: WARNING - No Authorization header (OAuth2 not configured)');
      }

      // 고정 엔드포인트로 연결 확인
      final url = Uri.parse(apiUrl);
      dev.log('OracleSyncService: Sending GET request to: $url');
      dev.log('OracleSyncService: Request timeout: ${SyncConstants.requestTimeout.inSeconds}s');
      
      final requestStartTime = DateTime.now();
      
      // 401 에러 발생 시 토큰 갱신 후 재시도 (최대 1회)
      late http.Response response;
      bool shouldRetry = true;
      int retryCount = 0;
      
      while (shouldRetry && retryCount < 2) {
        // 매번 최신 토큰으로 헤더 재생성
        final currentHeaders = await _getHeaders();
        
        response = await _requestWithRetry(
          () => http.get(url, headers: currentHeaders),
          operation: 'Oracle API Gateway connection check',
        );
        
        // 401 에러이고 아직 재시도하지 않았으면 토큰 갱신 후 재시도
        if (response.statusCode == 401 && retryCount == 0) {
          dev.log('OracleSyncService: 401 Unauthorized detected, refreshing token and retrying...');
          _cachedAccessToken = null;
          _tokenExpiresAt = null;
          retryCount++;
          shouldRetry = true;
          continue;
        }
        
        shouldRetry = false; // 성공하거나 다른 에러면 종료
      }
      
      final requestDuration = DateTime.now().difference(requestStartTime);

      dev.log('OracleSyncService: ========== Response Received ==========');
      dev.log('OracleSyncService: Response status: ${response.statusCode}');
      dev.log('OracleSyncService: Response time: ${requestDuration.inMilliseconds}ms');
      dev.log('OracleSyncService: Response headers: ${response.headers}');
      
      // 응답 본문 로깅 (상세 진단을 위해)
      if (response.body.isNotEmpty) {
        if (response.body.length < 1000) {
          dev.log('OracleSyncService: Response body: ${response.body}');
        } else {
          dev.log('OracleSyncService: Response body (first 1000 chars): ${response.body.substring(0, 1000)}...');
        }
      } else {
        dev.log('OracleSyncService: Response body is empty');
      }

      // 연결 성공 판단: 200, 404, 204는 성공으로 간주
      // 401, 403은 인증 문제이지만 연결은 성공한 것으로 간주 (서버에 도달했다는 의미)
      final isConnected = response.statusCode == OracleConstants.httpOk || 
                         response.statusCode == OracleConstants.httpNotFound ||
                         response.statusCode == OracleConstants.httpNoContent ||
                         response.statusCode == 401 || // 인증 필요 (연결은 성공)
                         response.statusCode == 403;   // 권한 없음 (연결은 성공)

      // 상세한 상태 메시지
      String statusMessage;
      if (response.statusCode == 200) {
        statusMessage = 'SUCCESS - Server responded with 200 OK';
      } else if (response.statusCode == 401) {
        statusMessage = 'PARTIAL - Server connected but authentication failed (401 Unauthorized). Check OAuth2 credentials.';
      } else if (response.statusCode == 403) {
        statusMessage = 'PARTIAL - Server connected but access forbidden (403 Forbidden). Check API Gateway permissions.';
      } else if (response.statusCode == 404) {
        statusMessage = 'SUCCESS - Server connected (404 Not Found is acceptable for connection test)';
      } else if (response.statusCode >= 500) {
        statusMessage = 'FAILED - Server error (${response.statusCode}). Oracle API Gateway may be down.';
      } else {
        statusMessage = 'UNKNOWN - Unexpected status code: ${response.statusCode}';
      }
      
      dev.log('OracleSyncService: Connection result: $isConnected');
      dev.log('OracleSyncService: Status message: $statusMessage');
      dev.log('OracleSyncService: ========== Connection Check End ==========');

      // 캐시 저장
      _cacheManager.cacheConnectionStatus(config, isConnected);
      
      // 네트워크 모니터 상태 업데이트
      _networkMonitor.updateStatus(isConnected);
      
      return isConnected;
    } catch (e, stackTrace) {
      dev.log('OracleSyncService: ========== Connection Check Failed ==========');
      dev.log('OracleSyncService: ERROR - Connection failed', error: e, stackTrace: stackTrace);
      
      // 에러 타입별 상세 로깅 및 진단
      String errorDiagnosis;
      if (e.toString().contains('SocketException')) {
        if (e.toString().contains('Network is unreachable')) {
          errorDiagnosis = 'Network is unreachable. Check internet connection.';
        } else if (e.toString().contains('Failed host lookup')) {
          errorDiagnosis = 'DNS lookup failed. Check API URL or DNS settings.';
        } else {
          errorDiagnosis = 'Network connectivity issue. Check firewall or network settings.';
        }
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorDiagnosis = 'Connection timeout. Server may be unreachable or slow. Check API Gateway status.';
      } else if (e.toString().contains('Certificate') || e.toString().contains('SSL') || e.toString().contains('TLS')) {
        errorDiagnosis = 'SSL/Certificate issue. Check certificate validity or use HTTPS.';
      } else if (e.toString().contains('FormatException') || e.toString().contains('Invalid URL')) {
        errorDiagnosis = 'Invalid URL format. Check ORACLE_DB_API_URL in .env file.';
      } else {
        errorDiagnosis = 'Unknown error. Check logs for details.';
      }
      
      dev.log('OracleSyncService: Error diagnosis: $errorDiagnosis');
      dev.log('OracleSyncService: Error type: ${e.runtimeType}');
      dev.log('OracleSyncService: Error message: ${e.toString()}');
      dev.log('OracleSyncService: ========== Connection Check End (Failed) ==========');
      
      // 실패도 캐시에 저장 (짧은 시간 동안 재시도 방지)
      _cacheManager.cacheConnectionStatus(config, false);
      _networkMonitor.updateStatus(false);
      
      return false;
    }
  }

  /// 모든 문서(document) 다운로드 (초기 동기화)
  /// 서버 API 표준 1.0: /delta 엔드포인트를 since_rev 없이 호출하여 전체 문서 반환
  @override
  Future<List<Map<String, dynamic>>> downloadAllDocs(SyncConfig config) async {
    final startTime = _performanceMonitor.startSync('download_all');
    final apiUrl = AppConfig.oracleDbApiUrl;
    _validateUrl(apiUrl);
    final headers = await _getHeaders();
    
    // GET /delta 엔드포인트를 since_rev 없이 호출하여 전체 문서 다운로드
    final deltaUrl = apiUrl.endsWith('/') ? '${apiUrl}delta' : '$apiUrl/delta';
    
    final response = await _requestWithRetry(
      () => http.get(Uri.parse(deltaUrl), headers: headers),
      operation: 'Download all docs (full sync)',
    );
    
    if (response.statusCode != OracleConstants.httpOk) {
      _performanceMonitor.endSync(
        'download_all',
        startTime!,
        itemsDownloaded: 0,
        error: 'HTTP ${response.statusCode}',
      );
      throw Exception('Failed to download all docs: HTTP ${response.statusCode}');
    }
    
    final data = OracleResponseParser.parseJsonResponse(response.body);
    
    // ✅ 서버 API 표준 1.0: 타입 구분 없이 전체 데이터를 한 번에 반환
    final items = OracleResponseParser.extractItems(data);
    final allDocs = <Map<String, dynamic>>[];
    
    for (final item in items) {
      try {
        final oracleDoc = item as Map<String, dynamic>;
        final appDoc = OracleDataConverter.convertFromOracle(oracleDoc);
        
        // 서버 응답의 type 필드 사용
        final docType = appDoc['type'] as String?;
        if (docType == null || docType.isEmpty) {
          dev.log('OracleSyncService: Document missing type field, skipping');
          continue;
        }
        
        // _id 필드 확인
        final docId = appDoc['_id'] as String? ?? appDoc['id'] as String?;
        if (docId == null) {
          dev.log('OracleSyncService: Document missing ID field, skipping');
          continue;
        }
        
        // 검증 (타입별)
        if (_enableValidation) {
          final validation = OracleDataValidator.validateDocument(appDoc, docType);
          if (!validation.isValid) {
            dev.log('OracleSyncService: Validation failed for $docId: ${validation.errors.join(', ')}');
            continue;
          }
        }
        
        allDocs.add(appDoc);
      } catch (e) {
        dev.log('OracleSyncService: Error parsing document in full sync response', error: e);
        continue;
      }
    }
    
    _performanceMonitor.endSync(
      'download_all',
      startTime!,
      itemsDownloaded: allDocs.length,
    );
    
    dev.log('OracleSyncService: Full sync completed - ${allDocs.length} documents');
    return allDocs;
  }

  /// AJD 컬렉션에서 모든 타입의 데이터 다운로드 (공통 로직)
  /// 
  /// ⚠️ 현재 구현: 타입별로 4번 API 호출 (비효율적)
  /// - 서버 API가 타입별 필터만 지원하므로 타입별 루프 필요
  /// - 서버 측 개선: 전체 데이터를 한 번에 반환하는 엔드포인트 제공 권장
  ///   (예: /metadata처럼 타입 구분 없이 전체 반환)
  /// 
  /// ✅ 최적화 방안:
  /// - 서버에서 타입별 필터 없이 전체 데이터를 한 번에 반환하는 API 제공
  /// - 또는 /delta 엔드포인트가 타입별 호출 없이 전체를 반환하도록 구현
  Future<_DownloadResult> _downloadFromAllTables(
    String apiUrl,
    Map<String, String> headers, {
    required bool useCache,
    DateTime? filterSince,
    required SyncConfig config,
  }) async {
    final List<Map<String, dynamic>> allDocs = [];
    int totalDownloaded = 0;
    Exception? error;
    final queryKey = filterSince?.toIso8601String();
    
    // AJD: 단일 컬렉션 사용
    final collectionName = OracleConstants.collections.first;

    // ⚠️ 타입별로 4번 API 호출 (서버 API 제약으로 인한 임시 구현)
    // TODO: 서버 측 개선 - 전체 데이터를 한 번에 반환하는 엔드포인트 제공
    for (final type in ['todo', 'context', 'recurring', 'scheduled']) {
      try {
        final cacheKey = '$collectionName:$type';
        
        // 캐시 확인
        if (useCache) {
          final cachedData = _cacheManager.getCachedResponse(
            config,
            cacheKey,
            query: queryKey,
          );
          if (cachedData != null && cachedData.isNotEmpty) {
            dev.log('OracleSyncService: Using cached data for $type (${cachedData.length} items)');
            allDocs.addAll(cachedData);
            totalDownloaded += cachedData.length;
            continue;
          }
        }

        // 데이터 다운로드 (타입 필터 포함)
        final typeDocs = filterSince != null
            ? await _downloadCollectionWithFilter(apiUrl, headers, filterSince, type)
            : await _downloadCollectionWithPaging(apiUrl, headers, type);

        // 필터링 적용 (서버 필터가 작동하지 않을 경우를 대비)
        final filteredDocs = filterSince != null
            ? _filterByUpdatedAt(typeDocs, filterSince)
            : typeDocs;

        allDocs.addAll(filteredDocs);
        totalDownloaded += filteredDocs.length;

        // 캐시 저장
        if (filteredDocs.isNotEmpty && useCache) {
          _cacheManager.cacheResponse(config, cacheKey, filteredDocs, query: queryKey);
        }
      } catch (e) {
        dev.log('OracleSyncService: Error downloading $type from collection', error: e);
        error = e is Exception ? e : Exception(e.toString());
      }
    }

    return _DownloadResult(
      docs: allDocs,
      totalDownloaded: totalDownloaded,
      error: error,
    );
  }

  /// 페이징을 사용하여 AJD 컬렉션의 특정 타입 데이터 다운로드
  Future<List<Map<String, dynamic>>> _downloadCollectionWithPaging(
    String apiUrl,
    Map<String, String> headers,
    String type,
  ) async {
    final List<Map<String, dynamic>> allDocs = [];
    int offset = 0;

    while (true) {
      try {
        final url = OracleUrlHelper.addQueryParams(
          apiUrl,
          limit: OracleConstants.defaultPageSize,
          offset: offset,
          type: type,
        );
        
        if (offset == 0) {
          debugPrint('OracleSyncService: Requesting URL for type $type: $url');
        }
        
        final response = await _requestWithRetry(
          () => http.get(Uri.parse(url), headers: headers),
          operation: 'Download page (type: $type, offset: $offset)',
        );

        if (response.statusCode != OracleConstants.httpOk) {
          if (response.statusCode == OracleConstants.httpNotFound) {
            break;
          }
          dev.log('OracleSyncService: Failed to download page: ${response.statusCode}');
          break;
        }

        final data = OracleResponseParser.parseJsonResponse(response.body);
        final collectionName = OracleConstants.collections.first;
        
        // 디버깅: 서버 응답 확인
        if (offset == 0) {
          debugPrint('OracleSyncService: Server response for type $type - Status: ${response.statusCode}, Body length: ${response.body.length}');
          if (response.body.length < 500) {
            debugPrint('OracleSyncService: Response body: ${response.body}');
          } else {
            debugPrint('OracleSyncService: Response body (first 500 chars): ${response.body.substring(0, 500)}...');
          }
          debugPrint('OracleSyncService: Parsed JSON keys: ${data.keys.join(", ")}');
        }
        
        final documents = OracleResponseParser.parseDocuments(
          data,
          collectionName,
          type,
          enableValidation: _enableValidation,
        );
        
        dev.log('OracleSyncService: Parsed ${documents.length} documents for type $type (offset: $offset)');
        if (documents.isNotEmpty && offset == 0) {
          final firstDoc = documents.first;
          dev.log('OracleSyncService: First parsed document - ID: ${firstDoc['_id'] ?? firstDoc['id'] ?? "missing"}, Keys: ${firstDoc.keys.join(", ")}');
        }

        if (documents.isEmpty) {
          dev.log('OracleSyncService: No documents found for type $type at offset $offset, stopping pagination');
          break;
        }

        allDocs.addAll(documents);

        final pagingInfo = OracleResponseParser.extractPagingInfo(data);
        if (!pagingInfo.hasMore || documents.length < OracleConstants.defaultPageSize) {
          break;
        }

        offset += documents.length;
        if (offset > OracleConstants.maxOffsetLimit) {
          dev.log('OracleSyncService: Reached maximum offset limit, stopping pagination');
          break;
        }
      } catch (e) {
        dev.log('OracleSyncService: Error downloading page', error: e);
        break;
      }
    }

    dev.log('OracleSyncService: Downloaded ${allDocs.length} items of type $type');
    return allDocs;
  }

  /// 필터를 사용하여 AJD 컬렉션에서 변경된 데이터 다운로드
  Future<List<Map<String, dynamic>>> _downloadCollectionWithFilter(
    String apiUrl,
    Map<String, String> headers,
    DateTime sinceDate,
    String type,
  ) async {
    final url = OracleUrlHelper.addQueryParams(
      apiUrl,
      sinceDate: sinceDate,
      type: type,
    );
    
    final response = await _requestWithRetry(
      () => http.get(Uri.parse(url), headers: headers),
      operation: 'Download changes (type: $type)',
    );

    if (response.statusCode == OracleConstants.httpOk) {
      debugPrint('OracleSyncService: Download response received for type: $type (filtered)');
      debugPrint('OracleSyncService: Response body length: ${response.body.length}');
      
      final data = OracleResponseParser.parseJsonResponse(response.body);
      debugPrint('OracleSyncService: Parsed JSON keys: ${data.keys.join(", ")}');
      
      final collectionName = OracleConstants.collections.first;
      
      // 원본 응답 샘플 로깅 (디버깅용)
      if (data.isNotEmpty && data.containsKey('items') && (data['items'] as List).isNotEmpty) {
        final firstItem = (data['items'] as List).first;
        if (firstItem is Map) {
          debugPrint('OracleSyncService: First item keys: ${firstItem.keys.join(", ")}');
          if (firstItem.containsKey('_id')) {
            debugPrint('OracleSyncService: First item _id: ${firstItem['_id']}');
          }
          if (firstItem.containsKey('RESID')) {
            debugPrint('OracleSyncService: First item RESID: ${firstItem['RESID']}');
          }
        }
      }
      
      final documents = OracleResponseParser.parseDocuments(
        data,
        collectionName,
        type,
        enableValidation: _enableValidation,
      );
      
      debugPrint('OracleSyncService: Parsed ${documents.length} documents for type $type (filtered)');
      return documents;
    }

    return [];
  }

  /// lastSeq 파싱 헬퍼
  DateTime? _parseLastSeq(String? lastSeq) {
    if (lastSeq == null) return null;
    try {
      return DateTime.parse(lastSeq);
    } catch (e) {
      dev.log('OracleSyncService: Failed to parse lastSeq: $lastSeq');
      return null;
    }
  }

  /// 변경된 문서(document) 다운로드 (델타 동기화) - GET /delta?since_rev 엔드포인트 사용
  /// 서버 API 표준 1.0: 타입 구분 없이 전체 변경 문서를 한 번에 반환
  /// rev 기반 델타 동기화로 더 정확한 변경 추적
  @override
  Future<Map<String, dynamic>> downloadChangedDocs(
    SyncConfig config,
    String? lastSeq,
  ) async {
    final apiUrl = AppConfig.oracleDbApiUrl;
    _validateUrl(apiUrl);
    final headers = await _getHeaders();

    // GET /delta?since_rev={value} 엔드포인트 사용
    final deltaUrl = apiUrl.endsWith('/') ? '${apiUrl}delta' : '$apiUrl/delta';
    final uri = Uri.parse(deltaUrl);
    
    // lastSeq가 rev 값인지 확인 (rev는 숫자 문자열이거나 null)
    final sinceRev = lastSeq != null && _isNumeric(lastSeq) ? lastSeq : null;
    // lastSeq가 DateTime 문자열인지 확인 (last_sync 파라미터용)
    final lastSync = lastSeq != null && !_isNumeric(lastSeq) ? lastSeq : null;
    
    final queryParams = <String, String>{};
    if (sinceRev != null) {
      queryParams['since_rev'] = sinceRev;
    }
    if (lastSync != null) {
      queryParams['last_sync'] = lastSync;
    }
    
    final url = uri.replace(queryParameters: queryParams);
    
    final response = await _requestWithRetry(
      () => http.get(url, headers: headers),
      operation: 'Delta sync (since_rev: $sinceRev)',
    );
    
    if (response.statusCode != OracleConstants.httpOk) {
      dev.log('OracleSyncService: Delta sync failed with status ${response.statusCode}');
      throw Exception('Failed to download changed docs: HTTP ${response.statusCode}');
    }
    
    final data = OracleResponseParser.parseJsonResponse(response.body);
    
    // ✅ 서버 API 표준 1.0: 타입 구분 없이 전체 데이터를 한 번에 반환
    // 서버 응답에서 모든 문서를 직접 파싱 (타입은 서버 응답의 type 필드 사용)
    final items = OracleResponseParser.extractItems(data);
    final allDocs = <Map<String, dynamic>>[];
    
    for (final item in items) {
      try {
        final oracleDoc = item as Map<String, dynamic>;
        final appDoc = OracleDataConverter.convertFromOracle(oracleDoc);
        
        // 서버 응답의 type 필드 사용 (이미 문서에 포함되어 있음)
        final docType = appDoc['type'] as String?;
        if (docType == null || docType.isEmpty) {
          dev.log('OracleSyncService: Document missing type field, skipping');
          continue;
        }
        
        // _id 필드 확인
        final docId = appDoc['_id'] as String? ?? appDoc['id'] as String?;
        if (docId == null) {
          dev.log('OracleSyncService: Document missing ID field, skipping');
          continue;
        }
        
        // 검증 (타입별)
        if (_enableValidation) {
          final validation = OracleDataValidator.validateDocument(appDoc, docType);
          if (!validation.isValid) {
            dev.log('OracleSyncService: Validation failed for $docId: ${validation.errors.join(', ')}');
            continue;
          }
        }
        
        allDocs.add(appDoc);
      } catch (e) {
        dev.log('OracleSyncService: Error parsing document in delta response', error: e);
        continue;
      }
    }
    
    dev.log('OracleSyncService: Delta sync completed - ${allDocs.length} documents');
    
    return {
      'docs': allDocs,
      'last_seq': sinceRev, // rev 값을 lastSeq로 반환
    };
  }
  
  /// 변경된 문서 다운로드 (기존 방식: updatedAt 기반 필터링)
  Future<Map<String, dynamic>> _downloadChangedDocsLegacy(
    SyncConfig config,
    String? lastSeq,
    String apiUrl,
    Map<String, String> headers,
  ) async {
    final sinceDate = _parseLastSeq(lastSeq);
    final result = await _downloadFromAllTables(
      apiUrl,
      headers,
      useCache: true,
      filterSince: sinceDate,
      config: config,
    );

    dev.log('OracleSyncService: Delta sync completed - ${result.docs.length} documents (legacy)');

    return {
      'docs': result.docs,
      'last_seq': DateTime.now().toIso8601String(),
    };
  }
  
  /// 문자열이 숫자인지 확인 (rev 값 검증)
  bool _isNumeric(String str) {
    return int.tryParse(str) != null || double.tryParse(str) != null;
  }

  /// 메타데이터만 조회 (GET /metadata 엔드포인트 사용)
  /// 서버 API 표준 1.0: 타입 구분 없이 전체 메타데이터 반환 (id, rev, type, updated_at)
  /// Returns a map of _id -> _rev for all documents
  @override
  Future<Map<String, String>> downloadMetadataOnly(SyncConfig config) async {
    final apiUrl = AppConfig.oracleDbApiUrl;
    _validateUrl(apiUrl);
    final headers = await _getHeaders();
    
    // GET /metadata 엔드포인트 사용
    final metadataUrl = apiUrl.endsWith('/') ? '${apiUrl}metadata' : '$apiUrl/metadata';
    
    final response = await _requestWithRetry(
      () => http.get(Uri.parse(metadataUrl), headers: headers),
      operation: 'Download metadata only',
    );
    
    if (response.statusCode != OracleConstants.httpOk) {
      dev.log('OracleSyncService: Metadata request failed with status ${response.statusCode}');
      throw Exception('Failed to download metadata: HTTP ${response.statusCode}');
    }
    
    final data = OracleResponseParser.parseJsonResponse(response.body);
    final metadata = OracleMetadataExtractor.extractMetadataFromResponse(data);
    dev.log('OracleSyncService: Downloaded metadata for ${metadata.length} documents');
    
    return metadata;
  }
  
  /// 메타데이터만 조회 (기존 방식: 타입별 순차 다운로드)
  /// Oracle SODA API는 필드 선택을 지원하지 않으므로, 응답 파싱 단계에서 메타데이터만 추출
  Future<Map<String, String>> _downloadMetadataOnlyLegacy(
    String apiUrl,
    Map<String, String> headers,
  ) async {
    final Map<String, String> metadata = {};
    
    // 각 타입별로 메타데이터만 추출 (전체 문서 객체 생성 안 함)
    for (final type in ['todo', 'context', 'recurring', 'scheduled']) {
      try {
        final url = OracleUrlHelper.addQueryParams(
          apiUrl,
          limit: OracleConstants.defaultPageSize, // 최대 페이지 크기로 한 번에 조회
          type: type,
        );
        
        final response = await _requestWithRetry(
          () => http.get(Uri.parse(url), headers: headers),
          operation: 'Download metadata only (type: $type, legacy)',
        );
        
        if (response.statusCode == OracleConstants.httpOk) {
          final data = OracleResponseParser.parseJsonResponse(response.body);
          // 메타데이터만 추출 (전체 문서 파싱 안 함)
          final typeMetadata = OracleMetadataExtractor.extractMetadataFromResponse(data);
          metadata.addAll(typeMetadata);
        }
      } catch (e) {
        dev.log('OracleSyncService: Error downloading metadata for type $type (legacy)', error: e);
        // 실패해도 계속 진행
      }
    }
    
    dev.log('OracleSyncService: Downloaded metadata for ${metadata.length} documents (legacy)');
    return metadata;
  }

  /// 각 타입별 최대 _rev 값만 조회 (메타데이터 최적화)
  /// Returns a map of type -> Map<_id, _rev> for documents with maximum _rev
  @override
  Future<Map<String, Map<String, String>>> downloadMaxRevMetadata(SyncConfig config) async {
    final apiUrl = AppConfig.oracleDbApiUrl;
    _validateUrl(apiUrl);
    final headers = await _getHeaders();
    
    final Map<String, Map<String, String>> result = {};
    
    // 각 타입별로 최신 문서 하나만 조회 (limit=1, orderby=_rev desc)
    for (final type in ['todo', 'context', 'recurring', 'scheduled']) {
      try {
        // Oracle SODA API에서 최신 문서 조회 시도 (orderby 지원 시)
        // limit=1로 설정하여 최신 문서 하나만 가져옴
        final url = OracleUrlHelper.addQueryParams(
          apiUrl,
          limit: 1,
          type: type,
          orderBy: '-_rev', // 내림차순 정렬 (_rev desc)
        );
        
        final response = await _requestWithRetry(
          () => http.get(Uri.parse(url), headers: headers),
          operation: 'Download max rev metadata (type: $type)',
        );
        
        if (response.statusCode == OracleConstants.httpOk) {
          final data = OracleResponseParser.parseJsonResponse(response.body);
          final documents = OracleResponseParser.parseDocuments(
            data,
            OracleConstants.collections.first,
            type,
            enableValidation: false, // 메타데이터만 필요하므로 검증 생략
          );
          
          // 최신 문서에서 _id와 _rev 추출
          if (documents.isNotEmpty) {
            final doc = documents.first;
            final id = doc['_id'] as String? ?? doc['id'] as String?;
            final rev = doc['_rev'] as String? ?? '';
            
            if (id != null) {
              // 각 문서의 _id를 키로 하여 _rev 저장
              // 하지만 동일 타입 내에서 최신 문서 하나만 필요하므로,
              // 타입별로 하나의 항목만 저장
              if (!result.containsKey(type)) {
                result[type] = {};
              }
              result[type]![id] = rev;
            }
          }
        }
      } catch (e) {
        dev.log('OracleSyncService: Error downloading max rev for type $type', error: e);
        // 실패해도 계속 진행 (다른 타입은 시도)
      }
    }
    
    // orderby가 지원되지 않는 경우를 대비하여,
    // 각 타입별로 모든 문서를 조회한 후 클라이언트에서 최신 _rev 찾기
    if (result.isEmpty || result.values.every((m) => m.isEmpty)) {
      dev.log('OracleSyncService: Oracle SODA API does not support orderby, metadata optimization unavailable');
      // orderby가 지원되지 않으면 빈 결과 반환 (호출자가 기존 방식 사용)
      return {};
    }
    
    return result;
  }

  /// 문서(document) 업로드 (벌크 업로드 최적화)
  @override
  Future<void> uploadDocs(SyncConfig config, List<Map<String, dynamic>> docs) async {
    if (docs.isEmpty) return;

    final startTime = _performanceMonitor.startSync('upload');
    final apiUrl = AppConfig.oracleDbApiUrl;
    _validateUrl(apiUrl);
    final headers = await _getHeaders();
    int totalUploaded = 0;

    // 타입별로 그룹화 및 변환 (AJD: 단일 컬렉션 사용)
    final groupedDocs = OracleDocumentGrouper.groupByTable(
      docs,
      _getTableFromType,
    );

    // 컬렉션별로 업로드 (AJD: 단일 컬렉션에 모든 타입 저장)
    for (final entry in groupedDocs.entries) {
      final collectionName = entry.key; // 단일 컬렉션 이름
      final collectionDocs = entry.value;

      // 배치로 나누어 업로드 (성능 최적화)
      int batchSuccessCount = 0;
      int batchFailureCount = 0;
      final List<String> failedDocIds = [];
      
      for (int i = 0; i < collectionDocs.length; i += SyncConstants.maxBatchSize) {
        final batch = collectionDocs.skip(i).take(SyncConstants.maxBatchSize).toList();
        
        try {
          dev.log('OracleSyncService: Uploading batch ${i ~/ SyncConstants.maxBatchSize + 1} (${batch.length} documents)');
          
          // 서버 API 표준 1.0: /bulk 엔드포인트 사용 (타입 구분 없이 통합 업로드)
          await _tryBulkUpload(apiUrl, batch, headers);
          
          batchSuccessCount += batch.length;
          totalUploaded += batch.length;
          
          // 업로드 성공 시 해당 컬렉션의 캐시 무효화
          _cacheManager.invalidateResponseCache(config, table: collectionName);
        } catch (e, stackTrace) {
          dev.log('OracleSyncService: Upload batch failed', error: e, stackTrace: stackTrace);
          batchFailureCount += batch.length;
          
          // 실패한 문서 ID 수집
          for (final doc in batch) {
            final docId = _extractDocId(doc);
            if (docId != null) {
              failedDocIds.add(docId);
            }
          }
          
          // 첫 번째 배치 실패 시 전체 실패로 처리
          if (i == 0) {
            _performanceMonitor.endSync(
              'upload',
              startTime!,
              itemsUploaded: totalUploaded,
              error: e.toString(),
            );
            rethrow;
          }
          
          // 이후 배치 실패는 로그만 남기고 계속 진행
          dev.log('OracleSyncService: Continuing with remaining batches despite batch failure');
        }
      }
      
      if (batchFailureCount > 0) {
        dev.log('OracleSyncService: Upload completed with some failures: $batchSuccessCount succeeded, $batchFailureCount failed');
        if (failedDocIds.isNotEmpty) {
          dev.log('OracleSyncService: Failed document IDs: ${failedDocIds.take(10).join(", ")}${failedDocIds.length > 10 ? "..." : ""}');
        }
        // 일부 실패가 있어도 전체 업로드는 부분 성공으로 처리
        if (batchSuccessCount == 0) {
          throw Exception('All uploads failed. Failed document IDs: ${failedDocIds.take(5).join(", ")}');
        }
      }
    }

    _performanceMonitor.endSync(
      'upload',
      startTime!,
      itemsUploaded: totalUploaded,
    );
  }

  /// 벌크 업로드 (POST /bulk 엔드포인트 사용)
  /// 서버 API 표준 1.0: 타입 구분 없이 모든 문서를 한 번에 업로드
  Future<void> _tryBulkUpload(
    String apiUrl,
    List<Map<String, dynamic>> batch,
    Map<String, String> headers,
  ) async {
    // POST /bulk 엔드포인트 사용
    final bulkUrl = apiUrl.endsWith('/') ? '${apiUrl}bulk' : '$apiUrl/bulk';
    final url = Uri.parse(bulkUrl);
    
    // JSON 배열 형식으로 벌크 업로드
    final body = jsonEncode(batch);
    
    dev.log('OracleSyncService: Uploading ${batch.length} items via bulk endpoint');
    
    final response = await _requestWithRetry(
      () => http.post(url, headers: headers, body: body),
      operation: 'Bulk upload (${batch.length} items)',
    );

    if (!OracleConstants.isSuccessStatusCode(response.statusCode) && 
        response.statusCode != OracleConstants.httpCreated &&
        response.statusCode != OracleConstants.httpNoContent) {
      dev.log('OracleSyncService: Bulk upload failed with status ${response.statusCode}');
      throw Exception('Bulk upload failed: HTTP ${response.statusCode}');
    }
    
    dev.log('OracleSyncService: ✅ Bulk upload successful (${batch.length} items, status: ${response.statusCode})');
  }

  /// 개별 문서 업로드 (폴백 방식, AJD)
  Future<void> _uploadIndividually(
    String apiUrl,
    List<Map<String, dynamic>> batch,
    Map<String, String> headers,
  ) async {
    final baseUrl = Uri.parse(apiUrl);
    
    dev.log('OracleSyncService: Uploading ${batch.length} documents individually');
    
    // 순차 업로드로 에러 추적 용이 (Python 코드와 동일한 방식)
    // Python 코드는 단일 항목을 POST로 업로드하므로, 여기서도 동일하게 처리
    int successCount = 0;
    int failureCount = 0;
    final List<String> failedDocIds = [];
    
    for (int i = 0; i < batch.length; i++) {
      final doc = batch[i];
      final docId = _extractDocId(doc);
      try {
        await _uploadSingleDoc(baseUrl, doc, headers);
        successCount++;
        dev.log('OracleSyncService: Successfully uploaded document ${i + 1}/${batch.length} (ID: $docId, type: ${doc['type']})');
      } catch (e, stackTrace) {
        failureCount++;
        failedDocIds.add(docId ?? 'unknown');
        dev.log('OracleSyncService: Failed to upload document ${i + 1}/${batch.length} (ID: $docId, type: ${doc['type']})', error: e, stackTrace: stackTrace);
        
        // 첫 번째 문서 실패 시 전체 업로드 실패로 처리 (인증/권한 문제 등)
        if (i == 0) {
          throw Exception('Failed to upload first document (ID: $docId, type: ${doc['type']}): ${e.toString()}');
        }
        
        // 이후 문서 실패는 로그만 남기고 계속 진행 (부분 실패 허용)
        dev.log('OracleSyncService: Continuing with remaining documents despite failure');
      }
    }
    
    dev.log('OracleSyncService: Completed individual upload - Success: $successCount, Failed: $failureCount');
    if (failedDocIds.isNotEmpty && failedDocIds.length <= 10) {
      dev.log('OracleSyncService: Failed document IDs: ${failedDocIds.join(", ")}');
    } else if (failedDocIds.length > 10) {
      dev.log('OracleSyncService: Failed document IDs (first 10): ${failedDocIds.take(10).join(", ")}... (${failedDocIds.length} total)');
    }
    
    // 최소한 하나도 성공하지 못했으면 예외 발생
    if (successCount == 0 && failureCount > 0) {
      throw Exception('All individual uploads failed. Failed document IDs: ${failedDocIds.take(5).join(", ")}');
    }
  }

  /// 단일 문서 업로드 (AJD) - 게이트웨이에서 이미 경로 매핑됨
  Future<void> _uploadSingleDoc(
    Uri baseUrl,
    Map<String, dynamic> doc,
    Map<String, String> headers,
  ) async {
    final docId = _extractDocId(doc);
    if (docId == null) {
      dev.log('OracleSyncService: Cannot upload doc - missing ID. Available keys: ${doc.keys.join(", ")}');
      throw Exception('Document ID is missing');
    }

    try {
      // 게이트웨이에서 이미 경로가 매핑되어 있으므로, 문서를 직접 업로드
      // 문서 ID는 본문에 포함하여 upsert 방식으로 처리
      final docWithId = Map<String, dynamic>.from(doc);
      // ID 필드 확인 및 정규화
      if (!docWithId.containsKey('id')) {
        docWithId['id'] = docId;
      }
      if (!docWithId.containsKey('_id')) {
        docWithId['_id'] = docId;
      }
      
      final baseUrlString = baseUrl.toString();
      final uploadUrl = Uri.parse(baseUrlString);
      
      dev.log('OracleSyncService: Uploading doc $docId (type: ${doc['type']}) to $uploadUrl');
      dev.log('OracleSyncService: Document keys: ${docWithId.keys.join(", ")}');
      
      // POST 요청으로 업로드 (upsert 방식 - 서버가 자동으로 생성/업데이트 처리)
      final response = await _requestWithRetry(
        () => http.post(uploadUrl, headers: headers, body: jsonEncode(docWithId)),
        operation: 'Upload/upsert doc $docId',
      );
      
      dev.log('OracleSyncService: Upload response status: ${response.statusCode}');
      if (response.body.length < 300) {
        dev.log('OracleSyncService: Upload response body: ${response.body}');
      } else {
        dev.log('OracleSyncService: Upload response body (first 300 chars): ${response.body.substring(0, 300)}...');
      }
      
      // 성공 상태 코드 확인
      if (response.statusCode == OracleConstants.httpCreated ||
          response.statusCode == OracleConstants.httpOk ||
          response.statusCode == OracleConstants.httpNoContent ||
          (response.statusCode >= 200 && response.statusCode < 300)) {
        // 성공 로그 제거 (너무 많이 출력됨)
        return;
      }
      
      // 400 에러 처리: 중복 키 에러는 이미 서버에 있는 문서이므로 성공으로 간주
      if (response.statusCode == 400) {
        final responseBody = response.body.toLowerCase();
        // 중복 키 에러인지 확인 (ORA-00001 또는 unique constraint)
        if (responseBody.contains('ora-00001') || 
            responseBody.contains('unique constraint') ||
            responseBody.contains('resid')) {
          // 중복 키 에러는 성공으로 간주하므로 로그 제거
          return; // 이미 존재하므로 성공으로 간주
        }
        
        // 다른 400 에러는 예외 던지기
        final errorMsg = 'Upload failed for $docId: HTTP ${response.statusCode}\nResponse: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}';
        dev.log('OracleSyncService: $errorMsg');
        throw Exception(errorMsg);
      }
      
      // 409 Conflict도 중복으로 간주할 수 있음
      if (response.statusCode == 409) {
        // 중복은 성공으로 간주하므로 로그 제거
        return; // 이미 존재하므로 성공으로 간주
      }
      
      // 기타 4xx 에러는 클라이언트 오류이므로 재시도하지 않음
      if (response.statusCode >= 400 && response.statusCode < 500) {
        final errorMsg = 'Upload failed for $docId: HTTP ${response.statusCode}\nResponse: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}';
        dev.log('OracleSyncService: $errorMsg');
        throw Exception(errorMsg);
      }
      
      // 5xx 에러는 서버 오류이므로 예외 던지기 (재시도 가능)
      throw Exception('Server error during upload: HTTP ${response.statusCode}');
      
    } catch (e, stackTrace) {
      dev.log('OracleSyncService: Failed to upload doc $docId', error: e, stackTrace: stackTrace);
      OracleErrorHandler.logError('Upload doc $docId', e);
      // 업로드 실패는 예외를 전파하여 상위에서 처리할 수 있도록 함
      rethrow;
    }
  }

  /// 문서 ID 추출 (대소문자 무시, _id도 확인)
  String? _extractDocId(Map<String, dynamic> doc) {
    return doc['_id'] as String? ??
           doc['id'] as String? ?? 
           doc['ID'] as String? ?? 
           doc['Id'] as String?;
  }


  /// 문서 삭제 (AJD)
  /// 단일 컬렉션에서 문서 삭제
  @override
  Future<void> deleteDoc(SyncConfig config, String id, String rev) async {
    final apiUrl = AppConfig.oracleDbApiUrl;
    _validateUrl(apiUrl);
    final headers = await _getHeaders();
    
    try {
      // 문서 ID로 고정 URL 구성 (게이트웨이에서 이미 경로 매핑됨)
      final url = Uri.parse(apiUrl).resolve(id);
      final response = await _requestWithRetry(
        () => http.delete(url, headers: headers),
        operation: 'Delete doc',
      );
      
      if (OracleConstants.isSuccessStatusCode(response.statusCode) || 
          response.statusCode == OracleConstants.httpNoContent) {
        return;
      }
    } catch (e) {
      dev.log('OracleSyncService: Delete failed', error: e);
    }
    
    throw Exception('Delete failed: Document not found');
  }

  /// SQL 쿼리 실행 (ORDS SQL 엔드포인트 사용)
  /// Oracle REST Data Services를 통해 직접 SQL을 실행하여 최대 rev 값 조회
  /// 예: SELECT MAX(JSON_VALUE(json_document, '$._rev' RETURNING NUMBER)) AS max_rev FROM GTDORO;
  @override
  Future<Map<String, dynamic>?> executeSqlQuery(String sql) async {
    final sqlUrl = AppConfig.oracleDbSqlUrl;
    try {
      _validateUrl(sqlUrl);
    } catch (e) {
      debugPrint('OracleSyncService: ⚠️ SQL URL not configured: $e');
      dev.log('OracleSyncService: SQL URL not configured', error: e);
      return null;
    }
    
    final headers = await _getHeaders();
    
    try {
      // ORDS SQL 엔드포인트는 POST 요청으로 SQL 쿼리를 실행
      // Content-Type: text/plain 또는 application/sql
      // 참고: ORDS SQL 엔드포인트는 일반적으로 text/plain을 사용
      final sqlHeaders = {
        ...headers,
        'Content-Type': 'text/plain',
        'Accept': 'application/json',
      };
      
      final response = await _requestWithRetry(
        () => http.post(
          Uri.parse(sqlUrl),
          headers: sqlHeaders,
          body: sql,
        ),
        operation: 'Execute SQL query',
      );
      
      if (response.statusCode == OracleConstants.httpOk) {
        final data = OracleResponseParser.parseJsonResponse(response.body);
        return data;
      } else {
        dev.log('OracleSyncService: SQL query failed', error: 'Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      dev.log('OracleSyncService: Error executing SQL query', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 최대 _rev 값 조회 (GET /max-rev 엔드포인트 사용)
  /// 서버에 저장된 가장 높은 rev 값을 반환
  /// Response: {"items": [{"max_rev": 123}]}
  Future<int?> getMaxRevBySql({String? type}) async {
    final apiUrl = AppConfig.oracleDbApiUrl;
    try {
      _validateUrl(apiUrl);
    } catch (e) {
      dev.log('OracleSyncService: API URL not configured', error: e);
      return null;
    }
    
    final headers = await _getHeaders();
    
    try {
      // GET /max-rev 엔드포인트 사용
      final maxRevUrl = apiUrl.endsWith('/') ? '${apiUrl}max-rev' : '$apiUrl/max-rev';
      
      final response = await _requestWithRetry(
        () => http.get(
          Uri.parse(maxRevUrl),
          headers: headers,
        ),
        operation: 'Get max rev',
      );
      
      if (response.statusCode == OracleConstants.httpOk) {
        final data = OracleResponseParser.parseJsonResponse(response.body);
        
        final maxRevNumber = _extractMaxRevFromResult(data);
        if (maxRevNumber != null) {
          return maxRevNumber;
        }
        
        dev.log('OracleSyncService: No max rev found in response');
        return null;
      } else {
        dev.log('OracleSyncService: Max rev request failed with status ${response.statusCode}', error: response.body);
        return null;
      }
    } catch (e, stackTrace) {
      dev.log('OracleSyncService: Error getting max rev', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// SQL 결과에서 max_rev 값 추출
  int? _extractMaxRevFromResult(Map<String, dynamic> result) {
    // ORDS SQL 응답 형식 확인
    // 일반적으로 {"items": [{"max_rev": value}]} 형식
    if (result.containsKey('items')) {
      final items = result['items'] as List?;
      if (items != null && items.isNotEmpty) {
        final firstItem = items.first as Map<String, dynamic>?;
        if (firstItem != null && firstItem.containsKey('max_rev')) {
          final maxRev = firstItem['max_rev'];
          if (maxRev != null) {
            // 숫자 또는 문자열로 반환될 수 있음
            return maxRev is num ? maxRev.toInt() : int.tryParse(maxRev.toString());
          }
        }
      }
    } else if (result.containsKey('max_rev')) {
      // 직접 max_rev 필드가 있는 경우
      final maxRev = result['max_rev'];
      if (maxRev != null) {
        return maxRev is num ? maxRev.toInt() : int.tryParse(maxRev.toString());
      }
    }
    return null;
  }

  /// 타입에서 컬렉션 이름 추출 (AJD: 단일 컬렉션 사용)
  String _getTableFromType(String type) {
    // AJD: 모든 타입이 단일 컬렉션에 저장됨
    return OracleConstants.collections.first;
  }


  /// updated_at 기준으로 문서(document) 필터링
  List<Map<String, dynamic>> _filterByUpdatedAt(
    List<Map<String, dynamic>> docs,
    DateTime sinceDate,
  ) {
    return docs.where((doc) {
      final updatedAtStr = doc['updatedAt'] as String?;
      if (updatedAtStr == null) return false;
      try {
        final docUpdatedAt = DateTime.parse(updatedAtStr);
        return docUpdatedAt.isAfter(sinceDate);
      } catch (_) {
        return false;
      }
    }).toList();
  }
}

/// 다운로드 결과 데이터 클래스
class _DownloadResult {
  final List<Map<String, dynamic>> docs;
  final int totalDownloaded;
  final Exception? error;

  _DownloadResult({
    required this.docs,
    required this.totalDownloaded,
    this.error,
  });
}
