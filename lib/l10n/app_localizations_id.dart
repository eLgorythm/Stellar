// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get wishCounter => 'Wish Counter';

  @override
  String get importExport => 'Import/Eksport';

  @override
  String get visionTest => 'What\'s your Vision?';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get about => 'About';

  @override
  String get loading => 'Loading...';

  @override
  String get question => 'PERTANYAAN';

  @override
  String get resultVision => 'Vision Kamu adalah';

  @override
  String get retryTest => 'ULANGI TES';

  @override
  String get importExportHistory => 'Impor/Ekspor History';

  @override
  String get importExportDesc =>
      'Pilih file JSON hasil export (UIGF v3.0, v4.2, atau SRGF v1.0) untuk digabungkan dengan data lokal Stellar.';

  @override
  String get uidOptional => 'UID Pemain (Opsional)';

  @override
  String get uidHint =>
      'Silakan isi UID untuk kompatibilitas dengan aplikasi lain, atau biarkan kosong jika tidak diperlukan.';

  @override
  String get selectJson => 'PILIH FILE JSON';

  @override
  String get exportJson => 'EKSPOR KE JSON';

  @override
  String successImport(int count) {
    return 'Success! Imported $count new entries.';
  }

  @override
  String get processing => 'MEMPROSES...';

  @override
  String get preparing => 'MENYIAPKAN...';

  @override
  String get successExport => 'Berhasil! File ekspor telah disimpan.';

  @override
  String get duplicationNote =>
      'Data yang sudah ada tidak akan terduplikasi berdasarkan ID internal.';
}
