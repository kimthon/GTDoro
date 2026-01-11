import 'package:flutter/material.dart' hide Action;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_strings.dart';
import 'package:gtdoro/core/utils/action_grouping_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';

class ActionMetadataRow extends StatelessWidget {
  final ActionWithContexts actionWithContexts;
  
  // 성능 최적화: DateFormat 캐싱 (반복 생성 방지)
  static final _shortDateFormatter = DateFormat('MM/dd');

  const ActionMetadataRow({super.key, required this.actionWithContexts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = actionWithContexts.action;
    
    // 성능 최적화: today를 한 번만 계산
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = ActionGroupingHelper.isOverdue(action, today);
    
    // 성능 최적화: Consumer 대신 Selector 사용 (contextIds만 변경될 때만 리빌드)
    return Selector<ContextProvider, List<Context>>(
      selector: (_, provider) => provider.getContextsByIds(actionWithContexts.contextIds),
      shouldRebuild: (previous, next) {
        // 성능 최적화: 길이와 ID만 비교
        if (previous.length != next.length) return true;
        for (int i = 0; i < previous.length; i++) {
          if (previous[i].id != next[i].id) return true;
        }
        return false;
      },
      builder: (context, contexts, child) {
        if (!_hasMetadata(action, contexts)) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 8, // Adjust spacing to prevent items from being too far apart on mobile
            runSpacing: 6, // Add space when wrapping to prevent overlap
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Overdue badge
              if (isOverdue && !action.isDone)
                _buildMetadataBadge(
                  icon: Icons.warning_amber_rounded,
                  label: AppStrings.overdueLabel,
                  color: theme.colorScheme.error,
                ),
              // Due date badge
              if (action.dueDate != null && !action.isDone)
                _buildMetadataBadge(
                  icon: Icons.calendar_today,
                  label: _shortDateFormatter.format(action.dueDate!),
                  color: isOverdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                ),
              if (action.energyLevel != null)
                _buildMetadataBadge(
                  icon: Icons.bolt,
                  label: '${action.energyLevel}',
                  color: theme.colorScheme.primary,
                ),
              if (action.duration != null)
                _buildMetadataBadge(
                  icon: Icons.timer_outlined,
                  label: '${action.duration}m',
                  color: theme.colorScheme.secondary,
                ),
              if (action.waitingFor != null && action.waitingFor!.isNotEmpty)
                _buildMetadataBadge(
                  icon: Icons.hourglass_empty_rounded,
                  label: action.waitingFor!,
                  color: theme.colorScheme.tertiary,
                ),
              ...contexts.map((ctx) =>
                  _buildMetadataBadge(
                    label: '#${ContextProvider.formatContextName(ctx)}',
                    color: Color(ctx.colorValue),
                    isContext: true,
                  )),
            ],
          ),
        );
      },
    );
  }

  bool _hasMetadata(Action action, List<Context> contexts) =>
      action.energyLevel != null ||
      action.duration != null ||
      action.waitingFor != null ||
      action.dueDate != null ||
      contexts.isNotEmpty;

  Widget _buildMetadataBadge({
    IconData? icon,
    required String label,
    required Color color,
    bool isContext = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.08).round()),
        borderRadius: BorderRadius.circular(6),
        border: isContext 
            ? Border.all(color: color.withAlpha((255 * 0.15).round()), width: 0.5) 
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color.withAlpha((255 * 0.8).round())),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withAlpha((255 * 0.9).round()),
              fontWeight: isContext ? FontWeight.w500 : FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
