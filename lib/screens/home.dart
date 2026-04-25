import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:stellar/logic/pair_logic.dart';
import 'package:stellar/logic/connect_logic.dart';
import 'package:stellar/native/frb_generated.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stellar/widgets/main_drawer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stellar/utils/ui_utils.dart';

class HomePage extends StatefulWidget {
  final String storageDir;
  const HomePage({super.key, required this.storageDir});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, UIUtils {
  bool _isLoading = false;
  StellarStatus _currentStatus = const StellarStatus.idle();
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  int? _activePort;
  Map<String, String> _historyLinks = {};

  static const platform = MethodChannel('labs.oxfnd.stellar/settings');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupServices();
    _checkInitialStatus();
  }

  Future<void> _loadSavedLink() async {
    try {
      final file = File('${widget.storageDir}/gacha_history.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          setState(() => _historyLinks = Map<String, String>.from(jsonDecode(content)));
        }
      }
    } catch (_) {}
  }

  void _checkInitialStatus() async {
    // Menggunakan fungsi dari Rust untuk memverifikasi status pairing yang sebenarnya
    final isPaired = await RustLib.instance.api.crateApiApiCheckPairingStatus(storageDir: widget.storageDir);
    
    if (mounted) {
      setState(() {
        _currentStatus = isPaired ? const StellarStatus.paired() : const StellarStatus.idle();
      });
    }
    _loadSavedLink();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    super.didChangeAppLifecycleState(state);
  }

  void _setupServices() async {
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
    if (await Permission.notification.request().isDenied) {
    if (!mounted) return;
      showSnackBar("Notification permission is required for code input.");
      return;
    }

    await NotificationService.showGuide();

    try {
      final service = await PairLogic.discoverPairingService();
      if (!mounted) return;

      _activePort = service?.port;
      
      if (_activePort != null) { 
        await NotificationService.showPairingInput(_activePort!);
      } else {
        await NotificationService.cancel(1);
        if (!mounted) return;
        showSnackBar("Pairing service not found.");
      }
    } catch (e) {
      await NotificationService.cancel(1); 
      if (!mounted) return;
      showErrorDialog("Pairing Failed", e.toString());
    }
  }

  void _submitPairing(String code) async {
    if (_activePort == null) {
      showSnackBar("Error: Port lost. Please try PAIR again.");
      return;
    }
    
    await NotificationService.cancelAll();
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _currentStatus = const StellarStatus.pairing();
    });

    try {
      await RustLib.instance.api.crateApiApiInitPairing(port: _activePort!, pairingCode: code, storageDir: widget.storageDir);
      await NotificationService.showSuccess();
      if (!mounted) return;
      setState(() => _currentStatus = const StellarStatus.paired());
      showSnackBar("Pairing Success!");
      
      Future.delayed(const Duration(seconds: 5), () {
        NotificationService.cancel(1);
      });
    } catch (e) {
      if (mounted) setState(() => _currentStatus = StellarStatus.error(e.toString()));
      showErrorDialog("Pairing Submission Failed", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnpair() async {
    try {
      final certFile = File('${widget.storageDir}/adb_cert.pem');
      final flagFile = File('${widget.storageDir}/pairing_success.flag');

      // Hapus kedua file penanda pairing secara paralel
      await Future.wait([
        if (await certFile.exists()) certFile.delete(),
        if (await flagFile.exists()) flagFile.delete(),
      ]);
    } catch (e) {
      debugPrint("Failed to delete pairing files: $e");
    }

    if (!mounted) return;
    setState(() {
      _currentStatus = const StellarStatus.idle();
      _activePort = null;
    });
    showSnackBar("Pairing session removed.");
  }

  String _identifyGame(String url) {
    if (url.contains('hk4e')) return 'gi';
    if (url.contains('hkrpg')) return 'hsr';
    if (url.contains('nap')) return 'zzz';
    return 'unknown';
  }

  Future<void> _persistGachaLink(String link) async {
    try {
      final gameId = _identifyGame(link);
      setState(() => _historyLinks[gameId] = link);
      
      final file = File('${widget.storageDir}/gacha_history.json');
      await file.writeAsString(jsonEncode(_historyLinks));
    } catch (_) {}
  }

  void _showGachaScannerDialog() {
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
              width: MediaQuery.of(context).size.width * 0.9,
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          foundLink!.isNotEmpty ? foundLink! : "No valid gacha link found in logs.", 
                          style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.white70),
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
                    await NotificationService.showScanningGachaLink();
                    try {
                      final link = await RustLib.instance.api.crateApiApiGetGachaLink(port: 0, storageDir: widget.storageDir);
                      debugPrint("DART: Gacha link received from Rust: '$link'");
                      setDialogState(() { foundLink = link; isScanning = false; });
                      _persistGachaLink(link);
                      await NotificationService.showLinkRetrieved();
                      await NotificationService.cancel(2); // Cancel scanning notification
                    } catch (e) {
                      setDialogState(() => isScanning = false);
                      Navigator.pop(context);
                      showErrorDialog("Scan Failed", e.toString());
                    }
                  },
                  child: const Text("SCAN NOW"),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: foundLink!));
                    showSnackBar("Copied!");
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
    final gameNames = {
      'gi': 'Genshin Impact',
      'hsr': 'Honkai: Star Rail',
      'zzz': 'Zenless Zone Zero',
      'unknown': 'Other / Unknown'
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gacha Link History"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: _historyLinks.isEmpty
              ? const Text("No link saved yet. Perform a scan first.")
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _historyLinks.entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(gameNames[entry.key] ?? entry.key, 
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFAEEA00))),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 18),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: entry.value));
                                          showSnackBar("Copied ${gameNames[entry.key]} link!");
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        onPressed: () async {
                                          setState(() => _historyLinks.remove(entry.key));
                                          final file = File('${widget.storageDir}/gacha_history.json');
                                          await file.writeAsString(jsonEncode(_historyLinks));
                                          if (context.mounted) Navigator.pop(context);
                                          _showHistoryDialog();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.value,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  Future<void> _handleConnect() async {
    setState(() => _isLoading = true);
    await NotificationService.showConnecting();
    try {
      final result = await ConnectLogic.connect(widget.storageDir);
      if (!mounted) return;
      setState(() => _currentStatus = const StellarStatus.connected());
      await NotificationService.showConnected();
      _showGachaScannerDialog();
    } catch (e) {
      if (mounted) setState(() => _currentStatus = StellarStatus.error(e.toString()));
      showErrorDialog("Connection Failed", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDeveloperOptions() async {
    try {
      await platform.invokeMethod('openDeveloperOptions');
    } on PlatformException catch (e) {
      if (!mounted) return;
      showSnackBar("Failed to open setting: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPaired = false;
    bool isConnected = false;
    bool isError = false;
    Color statusColor = Colors.white.withOpacity(0.6);
    String errorMessage = "";

    switch (_currentStatus) {
      case StellarStatus_Idle(): break;
      case StellarStatus_Pairing(): break;
      case StellarStatus_Connecting():
        isPaired = true;
        statusColor = const Color(0xFFD1C4E9);
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
        errorMessage = msg;
        // Cek manual keberadaan kedua file untuk memastikan status UI tetap sinkron saat error
        final hasCert = File('${widget.storageDir}/adb_cert.pem').existsSync();
        final hasFlag = File('${widget.storageDir}/pairing_success.flag').existsSync();
        isPaired = hasCert && hasFlag;
        statusColor = const Color(0xFFAEEA00);
        break;
    }

    String pairedDisplay = isPaired ? "True" : "False";
    String connectedDisplay = isConnected ? "True" : "False";

    if (isError) {
      if (isPaired) { connectedDisplay = "Error"; } else { pairedDisplay = "Error"; }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stellar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(onPressed: _showHistoryDialog, icon: const Icon(Icons.history_rounded)),
          IconButton(onPressed: _openDeveloperOptions, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      drawer: MainDrawer(storageDir: widget.storageDir),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        children: [const TextSpan(text: "Is Paired: "), TextSpan(text: pairedDisplay, style: TextStyle(color: (pairedDisplay == "True") ? statusColor : Colors.redAccent, fontWeight: FontWeight.bold))],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'VT323'),
                        children: [const TextSpan(text: "Is Connected: "), TextSpan(text: connectedDisplay, style: TextStyle(color: (connectedDisplay == "True") ? statusColor : Colors.redAccent, fontWeight: FontWeight.bold))],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPaired ? _handleUnpair : _handlePair,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaired ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF9575CD),
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
                      side: BorderSide(color: isPaired ? const Color(0xFF9575CD) : Colors.white10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("CONNECT"),
                  ),
                ),
              ],
            ),
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
                          Text("Connection Error", style: TextStyle(color: Colors.redAccent.withOpacity(0.9), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(errorMessage, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}