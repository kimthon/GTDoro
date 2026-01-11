import 'package:flutter/material.dart';

import 'package:gtdoro/core/utils/screen_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/screens/actions_screen.dart';

class ScheduledScreen extends StatelessWidget {
  const ScheduledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionScreen(
      title: 'Scheduled',
      subtitle: 'Action을 생성하는 스케줄입니다.',
      titleColor: colorScheme.tertiary,
      status: GTDStatus.scheduled,
      emptyMessage: ScreenHelper.getEmptyMessage(
        context,
        defaultMessage: '예정된 할 일이 없습니다.',
        filteredMessage: '이 컨텍스트에 해당하는 예정된 할 일이 없습니다.',
      ),
      showQuickInput: false,
      showContextFilterBar: false,
    );
  }
}
