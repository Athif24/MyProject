import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/widgets/app_chip.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_labels.dart';

/// Deretan chip kategori catatan.
///
/// [value] `null` berarti chip pertama aktif: "Semua" pada filter layar Catatan
/// atau "Tanpa kategori" pada form.
class NoteCategoryChips extends StatelessWidget {
  final NoteCategory? value;
  final String nullLabel;
  final ValueChanged<NoteCategory?> onChanged;

  const NoteCategoryChips({
    super.key,
    required this.value,
    required this.nullLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.itemSpacing,
      runSpacing: AppSizes.itemSpacing,
      children: [
        AppChip(
          label: nullLabel,
          isActive: value == null,
          onTap: () => onChanged(null),
        ),
        for (final category in NoteCategory.values)
          AppChip(
            label: noteCategoryLabel(category),
            isActive: value == category,
            onTap: () => onChanged(category),
          ),
      ],
    );
  }
}
