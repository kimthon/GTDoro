import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/features/todo/providers/context_provider.dart';

/// Helper utilities for screen widgets
class ScreenHelper {
  /// Check if there are active context filters
  static bool hasActiveFilters(BuildContext context) {
    return context.watch<ContextProvider>().activeFilterIds.isNotEmpty;
  }

  /// Get empty message based on filter state
  static String getEmptyMessage(
    BuildContext context, {
    required String defaultMessage,
    required String filteredMessage,
  }) {
    return hasActiveFilters(context) ? filteredMessage : defaultMessage;
  }
}
