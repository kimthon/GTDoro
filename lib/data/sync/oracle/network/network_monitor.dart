import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:gtdoro/core/config/app_config.dart';

/// 네트워크 상태 리스너 타입
typedef NetworkStatusListener = void Function(bool isOnline);

/// 네트워크 상태 모니터링 및 오프라인 감지
class OracleNetworkMonitor {
  static final OracleNetworkMonitor _instance = OracleNetworkMonitor._internal();
  factory OracleNetworkMonitor() => _instance;
  OracleNetworkMonitor._internal();

  bool _isOnline = true;
  DateTime? _lastCheckTime;
  final List<NetworkStatusListener> _listeners = [];
  
  // 네트워크 상태 체크 간격 (실시간 동기화: 더 자주 체크)
  static const Duration _checkInterval = Duration(seconds: 10); // 30초 → 10초
  
  // 마지막 성공한 요청 시간
  DateTime? _lastSuccessfulRequest;

  /// 네트워크 상태 리스너 추가
  void addListener(NetworkStatusListener listener) {
    _listeners.add(listener);
  }

  /// 네트워크 상태 리스너 제거
  void removeListener(NetworkStatusListener listener) {
    _listeners.remove(listener);
  }

  /// 네트워크 상태 확인
  Future<bool> checkNetworkStatus({String? testUrl}) async {
    try {
      // 간단한 HTTP 요청으로 네트워크 상태 확인
      final url = testUrl ?? 'https://www.google.com';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      
      final wasOnline = _isOnline;
      _isOnline = response.statusCode == 200;
      _lastCheckTime = DateTime.now();
      
      if (_isOnline) {
        _lastSuccessfulRequest = DateTime.now();
      }
      
      // 상태 변경 시 리스너에 알림
      if (wasOnline != _isOnline) {
        _notifyListeners();
      }
      
      return _isOnline;
    } catch (e) {
      final wasOnline = _isOnline;
      _isOnline = false;
      _lastCheckTime = DateTime.now();
      
      if (wasOnline != _isOnline) {
        _notifyListeners();
      }
      
      return false;
    }
  }

