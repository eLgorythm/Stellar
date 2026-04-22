import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @wishCounter.
  ///
  /// In en, this message translates to:
  /// **'Wish Counter'**
  String get wishCounter;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import/Export'**
  String get importExport;

  /// No description provided for @visionTest.
  ///
  /// In en, this message translates to:
  /// **'What\'s your Vision?'**
  String get visionTest;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'QUESTION'**
  String get question;

  /// No description provided for @resultVision.
  ///
  /// In en, this message translates to:
  /// **'Your Vision is'**
  String get resultVision;

  /// No description provided for @retryTest.
  ///
  /// In en, this message translates to:
  /// **'RETRY TEST'**
  String get retryTest;

  /// No description provided for @importExportHistory.
  ///
  /// In en, this message translates to:
  /// **'Import/Export History'**
  String get importExportHistory;

  /// No description provided for @importExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Select an exported JSON file (UIGF v3.0, v4.2, or SRGF v1.0) to merge with Stellar local data.'**
  String get importExportDesc;

  /// No description provided for @uidOptional.
  ///
  /// In en, this message translates to:
  /// **'Player UID (Optional)'**
  String get uidOptional;

  /// No description provided for @uidHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter UID for compatibility with other apps, or leave blank if not needed.'**
  String get uidHint;

  /// No description provided for @selectJson.
  ///
  /// In en, this message translates to:
  /// **'SELECT JSON FILE'**
  String get selectJson;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'EXPORT TO JSON'**
  String get exportJson;

  /// No description provided for @successImport.
  ///
  /// In en, this message translates to:
  /// **'Success! Imported {count} new entries.'**
  String successImport(int count);

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING...'**
  String get processing;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'PREPARING...'**
  String get preparing;

  /// No description provided for @successExport.
  ///
  /// In en, this message translates to:
  /// **'Success! Export file has been saved.'**
  String get successExport;

  /// No description provided for @duplicationNote.
  ///
  /// In en, this message translates to:
  /// **'Existing data will not be duplicated based on internal ID.'**
  String get duplicationNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
