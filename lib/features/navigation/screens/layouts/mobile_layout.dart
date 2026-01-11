import 'package:flutter/material.dart';
import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';

class MobileLayout extends StatelessWidget {
  final Widget contentView;
  final String title;

  const MobileLayout({
    super.key,
    required this.contentView,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Scaffold를 제거하고 AppBar만 반환
    // drawer는 상위 Scaffold(MainScreen)에서 관리됨
    return Column(
      children: [
        AppBar(
          title: Text(title),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                HapticFeedbackHelper.lightImpact();
                // 상위 Scaffold의 drawer를 열기 위해 위로 올라가서 찾음
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        Expanded(child: contentView),
      ],
    );
  }
}
