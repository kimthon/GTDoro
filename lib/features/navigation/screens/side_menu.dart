import 'package:flutter/material.dart';

import 'package:gtdoro/features/navigation/models/nav_tab.dart';
import 'package:gtdoro/features/navigation/widgets/logo.dart';
import 'package:gtdoro/features/navigation/widgets/side_menu_item.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback? onItemTap;
  const SideMenu({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      width: 250,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Logo(),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: NavTab.values
                          .where((t) => t != NavTab.settings && t != NavTab.statistics)
                          .map((tab) => _buildItem(tab))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                      child: Text(
                        'STATISTICS',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildItem(NavTab.statistics),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildItem(NavTab.settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(NavTab tab) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onItemTap?.call(),
      child: SideMenuItem(tab: tab),
    );
  }
}
