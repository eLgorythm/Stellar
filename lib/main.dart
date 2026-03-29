import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stellar/logic/pair_logic.dart';
import 'package:stellar/logic/connect_logic.dart';
import 'package:stellar/native/frb_generated.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/services/notification_service.dart';
import 'package:stellar/services/log_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const StellarApp());
}

class StellarApp extends StatelessWidget {
  const StellarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  String _status = "";
  int? _activePort;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupServices();
  }

  void _setupServices() async {
    // Init Log Service (Mendengarkan Rust stream)
    LogService().init();
    
    // Hubungkan UI ke LogService agar scroll otomatis saat ada log baru
    LogService().addListener(_scrollToBottom);

    // Setup Notification & Isolate Bridge
    await NotificationService.init(
      onPairingReceived: (pin, port) {
        if (port != null) _activePort = port;
        _submitPairing(pin);
      },
      onDidReceiveNotificationResponse: _onNotificationInForeground,
    );
  }

  @override
  void dispose() {
    LogService().removeListener(_scrollToBottom);
    NotificationService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onNotificationInForeground(NotificationResponse details) {
    if (details.actionId == 'enter_code' && details.input != null) {
      _submitPairing(details.input!);
    }
  }

  Future<void> _handlePair() async {
    // 1. Request Izin Notifikasi (Android 13+)
    if (await Permission.notification.request().isDenied) {
      _showSnackBar("Izin notifikasi diperlukan untuk input kode.");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "Mencari layanan Wireless Debugging...";
    });

    // 2. Tampilkan notifikasi "Searching"
    NotificationService.showGuide();

    try {
      // 3. Cari Service Otomatis di latar belakang
      final service = await PairLogic.discoverPairingService();
      
      _activePort = service?.port;
      
      // 4. Update notifikasi menjadi "Found" dengan input field
      await NotificationService.cancel(1);
      if (_activePort != null) await NotificationService.showPairingInput(_activePort!);
      
      LogService().log("DART: Discovery selesai. Port $_activePort siap. Menunggu input user...");
    } catch (e) {
      _showSnackBar("Gagal: $e");
      await NotificationService.cancel(1);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitPairing(String code) async {
    if (_activePort == null) {
      print("DART ERROR: _activePort null saat _submitPairing dipanggil.");
      _showSnackBar("Error: Port hilang. Silakan coba PAIR lagi.");
      return;
    }
    
    LogService().log("DART: Memanggil Rust init_pairing(port: $_activePort, code: $code)");
    setState(() {
      _isLoading = true;
      _status = "Mengirim kode pairing ke port $_activePort...";
    });

    try {
      final result = await PairLogic.pair(_activePort!, code);
      setState(() => _status = result);
      _showSnackBar("Pairing Berhasil!");
      await NotificationService.cancel(0);
    } catch (e) {
      setState(() => _status = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect() async {
    setState(() {
      _isLoading = true;
      _status = "Mencoba menghubungkan...";
    });

    try {
      final result = await ConnectLogic.connect();
      setState(() => _status = result);
    } catch (e) {
      setState(() => _status = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLogConsole() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.terminal, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
            const Text("System Logs", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy_all_outlined, size: 20),
              onPressed: () {
                final allLogs = LogService().logs.join('\n');
                Clipboard.setData(ClipboardData(text: allLogs));
                _showSnackBar("Log disalin ke clipboard");
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              onPressed: () => LogService().clear(),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectionArea(
            child: ListenableBuilder(
              listenable: LogService(),
              builder: (context, _) {
                final logs = LogService().logs;
                return ListView.builder(
                  controller: _logScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        logs[index],
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stellar", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _showLogConsole, icon: const Icon(Icons.receipt_long_outlined)),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text(
                "Wireless ADB Pairing",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handlePair,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("PAIR"),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _handleConnect,
                    child: const Text("CONNECT"),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              if (_status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_status, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}