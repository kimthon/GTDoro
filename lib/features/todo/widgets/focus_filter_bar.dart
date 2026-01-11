import 'package:flutter/material.dart';

/// Nirvana 스타일 Focus 필터 바
/// 에너지 레벨과 시간으로 필터링
class FocusFilterBar extends StatefulWidget {
  final Function(int?, int?) onFilterChanged;
  
  const FocusFilterBar({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<FocusFilterBar> createState() => _FocusFilterBarState();
}

class _FocusFilterBarState extends State<FocusFilterBar> {
  int? _selectedEnergy;
  int? _selectedDuration;
  
  void _updateFilters(int? energy, int? duration) {
    setState(() {
      _selectedEnergy = energy;
      _selectedDuration = duration;
    });
    widget.onFilterChanged(energy, duration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            'Focus',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.55).round()),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 14),
          // Energy 필터
          _buildFilterChip(
            theme: theme,
            label: 'Energy',
            value: _selectedEnergy,
            options: [1, 2, 3, 4, 5],
            onSelected: (value) {
              _updateFilters(
                _selectedEnergy == value ? null : value,
                _selectedDuration,
              );
            },
          ),
          const SizedBox(width: 10),
          // Duration 필터
          _buildFilterChip(
            theme: theme,
            label: 'Time',
            value: _selectedDuration,
            options: [10, 15, 25, 30, 45, 60],
            formatValue: (v) => '$v분',
            onSelected: (value) {
              _updateFilters(
                _selectedEnergy,
                _selectedDuration == value ? null : value,
              );
            },
          ),
          const Spacer(),
          if (_selectedEnergy != null || _selectedDuration != null)
            TextButton(
              onPressed: () {
                _updateFilters(null, null);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required ThemeData theme,
    required String label,
    required int? value,
    required List<int> options,
    String Function(int)? formatValue,
    required Function(int) onSelected,
  }) {
    return PopupMenuButton<int>(
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
            ),
          ),
        ),
        const PopupMenuDivider(),
        ...options.map((option) => PopupMenuItem(
          value: option,
          child: Row(
            children: [
              if (value == option)
                Icon(
                  Icons.check,
                  size: 16,
                  color: theme.colorScheme.primary,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                formatValue?.call(option) ?? option.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: value == option
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: value == option ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        )),
      ],
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: value != null
              ? theme.colorScheme.primaryContainer.withAlpha((255 * 0.15).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value != null
                ? theme.colorScheme.primary.withAlpha((255 * 0.4).round())
                : theme.colorScheme.outline.withAlpha((255 * 0.2).round()),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value != null
                    ? theme.colorScheme.primary.withAlpha((255 * 0.9).round())
                    : theme.colorScheme.onSurface.withAlpha((255 * 0.65).round()),
                letterSpacing: -0.1,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 5),
              Text(
                formatValue?.call(value) ?? value.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary.withAlpha((255 * 0.9).round()),
                  letterSpacing: -0.1,
                ),
              ),
            ],
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: value != null
                  ? theme.colorScheme.primary.withAlpha((255 * 0.8).round())
                  : theme.colorScheme.onSurface.withAlpha((255 * 0.45).round()),
            ),
          ],
        ),
      ),
    );
  }
}
