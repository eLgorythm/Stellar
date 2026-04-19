import 'package:flutter/material.dart';
import 'package:stellar/widgets/main_drawer.dart';
import 'package:stellar/native/frb_generated.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

class ImportDataPage extends StatefulWidget {
  final String storageDir;
  const ImportDataPage({super.key, required this.storageDir});

  @override
  State<ImportDataPage> createState() => _ImportDataPageState();
}

class _ImportDataPageState extends State<ImportDataPage> with UIUtils {
  String _selectedGame = 'gi';
  bool _isImporting = false;
  bool _isExporting = false;

  void _importFromJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      setState(() => _isImporting = true);
      try {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        final addedCount = await RustLib.instance.api.crateApiApiImportLocalJson(
          jsonContent: content,
          storageDir: widget.storageDir,
          game: _selectedGame,
        );

        showSnackBar("Success! Berhasil mengimpor $addedCount entri baru.");
      } catch (e) {
        showErrorDialog("Import Error", e.toString());
      } finally {
        setState(() => _isImporting = false);
      }
    }
  }

  void _exportToJson() async {
    setState(() => _isExporting = true);
    try {
      // 1. Ambil data JSON terformat dari Rust
      final jsonContent = await RustLib.instance.api.crateApiApiExportLocalJson(
        storageDir: widget.storageDir,
        game: _selectedGame,
      );

      // Convert String content to Uint8List for mobile compatibility
      final Uint8List bytes = utf8.encode(jsonContent);

      // 2. Gunakan FilePicker untuk menentukan lokasi simpan
      // Di Android/iOS, parameter 'bytes' wajib diisi
      await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan file export:',
        fileName: 'stellar_export_${_selectedGame}_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      showSnackBar("Berhasil! File export telah disimpan.");
    } catch (e) {
      showErrorDialog("Export Error", e.toString());
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import Data", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: MainDrawer(storageDir: widget.storageDir),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.drive_folder_upload_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              "Impor Riwayat Gacha",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pilih file JSON hasil export (UIGF/SRGF) untuk digabungkan dengan data lokal Stellar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 40),
            
            // Game Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<String>(
                value: _selectedGame,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                isExpanded: true,
                borderRadius: BorderRadius.circular(20),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'gi', child: Text("Genshin Impact")),
                  DropdownMenuItem(value: 'hsr', child: Text("Honkai: Star Rail")),
                  DropdownMenuItem(value: 'zzz', child: Text("Zenless Zone Zero")),
                ],
                onChanged: (v) => setState(() => _selectedGame = v!),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importFromJson,
                icon: _isImporting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_open_rounded),
                label: Text(
                  _isImporting ? "PROCESSING..." : "SELECT JSON FILE",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : _exportToJson,
                icon: _isExporting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded),
                label: Text(
                  _isExporting ? "PREPARING..." : "EXPORT TO JSON",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const Spacer(),
            Text(
              "Data yang sudah ada tidak akan terduplikasi berdasarkan internal ID.",
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}