import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';

class AppTypography {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.04,
      color: AppColors.textMuted,
    ),
  );
}
