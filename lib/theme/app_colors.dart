import 'package:flutter/material.dart';

/// Paleta de colores alegres y de alto contraste, pensada para niños.
/// Misma paleta que la app "Tablas de Multiplicar", para mantener la
/// identidad visual entre las dos apps.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF3A7BFF);
  static const Color primaryBlueDark = Color(0xFF1E56D6);
  static const Color sunYellow = Color(0xFFFFC93C);
  static const Color leafGreen = Color(0xFF3ECF6E);
  static const Color leafGreenDark = Color(0xFF1F9E4E);
  static const Color candyPink = Color(0xFFFF5C8A);
  static const Color skyBackground = Color(0xFFEFF6FF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1B2340);
  static const Color textMuted = Color(0xFF5C6788);
  static const Color errorRed = Color(0xFFE8484E);
  static const Color trophyGold = Color(0xFFFFB100);
  static const Color violetPurple = Color(0xFF8B5CF6);
  static const Color emberOrange = Color(0xFFFF7A33);

  static const List<Color> backgroundGradient = <Color>[
    Color(0xFFEFF6FF),
    Color(0xFFE3F3FF),
  ];
}
