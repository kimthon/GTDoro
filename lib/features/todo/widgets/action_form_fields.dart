import 'package:flutter/material.dart';

class ActionFormFields {
  static Widget buildTitle(TextEditingController controller, {VoidCallback? onChanged}) {
    // Use Builder to access context and apply theme
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return TextField(
          controller: controller,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
          decoration: InputDecoration(
            hintText: '할 일 제목',
            hintStyle: theme.textTheme.titleLarge?.copyWith(
              color: theme.hintColor.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged?.call(), // 상태 업데이트를 위한 콜백
        );
      },
    );
  }

  static Widget buildDescription(TextEditingController controller) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return TextField(
          controller: controller,
          maxLines: null,
          minLines: 1,
          keyboardType: TextInputType.multiline,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
          decoration: InputDecoration(
            hintText: '메모 추가...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            isDense: true,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Icon(
                Icons.notes_rounded,
                size: 18,
                color: theme.iconTheme.color?.withValues(alpha: 0.5) ?? Colors.grey,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        );
      },
    );
  }
}
