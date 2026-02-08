import 'package:flutter/material.dart';

abstract class EditorColors {
  static const primary = Color(0xFF000000);
  static const secondary = Color(0xFF0A0A0A);
  static const card = Color(0xFF111111);
  static const cardHover = Color(0xFF151515);

  static const borderSubtle = Color.fromRGBO(255, 255, 255, 0.08);
  static const borderDefault = Color.fromRGBO(255, 255, 255, 0.12);
  static const borderFocus = Color.fromRGBO(255, 255, 255, 0.30);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color.fromRGBO(255, 255, 255, 0.6);
  static const textTertiary = Color.fromRGBO(255, 255, 255, 0.4);

  static const accentPurple = Color(0xFFA78BFA);
  static const accentPurpleBg = Color.fromRGBO(139, 92, 246, 0.15);
  static const accentGreen = Color(0xFF86EFAC);
  static const accentGreenBg = Color.fromRGBO(34, 197, 94, 0.15);
  static const accentYellow = Color(0xFFFDE047);
  static const accentYellowBg = Color.fromRGBO(234, 179, 8, 0.15);
  static const accentBlue = Color(0xFF93C5FD);
  static const accentBlueBg = Color.fromRGBO(59, 130, 246, 0.15);
}

abstract class EditorTextStyles {
  static const _fontFamily = 'Inter';

  static const cardTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: EditorColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.7,
    color: EditorColors.textSecondary,
  );

  static const small = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: EditorColors.textSecondary,
  );

  static const label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1 * 13,
    color: EditorColors.textTertiary,
  );

  static const tiny = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: EditorColors.textTertiary,
  );
}

ThemeData editorTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: EditorColors.primary,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      surface: EditorColors.primary,
      primary: EditorColors.textPrimary,
    ),
    dividerColor: EditorColors.borderSubtle,
    iconTheme: const IconThemeData(
      color: EditorColors.textSecondary,
      size: 18,
    ),
  );
}
