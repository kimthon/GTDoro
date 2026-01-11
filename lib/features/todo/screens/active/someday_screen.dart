import 'package:flutter/material.dart';

import 'package:gtdoro/core/utils/screen_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/screens/actions_screen.dart';

class SomedayScreen extends StatelessWidget {
  const SomedayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionScreen(
      title: 'Someday',
      subtitle: '언젠가 할 일들을 모아두세요.',
      titleColor: colorScheme.secondary,
      status: GTDStatus.someday,
      emptyMessage: ScreenHelper.getEmptyMessage(
        context,
        defaultMessage: '언젠가 할 일이 없습니다.',
        filteredMessage: '이 컨텍스트에 해당하는 언젠가 할 일이 없습니다.',
      ),
      showContextFilterBar: false,
    );
  }
}
