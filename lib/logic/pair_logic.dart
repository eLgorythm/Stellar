import 'package:stellar/native/api/api.dart';
import 'package:nsd/nsd.dart';
import 'dart:async';

class PairLogic {
  // Simpan port secara static agar bisa diakses oleh background task
  static int? activePort;

  static Future<String> pair(int port, String pairingCode, String storageDir) async {
    return await initPairing(
      port: port,
      pairingCode: pairingCode,
      storageDir: storageDir,
    );
  }

  static Future<Service?> discoverPairingService() async {
    final discovery = await startDiscovery('_adb-tls-pairing._tcp');
    final completer = Completer<Service>();

    void listener() {
      if (discovery.services.isNotEmpty && !completer.isCompleted) {
        final service = discovery.services.first;
        activePort = service.port;
        completer.complete(service);
      }
    }

    discovery.addListener(listener);

    // Check if a service was already found during the startDiscovery call
    if (discovery.services.isNotEmpty) {
      activePort = discovery.services.first.port;
      completer.complete(discovery.services.first);
    }

    try {
      return await completer.future.timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception("Pairing service not found. Make sure Wireless Debugging enable.");
    } finally {
      discovery.removeListener(listener);
      await stopDiscovery(discovery);
    }
  }
}