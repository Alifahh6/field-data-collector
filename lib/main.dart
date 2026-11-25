import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/kunjungan_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/tugas_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settings = SettingsProvider();
  await settings.muat();
  final kunjungan = KunjunganProvider();
  await kunjungan.muat();
  final tugas = TugasProvider();
  await tugas.muat();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<KunjunganProvider>.value(value: kunjungan),
        ChangeNotifierProvider<TugasProvider>.value(value: tugas),
        ChangeNotifierProvider<SyncProvider>(create: (_) => SyncProvider()),
      ],
      child: const FieldDataCollectorApp(),
    ),
  );
}

class FieldDataCollectorApp extends StatelessWidget {
  const FieldDataCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: AppInfo.namaAplikasi,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
