import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:stellar/logic/pair_logic.dart';
import 'package:stellar/logic/connect_logic.dart';
import 'package:stellar/native/frb_generated.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  
  // Dapatkan direktori internal secara dinamis
  final directory = await getApplicationSupportDirectory();

  // Set status bar transparan untuk tampilan lebih clean
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(StellarApp(storageDir: directory.path));
}

class StellarApp extends StatelessWidget {
  final String storageDir;
  const StellarApp({super.key, required this.storageDir});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF9575CD), // Lavender base
          primary: const Color(0xFFD1C4E9),   // Light Lavender
          surface: const Color(0xFF1A1625),   // Dark Matte Background
          surfaceContainer: const Color(0xFF2D273F), // Matte Card color
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1625),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: HomePage(storageDir: storageDir),
    );
  }
}

class HomePage extends StatefulWidget {
  final String storageDir;
  const HomePage({super.key, required this.storageDir});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isLoading = false;
  // State Proxy: Menggunakan satu objek untuk semua informasi status
  StellarStatus _currentStatus = const StellarStatus.idle();
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  int? _activePort;

  // Channel untuk memicu intent Android (tetap hardcoded appId karena ini konstanta sistem)
  static const platform = MethodChannel('labs.oxfnd.stellar/settings');

  @override
  void initState() {
    super.initState();
    _setupServices();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialStatus();
  }

  void _checkInitialStatus() {
    // Cek apakah sertifikat ada secara sinkron untuk menentukan status awal
    final certFile = File('${widget.storageDir}/adb_cert.pem');
    if (certFile.existsSync()) {
      setState(() => _currentStatus = const StellarStatus.paired());
    } else {
      setState(() => _currentStatus = const StellarStatus.idle());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    super.didChangeAppLifecycleState(state);
  }

  void _setupServices() async {
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
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.dispose();
    super.dispose();
  }

  void _onNotificationInForeground(NotificationResponse details) {
    if (details.actionId == 'enter_code' && details.input != null) {
      _submitPairing(details.input!);
    }
  }

  Future<void> _handlePair() async {
    // 1. Request Izin Notifikasi (Android 13+)
    if (await Permission.notification.request().isDenied) {
      _showSnackBar("Notification permission is required for code input.");
      return;
    }

    // Tampilkan notifikasi petunjuk (Searching) segera setelah tombol ditekan
    await NotificationService.showGuide();

    try {
      // Cari Service Otomatis
      final service = await PairLogic.discoverPairingService();
      
      _activePort = service?.port;
      
      // Update notifikasi menjadi "Found" dengan input field
      if (_activePort != null) await NotificationService.showPairingInput(_activePort!);
    } catch (e) {
      _showSnackBar("Gagal: $e");
    }
  }

  void _submitPairing(String code) async {
    if (_activePort == null) {
      print("DART ERROR: _activePort is null when _submitPairing is called.");
      _showSnackBar("Error: Port lost. Please try PAIR again.");
      return;
    }
    
    setState(() {
      _isLoading = true;
      _currentStatus = const StellarStatus.pairing();
    });

    try {
      final result = await RustLib.instance.api.crateApiApiInitPairing(port: _activePort!, pairingCode: code, storageDir: widget.storageDir);
      setState(() => _currentStatus = const StellarStatus.paired());
      _showSnackBar("Pairing Success!");
      
      // 1. Bersihkan semua notifikasi yang menggantung (Searching/Input)
      await NotificationService.cancelAll(); 
      
      // 2. Tampilkan notifikasi sukses (swipable)
      await NotificationService.showSuccess();
      
      // 3. Hapus otomatis setelah 5 detik agar tidak menumpuk
      Future.delayed(const Duration(seconds: 5), () {
        NotificationService.cancel(2);
      });
    } catch (e) {
      setState(() => _currentStatus = StellarStatus.error(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnpair() async {
    // Logic untuk membersihkan certificate dan status
    try {
      // Hapus file sertifikat fisik sesuai path di pair.rs
      final certFile = File('${widget.storageDir}/adb_cert.pem');
      if (await certFile.exists()) {
        await certFile.delete();
      }
    } catch (e) {
    }

    setState(() {
      _currentStatus = const StellarStatus.idle();
      _activePort = null;
    });
    _showSnackBar("Pairing session removed.");
  }

  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);

    try {
      // Memanggil ConnectLogic yang melakukan discovery port _adb-tls-connect
      final result = await ConnectLogic.connect(widget.storageDir);
      setState(() => _currentStatus = const StellarStatus.connected());
    } catch (e) {
      setState(() => _currentStatus = StellarStatus.error(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openDeveloperOptions() async {
    try {
      await platform.invokeMethod('openDeveloperOptions');
    } on PlatformException catch (e) {
      _showSnackBar("Failed to open setting: ${e.message}");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic UI yang sangat bersih berdasarkan State Proxy
    bool isPaired = false;
    bool isConnected = false;
    bool isError = false;
    String statusDisplay = "(is not running)";
    Color statusColor = Colors.white.withOpacity(0.6);
    String errorMessage = "";

    switch (_currentStatus) {
      case StellarStatus_Idle():
        break;
      case StellarStatus_Pairing():
        statusDisplay = "(pairing...)";
        break;
      case StellarStatus_Connecting():
        statusDisplay = "(connecting...)";
        break;
      case StellarStatus_Paired():
        isPaired = true;
        statusDisplay = "(paired)";
        statusColor = const Color(0xFFAEEA00);
        break;
      case StellarStatus_Connected():
        isPaired = true;
        isConnected = true;
        statusDisplay = "(paired, connected)";
        statusColor = const Color(0xFFAEEA00);
        break;
      case StellarStatus_Error(field0: final msg):
        isError = true;
        statusDisplay = "(Error)";
        errorMessage = msg;
        statusColor = Colors.redAccent;
        break;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Stellar",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openDeveloperOptions,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFD1C4E9),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                              children: [
                                const TextSpan(text: "Stellar ", style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                  text: statusDisplay,
                                  style: TextStyle(color: statusColor, fontWeight: isPaired ? FontWeight.bold : FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPaired ? _handleUnpair : _handlePair,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaired 
                        ? Colors.redAccent.withOpacity(0.2) 
                        : const Color(0xFF9575CD),
                      foregroundColor: isPaired ? Colors.redAccent : Colors.white,
                    ),
                    child: Text(isPaired ? "UNPAIR" : "PAIR"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isPaired && !_isLoading ? _handleConnect : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isPaired ? const Color(0xFF9575CD) : Colors.white10
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("CONNECT"),
                  ),
                ),
              ],
            ),
            
            // Error Card Baru di Bagian Bawah
            if (isError && errorMessage.isNotEmpty) ...[
              const Spacer(),
              Card(
                elevation: 0,
                color: Colors.redAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Connection Error",
                            style: TextStyle(color: Colors.redAccent.withOpacity(0.9), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}