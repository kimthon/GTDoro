import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/widgets/dialogs/action_edit_dialog.dart';

class RecurringActionTile extends StatelessWidget {
  final RecurringAction recurringAction;

  const RecurringActionTile({
    super.key,
    required this.recurringAction,
  });

  String _formatRecurrenceType(RecurrenceType type, int interval) {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? '매일' : '$interval일마다';
      case RecurrenceType.weekly:
        return interval == 1 ? '매주' : '$interval주마다';
      case RecurrenceType.monthly:
        return interval == 1 ? '매월' : '$interval개월마다';
    }
  }

  // 성능 최적화: DateFormat 캐싱 (클래스 레벨)
  static final _dateFormatter = DateFormat('yyyy-MM-dd');
  
  String _formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOneTimeScheduled = recurringAction.totalCount == 1;
    final nextRunDate = recurringAction.nextRunDate;
    final nextRunDateOnly = DateTime(nextRunDate.year, nextRunDate.month, nextRunDate.day);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedbackHelper.lightImpact();
          showDialog(
            context: context,
            builder: (_) => ActionEditDialog(
              isRoutineMode: true,
              routineActionId: recurringAction.id,
            ),
          );
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
                      recurringAction.title,
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
              if (recurringAction.description != null && recurringAction.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  recurringAction.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                    letterSpacing: -0.1,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (isOneTimeScheduled) ...[
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
                      child: Text(
                        '시작일: ${_formatDate(nextRunDateOnly)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.tertiary.withAlpha((255 * 0.9).round()),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (recurringAction.advanceDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withAlpha((255 * 0.2).round()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${recurringAction.advanceDays}일 전 생성',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                  ] else ...[
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
                        _formatRecurrenceType(recurringAction.type, recurringAction.interval),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary.withAlpha((255 * 0.9).round()),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withAlpha((255 * 0.2).round()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '다음: ${_formatDate(nextRunDateOnly)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                  if (recurringAction.skipHolidays)
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
