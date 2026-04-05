import 'package:nsd/nsd.dart';
import 'package:stellar/native/api/api.dart';
import 'dart:async';

class ConnectLogic {
  /// Mencari port layanan Wireless Debugging (_adb-tls-connect._tcp) via mDNS.
  static Future<Service?> discoverConnectionService() async {
    final completer = Completer<Service?>();
    final discovery = await startDiscovery('_adb-tls-connect._tcp');

    void listener() {
      if (discovery.services.isNotEmpty && !completer.isCompleted) {
        final service = discovery.services.first;
        completer.complete(service);
      }
    }

    discovery.addListener(listener);

    if (discovery.services.isNotEmpty) {
      completer.complete(discovery.services.first);
    }

    try {
      // Timeout 10 detik untuk koneksi
      return await completer.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      return null;
    } finally {
      discovery.removeListener(listener);
      await stopDiscovery(discovery);
    }
  }

  /// Menjalankan alur koneksi lengkap: Discovery -> Rust TLS Connect.
  static Future<String> connect(String storageDir) async {
    final service = await discoverConnectionService();
    if (service == null) {
      throw "Connection service not found. Make sure Wireless Debugging is enable and paired.";
    }

    final String addr = "127.0.0.1:${service.port}";
    
    // Memanggil fungsi Rust hasil generate bridge
    return await connectToDevice(addr: addr, storageDir: storageDir);
  }
}