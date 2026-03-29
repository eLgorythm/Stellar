import 'dart:isolate';
import 'dart:ui';
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

  if (sendPort != null && details.actionId == 'enter_code' && details.input != null) {
    debugPrint("DART: Background Isolate mengirim data ke Main Isolate...");
    sendPort.send({
      'pin': details.input,
      'port': int.tryParse(details.payload ?? ''),
    });
  } else {
    debugPrint("DART ERROR: Gagal mengirim data. SendPort tidak ditemukan.");
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
      debugPrint("DART ERROR: Gagal mendaftarkan IsolateNameServer port: $isolateName");
    }

    _receivePort.listen((message) {
      if (message is Map) {
        onPairingReceived(message['pin'], message['port']);
      }
    });

    // 2. Setup Android Settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  /// Menampilkan notifikasi panduan awal (Ongoing).
  static Future<void> showGuide() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_guide_channel',
      'Petunjuk Pairing',
      channelDescription: 'Langkah-langkah untuk melakukan pairing Wireless ADB',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF673AB7),
      showWhen: false,
      category: AndroidNotificationCategory.reminder,
      ongoing: true,
    );

    await _plugin.show(
      1,
      'Mencari Layanan Pairing...',
      'Buka Developer Options > Wireless Debugging > Pair device with pairing code',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi input kode setelah port ditemukan.
  static Future<void> showPairingInput(int port) async {
    final androidDetails = AndroidNotificationDetails(
      'stellar_pairing_channel',
      'ADB Pairing Status',
      channelDescription: 'Notifikasi untuk input kode pairing Wireless ADB',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF673AB7),
      showWhen: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.status,
      ongoing: true,
      actions: [
        const AndroidNotificationAction(
          'enter_code',
          'INPUT KODE',
          inputs: [AndroidNotificationActionInput(label: '6-digit pairing code')],
        ),
      ],
    );

    await _plugin.show(
      0,
      'Layanan Ditemukan!',
      'Silakan masukkan kode pairing untuk melanjutkan.',
      NotificationDetails(android: androidDetails),
      payload: port.toString(),
    );
  }

  /// Menghapus notifikasi berdasarkan ID.
  static Future<void> cancel(int id) async => await _plugin.cancel(id);

  /// Membersihkan resource saat aplikasi ditutup.
  static void dispose() {
    IsolateNameServer.removePortNameMapping(isolateName);
    _receivePort.close();
  }
}