import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// 앱 전체에서 사용하는 로깅 유틸리티
/// 릴리즈 모드에서도 로그를 남길 수 있도록 구성
class AppLogger {
  /// 디버그 모드 여부 (전역 접근 가능)
  static bool get isDebugMode => kDebugMode;

  /// 일반 로그 (디버그 모드에서만 출력)
  /// 릴리즈 모드에서는 dev.log만 사용 (콘솔 출력 없음)
  static void debug(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      // 디버그 모드: debugPrint로 콘솔 출력
      debugPrint('[$name ?? "App"] $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
    }
    
    // dev.log는 릴리즈 모드에서도 동작 (Flutter DevTools에서 확인 가능)
    dev.log(
      message,
      name: name ?? 'App',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 정보 로그 (릴리즈 모드에서도 출력)
  /// 중요하지만 에러가 아닌 정보를 기록
  static void info(String message, {String? name}) {
    // 릴리즈 모드에서도 출력 (중요 정보)
    // ignore: avoid_print
    print('[INFO][${name ?? "App"}] $message');
    
    // dev.log도 함께 기록
    dev.log(
      message,
      name: name ?? 'App',
      level: 800, // info level
    );
  }

  /// 경고 로그 (릴리즈 모드에서도 출력)
  /// 문제가 될 수 있는 상황을 기록
  static void warning(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    // 릴리즈 모드에서도 출력 (경고)
    // ignore: avoid_print
    print('[WARNING][${name ?? "App"}] $message');
    if (error != null) {
      // ignore: avoid_print
      print('  Error: $error');
    }
    
    // dev.log도 함께 기록
    dev.log(
      message,
      name: name ?? 'App',
      error: error,
      stackTrace: stackTrace,
      level: 900, // warning level
    );
  }

  /// 에러 로그 (릴리즈 모드에서도 출력)
  /// 반드시 기록해야 하는 에러
  static void error(String message, {String? name, Object? error, StackTrace? stackTrace}) {
    // 릴리즈 모드에서도 출력 (에러는 반드시 기록)
    // ignore: avoid_print
    print('[ERROR][${name ?? "App"}] $message');
    if (error != null) {
      // ignore: avoid_print
      print('  Error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('  StackTrace: $stackTrace');
    }
    
    // dev.log도 함께 기록
    dev.log(
      message,
      name: name ?? 'App',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // error level
    );
  }

  /// 동기화 관련 로그 (릴리즈 모드에서도 출력)
  /// 동기화는 중요한 기능이므로 릴리즈에서도 로그 유지
  static void sync(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[SYNC] $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      debugPrint('═══════════════════════════════════════════════════════');
    }
    
    // 릴리즈 모드에서도 중요한 동기화 로그는 출력
    // ignore: avoid_print
    print('[SYNC] $message');
    if (error != null) {
      // ignore: avoid_print
      print('  Error: $error');
    }
    
    // dev.log도 함께 기록
    dev.log(
      message,
      name: 'Sync',
      error: error,
      stackTrace: stackTrace,
      level: 850, // sync level
    );
  }
}
