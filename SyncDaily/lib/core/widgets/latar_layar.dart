import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_gradients.dart';

class LayarLatar extends StatelessWidget {
  final Widget child;

  const LayarLatar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.page),
      child: child,
    );
  }
}
