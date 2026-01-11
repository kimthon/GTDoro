import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/utils/screen_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:gtdoro/features/pomodoro/widgets/pomodoro_timer_widget.dart';
import 'package:gtdoro/features/todo/screens/actions_screen.dart';
import 'package:gtdoro/features/todo/widgets/page_header.dart';
import 'package:gtdoro/features/todo/widgets/focus_filter_bar.dart';

class NextScreen extends StatefulWidget {
  const NextScreen({super.key});

  @override
  State<NextScreen> createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen> {
  int? _focusEnergy;
  int? _focusDuration;

  void _onFocusFilterChanged(int? energy, int? duration) {
    setState(() {
      _focusEnergy = energy;
      _focusDuration = duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pomodoroProvider = context.watch<PomodoroProvider>();

    return ActionScreen(
      headerBuilder: (context, count) => PageHeader(
        title: 'Next Actions',
        subtitle: '지금 당장 실행 가능한 작업들입니다.',
        color: colorScheme.secondary,
      ),
      headerAccessory: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Show Pomodoro Timer'),
              Switch(
                value: pomodoroProvider.showTimer,
                onChanged: (value) {
                  context.read<PomodoroProvider>().toggleTimer(value);
                },
              ),
            ],
          ),
          if (pomodoroProvider.showTimer) ...[
            const SizedBox(height: 16),
            PomodoroTimerWidget(currentAction: pomodoroProvider.selectedAction),
          ],
        ],
      ),
      status: GTDStatus.next,
      emptyMessage: ScreenHelper.getEmptyMessage(
        context,
        defaultMessage: '다음 행동이 없습니다.',
        filteredMessage: '이 컨텍스트에 해당하는 다음 행동이 없습니다.',
      ),
      showCompletedToggle: true,
      showQuickInput: false,
      showContextFilterBar: true,
      selectedPomodoroAction: pomodoroProvider.selectedAction,
      focusEnergy: _focusEnergy,
      focusDuration: _focusDuration,
      focusFilterBar: FocusFilterBar(
        onFilterChanged: _onFocusFilterChanged,
      ),
    );
  }
}
