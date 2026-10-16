import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF6C47FF);
  static const primaryDark = Color(0xFF5B3FD6);
  static const primaryGradientStart = Color(0xFF8E70FF);
  static const primaryGradientEnd = Color(0xFF5B3FD6);

  // Text
  static const ink = Color(0xFF141318);
  static const textSecondary = Color(0xFF4A475E);
  static const textMuted = Color(0xFF6B6880);

  // Borders
  static const border = Color(0xFFE6E3F5);
  static const borderSoft = Color(0xFFECE9F7);

  // Surfaces
  static const surface = Color(0xFFFFFFFF);
  static const pageBackgroundStart = Color(0xFFEEEBFF);
  static const pageBackgroundEnd = Color(0xFFFFFFFF);

  // Nav
  static const navActiveBg = Color(0xFFF0ECFF);
  static const unreadBg = Color(0xFFF3F0FF);
  static const unreadBorder = Color(0xFFE0D9FF);

  // Lapisan panel "Buat Baru" (tombol + navigasi bawah).
  //
  // TODO(design): warna lapisan gelap panel belum dirinci di DESIGN.md;
  // sementara memakai warna ink dengan kepekatan 40% agar tetap sewarna teks
  // utama dan tombol hitam.
  static const scrim = Color(0x66141318);

  // Category colors
  static const taskBg = Color(0xFFE7E1FF);
  static const taskIcon = Color(0xFF5B3FD6);
  static const reminderBg = Color(0xFFFFE6D6);
  static const reminderIcon = Color(0xFFA64515);
  static const eventBg = Color(0xFFD9EEFB);
  static const eventIcon = Color(0xFF17608F);
  static const milestoneBg = Color(0xFFDDF3E6);
  static const milestoneIcon = Color(0xFF1B6E43);
  static const noteBg = Color(0xFFFFE0EC);
  static const noteIcon = Color(0xFFA32E5F);
  static const projectBg = Color(0xFFFFF1C9);
  static const projectIcon = Color(0xFF7E5C00);
  static const deadlineBg = Color(0xFFFFE0E6);
  static const deadlineIcon = Color(0xFFB3263E);

  // Palet avatar inisial (latar / teks), memakai warna kategori.
  static const avatarPalette = <AvatarColor>[
    AvatarColor(background: taskBg, foreground: taskIcon),
    AvatarColor(background: reminderBg, foreground: reminderIcon),
    AvatarColor(background: eventBg, foreground: eventIcon),
    AvatarColor(background: milestoneBg, foreground: milestoneIcon),
    AvatarColor(background: noteBg, foreground: noteIcon),
    AvatarColor(background: projectBg, foreground: projectIcon),
    AvatarColor(background: deadlineBg, foreground: deadlineIcon),
  ];
}

class AvatarColor {
  final Color background;
  final Color foreground;

  const AvatarColor({required this.background, required this.foreground});
}
