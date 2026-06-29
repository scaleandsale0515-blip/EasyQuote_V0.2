import 'package:flutter/material.dart';

/// Colors pulled from the EasyQuote app icon (dark slab + electric blue)
/// and the original web blueprint, so the app and the icon feel consistent.
class AppColors {
  static const paper = Color(0xFFEDEAE2);
  static const paperDim = Color(0xFFE3DFD4);
  static const ink = Color(0xFF232220);
  static const inkSoft = Color(0xFF5B5750);
  static const slab = Color(0xFF0B0B0D);
  static const slab2 = Color(0xFF1A1A1D);
  static const blueprint = Color(0xFF2B5F75);
  static const blueprintDk = Color(0xFF1F4757);
  static const electricBlue = Color(0xFF3DA9FF);
  static const rebar = Color(0xFFC2702C);
  static const ok = Color(0xFF4C7A52);
  static const danger = Color(0xFFA4432E);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFD8D3C8);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.electricBlue,
      primary: AppColors.blueprint,
      secondary: AppColors.rebar,
      surface: AppColors.card,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.slab,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFCFBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blueprint,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
  );
}
