import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/theme/category_theme.dart';

/// Kartu statistik Beranda: label, angka besar, dan grafik garis kecil
/// dekoratif.
class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final TaskCategory category;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.categoryColors;
    final background = colors.backgroundFor(category);
    final accent = colors.iconFor(category);

    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: accent,
                ),
              ),
              const SizedBox(height: AppSizes.itemSpacing),
              Text('$value', style: AppTypography.textTheme.displayLarge),
              const SizedBox(height: AppSizes.itemSpacing),
              SizedBox(
                height: AppSizes.statChartHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: StatSparklinePainter(color: accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grafik garis dekoratif (BUKAN data nyata) — hanya hiasan visual kartu.
///
/// TODO(F3): ganti dengan grafik tren berbasis data nyata bila diperlukan.
class StatSparklinePainter extends CustomPainter {
  final Color color;

  const StatSparklinePainter({required this.color});

  static const List<double> _points = [
    0.55, 0.35, 0.62, 0.30, 0.48, 0.72, 0.40, 0.85,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < _points.length; i++) {
      final dx = size.width * (i / (_points.length - 1));
      final dy = size.height * (1 - _points[i]);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    canvas.drawPath(path, paint);

    final dot = Paint()..color = color;
    final lastDx = size.width;
    final lastDy = size.height * (1 - _points.last);
    canvas.drawCircle(Offset(lastDx, lastDy), 3, dot);
  }

  @override
  bool shouldRepaint(StatSparklinePainter oldDelegate) =>
      oldDelegate.color != color;
}
