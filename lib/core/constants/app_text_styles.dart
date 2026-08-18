import 'package:flutter/material.dart';

/// Centralized text styles for the PostSA Flutter POS app.
///
/// Used across all feature screens and the app theme to keep typography
/// consistent. All styles are `const` so they can be used in `const`
/// widget trees (required by `analysis_options.yaml` rules
/// `prefer_const_constructors` & `prefer_const_literals_to_create_immutables`).
class AppTextStyles {
  AppTextStyles._();

  // ── Display ────────────────────────────────────────────────────────────
  /// Large numeric display (e.g. dashboard KPI values, loyalty points).
  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: _textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
    height: 1.25,
    letterSpacing: -0.25,
  );

  // ── Titles ─────────────────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _textPrimary,
    height: 1.35,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _textPrimary,
    height: 1.4,
  );

  // ── Body ───────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _textSecondary,
    height: 1.5,
  );

  // ── Caption / Overline ─────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: _textMuted,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: _textMuted,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ── Button ─────────────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // ── Internal color references (kept in sync with AppColors) ────────────
  // Inlined as constants so this file has no dependency on app_colors.dart
  // and can be used in `const` contexts.
  static const Color _textPrimary = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted = Color(0xFF64748B);
}
