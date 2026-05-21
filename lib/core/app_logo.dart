import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/logo-dark.png' : 'assets/logo-light.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Image.asset('assets/logo.png', width: size, height: size),
    );
  }
}
