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
  
  // Gunakan external storage (Android/data/...) agar file JSON dapat diakses user secara manual
  final directory = await getExternalStorageDirectory();
  final storagePath = directory?.path ?? (await getApplicationSupportDirectory()).path;

  // Set status bar transparan untuk tampilan lebih clean
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(StellarApp(storageDir: storagePath));
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
  String? _savedGachaLink;

  // Channel untuk memicu intent Android (tetap hardcoded appId karena ini konstanta sistem)
  static const platform = MethodChannel('labs.oxfnd.stellar/settings');

  @override
  void initState() {
    super.initState();
    _setupServices();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialStatus();
  }

  Future<void> _loadSavedLink() async {
    try {
      final file = File('${widget.storageDir}/gacha_link.txt');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          setState(() => _savedGachaLink = content);
        }
      }
    } catch (_) {}
  }

  void _checkInitialStatus() {
    // Cek apakah sertifikat ada secara sinkron untuk menentukan status awal
    final certFile = File('${widget.storageDir}/adb_cert.pem');
    if (certFile.existsSync()) {
      setState(() => _currentStatus = const StellarStatus.paired());
    } else {
      setState(() => _currentStatus = const StellarStatus.idle());
    }
    _loadSavedLink();
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
      
      if (_activePort != null) { 
        await NotificationService.showPairingInput(_activePort!);
      } else {
        // Jika layanan tidak ditemukan, batalkan panduan searching dan beri tahu user
        await NotificationService.cancel(1); 
        _showSnackBar("Pairing service not found.");
      }
    } catch (e) {
      // Jika terjadi error selama discovery, batalkan panduan searching
      await NotificationService.cancel(1); 
      _showSnackBar("Gagal: $e");
    }
  }

  void _submitPairing(String code) async {
    if (_activePort == null) {
      print("DART ERROR: _activePort is null when _submitPairing is called.");
      _showSnackBar("Error: Port lost. Please try PAIR again.");
      return;
    }
    
    // Batalkan notifikasi input & guide agar tidak "nyangkut"
    await NotificationService.cancelAll();
    
    setState(() {
      _isLoading = true;
      _currentStatus = const StellarStatus.pairing();
    });

    try {
      final result = await RustLib.instance.api.crateApiApiInitPairing(port: _activePort!, pairingCode: code, storageDir: widget.storageDir);
      await NotificationService.showSuccess();
      setState(() => _currentStatus = const StellarStatus.paired());
      _showSnackBar("Pairing Success!");
      
      // 3. Hapus otomatis setelah 5 detik agar tidak menumpuk
      Future.delayed(const Duration(seconds: 5), () {
        NotificationService.cancel(1); // Update ID to match showSuccess()
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

  Future<void> _persistGachaLink(String link) async {
    try {
      final file = File('${widget.storageDir}/gacha_link.txt');
      await file.writeAsString(link);
      setState(() => _savedGachaLink = link);
    } catch (_) {}
  }

  void _showGachaScannerDialog() {
    // Pindahkan variabel ke sini agar tidak ter-reset saat builder berjalan ulang
    bool isScanning = false;
    String? foundLink;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Gacha Link Scanner"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // Gunakan 90% lebar layar
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("1. Open Genshin/HSR/HI3/ZZZ\n2. Open Wish History\n3. Tap SCAN below", style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 20),
                  if (isScanning) const LinearProgressIndicator(),
                  if (foundLink != null) 
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      width: double.infinity, // Paksa melebar
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4, // Gunakan 40% tinggi layar
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText( // Gunakan SelectableText agar lebih mudah diinspeksi
                          foundLink!.isNotEmpty ? foundLink! : "No valid gacha link found in logs.", 
                          style: const TextStyle(
                            fontSize: 14, 
                            fontFamily: 'monospace', 
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              if (foundLink == null)
                ElevatedButton(
                  onPressed: isScanning ? null : () async {
                    setDialogState(() => isScanning = true);
                    // Trigger notification untuk background scanning
                    await NotificationService.showStatus("Scanning Gacha Link...", "Please open Wish History in game");
                    try {
                      final link = await RustLib.instance.api.crateApiApiGetGachaLink(port: 0, storageDir: widget.storageDir);
                      debugPrint("DART: Gacha link received from Rust: '$link'"); // Tambahkan debug print ini
                      setDialogState(() { foundLink = link; isScanning = false; });
                      _persistGachaLink(link); // Jalankan tanpa await agar lebih responsif
                      await NotificationService.showStatus("Link Retrieved!", "Tap to go back to Stellar", id: 4);
                      await NotificationService.cancel(3); // Hapus notifikasi scanning setelah yang baru muncul
                    } catch (e) {
                      setDialogState(() => isScanning = false);
                      _showSnackBar("Scan failed: $e");
                      await NotificationService.cancelAll();
                    }
                  },
                  child: const Text("SCAN NOW"),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: foundLink!));
                    _showSnackBar("Copied!");
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text("COPY"),
                ),
            ],
          );
        }
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Last Scanned Link"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: _savedGachaLink == null
              ? const Text("No link saved yet. Perform a scan first.")
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _savedGachaLink!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
          if (_savedGachaLink != null)
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _savedGachaLink!));
                _showSnackBar("Copied to clipboard!");
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text("COPY"),
            ),
          if (_savedGachaLink != null)
            IconButton(
              onPressed: () async {
                await File('${widget.storageDir}/gacha_link.txt').delete();
                setState(() => _savedGachaLink = null);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);
    await NotificationService.showStatus("Connecting...", "Establishing secure ADB session");

     try {
      // Memanggil ConnectLogic yang melakukan discovery port _adb-tls-connect
      final result = await ConnectLogic.connect(widget.storageDir);
      setState(() => _currentStatus = const StellarStatus.connected());
      
      await NotificationService.showStatus("Connected", "Device is ready for scanning");
      
      _showGachaScannerDialog();
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
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic UI yang sangat bersih berdasarkan State Proxy
    bool isPaired = false;
    bool isConnected = false;
    bool isError = false;
    Color statusColor = Colors.white.withOpacity(0.6);
    String errorMessage = "";

    switch (_currentStatus) {
      case StellarStatus_Idle():
        break;
      case StellarStatus_Pairing():
        break;
      case StellarStatus_Connecting():
        isPaired = true;
        statusColor = const Color(0xFFD1C4E9); // Light lavender saat proses
        break;
      case StellarStatus_Paired():
        isPaired = true;
        statusColor = const Color(0xFFAEEA00);
        break;
      case StellarStatus_Connected():
        isPaired = true;
        isConnected = true;
        statusColor = const Color(0xFFAEEA00);
        break;
      case StellarStatus_Error(field0: final msg):
        isError = true;
        isPaired = File('${widget.storageDir}/adb_cert.pem').existsSync();
        errorMessage = msg;
        statusColor = const Color(0xFFAEEA00);
        break;
    }
    
    // Menentukan teks yang ditampilkan untuk masing-masing status
    // Jika dalam state error, kita tentukan mana yang menunjukkan pesan "Error"
    String pairedDisplay = isPaired ? "True" : "False";
    String connectedDisplay = isConnected ? "True" : "False";

    if (isError) {
      if (isPaired) {
        connectedDisplay = "Error";
      } else {
        pairedDisplay = "Error";
      }
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
            onPressed: _showHistoryDialog,
            icon: const Icon(Icons.history_rounded),
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'VT323'),
                        children: [
                          const TextSpan(text: "Is Paired: "),
                          TextSpan(
                            text: pairedDisplay,
                            style: TextStyle(
                              color: (pairedDisplay == "True") ? statusColor : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'VT323'),
                        children: [
                          const TextSpan(text: "Is Connected: "),
                          TextSpan(
                            text: connectedDisplay,
                            style: TextStyle(
                              color: (connectedDisplay == "True") ? statusColor : Colors.redAccent,
                              fontWeight: FontWeight.bold,
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