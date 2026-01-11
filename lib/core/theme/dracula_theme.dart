import 'package:flutter/material.dart';
import 'package:gtdoro/core/theme/app_theme_base.dart';

class DraculaTheme extends AppThemeBase {
  @override Color get background => const Color(0xFF1E1F29); // Darker background
  @override Color get surface => const Color(0xFF282A36);     // Darker surface
  @override Color get onSurface => const Color(0xFFF8F8F2);     // foreground
  @override Color get primary => const Color(0xFFBD93F9);       // purple
  @override Color get secondary => const Color(0xFFFF79C6);     // pink
  @override Color get error => const Color(0xFFFF5555);        // red
  @override Color get comment => const Color(0xFF6272A4);
  @override Color get selection => const Color(0xFF44475A);
}
