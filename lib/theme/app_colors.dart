import 'package:flutter/material.dart';
import 'package:peakform_ai/services/theme_service.dart';

abstract final class AppColors {
  static bool get _dark => ThemeService.instance.isDark.value;

  static Color get background =>
      _dark ? const Color(0xFF0B0E11) : const Color(0xFFF4F6FA);

  static Color get card =>
      _dark ? const Color(0xFF141820) : const Color(0xFFFFFFFF);

  static Color get cardBorder =>
      _dark ? const Color(0x0FFFFFFF) : const Color(0x1A111827);

  static const accent = Color(0xFF5D5FEF);

  static Color get accentLight =>
      _dark ? const Color(0xFFA5A7F9) : const Color(0xFF3F42C7);

  static Color get green =>
      _dark ? const Color(0xFF00F5A0) : const Color(0xFF047857);

  static Color get yellow =>
      _dark ? const Color(0xFFFFD600) : const Color(0xFFB45309);

  static Color get textPrimary =>
      _dark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);

  static Color get textSecondary =>
      _dark ? const Color(0xFF8B95A5) : const Color(0xFF4B5563);

  static Color get textTertiary =>
      _dark ? const Color(0xFFC4CAD4) : const Color(0xFF374151);

  static Color get barTrack =>
      _dark ? const Color(0xFF1E2433) : const Color(0xFFE5E7EB);

  static Color get navInactive =>
      _dark ? const Color(0xFF555555) : const Color(0xFF6B7280);

  static Color get nextGameStart =>
      _dark ? const Color(0xFF1A1F3A) : const Color(0xFFE8EAF8);

  static Color get nextGameEnd =>
      _dark ? const Color(0xFF12182B) : const Color(0xFFDDE1F5);

  static Color get navBar =>
      _dark ? const Color(0xF20B0E11) : const Color(0xF2FFFFFF);

  static Color get divider =>
      _dark ? const Color(0x0FFFFFFF) : const Color(0x1A111827);
}
