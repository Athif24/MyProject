import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/presentation/theme/note_color_theme.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_labels.dart';

/// Item catatan pada tampilan daftar: kotak ikon berwarna kategori, judul,
/// label kategori, tanggal, dan penanda sematan.
///
/// TODO(design): tampilan daftar layar Catatan belum didesain; sementara
/// menumpang gaya `ListItemTile` yang sudah ada.
class NoteTile extends StatelessWidget {
  final Note note;
  final DateTime today;
  final VoidCallback? onTap;

  const NoteTile({
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.listItem),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: Row(
              children: [
                Container(
                  height: AppSizes.listItemIcon,
                  width: AppSizes.listItemIcon,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(AppRadius.iconBoxSmall),
                  ),
                  child: Icon(
                    AppIcons.notes,
                    color: palette.icon,
                    size: AppSizes.iconSmall,
                  ),
                ),
                const SizedBox(width: AppSizes.cardGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        note.title,
                        style: AppTypography.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noteCategoryLabelFromStorage(note.category),
                        style: AppTypography.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.itemSpacing),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      noteDateLabel(note.updatedAt, today),
                      style: AppTypography.textTheme.bodySmall,
                    ),
                    if (note.isPinned) ...[
                      const SizedBox(height: 2),
                      Semantics(
                        label: AppStrings.notePin,
                        child: Icon(
                          AppIcons.pin,
                          size: AppSizes.iconSmall,
                          color: palette.icon,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
