import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../screens/lock_screen.dart';
import '../screens/main_shell.dart';
import 'page_route.dart';

/// Menentukan layar tujuan setelah splash / onboarding.
class AppFlow {
  static void masuk(BuildContext context) {
    final s = context.read<SettingsProvider>();
    final Widget tujuan = s.kunciAktif
        ? LockScreen(
            onUnlocked: (ctx) =>
                Navigator.of(ctx).pushReplacement(AppRoute(page: const MainShell())),
          )
        : const MainShell();
    Navigator.of(context).pushReplacement(AppRoute(page: tujuan));
  }
}
