import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/utils/error_handler.dart';
import 'package:gtdoro/core/utils/haptic_feedback_helper.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';

class ActionQuickInput extends StatefulWidget {
  final GTDStatus status;
  const ActionQuickInput({super.key, required this.status});

  @override
  State<ActionQuickInput> createState() => _ActionQuickInputState();
}

class _ActionQuickInputState extends State<ActionQuickInput> {
  late final TextEditingController _controller = TextEditingController();

  void _submit() async {
    final value = _controller.text.trim();
    dev.log('ActionQuickInput: _submit called, value: "$value", status: ${widget.status}');
    
    if (value.isNotEmpty) {
      try {
        HapticFeedbackHelper.mediumImpact();
        dev.log('ActionQuickInput: Reading ActionProvider from context');
        final actionProvider = context.read<ActionProvider>();
        dev.log('ActionQuickInput: ActionProvider read successfully: ${actionProvider.runtimeType}');
        dev.log('ActionQuickInput: Calling addAction with title: "$value", status: ${widget.status}');
        await actionProvider.addAction(title: value, status: widget.status);
        dev.log('ActionQuickInput: addAction completed successfully');
        _controller.clear();
        dev.log('ActionQuickInput: Controller cleared');
      } catch (e, stackTrace) {
        dev.log('ActionQuickInput: Error in _submit', error: e, stackTrace: stackTrace);
        if (mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    } else {
      dev.log('ActionQuickInput: Value is empty, skipping submit');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInbox = widget.status == GTDStatus.inbox;
    
    // Nirvana 스타일: Inbox는 더 미니멀하고 빠른 입력
    if (isInbox) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: TextField(
          controller: _controller,
          enabled: true,
          autofocus: false,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.2,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: '빠르게 추가...',
            hintStyle: TextStyle(
              fontSize: 17,
              color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.5).round()),
              letterSpacing: -0.2,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      );
    }
    
    // 다른 화면은 기존 스타일 유지
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: true,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '${widget.status.name.toUpperCase()} 빠른 추가...',
                hintStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                prefixIcon: Icon(Icons.add_task, size: 20, color: theme.colorScheme.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.4).round()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _submit,
            icon: const Icon(Icons.arrow_upward, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}
