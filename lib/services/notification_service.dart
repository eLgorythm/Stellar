import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler top-level untuk memproses input notifikasi di latar belakang.
/// Harus berada di luar class atau static dengan @pragma('vm:entry-point').
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  debugPrint("DART BG: lookup isolate...");
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(NotificationService.isolateName);

  debugPrint("DART BG: payload = ${details.payload}");
  debugPrint("DART BG: input = ${details.input}");
  debugPrint("DART BG: sendPort = $sendPort");

  // Hapus notifikasi input (ID 0) segera setelah tombol ditekan
  if (details.actionId == 'enter_code') {
    FlutterLocalNotificationsPlugin().cancel(1);
  }

  if (sendPort != null && details.actionId == 'enter_code' && details.input != null) {
    debugPrint("DART: Background Isolate sends data to Main Isolate...");
    sendPort.send({
      'pin': details.input,
      'port': int.tryParse(details.payload ?? ''),
    });
  } else {
    debugPrint("DART ERROR: Failed to send data. SendPort not found.");
  }
}

class NotificationService {
  static const String isolateName = 'stellar_pairing_port';
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static final ReceivePort _receivePort = ReceivePort();
  /// Inisialisasi plugin notifikasi dan jalur komunikasi antar Isolate.
  static Future<void> init({
    required Function(String code, int? port) onPairingReceived,
    required DidReceiveNotificationResponseCallback onDidReceiveNotificationResponse,
  }) async {
    // 1. Setup Isolate Communication
    IsolateNameServer.removePortNameMapping(isolateName);
    final bool success = IsolateNameServer.registerPortWithName(_receivePort.sendPort, isolateName);
    if (!success) {
      debugPrint("DART ERROR: Failed to register IsolateNameServer port: $isolateName");
    }

    _receivePort.listen((message) {
      if (message is Map) {
        onPairingReceived(message['pin'], message['port']);
      }
    });

    // 2. Setup Android Settings
    const androidInit = AndroidInitializationSettings('notification_icon');
    
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Map<String, dynamic>? _cache;

  /// Mendapatkan teks terjemahan dari file JSON di assets.
  static Future<String> _t(String key) async {
    if (_cache == null) {
      String code = PlatformDispatcher.instance.locale.languageCode;
      
      // Fallback: id menggunakan en, bahasa lain yang tidak didukung juga ke en.
      if (code == 'id' || !['ja', 'zh'].contains(code)) {
        code = 'en';
      }

      try {
        final jsonString = await rootBundle.loadString('assets/notification/$code.json');
        _cache = json.decode(jsonString);
      } catch (e) {
        debugPrint("DART ERROR: Gagal memuat notification assets: $e");
        // Mengembalikan string kosong atau default jika gagal memuat
        return ""; 
      }
    }
    // Mengembalikan string kosong jika key tidak ditemukan
    return _cache?[key] ?? ""; 
  }

  /// Menampilkan notifikasi panduan awal (Ongoing).
  static Future<void> showGuide() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1',
      'Pairing Alerts',
      channelDescription: 'Wireless ADB pairing process status',
      importance: Importance.max, // Tetap popup tapi tanpa suara
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      category: AndroidNotificationCategory.reminder,
      ongoing: true,
    );

    final title = await _t('guide_title');
    final body = await _t('guide_body');

    await _plugin.show(
      1, // ID notifikasi
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi input kode setelah port ditemukan.
  static Future<void> showPairingInput(int port) async {
    final actionLabel = await _t('pairing_action_label');
    final inputLabel = await _t('pairing_input_label');

    final androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1', 
      'Pairing Alerts',
      channelDescription: 'Wireless ADB pairing process status',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      autoCancel: true, // Notifikasi hilang jika di-tap body-nya
      ticker: 'Stellar Pairing',
      onlyAlertOnce: false, // Pastikan selalu alert meskipun ID sama
      showWhen: false,
      category: AndroidNotificationCategory.status,
      ongoing: false, // Ubah menjadi false agar bisa di-swipe
      actions: [
        AndroidNotificationAction(
          'enter_code',
          actionLabel,
          inputs: [AndroidNotificationActionInput(label: inputLabel)],
        ),
      ],
    );

    final title = await _t('pairing_ready_title');
    final body = await _t('pairing_input_body');

    await _plugin.show(
      1, // Menggunakan ID 1 agar menimpa notifikasi Searching
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: port.toString(),
    );
  }

