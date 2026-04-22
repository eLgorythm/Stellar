// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get home => '主页';

  @override
  String get wishCounter => '抽卡记录';

  @override
  String get importExport => '导入/导出';

  @override
  String get visionTest => '你的神之眼是什么？';

  @override
  String get tutorial => '教程';

  @override
  String get about => '关于';

  @override
  String get loading => '加载中...';

  @override
  String get question => '问题';

  @override
  String get resultVision => '你的神之眼是';

  @override
  String get retryTest => '重新测试';

  @override
  String get importExportHistory => '导入/导出历史';

  @override
  String get importExportDesc =>
      '选择导出的JSON文件（UIGF v3.0, v4.2, 或 SRGF v1.0）以合并到Stellar本地数据。';

  @override
  String get uidOptional => '玩家UID（可选）';

  @override
  String get uidHint => '请输入UID以兼容其他应用，如果不需要则留空。';

  @override
  String get selectJson => '选择JSON文件';

  @override
  String get exportJson => '导出为JSON';

  @override
  String successImport(int count) {
    return '成功！导入了 $count 条新记录。';
  }

  @override
  String get processing => '处理中...';

  @override
  String get preparing => '准备中...';

  @override
  String get successExport => '成功！导出文件已保存。';

  @override
  String get duplicationNote => '现有数据将根据内部 ID 自动去重。';
}
