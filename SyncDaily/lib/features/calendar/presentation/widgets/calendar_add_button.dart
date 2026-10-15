import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';

/// Tombol tambah ungu di seksi "Tugas Hari Ini" pada layar Kalender.
///
/// TODO(design): bentuk dan ukuran tombol tambah Kalender belum dirinci di
/// DESIGN.md; sementara memakai lingkaran primary dengan ukuran target sentuh
/// minimum.
class CalendarAddButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CalendarAddButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.addItem,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppSizes.minTouchTarget,
          width: AppSizes.minTouchTarget,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            AppIcons.add,
            color: AppColors.surface,
            size: AppSizes.iconSmall,
          ),
        ),
      ),
    );
  }
}
