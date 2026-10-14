import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';

class AppGradients {
  const AppGradients._();

  static const LinearGradient page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment(0, -0.2),
    colors: [AppColors.pageBackgroundStart, AppColors.pageBackgroundEnd],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment(-0.574, -0.819),
    end: Alignment(0.574, 0.819),
    colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
  );
}
