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
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  /// Menampilkan notifikasi panduan awal (Ongoing).
  static Future<void> showGuide() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_high_priority_channel',
      'Pairing Alerts',
      channelDescription: 'Status proses pairing Wireless ADB',
      importance: Importance.high, // Aktifkan popup
      priority: Priority.max,
      showWhen: false,
      category: AndroidNotificationCategory.reminder,
      ongoing: true,
    );

    await _plugin.show(
      1,
      'Searching...',
      'Please open Wireless Debugging settings.',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menampilkan notifikasi input kode setelah port ditemukan.
  static Future<void> showPairingInput(int port) async {
    final androidDetails = AndroidNotificationDetails(
      'stellar_high_priority_channel',
      'Pairing Alerts',
      channelDescription: 'Status proses pairing Wireless ADB',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.status,
      ongoing: true,
      actions: [
        const AndroidNotificationAction(
          'enter_code',
          'Pair Now',
          inputs: [AndroidNotificationActionInput(label: '6-digit pairing code')],
        ),
      ],
    );

    await _plugin.show(
      0,
      'Ready to Pair',
      'Enter the code from system settings.',
      NotificationDetails(android: androidDetails),
      payload: port.toString(),
    );
  }

  /// Menampilkan notifikasi sukses pairing yang bisa di-swipe.
  static Future<void> showSuccess() async {
    const androidDetails = AndroidNotificationDetails(
      'stellar_high_priority_channel',
      'Pairing Alerts',
      channelDescription: 'Status proses pairing Wireless ADB',
      importance: Importance.high,
      priority: Priority.max,
      showWhen: false,
      category: AndroidNotificationCategory.status,
      ongoing: false, // Bisa di-swipe oleh user
    );

    await _plugin.show(
      2, // ID berbeda agar tidak menimpa yang sedang berjalan jika ada
      'Success',
      'Device paired successfully.',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Menghapus notifikasi berdasarkan ID.
  static Future<void> cancel(int id) async => await _plugin.cancel(id);

  /// Menghapus semua notifikasi yang ada.
  static Future<void> cancelAll() async => await _plugin.cancelAll();

  /// Membersihkan resource saat aplikasi ditutup.
  static void dispose() {
    IsolateNameServer.removePortNameMapping(isolateName);
    _receivePort.close();
  }
}