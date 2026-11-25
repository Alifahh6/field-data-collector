import 'package:flutter/material.dart';

/// Transisi halaman halus: fade + geser tipis dari kanan.
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
                    .animate(curved),
                child: child,
              ),
            );
          },
        );
}
