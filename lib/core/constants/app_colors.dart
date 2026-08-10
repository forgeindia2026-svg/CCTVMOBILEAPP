import 'package:flutter/material.dart';

class AppColors {
  // SK Technology Primary Brand Colors
  static const Color primaryRed = Color(0xFFD91F3D);       // SK Crimson Red
  static const Color primaryRedDark = Color(0xFFB5142E);   // Deep Red
  static const Color primaryRedLight = Color(0xFFFFF0F2);  // Soft Pink Tint
  static const Color primaryRedDarkTint = Color(0xFF2C1016); // Dark Pink Tint
  static const Color accentRed = Color(0xFFFF2B4A);       // Vibrant Red

  // Status Colors
  static const Color statusGreen = Color(0xFF10B981);     // Active / Delivered
  static const Color statusAmber = Color(0xFFF59E0B);     // Warning / Pending
  static const Color statusBlue = Color(0xFF3B82F6);      // Info / Shipped

  // Background & Surfaces (Light Theme matching Image 1)
  static const Color bgLight = Color(0xFFF8FAFC);         // Soft Crisp White Canvas
  static const Color surfaceWhite = Color(0xFFFFFFFF);     // Pure White Card Background
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Light Gray Input Fill
  static const Color borderLight = Color(0xFFE2E8F0);     // Light Gray Border

  // Background & Surfaces (Dark Theme)
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF161F33);
  static const Color surfaceDarkSecondary = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF26334D);

  // Text Colors (Light Mode)
  static const Color textPrimary = Color(0xFF0F172A);     // Dark Slate
  static const Color textSecondary = Color(0xFF64748B);   // Slate Gray
  static const Color textMuted = Color(0xFF94A3B8);       // Light Gray

  // Text Colors (Dark Mode)
  static const Color textDarkPrimary = Color(0xFFF8FAFC);
  static const Color textDarkSecondary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFFF2B4A), Color(0xFFD91F3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
