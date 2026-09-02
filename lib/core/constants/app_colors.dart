import 'package:flutter/material.dart';

class AppColors {
  // Warm Botanical Palette (Light Mode)
  static const Color primary = Color(0xFF7A967E); // Sage Green
  static const Color primaryLight = Color(0xFF8DAA91);
  static const Color primaryDark = Color(0xFF5F7A63);
  static const Color secondary = Color(0xFFE6BAA3); // Warm Peach
  static const Color secondaryLight = Color(0xFFFAF0EB);
  static const Color accent = Color(0xFF7A967E);
  static const Color accentLight = Color(0xFFEAF1EB);
  static const Color surfaceSoft = Color(0xFFF1ECE6);

  // Status & Highlights
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color discountRed = Color(0xFFDC2626);
  static const Color discountRedLight = Color(0xFFFEF2F2);
  static const Color successGreen = Color(0xFF5F7A63);
  static const Color successGreenLight = Color(0xFFEAF1EB);

  // Neutral Light Theme
  static const Color backgroundLight = Color(0xFFFCF9F5); // Warm cream
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF2D312E);
  static const Color textSecondaryLight = Color(0xFF727871);
  static const Color borderLight = Color(0xFFEAE3DB);

  // Neutral Dark Theme
  static const Color backgroundDark = Color(0xFF1A1C1B);
  static const Color surfaceDark = Color(0xFF232624);
  static const Color cardDark = Color(0xFF232624);
  static const Color textPrimaryDark = Color(0xFFF1F2F1);
  static const Color textSecondaryDark = Color(0xFFA3A8A2);
  static const Color borderDark = Color(0xFF383D39);
  static const Color surfaceSoftDark = Color(0xFF2D312E);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7A967E), Color(0xFF5F7A63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient flashSaleGradient = LinearGradient(
    colors: [Color(0xFFE6BAA3), Color(0xFFC98A6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient botanicalGradient = LinearGradient(
    colors: [Color(0xFF7A967E), Color(0xFFE6BAA3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF232624), Color(0xFF1A1C1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
