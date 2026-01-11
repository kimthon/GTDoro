import 'package:flutter/material.dart' hide Action;

import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/widgets/action_quick_input.dart';
import 'package:gtdoro/features/todo/widgets/tiles/action_item_tile.dart';

class ActionListView extends StatelessWidget {
  final List<ActionWithContexts> actions;
  final GTDStatus currentStatus;
  final String emptyMessage;
  final bool showQuickInput;
  final Action? selectedPomodoroAction;

  const ActionListView({
    super.key,
    required this.actions,
    required this.currentStatus,
    this.emptyMessage = '할 일이 없습니다.',
    this.showQuickInput = true,
    this.selectedPomodoroAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLogbook = currentStatus == GTDStatus.completed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Quick input section
        if (!isLogbook && showQuickInput)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p8),
            child: ActionQuickInput(status: currentStatus),
          ),

        // 2. List or empty state
        actions.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                shrinkWrap: true, // Match height to children when parent is scroll view (key to fix error)
                physics: const NeverScrollableScrollPhysics(), // Prevent nested scroll conflicts
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final actionWithContexts = actions[index];
                  // 삭제된 Action은 표시하지 않음 (이중 체크)
                  if (actionWithContexts.action.isDeleted) {
                    return const SizedBox.shrink();
                  }
                  final isPomodoroSelected = actionWithContexts.action.id == selectedPomodoroAction?.id;
                  return Padding(
                    key: Key('action_${actionWithContexts.action.id}_${actionWithContexts.action.updatedAt?.millisecondsSinceEpoch ?? 0}'),
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ActionItemTile(
                      actionWithContexts: actionWithContexts,
                      isLogbook: isLogbook,
                      isPomodoroSelected: isPomodoroSelected,
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(),
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (currentStatus) {
      case GTDStatus.completed:
        return Icons.history_rounded;
      case GTDStatus.inbox:
        return Icons.all_inbox_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }
}