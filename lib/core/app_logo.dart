import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_provider.dart';

class AppLogo extends ConsumerWidget {
  final double size;
  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoPath = ref.watch(logoPathProvider);
    if (logoPath != null && logoPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(logoPath),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/logo.png', width: size, height: size),
        ),
      );
    }
    return Image.asset('assets/logo.png', width: size, height: size);
  }
}
