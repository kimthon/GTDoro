import 'package:flutter/services.dart';

/// Helper class for haptic feedback in Android
class HapticFeedbackHelper {
  /// Light haptic feedback for selection changes
  static void lightImpact() {
    HapticFeedback.selectionClick();
  }

  /// Medium haptic feedback for button taps
  static void mediumImpact() {
    HapticFeedback.lightImpact();
  }

  /// Heavy haptic feedback for important actions
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Vibrate for notifications or errors
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}
