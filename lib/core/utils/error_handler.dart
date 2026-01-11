import 'package:flutter/material.dart';

/// Centralized error handling utility
/// Provides consistent error message formatting and user feedback
class ErrorHandler {
  /// Convert error to user-friendly message
  static String formatErrorMessage(dynamic error) {
    if (error == null) {
      return '알 수 없는 오류가 발생했습니다.';
    }

    final errorString = error.toString().toLowerCase();
    final errorMessage = error.toString();

    // Argument errors (validation errors)
    if (error is ArgumentError || errorString.contains('argument')) {
      return errorMessage.replaceAll('ArgumentError: ', '').trim();
    }

    // State errors (not found, invalid state)
    if (error is StateError) {
      if (errorString.contains('not found')) {
        return '항목을 찾을 수 없습니다.';
      }
      return '상태 오류가 발생했습니다.';
    }

    // Database errors
    if (errorString.contains('database') || 
        errorString.contains('sql') || 
        errorString.contains('drift')) {
      return '데이터베이스 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    // Network errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return '네트워크 오류가 발생했습니다. 연결을 확인해주세요.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
    }

    // Authentication errors
    if (errorString.contains('auth') || 
        errorString.contains('인증') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return '인증에 실패했습니다. 인증 정보를 확인해주세요.';
    }

    // Server errors
    if (errorString.contains('server') || 
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    // Not found errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return '요청한 리소스를 찾을 수 없습니다.';
    }

    // Protocol errors
    if (errorString.contains('프로토콜') || 
        errorString.contains('unsupported protocol')) {
      return '지원되지 않는 프로토콜입니다. HTTP 또는 HTTPS를 사용해주세요.';
    }

    // Waiting For validation
    if (errorString.contains('waiting for')) {
      return 'Waiting For 필드를 입력해주세요.';
    }

    // Default: return original message if it's user-friendly, otherwise generic message
    if (errorMessage.length < 100 && !errorMessage.contains('Exception:')) {
      return errorMessage;
    }

    return '작업을 완료할 수 없습니다. 잠시 후 다시 시도해주세요.';
  }

  /// Show error snackbar to user (Android Material Design 3 style)
  static void showError(BuildContext context, dynamic error, {Duration? duration}) {
    if (!context.mounted) return;

    final message = formatErrorMessage(error);
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontSize: 14,
          ),
        ),
        backgroundColor: theme.colorScheme.errorContainer,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: '확인',
          textColor: theme.colorScheme.onErrorContainer,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar to user (Android Material Design 3 style)
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    if (!context.mounted) return;

    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontSize: 14,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error with retry option (Android Material Design 3 style)
  static void showErrorWithRetry(
    BuildContext context,
    dynamic error,
    VoidCallback onRetry, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final message = formatErrorMessage(error);
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontSize: 14,
          ),
        ),
        backgroundColor: theme.colorScheme.errorContainer,
        duration: duration ?? const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: '다시 시도',
          textColor: theme.colorScheme.onErrorContainer,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onRetry();
          },
        ),
      ),
    );
  }
}
