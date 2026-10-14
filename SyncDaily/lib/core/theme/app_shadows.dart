import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> nav = [
    BoxShadow(
      color: Color(0x293C288C),
      offset: Offset(0, 8),
      blurRadius: 30,
    ),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0xFFFFFFFF),
      blurRadius: 5,
    ),
    BoxShadow(
      color: Color(0x736C47FF),
      offset: Offset(0, 10),
      blurRadius: 24,
    ),
  ];
}
