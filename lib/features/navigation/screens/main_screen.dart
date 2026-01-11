import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as widget show Actions, Shortcuts, CallbackAction;
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_breakpoints.dart';
import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/core/constants/app_strings.dart';
import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';
import 'package:gtdoro/data/local/app_database.dart' hide Action;
import 'package:gtdoro/features/navigation/models/nav_tab.dart';
import 'package:gtdoro/features/navigation/models/nav_tab_extensions.dart';
import 'package:gtdoro/features/navigation/providers/navigation_provider.dart';
import 'package:gtdoro/features/navigation/screens/side_menu.dart';
import 'package:gtdoro/features/statistics/screens/statistics_screen.dart';
import 'package:gtdoro/features/todo/screens/active/next_screen.dart';
import 'package:gtdoro/features/todo/screens/active/scheduled_screen.dart';
import 'package:gtdoro/features/todo/screens/active/someday_screen.dart';
import 'package:gtdoro/features/todo/screens/active/waiting_screen.dart';
import 'package:gtdoro/features/todo/screens/archive/logbook_screen.dart';
import 'package:gtdoro/features/todo/screens/inbox/inbox_screen.dart';
import 'package:gtdoro/features/todo/screens/settings_screen.dart';
import 'package:gtdoro/features/todo/widgets/dialogs/action_edit_dialog.dart';
import 'package:gtdoro/main.dart' show NavigationIntent, AddActionIntent;

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navProvider = context.watch<NavigationProvider>();
    final currentStatus = navProvider.currentTab.mapToStatus();

    final List<Widget> screens = const [
      InboxScreen(),
      NextScreen(),
      WaitingScreen(),
      ScheduledScreen(),
      SomedayScreen(),
      LogbookScreen(),
      StatisticsScreen(),
      SettingsScreen(),
    ];

    return widget.Shortcuts(
      shortcuts: !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
          ? {
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): const NavigationIntent(0), // Inbox
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): const NavigationIntent(1), // Next
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3): const NavigationIntent(2), // Waiting
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4): const NavigationIntent(3), // Scheduled
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5): const NavigationIntent(4), // Someday
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit6): const NavigationIntent(5), // Logbook
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit7): const NavigationIntent(6), // Statistics
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma): const NavigationIntent(7), // Settings
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const AddActionIntent(),
            }
          : {},
      child: widget.Actions(
        actions: {
          NavigationIntent: widget.CallbackAction<NavigationIntent>(
            onInvoke: (intent) {
              final tabs = NavTab.values;
              if (intent.index >= 0 && intent.index < tabs.length) {
                navProvider.setTab(tabs[intent.index]);
              }
              return null;
            },
          ),
          AddActionIntent: widget.CallbackAction<AddActionIntent>(
            onInvoke: (intent) {
              if (currentStatus != null) {
                _handleQuickAdd(context, currentStatus);
              }
              return null;
            },
          ),
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.pop(context);
            } else if (navProvider.currentIndex != 0) {
              navProvider.setTab(NavTab.inbox);
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < AppBreakpoints.mobile;
              return Scaffold(
                resizeToAvoidBottomInset: true,
                backgroundColor: colorScheme.surface,
                drawer: isMobile
                    ? Drawer(
                        width: AppSizes.drawerWidth,
                        child: SideMenu(onItemTap: () => Navigator.pop(context)),
                      )
                    : null,
                appBar: isMobile
                    ? AppBar(
                        title: Text(
                          navProvider.currentTab.getDisplayName(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
                        centerTitle: false,
                        elevation: 0,
                        scrolledUnderElevation: 1,
                        backgroundColor: colorScheme.surface,
                        surfaceTintColor: colorScheme.surfaceTint,
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            tooltip: '메뉴',
                            onPressed: () {
                              HapticFeedbackHelper.lightImpact();
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        ),
                        actions: [
                          // 현재 탭에 맞는 액션 버튼 추가 가능
                        ],
                      )
                    : null,
                body: isMobile
                    ? IndexedStack(
                        index: navProvider.currentIndex,
                        children: screens,
                      )
                    : Row(
                        children: [
                          const SideMenu(),
                          Expanded(
                            child: IndexedStack(
                              index: navProvider.currentIndex,
                              children: screens,
                            ),
                          ),
                        ],
                      ),
                floatingActionButton: _buildGlobalFAB(
                    context, colorScheme, navProvider.currentTab, currentStatus),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalFAB(BuildContext context, ColorScheme colorScheme, NavTab currentTab, GTDStatus? currentStatus) {
    // Hide FAB on non-action screens
    if (currentStatus == null || currentTab == NavTab.logbook || currentTab == NavTab.statistics || currentTab == NavTab.settings) {
      return const SizedBox.shrink();
    }

    // Material Design 3 FAB with extended style
    return FloatingActionButton.extended(
      heroTag: AppStrings.fabAddActionHeroTag,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 3,
      highlightElevation: 6,
      onPressed: () {
        HapticFeedbackHelper.mediumImpact();
        _handleQuickAdd(context, currentStatus);
      },
      icon: Icon(
        Icons.add_rounded,
        size: 24,
      ),
      label: const Text(
        '추가',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  void _handleQuickAdd(BuildContext context, GTDStatus status) {
    // Since we don't have a full Action object to pass anymore,
    // we can pass null and let the dialog know it's a new action.
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ActionEditDialog(
        actionWithContexts: null, // Pass null for new actions
        isRoutineMode: status == GTDStatus.scheduled,
        prefilledStatus: status, // Pass the status for pre-filling
      ),
    );
  }
}
