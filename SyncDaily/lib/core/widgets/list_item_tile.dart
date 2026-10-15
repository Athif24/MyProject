import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/widgets/app_avatar.dart';
import 'package:sync_daily/core/widgets/unread_badge.dart';
import 'package:sync_daily/core/widgets/unread_dot.dart';

class ListItemTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? time;
  final IconData? icon;
  final String? avatarName;
  final Color? iconBackground;
  final Color? iconColor;
  final int unreadCount;
  final bool isUnread;

  /// True bila item sudah selesai: judulnya dicoret (dipakai Kalender, yang
  /// tetap menampilkan item selesai). Bawaan `false` agar tampilan lama sama.
  final bool isCompleted;

  /// Isi tambahan selebar kartu di bawah baris judul, MASIH di dalam area
  /// ketuk utama (dipakai Kalender untuk daftar sub-tugas). Jarak dan padding
  /// diatur pemanggil supaya bisa ikut beranimasi. Bawaan `null` agar tampilan
  /// lama sama.
  final Widget? footer;

  /// Baris tambahan di dasar kartu, DI LUAR area ketuk utama ([onTap]) supaya
  /// bisa punya aksi sendiri (dipakai Kalender untuk baris panah sub-tugas).
  /// Bawaan `null` agar tampilan lama sama.
  final Widget? bottomBar;
  final VoidCallback? onTap;

  const ListItemTile({
    super.key,
    required this.title,
    this.subtitle,
    this.time,
    this.icon,
    this.avatarName,
    this.iconBackground,
    this.iconColor,
    this.unreadCount = 0,
    this.isUnread = false,
    this.isCompleted = false,
    this.footer,
    this.bottomBar,
    this.onTap,
  }) : assert(
          icon != null || avatarName != null,
          'ListItemTile butuh icon atau avatarName',
        );

  bool get _hasUnread => unreadCount > 0 || isUnread;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: title,
      child: Container(
        decoration: BoxDecoration(
          color: _hasUnread ? AppColors.unreadBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.listItem),
          border: Border.all(
            color: _hasUnread ? AppColors.unreadBorder : AppColors.borderSoft,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.cardPadding),
                    child: Row(
                      children: [
                        _Leading(
                          icon: icon,
                          avatarName: avatarName,
                          iconBackground: iconBackground,
                          iconColor: iconColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: isCompleted
                                    ? AppTypography.textTheme.titleMedium
                                        ?.copyWith(
                                        decoration:
                                            TextDecoration.lineThrough,
                                        decorationColor: AppColors.textMuted,
                                      )
                                    : AppTypography.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  style: AppTypography.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (time != null)
                              Text(
                                time!,
                                style: AppTypography.textTheme.bodySmall,
                              ),
                            if (_hasUnread) ...[
                              const SizedBox(height: 6),
                              unreadCount > 0
                                  ? UnreadBadge(count: unreadCount)
                                  : const UnreadDot(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ?footer,
                ],
              ),
            ),
            ?bottomBar,
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  final IconData? icon;
  final String? avatarName;
  final Color? iconBackground;
  final Color? iconColor;

  const _Leading({
    this.icon,
    this.avatarName,
    this.iconBackground,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarName != null) {
      return AppAvatar(name: avatarName!, size: AppSizes.listItemIcon);
    }
    return Container(
      height: AppSizes.listItemIcon,
      width: AppSizes.listItemIcon,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconBackground ?? AppColors.navActiveBg,
        borderRadius: BorderRadius.circular(AppRadius.iconBoxSmall),
      ),
      child: Icon(
        icon,
        color: iconColor ?? AppColors.primary,
        size: 22,
      ),
    );
  }
}
