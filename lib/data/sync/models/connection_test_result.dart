/// 연결 테스트 결과 모델
class ConnectionTestResult {
  final bool success;
  final String message;
  final int? statusCode;
  final String? errorType;
  final String? details;
  final DateTime testTime;
  final bool hasNetwork;
  final bool hasOAuth2;
  final String apiUrl;

  ConnectionTestResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.errorType,
    this.details,
    required this.testTime,
    required this.hasNetwork,
    required this.hasOAuth2,
    required this.apiUrl,
  });

  String get statusText => success ? '연결 성공' : '연결 실패';
  
  String get fullMessage {
    final buffer = StringBuffer();
    buffer.writeln('테스트 시간: ${testTime.toLocal().toString().split('.')[0]}');
    buffer.writeln('API URL: $apiUrl');
    buffer.writeln('네트워크: ${hasNetwork ? "연결됨" : "오프라인"}');
    buffer.writeln('OAuth2 인증: ${hasOAuth2 ? "설정됨" : "미설정"}');
    if (statusCode != null) {
      buffer.writeln('HTTP 상태 코드: $statusCode');
    }
    if (errorType != null) {
      buffer.writeln('에러 타입: $errorType');
    }
    buffer.writeln('결과: $message');
    if (details != null) {
      buffer.writeln('\n상세 정보:\n$details');
    }
    return buffer.toString();
  }
}
