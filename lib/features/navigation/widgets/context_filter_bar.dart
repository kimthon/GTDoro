import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';

class ContextFilterBar extends StatelessWidget {
  const ContextFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final contextProvider = context.watch<ContextProvider>();
    final contexts = contextProvider.availableContexts;
    final activeFilterIds = contextProvider.activeFilterIds; // Use activeFilterIds

    if (contexts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          // "All" chip
          _buildChip(
            context: context,
            label: 'All',
            isSelected: activeFilterIds.isEmpty,
            onTap: () => context.read<ContextProvider>().clearFilters(),
          ),
          // Context chips
          ...contexts.map((contextModel) => _buildChip(
            context: context,
            label: '#${ContextProvider.formatContextName(contextModel)}',
            color: Color(contextModel.colorValue),
            isSelected: activeFilterIds.contains(contextModel.id),
            onTap: () => context.read<ContextProvider>().toggleFilter(contextModel),
          )),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final selectedColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      onSelected: (_) => onTap(),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          letterSpacing: -0.1,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
      selected: isSelected,
      backgroundColor: Colors.transparent,
      selectedColor: selectedColor.withAlpha((255 * 0.12).round()),
      checkmarkColor: selectedColor.withAlpha((255 * 0.9).round()),
      side: isSelected
          ? BorderSide(color: selectedColor.withAlpha((255 * 0.4).round()), width: 0.5)
          : BorderSide(color: theme.colorScheme.outline.withAlpha((255 * 0.2).round()), width: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}