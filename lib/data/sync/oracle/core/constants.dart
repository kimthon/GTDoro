/// Oracle Autonomous JSON Database (AJD) 동기화 관련 상수
/// Oracle Database 26ai 버전 지원
class OracleConstants {
  OracleConstants._(); // 인스턴스 생성 방지

  // Oracle Database 버전
  static const String oracleVersion = '26ai';
  static const String databaseType = 'AJD'; // Autonomous JSON Database

  // AJD 컬렉션 목록 (JSON 문서 컬렉션)
  // 단일 컬렉션에 모든 타입 저장하거나, 타입별 컬렉션 분리 가능
  static const List<String> collections = [
    'gtdoro', // 단일 컬렉션에 모든 문서 저장 (type 필드로 구분)
  ];

  // 문서 타입 매핑 (단일 컬렉션 사용 시)
  static const Map<String, String> typeToCollection = {
    'todo': 'gtdoro',
    'context': 'gtdoro',
    'recurring': 'gtdoro',
    'scheduled': 'gtdoro',
  };

  // 페이징 설정
  static const int defaultPageSize = 1000; // Oracle API Gateway 기본 limit
  static const int maxPageSize = 5000; // 최대 페이지 크기
  static const int maxOffsetLimit = 50000; // 최대 offset (무한 루프 방지)

  // 업로드 설정
  static const int maxConcurrentUploads = 5; // 최대 동시 업로드 수

  // HTTP 상태 코드
  static const int httpOk = 200;
  static const int httpCreated = 201;
  static const int httpNoContent = 204;
  static const int httpBadRequest = 400;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpServerError = 500;

  // 성공 상태 코드 범위
  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  // 클라이언트 오류 상태 코드 범위
  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }

  // 서버 오류 상태 코드 범위
  static bool isServerError(int statusCode) {
    return statusCode >= 500 && statusCode < 600;
  }
}
