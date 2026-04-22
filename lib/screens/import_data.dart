import 'package:flutter/material.dart';
import 'package:stellar/widgets/main_drawer.dart';
import 'package:stellar/native/frb_generated.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stellar/l10n/app_localizations.dart';

class ImportDataPage extends StatefulWidget {
  final String storageDir;
  const ImportDataPage({super.key, required this.storageDir});

  @override
  State<ImportDataPage> createState() => _ImportDataPageState();
}

class _ImportDataPageState extends State<ImportDataPage> with UIUtils {
  String _selectedGame = 'gi';
  String _selectedVersion = '3.0';
  bool _isImporting = false;
  bool _isExporting = false;
  final TextEditingController _uidController = TextEditingController();

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
          uid: _uidController.text.isEmpty ? null : _uidController.text,
        );

        if (!mounted) return;
        showSnackBar(AppLocalizations.of(context)!.successImport(addedCount.toInt()));
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
      final packageInfo = await PackageInfo.fromPlatform();

      // 1. Ambil data JSON terformat dari Rust menggunakan struct ExportResult
      final exportResult = await RustLib.instance.api.crateApiApiExportLocalJson(
        storageDir: widget.storageDir,
        game: _selectedGame,
        version: _selectedVersion,
        uid: _uidController.text.isEmpty ? null : _uidController.text,
        appVersion: packageInfo.version,
      );

      // Convert String content to Uint8List for mobile compatibility
      final Uint8List bytes = utf8.encode(exportResult.content);

      // 2. Gunakan FilePicker untuk menentukan lokasi simpan
      // Di Android/iOS, parameter 'bytes' wajib diisi
      await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan file export:',
        fileName: exportResult.fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (!mounted) return;
      showSnackBar(AppLocalizations.of(context)!.successExport);
    } catch (e) {
      showErrorDialog("Export Error", e.toString());
    } finally {
      setState(() => _isExporting = false);
    }
  }

  List<DropdownMenuItem<String>> _buildVersionItems() {
    List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: '4.2', child: Text("UIGF v4.2 (Latest)")),
    ];

    if (_selectedGame == 'gi') {
      items.insert(0, const DropdownMenuItem(value: '3.0', child: Text("UIGF v3.0 (GENSHIN)")));
    } else if (_selectedGame == 'hsr') {
      items.insert(0, const DropdownMenuItem(value: '1.0', child: Text("SRGF v1.0 (HSR)")));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importExport, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: MainDrawer(storageDir: widget.storageDir),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.importExportHistory,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.importExportDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 40),
            
            // Selector Row: Game
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
                onChanged: (v) {
                  setState(() {
                    _selectedGame = v!;
                    // Validasi versi saat ganti game
                    if (_selectedGame == 'zzz') {
                      _selectedVersion = '4.2';
                    } else if (_selectedGame == 'hsr' && _selectedVersion == '3.0') {
                      _selectedVersion = '1.0';
                    } else if (_selectedGame == 'gi' && _selectedVersion == '1.0') {
                      _selectedVersion = '3.0';
                    }
                  });
                },
              ),
            ),
            
            const SizedBox(height: 12),

            // Selector Row: UIGF Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<String>(
                value: _selectedVersion,
                icon: const Icon(Icons.settings_outlined, size: 20),
                isExpanded: true,
                borderRadius: BorderRadius.circular(20),
                underline: const SizedBox(),
                items: _buildVersionItems(),
                onChanged: (v) => setState(() => _selectedVersion = v!),
              ),
            ),
            
            const SizedBox(height: 12),

            // Selector Row: UID Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _uidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.uidOptional,
                  border: InputBorder.none,
                  icon: const Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                l10n.uidHint,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
                textAlign: TextAlign.start,
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
                  _isImporting ? l10n.processing : l10n.selectJson,
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
                  _isExporting ? l10n.preparing : l10n.exportJson,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const Spacer(),
            Text(
              l10n.duplicationNote,
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