  /// Oracle API Gateway 연결 확인
  Future<bool> checkOracleConnection(String oracleUrl) async {
    dev.log('OracleNetworkMonitor: ========== Oracle Connection Check Start ==========');
    dev.log('OracleNetworkMonitor: Oracle URL: $oracleUrl');
    
    try {
      // URL 정규화
      final url = oracleUrl.endsWith('/') ? oracleUrl.substring(0, oracleUrl.length - 1) : oracleUrl;
      
      // OAuth2 인증 헤더 생성 (AppConfig에서 읽어옴)
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // OAuth2 Client Credentials 사용
      final clientId = AppConfig.oracleDbClientId;
      final clientSecret = AppConfig.oracleDbClientSecret;
      
      if (clientId != null && clientSecret != null && clientId.isNotEmpty && clientSecret.isNotEmpty) {
        final auth = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';
        headers['Authorization'] = auth;
        dev.log('OracleNetworkMonitor: OAuth2 authentication configured (Client ID length: ${clientId.length})');
      } else {
        dev.log('OracleNetworkMonitor: WARNING - No OAuth2 credentials found, connecting without auth');
        dev.log('OracleNetworkMonitor: This may cause authentication errors. Set ORACLE_DB_CLIENT_ID and ORACLE_DB_CLIENT_SECRET in .env');
      }
      
      dev.log('OracleNetworkMonitor: Sending GET request to: $url');
      final requestStartTime = DateTime.now();
      final response = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      final requestDuration = DateTime.now().difference(requestStartTime);
      
      dev.log('OracleNetworkMonitor: ========== Oracle Response Received ==========');
      dev.log('OracleNetworkMonitor: Response status: ${response.statusCode}');
      dev.log('OracleNetworkMonitor: Response time: ${requestDuration.inMilliseconds}ms');
      
      final wasOnline = _isOnline;
      // 200, 404, 204는 연결 성공 (인증 문제는 401, 403 등)
      // 4xx는 연결은 되지만 인증/권한 문제이므로 연결은 성공으로 간주
      final isConnected = response.statusCode == 200 || 
                  response.statusCode == 404 || 
                  response.statusCode == 204 ||
                  (response.statusCode >= 400 && response.statusCode < 500);
      
      _isOnline = isConnected;
      _lastCheckTime = DateTime.now();
      
      if (_isOnline) {
        _lastSuccessfulRequest = DateTime.now();
      }
      
      if (wasOnline != _isOnline) {
        dev.log('OracleNetworkMonitor: Network status changed: ${wasOnline ? "online" : "offline"} -> ${_isOnline ? "online" : "offline"}');
        _notifyListeners();
      }
      
      // 응답 본문 로깅 (상세 진단)
      if (response.body.isNotEmpty) {
        final responsePreview = response.body.length > 300 
            ? '${response.body.substring(0, 300)}...' 
            : response.body;
        dev.log('OracleNetworkMonitor: Response body: $responsePreview');
      } else {
        dev.log('OracleNetworkMonitor: Response body is empty');
      }
      
      String statusMessage;
      if (response.statusCode == 200) {
        statusMessage = 'SUCCESS - Server responded with 200 OK';
      } else if (response.statusCode == 401) {
        statusMessage = 'PARTIAL - Connected but authentication failed (401). Check OAuth2 credentials.';
      } else if (response.statusCode == 403) {
        statusMessage = 'PARTIAL - Connected but access forbidden (403). Check API Gateway permissions.';
      } else if (response.statusCode == 404) {
        statusMessage = 'SUCCESS - Connected (404 is acceptable for connection test)';
      } else if (response.statusCode >= 500) {
        statusMessage = 'FAILED - Server error (${response.statusCode}). Oracle API Gateway may be down.';
      } else {
        statusMessage = 'Status code: ${response.statusCode}';
      }
      
      dev.log('OracleNetworkMonitor: Connection result: $isConnected - $statusMessage');
      dev.log('OracleNetworkMonitor: ========== Oracle Connection Check End ==========');
      
      return _isOnline;
    } catch (e, stackTrace) {
      dev.log('OracleNetworkMonitor: ========== Oracle Connection Check Failed ==========');
      dev.log('OracleNetworkMonitor: ERROR - Oracle connection check failed', error: e, stackTrace: stackTrace);
      
      // 에러 진단
      String errorDiagnosis;
      if (e.toString().contains('SocketException')) {
        if (e.toString().contains('Network is unreachable')) {
          errorDiagnosis = 'Network unreachable. Check internet connection.';
        } else if (e.toString().contains('Failed host lookup')) {
          errorDiagnosis = 'DNS lookup failed. Check Oracle URL or DNS.';
        } else {
          errorDiagnosis = 'Network connectivity issue.';
        }
      } else if (e.toString().contains('TimeoutException')) {
        errorDiagnosis = 'Connection timeout. Oracle API Gateway may be slow or unreachable.';
      } else if (e.toString().contains('Certificate') || e.toString().contains('SSL')) {
        errorDiagnosis = 'SSL/Certificate issue. Check certificate validity.';
      } else {
        errorDiagnosis = 'Unknown error: ${e.toString()}';
      }
      
      dev.log('OracleNetworkMonitor: Error diagnosis: $errorDiagnosis');
      dev.log('OracleNetworkMonitor: ========== Oracle Connection Check End (Failed) ==========');
      
      final wasOnline = _isOnline;
      _isOnline = false;
      _lastCheckTime = DateTime.now();
      
      if (wasOnline != _isOnline) {
        _notifyListeners();
      }
      
      return false;
    }
  }

  /// 현재 네트워크 상태
  bool get isOnline => _isOnline;

  /// 마지막 체크 시간
  DateTime? get lastCheckTime => _lastCheckTime;

  /// 마지막 성공한 요청 시간
  DateTime? get lastSuccessfulRequest => _lastSuccessfulRequest;

  /// 네트워크가 오프라인인지 확인
  bool get isOffline => !_isOnline;

  /// 네트워크 상태가 오래되었는지 확인
  bool get isStatusStale {
    if (_lastCheckTime == null) return true;
    return DateTime.now().difference(_lastCheckTime!) > _checkInterval;
  }

  /// 리스너에 알림
  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener(_isOnline);
      } catch (e) {
        dev.log('OracleNetworkMonitor: Error notifying listener', error: e);
      }
    }
  }

  /// 네트워크 상태 수동 업데이트
  void updateStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _lastCheckTime = DateTime.now();
      if (isOnline) {
        _lastSuccessfulRequest = DateTime.now();
      }
      _notifyListeners();
    }
  }

  /// 네트워크 상태 리셋
  void reset() {
    _isOnline = true;
    _lastCheckTime = null;
    _lastSuccessfulRequest = null;
  }
}
