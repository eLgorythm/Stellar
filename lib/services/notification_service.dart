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
        const AndroidNotificationAction(
          'enter_code',
          'Pair Now',
          inputs: [AndroidNotificationActionInput(label: '6-digit pairing code')],
        ),
      ],
    );

    await _plugin.show(
      1, // Menggunakan ID 1 agar menimpa notifikasi Searching
      'Ready to Pair',
      'Enter the code from system settings.',
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

    await _plugin.show(
      1, // Menggunakan ID 1 agar menimpa notifikasi Connecting/Input
      'Success',
      'Device paired successfully.',
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