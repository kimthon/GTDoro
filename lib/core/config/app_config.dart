import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 애플리케이션 설정 관리 클래스
/// 환경 변수(.env 파일)에서 설정 값을 읽어옵니다
class AppConfig {
  /// 기본 Oracle API Gateway URL (게이트웨이에서 이미 경로 매핑됨)
  static const String defaultOracleDbApiUrl = 
      'https://f5zsyrqay7emcgtj6ybs474i5q.apigateway.ap-chuncheon-1.oci.customer-oci.com/project/gtdoro';

  /// Oracle API Gateway 엔드포인트 URL (고정 엔드포인트)
  /// 환경 변수가 없으면 기본 URL 사용
  static String get oracleDbApiUrl => dotenv.env['ORACLE_DB_API_URL'] ?? 
                                      dotenv.env['ORACLE_DB_URL'] ?? 
                                      defaultOracleDbApiUrl;

  /// OAuth2 Client ID (환경 변수에서 읽어옴)
  static String? get oracleDbClientId => dotenv.env['ORACLE_DB_CLIENT_ID'];

  /// OAuth2 Client Secret (환경 변수에서 읽어옴)
  static String? get oracleDbClientSecret => dotenv.env['ORACLE_DB_CLIENT_SECRET'];

  /// OAuth2 토큰 발급 URL (Oracle ORDS)
  static const String defaultOracleDbTokenUrl = 
      'https://gd5ecc577e0d932-oracle.adb.ap-chuncheon-1.oraclecloudapps.com/ords/admin/oauth/token';

  /// OAuth2 토큰 발급 URL (환경 변수에서 읽어옴, 없으면 기본값 사용)
  static String get oracleDbTokenUrl => dotenv.env['ORACLE_DB_TOKEN_URL'] ?? 
                                        dotenv.env['ORACLE_DB_OAUTH_URL'] ?? 
                                        defaultOracleDbTokenUrl;

  /// Oracle ORDS SQL 엔드포인트 URL (SQL 쿼리 실행용)
  static const String defaultOracleDbSqlUrl = 
      'https://gd5ecc577e0d932-oracle.adb.ap-chuncheon-1.oraclecloudapps.com/ords/admin/_/sql';

  /// Oracle ORDS SQL 엔드포인트 URL (환경 변수에서 읽어옴, 없으면 기본값 사용)
  static String get oracleDbSqlUrl => dotenv.env['ORACLE_DB_SQL_URL'] ?? 
                                      dotenv.env['ORDS_SQL_URL'] ?? 
                                      defaultOracleDbSqlUrl;
}
