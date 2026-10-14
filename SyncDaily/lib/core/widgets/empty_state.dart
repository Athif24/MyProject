import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            style: AppTypography.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 16),
          action!,
        ],
      ],
    );
  }
}
