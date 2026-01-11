import 'package:flutter/material.dart' hide Action;
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/widgets/tiles/action_item_tile.dart';

class NextActionDateGroup extends StatelessWidget {
  final String dateKey;
  final List<ActionWithContexts> actions;
  final Action? selectedPomodoroAction;

  const NextActionDateGroup({
    super.key,
    required this.dateKey,
    required this.actions,
    this.selectedPomodoroAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = dateKey == '⚠️ 마감일 지남';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header - Nirvana 스타일: 더 미니멀하고 깔끔
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              if (isOverdue) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: theme.colorScheme.error.withAlpha((255 * 0.8).round()),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                dateKey,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isOverdue
                      ? theme.colorScheme.error.withAlpha((255 * 0.9).round())
                      : theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${actions.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOverdue
                      ? theme.colorScheme.error.withAlpha((255 * 0.7).round())
                      : theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.6).round()),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        // Actions list
        // 성능 최적화: map() 대신 List.generate 사용 (동일한 성능이지만 더 명시적)
        ...List.generate(actions.length, (index) {
          final actionWithContexts = actions[index];
          final isPomodoroSelected = actionWithContexts.action.id == selectedPomodoroAction?.id;
          return Padding(
            key: Key('next_action_${actionWithContexts.action.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: ActionItemTile(
              actionWithContexts: actionWithContexts,
              isLogbook: false,
              isPomodoroSelected: isPomodoroSelected,
            ),
          );
        }),
      ],
    );
  }
}
