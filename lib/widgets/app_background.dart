import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fondo con degradado suave, usado como base de todas las pantallas
/// para dar una sensación alegre y consistente.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.backgroundGradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }
}
