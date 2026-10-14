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
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hasUnread ? AppColors.unreadBg : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.listItem),
            border: Border.all(
              color: _hasUnread ? AppColors.unreadBorder : AppColors.borderSoft,
            ),
          ),
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
                      style: AppTypography.textTheme.titleMedium,
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
                    Text(time!, style: AppTypography.textTheme.bodySmall),
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
