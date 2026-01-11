import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String? filterName;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    this.filterName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Nirvana 스타일: 더 미니멀하고 깔끔한 헤더
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: -0.8,
                  height: 1.0,
                ),
              ),
              if (filterName != null) ...[
                const SizedBox(width: 12),
                Text(
                  '@$filterName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: color.withAlpha((255 * 0.65).round()),
                    letterSpacing: -0.3,
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.55).round()),
              letterSpacing: 0.1,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}