import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_gradients.dart';

class LayarLatar extends StatelessWidget {
  final Widget child;

  const LayarLatar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Selalu mengisi ruang yang tersedia. Tanpa ini `Container` hanya setinggi
    // anaknya, sehingga saat isi halaman lebih pendek dari layar (mis. daftar
    // kosong) ada area yang tidak dilukis apa pun; karena Scaffold bertema
    // transparan, area itu tampak hitam.
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: const BoxDecoration(gradient: AppGradients.page),
      child: child,
    );
  }
}
