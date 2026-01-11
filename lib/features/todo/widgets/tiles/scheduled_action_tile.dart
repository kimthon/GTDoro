import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/core/constants/app_strings.dart';
import 'package:gtdoro/core/utils/error_handler.dart';
import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';
import 'package:gtdoro/features/todo/providers/scheduled_provider.dart';
import 'package:gtdoro/features/todo/widgets/dialogs/action_edit_dialog.dart';

class ScheduledActionTile extends StatefulWidget {
  final ScheduledAction scheduledAction;
  
  const ScheduledActionTile({
    super.key,
    required this.scheduledAction,
  });

  @override
  State<ScheduledActionTile> createState() => _ScheduledActionTileState();
}

class _ScheduledActionTileState extends State<ScheduledActionTile> {
  // 성능 최적화: DateFormat 캐싱 (클래스 레벨)
  static final _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledAction = widget.scheduledAction;
    
    // 삭제된 아이템은 표시하지 않음 (stream이 업데이트되면 자동으로 제거됨)
    if (scheduledAction.isDeleted) {
      return const SizedBox.shrink();
    }
    
    return Dismissible(
      key: Key('${scheduledAction.id}_${scheduledAction.updatedAt?.millisecondsSinceEpoch ?? 0}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        
        HapticFeedbackHelper.heavyImpact();
        try {
          // 삭제 전에 아이템이 여전히 존재하는지 확인
          final scheduledProvider = context.read<ScheduledProvider>();
          final exists = scheduledProvider.actions.any((a) => a.id == scheduledAction.id && !a.isDeleted);
          
          if (exists && context.mounted) {
            // confirmDismiss에서 실제 삭제 수행
            await scheduledProvider.removeAction(scheduledAction.id);
            // 삭제 성공 시 SnackBar 표시
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${scheduledAction.title}" ${AppStrings.actionDeleted}'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
            return true; // dismiss 허용
          }
          return false; // 아이템이 없으면 dismiss 취소
        } catch (e) {
          dev.log('ScheduledActionTile: Error removing action', error: e);
          if (context.mounted) {
            ErrorHandler.showErrorWithRetry(
              context,
              e,
              () async {
                try {
                  if (context.mounted) {
                    await context.read<ScheduledProvider>().removeAction(scheduledAction.id);
                  }
                } catch (_) {}
              },
            );
          }
          return false; // 에러 발생 시 dismiss 취소
        }
      },
      onDismissed: (_) {
        // confirmDismiss에서 이미 삭제를 수행했으므로 여기서는 아무것도 하지 않음
        // 위젯은 stream 업데이트로 자동으로 제거됨
      },
      background: Container(
        color: theme.colorScheme.error.withAlpha((255 * 0.75).round()),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.p20),
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedbackHelper.lightImpact();
            _showEditDialog(context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha((255 * 0.2).round()),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: theme.colorScheme.tertiary.withAlpha((255 * 0.8).round()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scheduledAction.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.2,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (scheduledAction.description != null && scheduledAction.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  scheduledAction.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Selector<ContextProvider, List<Context>>(
                selector: (_, provider) => provider.getContextsByIds(scheduledAction.contextIds),
                shouldRebuild: (previous, next) {
                  if (previous.length != next.length) return true;
                  for (int i = 0; i < previous.length; i++) {
                    if (previous[i].id != next[i].id) return true;
                  }
                  return false;
                },
                builder: (context, contexts, child) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Start Date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer.withAlpha((255 * 0.3).round()),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.tertiary.withAlpha((255 * 0.3).round()),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 11,
                              color: theme.colorScheme.tertiary.withAlpha((255 * 0.9).round()),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _dateFormatter.format(scheduledAction.startDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.tertiary.withAlpha((255 * 0.9).round()),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Energy Level
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha((255 * 0.3).round()),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 11,
                              color: theme.colorScheme.primary.withAlpha((255 * 0.9).round()),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${scheduledAction.energyLevel}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary.withAlpha((255 * 0.9).round()),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Duration
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withAlpha((255 * 0.3).round()),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withAlpha((255 * 0.3).round()),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 11,
                              color: theme.colorScheme.secondary.withAlpha((255 * 0.9).round()),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${scheduledAction.duration}m',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.secondary.withAlpha((255 * 0.9).round()),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Advance Days
                      if (scheduledAction.advanceDays > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withAlpha((255 * 0.2).round()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${scheduledAction.advanceDays}일 전 생성',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      // Skip Holidays
                      if (scheduledAction.skipHolidays)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withAlpha((255 * 0.2).round()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '휴일 건너뛰기',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      // Is Created
                      if (scheduledAction.isCreated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.colorScheme.primary.withAlpha((255 * 0.3).round()),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '생성됨',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary.withAlpha((255 * 0.9).round()),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      // Contexts
                      ...contexts.map((ctx) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(ctx.colorValue).withAlpha((255 * 0.08).round()),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Color(ctx.colorValue).withAlpha((255 * 0.15).round()),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '#${ContextProvider.formatContextName(ctx)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(ctx.colorValue).withAlpha((255 * 0.9).round()),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ActionEditDialog(
        isRoutineMode: true,
        scheduledAction: widget.scheduledAction,
      ),
    );
  }
}
