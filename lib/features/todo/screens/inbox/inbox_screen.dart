import 'package:flutter/material.dart';

import 'package:gtdoro/core/utils/screen_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/screens/actions_screen.dart';
import 'package:gtdoro/features/todo/widgets/page_header.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ActionScreen(
      headerBuilder: (context, count) => PageHeader(
        title: 'Inbox',
        subtitle: count == 0 ? '빈 인박스' : '$count개의 항목',
        color: Theme.of(context).colorScheme.primary,
      ),
      status: GTDStatus.inbox,
      emptyMessage: ScreenHelper.getEmptyMessage(
        context,
        defaultMessage: '인박스가 비어있습니다. 아이디어를 추가하세요!',
        filteredMessage: '이 컨텍스트에 해당하는 아이디어가 없습니다.',
      ),
      showCompletedToggle: true,
      showContextFilterBar: false,
    );
  }
}