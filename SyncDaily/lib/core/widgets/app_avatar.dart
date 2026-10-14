import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool isGroup;

  const AppAvatar({
    super.key,
    required this.name,
    this.size = AppSizes.avatar,
    this.isGroup = false,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
  }

  AvatarColor get _color {
    final index = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return AppColors.avatarPalette[index % AppColors.avatarPalette.length];
  }

  IconData? get _groupIcon => isGroup ? Icons.groups_outlined : null;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final icon = _groupIcon;

    return Semantics(
      label: name,
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.background,
          shape: BoxShape.circle,
        ),
        child: icon != null
            ? Icon(icon, color: color.foreground, size: size * 0.5)
            : Text(
                _initials,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: color.foreground,
                ),
              ),
      ),
    );
  }
}
