import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/navigation/widgets/context_filter_bar.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/providers/scheduled_provider.dart';
import 'package:gtdoro/features/todo/widgets/action_list_view.dart';
import 'package:gtdoro/features/todo/widgets/action_quick_input.dart';
import 'package:gtdoro/features/todo/widgets/completed_toggle.dart';
import 'package:gtdoro/features/todo/widgets/next_action_date_group.dart';
import 'package:gtdoro/features/todo/widgets/page_header.dart';
import 'package:gtdoro/features/todo/widgets/tiles/scheduled_action_tile.dart';

typedef HeaderBuilder = Widget Function(BuildContext context, int count);

class ActionScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final Color? titleColor;
  final HeaderBuilder? headerBuilder;
  final GTDStatus status;
  final String emptyMessage;
  final bool showCompletedToggle;
  final bool showQuickInput;
  final bool showContextFilterBar;
  final Action? selectedPomodoroAction;
  final Widget? headerAccessory;
  final int? focusEnergy;
  final int? focusDuration;
  final Widget? focusFilterBar;

  const ActionScreen({
    super.key,
    this.title,
    this.subtitle,
    this.titleColor,
    this.headerBuilder,
    required this.status,
    required this.emptyMessage,
    this.showCompletedToggle = false,
    this.showQuickInput = true,
    this.showContextFilterBar = false,
    this.selectedPomodoroAction,
    this.headerAccessory,
    this.focusEnergy,
    this.focusDuration,
    this.focusFilterBar,
  }) : assert(headerBuilder != null ||
            (title != null && subtitle != null && titleColor != null));

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header section (fixed) - Nirvana 스타일: 더 넓은 간격
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Selector<ActionProvider, int>(
                    selector: (_, provider) {
                      // activeActions는 이미 isDone == false && isDeleted == false로 필터링됨
                      final count = provider.activeActions
                          .where((t) => t.action.status == widget.status)
                          .length;
                      return count;
                    },
                    shouldRebuild: (previous, next) => previous != next,
                    builder: (context, activeActionCount, child) {
                      return widget.headerBuilder != null
                          ? widget.headerBuilder!(context, activeActionCount)
                          : PageHeader(
                              title: widget.title!,
                              subtitle: widget.subtitle!,
                              color: widget.titleColor!,
                            );
                    },
                  ),
                  if (widget.headerAccessory != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: widget.headerAccessory!,
                    ),
                  ],
                  if (widget.showContextFilterBar) ...[
                    const SizedBox(height: 10),
                    const ContextFilterBar(),
                  ],
                  if (widget.focusFilterBar != null) ...[
                    widget.focusFilterBar!,
                  ]
                ],
              ),
            ),

            const SizedBox(height: 8), // Adjusted spacing

            // 2. List section (scrollable)
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 80), // FAB 공간 확보
                child: Column(
                  children: [
                    // Incomplete actions list
                    // For Scheduled, show ScheduledActions (schedules), not generated Actions
                    if (widget.status == GTDStatus.scheduled)
                      Selector<ScheduledProvider, List<ScheduledAction>>(
                        selector: (_, provider) => provider.actions,
                        shouldRebuild: (previous, next) {
                          // 성능 최적화: 빠른 비교
                          if (previous.length != next.length) return true;
                          if (previous.isEmpty) return false;
                          
                          // 첫 번째와 마지막 항목만 확인 (대부분의 경우 충분)
                          final firstChanged = previous.first.id != next.first.id ||
                              previous.first.updatedAt?.millisecondsSinceEpoch != next.first.updatedAt?.millisecondsSinceEpoch;
                          final lastChanged = previous.last.id != next.last.id ||
                              previous.last.updatedAt?.millisecondsSinceEpoch != next.last.updatedAt?.millisecondsSinceEpoch;
                          
                          if (firstChanged || lastChanged) return true;
                          
                          // 전체 비교 (드물게만 실행)
                          for (int i = 0; i < previous.length; i++) {
                            if (previous[i].id != next[i].id ||
                                previous[i].updatedAt?.millisecondsSinceEpoch != next[i].updatedAt?.millisecondsSinceEpoch) {
                              return true;
                            }
                          }
                          
                          return false;
                        },
                        builder: (context, scheduledActions, child) {
                          if (scheduledActions.isEmpty) {
                            return ActionListView(
                              currentStatus: widget.status,
                              actions: [],
                              emptyMessage: widget.emptyMessage,
                              showQuickInput: widget.showQuickInput,
                              selectedPomodoroAction: widget.selectedPomodoroAction,
                            );
                          }
                          
                          return Column(
                            children: [
                              if (widget.showQuickInput && widget.status != GTDStatus.completed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ActionQuickInput(status: widget.status),
                                ),
                              // Scheduled actions list
                              ...scheduledActions.map((sa) {
                                return Padding(
                                  key: Key('scheduled_${sa.id}'),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ScheduledActionTile(scheduledAction: sa),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      )
                    // For Next Actions, show grouped by date with overdue
                    else if (widget.status == GTDStatus.next)
                      Selector<ActionProvider, Map<String, List<ActionWithContexts>>>(
                        selector: (_, provider) {
                          final grouped = provider.groupedNextActions;
                          
                          // Apply focus filters if set
                          if (widget.focusEnergy != null || widget.focusDuration != null) {
                            final filtered = <String, List<ActionWithContexts>>{};
                            grouped.forEach((key, actions) {
                              final filteredActions = actions.where((actionWithContexts) {
                                final action = actionWithContexts.action;
                                // Energy 필터: 정확히 일치하는 것만
                                if (widget.focusEnergy != null && action.energyLevel != widget.focusEnergy) {
                                  return false;
                                }
                                // Duration 필터: 선택한 시간보다 작거나 같은 것만 (<=)
                                if (widget.focusDuration != null) {
                                  if (action.duration == null || action.duration! > widget.focusDuration!) {
                                    return false;
                                  }
                                }
                                return true;
                              }).toList();
                              if (filteredActions.isNotEmpty) {
                                filtered[key] = filteredActions;
                              }
                            });
                            return filtered;
                          }
                          
                          return grouped;
                        },
                        shouldRebuild: (previous, next) {
                          // 성능 최적화: 빠른 비교
                          if (previous.length != next.length) return true;
                          
                          // 키 비교 (빠른 비교)
                          final prevKeys = previous.keys.toList()..sort();
                          final nextKeys = next.keys.toList()..sort();
                          if (prevKeys.length != nextKeys.length) return true;
                          for (int i = 0; i < prevKeys.length; i++) {
                            if (prevKeys[i] != nextKeys[i]) return true;
                          }
                          
                          // 각 키의 액션 개수나 첫/마지막 ID만 확인 (성능 최적화)
                          for (final key in previous.keys) {
                            if (!next.containsKey(key)) return true;
                            final prevActions = previous[key]!;
                            final nextActions = next[key]!;
                            if (prevActions.length != nextActions.length) return true;
                            
                            // 첫 번째와 마지막 항목만 확인 (대부분의 경우 충분)
                            if (prevActions.isNotEmpty && nextActions.isNotEmpty) {
                              if (prevActions.first.action.id != nextActions.first.action.id ||
                                  prevActions.last.action.id != nextActions.last.action.id) {
                                return true;
                              }
                            }
                          }
                          
                          return false;
                        },
                        builder: (context, groupedActions, child) {
                          if (groupedActions.isEmpty) {
                            return ActionListView(
                              currentStatus: widget.status,
                              actions: [],
                              emptyMessage: widget.emptyMessage,
                              showQuickInput: widget.showQuickInput,
                              selectedPomodoroAction: widget.selectedPomodoroAction,
                            );
                          }
                          
                          // Sort keys: overdue first, then by date
                          final sortedKeys = groupedActions.keys.toList()..sort((a, b) {
                            if (a == '⚠️ 마감일 지남') return -1;
                            if (b == '⚠️ 마감일 지남') return 1;
                            if (a == '마감일 없음') return 1;
                            if (b == '마감일 없음') return -1;
                            return a.compareTo(b);
                          });
                          
                          return Column(
                            children: [
                              if (widget.showQuickInput && widget.status != GTDStatus.completed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ActionQuickInput(status: widget.status),
                                ),
                              ...sortedKeys.map((dateKey) {
                                return NextActionDateGroup(
                                  dateKey: dateKey,
                                  actions: groupedActions[dateKey]!,
                                  selectedPomodoroAction: widget.selectedPomodoroAction,
                                );
                              }),
                            ],
                          );
                        },
                      )
                    // For other statuses (waiting, someday, etc.)
                    else
                      Selector<ActionProvider, List<ActionWithContexts>>(
                            selector: (_, provider) {
                              final filtered = provider.activeActions
                                  .where((t) => t.action.status == widget.status)
                                  .toList();
                              
                              // For waiting status, only show items with waitingFor
                              // For other statuses, exclude items with waitingFor
                              if (widget.status == GTDStatus.waiting) {
                                return filtered.where((t) => 
                                  t.action.waitingFor != null && 
                                  t.action.waitingFor!.isNotEmpty
                                ).toList();
                              } else {
                                return filtered.where((t) => 
                                  t.action.waitingFor == null || 
                                  t.action.waitingFor!.isEmpty
                                ).toList();
                              }
                            },
                            shouldRebuild: (previous, next) =>
                                !listEquals(previous, next),
                            builder: (context, activeActions, child) {
                              return ActionListView(
                                currentStatus: widget.status,
                                actions: activeActions,
                                emptyMessage: widget.emptyMessage,
                                showQuickInput: widget.showQuickInput,
                                selectedPomodoroAction: widget.selectedPomodoroAction,
                              );
                            },
                          ),

                    // Completed actions toggle and list
                    if (widget.showCompletedToggle)
                      Selector<ActionProvider, List<ActionWithContexts>>(
                        selector: (_, provider) => provider.todayCompletedActions
                            .where((t) => t.action.status == widget.status)
                            .toList(),
                        shouldRebuild: (previous, next) =>
                            !listEquals(previous, next),
                        builder: (context, completedActions, child) {
                          if (completedActions.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              const SizedBox(height: 12),
                              CompletedToggle(
                                isExpanded: _showCompleted,
                                count: completedActions.length,
                                onTap: () =>
                                    setState(() => _showCompleted = !_showCompleted),
                              ),
                              if (_showCompleted)
                                ActionListView(
                                  currentStatus: GTDStatus.completed,
                                  actions: completedActions,
                                  showQuickInput: false,
                                  selectedPomodoroAction:
                                      widget.selectedPomodoroAction,
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
