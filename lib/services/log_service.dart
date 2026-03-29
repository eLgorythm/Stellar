import 'package:flutter/foundation.dart';
import 'package:stellar/native/api/api.dart';

class LogService extends ChangeNotifier {
  // Singleton Pattern
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  /// Menghubungkan jembatan log Rust ke service ini
  void init() {
    try {
      createLogStream().listen((msg) {
        log(msg);
      });
    } catch (e) {
      log("DART ERROR: Gagal inisialisasi log stream Rust: $e");
    }
  }

  /// Mencatat log baru dengan timestamp
  void log(String message) {
    final timestamp = DateTime.now().toString().split(' ').last.substring(0, 8);
    final formattedMsg = "[$timestamp] $message";
    
    _logs.add(formattedMsg);
    if (_logs.length > 200) _logs.removeAt(0);
    
    // Tetap print ke console terminal (flutter run)
    print(formattedMsg);
    
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}