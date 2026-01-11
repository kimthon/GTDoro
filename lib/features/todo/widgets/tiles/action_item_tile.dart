import 'dart:developer' as dev;

import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/core/constants/app_strings.dart';
import 'package:gtdoro/core/theme/theme_provider.dart';
import 'package:gtdoro/core/utils/error_handler.dart';
import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/widgets/action_metadata_row.dart';
import 'package:gtdoro/features/todo/widgets/dialogs/action_edit_dialog.dart';
import 'package:gtdoro/features/todo/widgets/dialogs/inbox_simple_edit_dialog.dart';

class ActionItemTile extends StatefulWidget {
  final ActionWithContexts actionWithContexts;
  final bool isLogbook;
  final bool isPomodoroSelected;

  const ActionItemTile({
    super.key,
    required this.actionWithContexts,
    required this.isLogbook,
    this.isPomodoroSelected = false,
  });

  @override
  State<ActionItemTile> createState() => _ActionItemTileState();
}

class _ActionItemTileState extends State<ActionItemTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentColor = context.watch<ThemeProvider>().theme.comment;
    final action = widget.actionWithContexts.action;
    final bool hasDescription = action.description != null && action.description!.isNotEmpty;

    // 삭제된 아이템은 표시하지 않음 (stream이 업데이트되면 자동으로 제거됨)
    if (action.isDeleted) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key('${action.id}_${action.updatedAt?.millisecondsSinceEpoch ?? 0}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        
        HapticFeedbackHelper.heavyImpact();
        try {
          // 삭제 전에 아이템이 여전히 존재하는지 확인
          final actionProvider = context.read<ActionProvider>();
          final exists = actionProvider.allActions.any((a) => a.action.id == action.id && !a.action.isDeleted);
          
          if (exists && context.mounted) {
            // confirmDismiss에서 실제 삭제 수행
            await actionProvider.removeAction(action.id);
            // 삭제 성공 시 SnackBar 표시
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${action.title}" ${AppStrings.actionDeleted}'),
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
          dev.log('ActionItemTile: Error removing action', error: e);
          if (context.mounted) {
            ErrorHandler.showErrorWithRetry(
              context,
              e,
              () async {
                try {
                  if (context.mounted) {
                    await context.read<ActionProvider>().removeAction(action.id);
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
            // 인박스는 간단한 제목 수정만, 다른 화면은 상세 편집
            if (action.status == GTDStatus.inbox && !action.isDone) {
              showDialog(
                context: context,
                builder: (_) => InboxSimpleEditDialog(actionWithContexts: widget.actionWithContexts),
              );
            } else {
              showDialog(
                context: context,
                builder: (_) => ActionEditDialog(actionWithContexts: widget.actionWithContexts),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: widget.isPomodoroSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
              color: widget.isPomodoroSelected
                  ? theme.colorScheme.primaryContainer.withAlpha((255 * 0.15).round())
                  : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: action.isDone,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (_) async {
                  HapticFeedbackHelper.mediumImpact();
                  try {
                    await context.read<ActionProvider>().toggleDone(action.id);
                  } catch (e) {
                    dev.log('ActionItemTile: Error toggling done', error: e);
                    if (context.mounted) {
                      ErrorHandler.showError(context, e);
                    }
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        color: action.isDone 
                            ? commentColor 
                            : theme.colorScheme.onSurface,
                        decoration: action.isDone ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (hasDescription)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          action.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
                            height: 1.4,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    if (!action.isDone)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ActionMetadataRow(actionWithContexts: widget.actionWithContexts),
                      ),
                  ],
                ),
              ),
              if (action.status == GTDStatus.next && !action.isDone)
                IconButton(
                  icon: const Icon(Icons.timer_outlined),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: theme.colorScheme.primary.withAlpha((255 * 0.7).round()),
                  onPressed: () {
                    HapticFeedbackHelper.mediumImpact();
                    context.read<PomodoroProvider>().selectAction(action);
                  },
                  tooltip: 'Start Pomodoro',
                ),
              if (action.status == GTDStatus.inbox && !action.isDone) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: theme.colorScheme.primary.withAlpha((255 * 0.7).round()),
                  tooltip: 'Next Action으로 지정',
                  onPressed: () async {
                    HapticFeedbackHelper.mediumImpact();
                    try {
                      await context
                          .read<ActionProvider>()
                          .updateActionStatus(action.id, GTDStatus.next);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(AppStrings.nextActionAssigned),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      dev.log('ActionItemTile: Error updating status', error: e);
                      if (context.mounted) {
                        ErrorHandler.showError(context, e);
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
