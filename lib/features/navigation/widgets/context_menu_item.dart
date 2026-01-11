import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/navigation/screens/side_menu.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';

class ContextMenuItem extends StatelessWidget {
  final Context contextModel;

  const ContextMenuItem({super.key, required this.contextModel});

  @override
  Widget build(BuildContext context) {
    final contextProvider = context.watch<ContextProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final bool isSelected = contextProvider.activeFilterIds.contains(contextModel.id);

    // Use a Listener to handle the onItemTap callback for closing the drawer on mobile
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        final dynamic sideMenu = context.findAncestorWidgetOfExactType<SideMenu>();
        sideMenu?.onItemTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () {
            HapticFeedbackHelper.lightImpact();
            context.read<ContextProvider>().toggleFilter(contextModel);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? Color(contextModel.colorValue).withAlpha(38) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: isSelected ? 18 : 0,
                  decoration: BoxDecoration(
                    color: Color(contextModel.colorValue),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.label_outline, // Using a generic icon
                  size: 20,
                  color: isSelected ? Color(contextModel.colorValue) : colorScheme.onSurface.withAlpha(102),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ContextProvider.formatContextName(contextModel),
                    style: TextStyle(
                      color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withAlpha(102),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}