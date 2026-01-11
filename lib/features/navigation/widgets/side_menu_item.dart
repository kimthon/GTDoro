import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';
import 'package:gtdoro/features/navigation/models/nav_tab.dart';
import 'package:gtdoro/features/navigation/models/nav_tab_extensions.dart';
import 'package:gtdoro/features/navigation/providers/navigation_provider.dart';

class SideMenuItem extends StatelessWidget {
  final NavTab tab;

  const SideMenuItem({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = navProvider.currentTab == tab;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          HapticFeedbackHelper.lightImpact();
          navProvider.setTab(tab);
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withAlpha(38)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withAlpha(51)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: isSelected ? 18 : 0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isSelected ? 12 : 0),
              Icon(
                tab.icon,
                size: 20,
                color: isSelected
                    ? colorScheme.secondary
                    : colorScheme.onSurface.withAlpha(102),
              ),
              const SizedBox(width: 12),
              Text(
                tab.label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withAlpha(102),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
