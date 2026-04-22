// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get home => 'ホーム';

  @override
  String get wishCounter => 'ガチャ履歴';

  @override
  String get importExport => 'インポート/エクスポート';

  @override
  String get visionTest => 'あなたの神の目は？';

  @override
  String get tutorial => 'チュートリアル';

  @override
  String get about => 'について';

  @override
  String get loading => '読み込み中...';

  @override
  String get question => '質問';

  @override
  String get resultVision => 'あなたの神の目は';

  @override
  String get retryTest => '再テスト';

  @override
  String get importExportHistory => 'インポート/エクスポート履歴';

  @override
  String get importExportDesc =>
      'エクスポートされたJSONファイル（UIGF v3.0、v4.2、またはSRGF v1.0）を選択して、Stellarのローカルデータとマージします。';

  @override
  String get uidOptional => 'プレイヤーUID（オプション）';

  @override
  String get uidHint => '他のアプリとの互換性のためにUIDを入力してください。不要な場合は空白のままにしてください。';

  @override
  String get selectJson => 'JSONファイルを選択';

  @override
  String get exportJson => 'JSONにエクスポート';

  @override
  String successImport(int count) {
    return '成功！ $count 件の新しいエントリをインポートしました。';
  }

  @override
  String get processing => '処理中...';

  @override
  String get preparing => '準備中...';

  @override
  String get successExport => '成功しました！エクスポートファイルが保存されました。';

  @override
  String get duplicationNote => '既存のデータは内部IDに基づいて重複除去されます。';
}
