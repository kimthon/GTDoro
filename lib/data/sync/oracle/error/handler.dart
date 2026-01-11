import 'dart:developer' as dev;

/// Oracle 동기화 에러 처리 유틸리티
class OracleErrorHandler {
  /// Oracle 특화 에러 메시지 생성
  static String formatOracleError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Oracle 에러 코드별 처리
    if (errorString.contains('ora-00942')) {
      return '테이블을 찾을 수 없습니다. Oracle DB 스키마가 올바르게 생성되었는지 확인하세요.';
    }
    if (errorString.contains('ora-00904')) {
      return '컬럼을 찾을 수 없습니다. 테이블 구조를 확인하세요.';
    }
    if (errorString.contains('ora-01017')) {
      return '인증에 실패했습니다. 사용자명과 비밀번호를 확인해주세요.';
    }
    if (errorString.contains('ora-12541') || errorString.contains('ora-12154')) {
      return '데이터베이스에 연결할 수 없습니다. 네트워크 및 연결 정보를 확인하세요.';
    }
    if (errorString.contains('ora-28040')) {
      return '인증 프로토콜이 맞지 않습니다. Oracle DB 버전을 확인하세요.';
    }

    // HTTP 상태 코드별 처리
    if (errorString.contains('404')) {
      return '스키마나 테이블을 찾을 수 없습니다. Oracle API Gateway 설정을 확인하세요.';
    }
    if (errorString.contains('403') || errorString.contains('401')) {
      return '접근 권한이 없습니다. 인증 정보를 확인해주세요.';
    }
    if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    // 네트워크 관련 에러
    if (errorString.contains('connection') || errorString.contains('network')) {
      return '네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.';
    }
    if (errorString.contains('timeout')) {
      return '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
    }
    if (errorString.contains('socket')) {
      return '네트워크 연결이 끊어졌습니다. 연결을 확인해주세요.';
    }

    // 프로토콜 관련 에러
    if (errorString.contains('프로토콜') || errorString.contains('지원되지 않는')) {
      return '지원되지 않는 프로토콜입니다. HTTPS를 사용해주세요.';
    }

    // 기본 메시지
    return '동기화 중 오류가 발생했습니다: ${error.toString()}';
  }

  /// 에러 로깅
  static void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    dev.log(
      'OracleErrorHandler: $operation failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 에러가 재시도 가능한지 확인
  static bool isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // 재시도 불가능한 에러
    if (errorString.contains('ora-00942') || // 테이블 없음
        errorString.contains('ora-00904') || // 컬럼 없음
        errorString.contains('ora-01017') || // 인증 실패
        errorString.contains('404') || // Not Found
        errorString.contains('401') || // Unauthorized
        errorString.contains('403')) { // Forbidden
      return false;
    }
    
    // 재시도 가능한 에러
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return true;
    }
    
    // 기본적으로 재시도 가능
    return true;
  }

  /// 에러 타입 분류
  static OracleErrorType classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('ora-')) {
      return OracleErrorType.databaseError;
    }
    if (errorString.contains('connection') || 
        errorString.contains('network') ||
        errorString.contains('timeout')) {
      return OracleErrorType.networkError;
    }
    if (errorString.contains('401') || 
        errorString.contains('403') ||
        errorString.contains('ora-01017')) {
      return OracleErrorType.authenticationError;
    }
    if (errorString.contains('404') ||
        errorString.contains('ora-00942')) {
      return OracleErrorType.notFoundError;
    }
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return OracleErrorType.serverError;
    }
    
    return OracleErrorType.unknownError;
  }
}

/// 에러 타입 열거형
enum OracleErrorType {
  databaseError,
  networkError,
  authenticationError,
  notFoundError,
  serverError,
  unknownError,
}
