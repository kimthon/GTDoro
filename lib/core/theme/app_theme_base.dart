import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppThemeBase {
  Color get primary;
  Color get secondary;
  Color get background;
  Color get surface;
  Color get onSurface;
  Color get error;
  Color get selection;
  Color get comment;

  ThemeData get themeData {
    final baseTextTheme = GoogleFonts.sourceCodeProTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        error: error,
      ),
      // Material 3 components
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurface.withAlpha(102),
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Apply text selection and cursor colors
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: selection,
        selectionHandleColor: primary,
      ),
      // Set default input field styles
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
    );
  }
}
