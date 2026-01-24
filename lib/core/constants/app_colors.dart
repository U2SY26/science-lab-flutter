import 'package:flutter/material.dart';

/// 3DWeb Science Lab 색상 팔레트
/// globals.css :root 변수에서 포팅
class AppColors {
  AppColors._();

  // 배경색
  static const Color bg = Color(0xFF0A0A0F);
  static const Color bgSoft = Color(0xFF0D0D14);

  // 텍스트 색상
  static const Color ink = Color(0xFFE0F4FF);
  static const Color muted = Color(0xFF5A8A9A);

  // 강조 색상
  static const Color accent = Color(0xFF00D4FF);
  static const Color accent2 = Color(0xFFFF6B35);

  // 카드 색상
  static const Color card = Color(0xFF0A141E);
  static const Color cardBorder = Color(0x4D00D4FF); // rgba(0, 212, 255, 0.3)

  // 그리드 색상
  static const Color grid = Color(0x1400D4FF); // rgba(0, 212, 255, 0.08)

  // 시뮬레이션 색상
  static const Color simBg = Color(0xFF0D1A20);
  static const Color simGrid = Color(0xFF1A3040);
  static const Color pivot = Color(0xFF52626F);
  static const Color rod = Color(0xFF8CA0AB);
  static const Color trailColor = Color(0xFFF76C3C);

  // 그라데이션
  static const List<Color> bobGradient = [
    Color(0xFF5AA3B3),
    Color(0xFF2B6F7D),
  ];
}
