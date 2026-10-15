import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';

/// Tombol tambah ungu (lingkaran primary) yang dipakai layar Catatan.
///
/// TODO(design): bentuk dan ukuran tombol tambah layar Catatan belum dirinci di
/// DESIGN.md; sementara memakai lingkaran primary dengan ukuran target sentuh
/// minimum, sama seperti tombol tambah Kalender.
class AppAddButton extends StatelessWidget {
  final String semanticLabel;
  final VoidCallback? onTap;

  const AppAddButton({
    super.key,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
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
