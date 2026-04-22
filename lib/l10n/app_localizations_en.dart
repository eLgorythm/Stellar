// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get wishCounter => 'Wish Counter';

  @override
  String get importExport => 'Import/Export';

  @override
  String get visionTest => 'What\'s your Vision?';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get about => 'About';

  @override
  String get loading => 'Loading...';

  @override
  String get question => 'QUESTION';

  @override
  String get resultVision => 'Your Vision is';

  @override
  String get retryTest => 'RETRY TEST';

  @override
  String get importExportHistory => 'Import/Export History';

  @override
  String get importExportDesc =>
      'Select an exported JSON file (UIGF v3.0, v4.2, or SRGF v1.0) to merge with Stellar local data.';

  @override
  String get uidOptional => 'Player UID (Optional)';

  @override
  String get uidHint =>
      'Please enter UID for compatibility with other apps, or leave blank if not needed.';

  @override
  String get selectJson => 'SELECT JSON FILE';

  @override
  String get exportJson => 'EXPORT TO JSON';

  @override
  String successImport(int count) {
    return 'Success! Imported $count new entries.';
  }

  @override
  String get processing => 'PROCESSING...';

  @override
  String get preparing => 'PREPARING...';

  @override
  String get successExport => 'Success! Export file has been saved.';

  @override
  String get duplicationNote =>
      'Existing data will not be duplicated based on internal ID.';
}
