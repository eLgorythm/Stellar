import 'package:nsd/nsd.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/services/log_service.dart';

class ConnectLogic {
  /// Mencari port layanan Wireless Debugging (_adb-tls-connect._tcp) via mDNS.
  static Future<Service?> discoverConnectionService() async {
    LogService().log("DART: Starting mDNS discovery for _adb-tls-connect._tcp");
    const String serviceType = '_adb-tls-connect._tcp';
    final discovery = await startDiscovery(serviceType);
    
    Service? foundService;
    final stopwatch = Stopwatch()..start();
    
    // Timeout 7 detik (Discovery koneksi terkadang lebih lambat dari pairing)
    while (stopwatch.elapsedMilliseconds < 7000) {
      if (discovery.services.isNotEmpty) {
        foundService = discovery.services.first;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    await stopDiscovery(discovery);
    return foundService;
  }

  /// Menjalankan alur koneksi lengkap: Discovery -> Rust TLS Connect.
  static Future<String> connect() async {
    final service = await discoverConnectionService();
    if (service == null) {
      throw "Connection service not found. Make sure Wireless Debugging is ON and paired.";
    }

    final String addr = "127.0.0.1:${service.port}";
    LogService().log("DART: Connecting to $addr...");
    
    // Memanggil fungsi Rust hasil generate bridge
    return await connectToDevice(addr: addr);
  }
}