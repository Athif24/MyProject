import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_gradients.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_shadows.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isOpen;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          height: AppSizes.navHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.navPill),
            boxShadow: AppShadows.nav,
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                label: 'Beranda',
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                label: 'Pesan',
              ),
              _CenterFab(
                isOpen: isOpen,
                onTap: () => onTap(4),
              ),
              _NavItem(
                icon: Icons.note_alt_outlined,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                label: 'Catatan',
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                label: 'Kalender',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String label;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              height: AppSizes.navIconBox,
              width: AppSizes.navIconBox,
              decoration: BoxDecoration(
                color: isActive ? AppColors.navActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.iconBox),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _CenterFab({
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isOpen ? 'Tutup' : 'Buat baru',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: AppSizes.fab,
          height: AppSizes.navHeight,
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -AppSizes.fabLift),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: AppSizes.fab,
                width: AppSizes.fab,
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.ink : null,
                  gradient: isOpen ? null : AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.fab),
                  boxShadow: AppShadows.fab,
                ),
                child: AnimatedRotation(
                  turns: isOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
