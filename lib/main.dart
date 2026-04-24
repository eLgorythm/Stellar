import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/native/frb_generated.dart';
import 'package:stellar/screens/home.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stellar/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  
   // Gunakan external storage (Android/data/...) agar file JSON dapat diakses user secara manual
  final directory = await getExternalStorageDirectory();
  final storagePath = directory?.path ?? (await getApplicationSupportDirectory()).path;

  // Jalankan persiapan sertifikat di latar belakang (tanpa await agar boot tetap cepat)
  RustLib.instance.api.crateApiApiPreWarmAdb(storageDir: storagePath);

  // Set status bar transparan untuk tampilan lebih clean
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(StellarApp(storageDir: storagePath));
}

class StellarApp extends StatelessWidget {
  final String storageDir;
  const StellarApp({super.key, required this.storageDir});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        // Jika locale sistem tidak terdeteksi, gunakan bahasa pertama (English)
        if (locale == null) return supportedLocales.first;

        // Periksa apakah bahasa sistem didukung oleh aplikasi
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        // Jika tidak didukung (e.g. Perancis, Jerman), fallback ke English
        return supportedLocales.first;
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF9575CD), // Lavender base
          primary: const Color(0xFFD1C4E9),   // Light Lavender
          surface: const Color(0xFF1A1625),   // Dark Matte Background
          surfaceContainer: const Color(0xFF2D273F), // Matte Card color
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1625),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: HomePage(storageDir: storageDir),
    );
  }
}
