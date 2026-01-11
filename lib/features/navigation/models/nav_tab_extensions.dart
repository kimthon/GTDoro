import 'package:flutter/material.dart';
import 'package:gtdoro/features/navigation/models/nav_tab.dart';
import 'package:gtdoro/data/local/app_database.dart';

extension NavTabExtension on NavTab {
  IconData get icon {
    switch (this) {
      case NavTab.inbox:
        return Icons.inbox_rounded;
      case NavTab.next:
        return Icons.bolt_rounded;
      case NavTab.waiting:
        return Icons.hourglass_empty_rounded;
      case NavTab.scheduled:
        return Icons.calendar_month_rounded;
      case NavTab.someday:
        return Icons.archive_rounded;
      case NavTab.logbook:
        return Icons.history_rounded;
      case NavTab.statistics:
        return Icons.bar_chart_rounded;
      case NavTab.settings:
        return Icons.settings_rounded;
    }
  }

  String get label {
    switch (this) {
      case NavTab.inbox:
        return 'Inbox';
      case NavTab.next:
        return 'Next Actions';
      case NavTab.waiting:
        return 'Waiting For';
      case NavTab.scheduled:
        return 'Scheduled';
      case NavTab.someday:
        return 'Someday';
      case NavTab.logbook:
        return 'Logbook';
      case NavTab.statistics:
        return 'Statistics';
      case NavTab.settings:
        return 'Settings';
    }
  }

  String getDisplayName() {
    return label;
  }

  GTDStatus? mapToStatus() {
    switch (this) {
      case NavTab.inbox:
        return GTDStatus.inbox;
      case NavTab.next:
        return GTDStatus.next;
      case NavTab.waiting:
        return GTDStatus.waiting;
      case NavTab.scheduled:
        return GTDStatus.scheduled;
      case NavTab.someday:
        return GTDStatus.someday;
      default:
        return null; // For tabs like logbook, statistics, settings
    }
  }
}