  /// Menampilkan notifikasi sukses pairing yang bisa di-swipe.
  static Future<void> showSuccess() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1',
      'Pairing Alerts',
      channelDescription: 'Wireless ADB pairing process status',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      ticker: 'Stellar Success',
      onlyAlertOnce: false,
      showWhen: false,
      category: AndroidNotificationCategory.status,
      ongoing: false, // Bisa di-swipe oleh user
    );

    final title = await _t('success_title');
    final body = await _t('success_body');

    await _plugin.show(
      1, // ID notifikasi
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi status "Scanning Gacha Link...".
  static Future<void> showScanningGachaLink() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1',
      'Pairing Alerts',
      channelDescription: 'General application status',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      ticker: 'Stellar Status',
      onlyAlertOnce: false,
      showWhen: true,
      category: AndroidNotificationCategory.status,
    );

    final title = await _t('scanning_gacha_link_title');
    final body = await _t('scanning_gacha_link_body');

    await _plugin.show(
      2, // ID notifikasi unik untuk scanning
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi status "Link Retrieved!".
  static Future<void> showLinkRetrieved() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1',
      'Pairing Alerts',
      channelDescription: 'General application status',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      ticker: 'Stellar Status',
      onlyAlertOnce: false,
      showWhen: true,
      category: AndroidNotificationCategory.status,
    );

    final title = await _t('link_retrieved_title');
    final body = await _t('link_retrieved_body');

    await _plugin.show(
      3, // ID notifikasi unik untuk link retrieved
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi status "Connecting...".
  static Future<void> showConnecting() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1',
      'Pairing Alerts',
      channelDescription: 'General application status',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      ticker: 'Stellar Status',
      onlyAlertOnce: false,
      showWhen: true,
      category: AndroidNotificationCategory.status,
    );

    final title = await _t('connecting_title');
    final body = await _t('connecting_body');

    await _plugin.show(
      2, // ID notifikasi unik untuk connecting (bisa menimpa scanning jika perlu)
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi status "Connected".
  static Future<void> showConnected() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1',
      'Pairing Alerts',
      channelDescription: 'General application status',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      ticker: 'Stellar Status',
      onlyAlertOnce: false,
      showWhen: true,
      category: AndroidNotificationCategory.status,
    );

    final title = await _t('connected_title');
    final body = await _t('connected_body');

    await _plugin.show(
      3, // ID notifikasi unik untuk connected (bisa menimpa link retrieved jika perlu)
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi status umum (Connecting/Scanning).
  static Future<void> showStatus(String title, String body, {int id = 1}) async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_silent_v1',
      'Pairing Alerts',
      channelDescription: 'General application status',
      importance: Importance.max, // Memastikan popup muncul di atas game
      priority: Priority.max,
      playSound: false,
      enableVibration: false,
      autoCancel: true,
      ticker: 'Stellar Status',
      onlyAlertOnce: false, // Sangat penting agar update status (Scanning -> Retrieved) tetap popup
      showWhen: true,
      category: AndroidNotificationCategory.status,
    );

    await _plugin.show(
      id, 
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menghapus notifikasi berdasarkan ID.
  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      // Menghindari crash "Missing type parameter" yang merupakan bug 
      // platform-side serialization pada plugin di beberapa perangkat Android.
      debugPrint("DART: Gagal menghapus notifikasi ID $id: $e");
    }
  }

  /// Menghapus semua notifikasi yang ada.
  static Future<void> cancelAll() async {
    // Kita tidak menggunakan _plugin.cancelAll() secara langsung karena sering 
    // memicu RuntimeException pada daftar scheduled notifications yang kosong/korup.
    // Menggunakan Future.wait agar proses pembatalan berjalan paralel (lebih cepat).
    await Future.wait([0, 1, 2, 3, 4].map((id) => cancel(id)).toList());
  }

  /// Membersihkan resource saat aplikasi ditutup.
  static void dispose() {
    IsolateNameServer.removePortNameMapping(isolateName);
    _receivePort.close();
  }
}