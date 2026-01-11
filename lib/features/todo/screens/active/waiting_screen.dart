import 'package:flutter/material.dart';

import 'package:gtdoro/core/utils/screen_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/screens/actions_screen.dart';
import 'package:gtdoro/features/todo/widgets/page_header.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionScreen(
      headerBuilder: (context, count) => PageHeader(
        title: 'Waiting For',
        subtitle: '다른 사람이 해야 할 일을 기다리는 항목들입니다.',
        color: colorScheme.tertiary,
      ),
      status: GTDStatus.waiting,
      emptyMessage: ScreenHelper.getEmptyMessage(
        context,
        defaultMessage: '대기 중인 항목이 없습니다.',
        filteredMessage: '이 컨텍스트에 해당하는 대기 중인 항목이 없습니다.',
      ),
      showCompletedToggle: true,
      showQuickInput: false,
      showContextFilterBar: false,
    );
  }
}
