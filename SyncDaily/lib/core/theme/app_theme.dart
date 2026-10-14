import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/theme/category_theme.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.navActiveBg,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AppTypography.textTheme,
      extensions: const <ThemeExtension>[
        AppCategoryColors.defaultValue,
      ],
      dividerTheme: const DividerThemeData(color: AppColors.borderSoft),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTypography.textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
    );
  }
}

extension AppThemeExt on BuildContext {
  AppCategoryColors get categoryColors =>
      Theme.of(this).extension<AppCategoryColors>()!;
}
