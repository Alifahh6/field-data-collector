import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/page_route.dart';
import 'akun_screen.dart';
import 'beranda_screen.dart';
import 'ekspor_screen.dart';
import 'lock_screen.dart';
import 'riwayat_screen.dart';

/// Kerangka utama: Bottom Navigation Bar (Beranda, Riwayat, Ekspor, Akun).
/// Juga mengunci ulang aplikasi bila ditinggalkan > 60 detik (jika kunci aktif).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  DateTime? _dijeda;
  bool _kunciTerbuka = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _dijeda = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final s = context.read<SettingsProvider>();
      final lama = _dijeda == null ? Duration.zero : DateTime.now().difference(_dijeda!);
      if (s.kunciAktif && !_kunciTerbuka && lama > const Duration(seconds: 60)) {
        _kunciTerbuka = true;
        Navigator.of(context)
            .push(AppRoute(page: LockScreen(onUnlocked: (ctx) => Navigator.of(ctx).pop())))
            .then((_) => _kunciTerbuka = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final halaman = <Widget>[
      BerandaScreen(onLihatRiwayat: () => setState(() => _index = 1)),
      const RiwayatScreen(),
      const EksporScreen(),
      const AkunScreen(),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_index), child: halaman[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.ios_share_outlined), selectedIcon: Icon(Icons.ios_share_rounded), label: 'Ekspor'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Akun'),
        ],
      ),
    );
  }
}
