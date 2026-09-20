import 'package:flutter/material.dart';

/// Brand palette used across the app (matches the CRM mobile look).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF165BAB);
  static const Color primaryDark = Color(0xFF0E3D78);
  static const Color accent = Color(0xFF1E88E5);
  static const Color success = Color(0xFF2E9E5B);
  static const Color danger = Color(0xFFD64545);
  static const Color warning = Color(0xFFE8890C);
  static const Color info = Color(0xFF1E7BB5);

  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);

  static const Color surfaceLight = Color(0xFFF5F6F8);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFECEDEF);

  static const Color starGold = Color(0xFFF5A623);

  // Lead / record status colors (Cold/Warm/Hot/Inactive).
  static const Color cold = Color(0xFF1E7BB5);
  static const Color warm = Color(0xFFE8890C);
  static const Color hot = Color(0xFFD64545);
  static const Color inactive = Color(0xFF9AA0A6);
  static const Color planned = Color(0xFF1E7BB5);
  static const Color held = Color(0xFF2E9E5B);
  static const Color notHeld = Color(0xFFD64545);
}
