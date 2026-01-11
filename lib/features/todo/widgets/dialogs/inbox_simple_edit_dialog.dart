import 'dart:developer' as dev;

import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/core/utils/error_handler.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/widgets/dialogs/action_edit_dialog.dart';

/// GTD 인박스용 간단한 제목 수정 다이얼로그
/// 인박스는 빠른 캡처만 하므로 제목만 수정 가능
class InboxSimpleEditDialog extends StatefulWidget {
  final ActionWithContexts actionWithContexts;

  const InboxSimpleEditDialog({
    super.key,
    required this.actionWithContexts,
  });

  @override
  State<InboxSimpleEditDialog> createState() => _InboxSimpleEditDialogState();
}

class _InboxSimpleEditDialogState extends State<InboxSimpleEditDialog> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.actionWithContexts.action.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }

    try {
      await context.read<ActionProvider>().updateAction(
        widget.actionWithContexts.action.id,
        title: title,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, stackTrace) {
      dev.log('InboxSimpleEditDialog: Error updating action', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  void _openFullEdit() {
    Navigator.pop(context); // 간단한 다이얼로그 닫기
    showDialog(
      context: context,
      builder: (_) => ActionEditDialog(actionWithContexts: widget.actionWithContexts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final content = TextField(
      controller: _titleController,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: '할 일 제목',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('제목 수정'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: '상세 편집',
              onPressed: _openFullEdit,
            ),
            TextButton(
              onPressed: _save,
              child: const Text(
                '저장',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: content,
        ),
      );
    } else {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r28),
        ),
        title: const Text('제목 수정'),
        content: SizedBox(
          width: 400,
          child: content,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ),
          TextButton.icon(
            onPressed: _openFullEdit,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('상세 편집'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
          FilledButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      );
    }
  }
}
