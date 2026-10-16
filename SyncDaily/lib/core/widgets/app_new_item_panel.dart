import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/theme/category_theme.dart';

/// Pilihan ubin pada panel "Buat Baru".
///
/// [project] belum tersedia karena fitur proyek belum dibuat, jadi ubinnya
/// tampil tidak aktif dan tidak pernah dikirim lewat `onSelected`.
enum AppNewItemKind { task, event, reminder, milestone, note, project }

/// Panel "Buat Baru": latar gelap blur + panel melayang berisi enam ubin.
///
/// Panel hidup di dalam `AppShell` (bukan rute) supaya navigasi bawah tetap
/// tergambar di atas latar gelap sehingga tombol + dapat berputar menjadi x.
/// Widget ini hanya menampilkan state dan mengirim pilihan; pemetaan ubin ke
/// rute dikerjakan pemanggil. Saat tertutup widget tidak menggambar apa pun,
/// jadi lapisan blur tidak membebani gambar setiap frame.
class AppNewItemPanel extends StatefulWidget {
  /// Terbuka/tertutup. Perubahan nilai menjalankan animasi buka-tutup.
  final bool isOpen;

  /// Dipanggil saat latar gelap di luar panel diketuk.
  final VoidCallback onClose;

  /// Dipanggil saat ubin aktif dipilih.
  final ValueChanged<AppNewItemKind> onSelected;

  const AppNewItemPanel({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onSelected,
  });

  @override
  State<AppNewItemPanel> createState() => _AppNewItemPanelState();
}

class _AppNewItemPanelState extends State<AppNewItemPanel>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 250);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.isOpen) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AppNewItemPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen == oldWidget.isOpen) {
      return;
    }
    if (widget.isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isDismissed) {
          return const SizedBox.shrink();
        }

        final media = MediaQuery.of(context);
        // Panel melayang tepat di atas pill navigasi: tepi aman bawah + tinggi
        // pill + jaraknya ke tepi aman + celah.
        final bottom = media.padding.bottom +
            AppSizes.navHeight +
            AppSizes.navBottomMargin +
            AppSizes.panelGapAboveNav;

        return Stack(
          children: [
            Positioned.fill(
              child: _Backdrop(opacity: _fade.value, onTap: widget.onClose),
            ),
            Positioned(
              left: AppSizes.navHorizontalMargin,
              right: AppSizes.navHorizontalMargin,
              bottom: bottom,
              // Pembungkus gulir: jaring pengaman agar isi panel tidak pernah
              // meluap pada layar pendek atau skala teks besar. Pada keadaan
              // normal isi lebih pendek dari ruang tersedia sehingga tidak
              // menggulir.
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  child: _Panel(onSelected: widget.onSelected),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Latar gelap berblur yang menutupi seluruh halaman.
class _Backdrop extends StatelessWidget {
  final double opacity;
  final VoidCallback onTap;

  const _Backdrop({required this.opacity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const layer = ColoredBox(color: AppColors.scrim);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: ClipRect(
          child: AppSizes.panelBlur <= 0
              ? layer
              : BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: AppSizes.panelBlur,
                    sigmaY: AppSizes.panelBlur,
                  ),
                  child: layer,
                ),
        ),
      ),
    );
  }
}

/// Panel melayang berisi judul dan enam ubin.
class _Panel extends StatelessWidget {
  final ValueChanged<AppNewItemKind> onSelected;

  const _Panel({required this.onSelected});

  static const List<_TileSpec> _tiles = [
    _TileSpec(
      kind: AppNewItemKind.task,
      label: AppStrings.newPanelTask,
      icon: AppIcons.checkCircle,
      category: TaskCategory.task,
    ),
    _TileSpec(
      kind: AppNewItemKind.event,
      label: AppStrings.newPanelEvent,
      icon: AppIcons.event,
      category: TaskCategory.event,
    ),
    _TileSpec(
      kind: AppNewItemKind.reminder,
      label: AppStrings.newPanelReminder,
      icon: AppIcons.bell,
      category: TaskCategory.reminder,
    ),
    _TileSpec(
      kind: AppNewItemKind.milestone,
      label: AppStrings.newPanelMilestone,
      icon: AppIcons.flag,
      category: TaskCategory.milestone,
    ),
    _TileSpec(
      kind: AppNewItemKind.note,
      label: AppStrings.newPanelNote,
      icon: AppIcons.notes,
      category: TaskCategory.note,
    ),
    _TileSpec(
      kind: AppNewItemKind.project,
      label: AppStrings.newPanelProject,
      icon: AppIcons.folder,
      category: TaskCategory.project,
      enabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.categoryColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.bottomPanel),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.newPanelTitle,
              style: AppTypography.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSizes.sectionGap),
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 3;
                final width = (constraints.maxWidth -
                        AppSizes.cardGap * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: AppSizes.cardGap,
                  runSpacing: AppSizes.cardGap,
                  children: [
                    for (final tile in _tiles)
                      SizedBox(
                        width: width,
                        child: _PanelTile(
                          label: tile.label,
                          icon: tile.icon,
                          background: colors.backgroundFor(tile.category),
                          foreground: colors.iconFor(tile.category),
                          enabled: tile.enabled,
                          onTap: tile.enabled
                              ? () => onSelected(tile.kind)
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu ubin: kotak ikon + nama. Ubin nonaktif tampil redup dan tidak bisa
/// diketuk.
class _PanelTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool enabled;
  final VoidCallback? onTap;

  const _PanelTile({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? label : '$label, ${AppStrings.comingSoon}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: AppSizes.panelTileIconBox,
              width: AppSizes.panelTileIconBox,
              decoration: BoxDecoration(
                color: enabled ? background : AppColors.borderSoft,
                borderRadius: BorderRadius.circular(AppRadius.iconBox),
              ),
              child: Icon(
                icon,
                color: enabled ? foreground : AppColors.textMuted,
                size: AppSizes.panelTileIcon,
              ),
            ),
            const SizedBox(height: AppSizes.itemSpacing),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.titleSmall?.copyWith(
                color: enabled ? null : AppColors.textMuted,
              ),
            ),
            if (!enabled)
              Text(
                AppStrings.comingSoon,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.labelMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _TileSpec {
  final AppNewItemKind kind;
  final String label;
  final IconData icon;
  final TaskCategory category;
  final bool enabled;

  const _TileSpec({
    required this.kind,
    required this.label,
    required this.icon,
    required this.category,
    this.enabled = true,
  });
}
