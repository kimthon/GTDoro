import 'dart:io' show Platform;
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gtdoro/app_providers.dart';
import 'package:gtdoro/core/theme/theme_provider.dart';
import 'package:gtdoro/features/navigation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 로그 출력 테스트 (디버그 모드 확인)
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('GTDoro 앱 시작 - 로그 출력 테스트');
  debugPrint('디버그 모드: ${kDebugMode ? "ON" : "OFF"}');
  debugPrint('═══════════════════════════════════════════════════════');
  dev.log('GTDoro: App starting - dev.log test', name: 'Main');
  
  // 환경 변수 파일 로드 (.env)
  // 파일이 없어도 에러가 발생하지 않도록 처리
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ 환경 변수 파일(.env) 로드 성공');
    dev.log('GTDoro: .env file loaded successfully', name: 'Main');
  } catch (e) {
    // .env 파일이 없거나 로드에 실패한 경우 계속 진행
    // 환경 변수는 선택사항이므로 앱 실행에는 영향을 주지 않습니다
    debugPrint('⚠️ 환경 변수 파일(.env)을 로드할 수 없습니다: $e');
    dev.log('GTDoro: Failed to load .env file: $e', name: 'Main');
  }
  
  // Set initial system UI overlay style (Android only)
  // Will be updated dynamically based on theme
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  runApp(
    AppProviders(child: const GTDoro()),
  );
}

class GTDoro extends StatelessWidget {
  const GTDoro({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeData = themeProvider.themeData;
    final isDark = themeData.brightness == Brightness.dark;
    
    // Update system UI overlay style based on theme (Android only)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ));
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const MainScreen(),
      shortcuts: _getShortcuts(),
      actions: _getActions(context),
    );
  }

  // Keyboard shortcuts for desktop platforms (Linux, Windows, macOS)
  Map<LogicalKeySet, Intent> _getShortcuts() {
    if (kIsWeb || (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS)) {
      return {};
    }
    
    return {
      // Navigation shortcuts
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): const NavigationIntent(0), // Inbox
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): const NavigationIntent(1), // Next
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3): const NavigationIntent(2), // Waiting
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4): const NavigationIntent(3), // Scheduled
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5): const NavigationIntent(4), // Someday
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit6): const NavigationIntent(5), // Logbook
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit7): const NavigationIntent(6), // Statistics
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma): const NavigationIntent(7), // Settings
      
      // Action shortcuts
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const AddActionIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const CloseDialogIntent(),
    };
  }

  // Actions for keyboard shortcuts
  Map<Type, Action<Intent>> _getActions(BuildContext context) {
    if (kIsWeb || (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS)) {
      return {};
    }
    
    return {
      NavigationIntent: CallbackAction<NavigationIntent>(
        onInvoke: (intent) {
          // Navigation will be handled in MainScreen
          return null;
        },
      ),
      AddActionIntent: CallbackAction<AddActionIntent>(
        onInvoke: (intent) {
          // Add action will be handled in MainScreen
          return null;
        },
      ),
      CloseDialogIntent: CallbackAction<CloseDialogIntent>(
        onInvoke: (intent) {
          // Safely close dialog if Navigator is available
          try {
            final navigator = Navigator.maybeOf(context);
            if (navigator != null && navigator.canPop()) {
              navigator.maybePop();
            }
          } catch (e) {
            // Silently ignore if Navigator is not available
          }
          return null;
        },
      ),
    };
  }
}

// Intent classes for keyboard shortcuts
class NavigationIntent extends Intent {
  final int index;
  const NavigationIntent(this.index);
}

class AddActionIntent extends Intent {
  const AddActionIntent();
}

class CloseDialogIntent extends Intent {
  const CloseDialogIntent();
}
