import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Ancho máximo del "marco" de la app en pantallas grandes (por si en
/// el futuro también se publica una versión web, como con Tablas de
/// Multiplicar). En un celular real no tiene ningún efecto.
const double _kMaxAppWidth = 480;

/// Widget raíz de la aplicación.
class MultiplicacionesColumnaApp extends StatelessWidget {
  const MultiplicacionesColumnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplicaciones en Columna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
      builder: (BuildContext context, Widget? child) {
        return ColoredBox(
          color: AppColors.textDark,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxAppWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
