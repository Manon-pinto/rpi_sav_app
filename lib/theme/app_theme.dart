import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  const seed = AppColors.primary;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    primary: seed,
    secondary: AppColors.accent,
    surface: AppColors.card,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.shell,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      toolbarHeight: 46,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 8,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
      iconTheme: IconThemeData(size: 22, color: AppColors.ink),
      actionsIconTheme: IconThemeData(size: 22, color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      secondaryLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.card,
      ),
      backgroundColor: AppColors.card,
      disabledColor: AppColors.line.withValues(alpha: 0.45),
      selectedColor: seed,
      checkmarkColor: AppColors.card,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: seed, width: 1.4),
      ),
    ),
    dividerColor: AppColors.line,
  );
}
