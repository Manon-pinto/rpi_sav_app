import 'package:flutter/material.dart';

/// Palette fidèle au logo RPI Menuiserie : noir/anthracite + point orange,
/// sur fond blanc/gris très clair (voir charte/RPI LOGO base line noir.png).
class AppColors {
  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFE2E2E2);
  static const Color shell = Color(0xFFF7F7F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFF6A623);
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFC58B1B);
  static const Color danger = Color(0xFFB2503A);

  static Color colorFromHex(
    String hex, {
    Color fallback = const Color(0xFF8A99A8),
  }) {
    final sanitized = hex.trim().replaceFirst('#', '');
    if (sanitized.length != 6) return fallback;
    final value = int.tryParse(sanitized, radix: 16);
    if (value == null) return fallback;
    return Color(value + 0xFF000000);
  }

  static Color statusColor(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return muted;
    if (normalized.contains('fait') || normalized.contains('termin')) {
      return success;
    }
    if (normalized.contains('partiel') || normalized.contains('multi')) {
      return accent;
    }
    if (normalized.contains('programme') || normalized.contains('programmé')) {
      return primary;
    }
    if (normalized.contains('cours') || normalized.contains('pose')) {
      return success;
    }
    if (normalized.contains('transport')) return primary;
    if (normalized.contains('prépa') || normalized.contains('plan')) {
      return warning;
    }
    if (normalized.contains('bloq') ||
        normalized.contains('retard') ||
        normalized.contains('erreur')) {
      return danger;
    }
    return muted;
  }

  static Color softStatusColor(String status) {
    return statusColor(status).withValues(alpha: 0.12);
  }
}
