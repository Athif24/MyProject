import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/presentation/theme/note_color_theme.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_labels.dart';

/// Kartu catatan pada tampilan grid dua kolom.
///
/// Isi singkat dibatasi [AppSizes.notePreviewLines] baris dengan elipsis.
///
/// TODO(design): layar Catatan belum memerinci kartu catatan (padding, rasio,
/// dan gaya label). Sementara memakai token theme sampai desain tersedia.
class NoteCard extends StatelessWidget {
  final Note note;

  /// Tanggal hari ini (tanpa jam) untuk label "Hari ini"/"Kemarin".
  final DateTime today;
  final VoidCallback? onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.today,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = noteCategoryFromStorage(note.category);
    final palette = context.notePaletteFor(category, note.color);

    return Semantics(
      button: onTap != null,
      label: note.title,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      noteCategoryLabelFromStorage(note.category),
                      style: AppTypography.textTheme.labelSmall
                          ?.copyWith(color: palette.icon),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    Semantics(
                      label: AppStrings.notePin,
                      child: Icon(
                        AppIcons.pin,
                        size: AppSizes.iconSmall,
                        color: palette.icon,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.itemSpacing),
              Text(
                note.title,
                style: AppTypography.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.itemSpacing),
              // Isi singkat mengisi sisa tinggi kartu supaya tidak meluap.
              Expanded(
                child: Text(
                  note.content.trim().isEmpty
                      ? AppStrings.noNoteContent
                      : note.content,
                  style: AppTypography.textTheme.bodySmall,
                  maxLines: AppSizes.notePreviewLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSizes.itemSpacing),
              Text(
                noteDateLabel(note.updatedAt, today),
                style: AppTypography.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
