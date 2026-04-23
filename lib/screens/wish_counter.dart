import 'package:flutter/material.dart';
import 'package:stellar/widgets/main_drawer.dart';
import 'package:stellar/widgets/wish_result.dart';
import 'package:stellar/widgets/wish_banner.dart';
import 'package:stellar/native/frb_generated.dart';
import 'package:stellar/native/api/api.dart';
import 'package:stellar/native/wish_parser.dart';
import 'package:stellar/utils/ui_utils.dart';

class WishCounterPage extends StatefulWidget {
  final String storageDir;
  const WishCounterPage({super.key, required this.storageDir});

  @override
  State<WishCounterPage> createState() => _WishCounterPageState();
}

enum WishStage { input, processing, completed, results }

class _WishCounterPageState extends State<WishCounterPage> with UIUtils {
  WishStage _stage = WishStage.input;
  final TextEditingController _urlController = TextEditingController();
  String _selectedGame = 'gi'; // Default: Genshin Impact

  // State untuk progres loading dari Rust Stream
  String _processingGachaType = "";
  int _processingCurrentPage = 0;
  int _totalEntriesFetched = 0; // This is cumulative
  List<CompletedBannerInfo> _completedBannerDetails = []; // Changed to use the new struct

  final List<WishBanner> _bannerResults = [];

  void _startImport() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _stage = WishStage.processing;
      _completedBannerDetails.clear(); // Clear the new list
      _bannerResults.clear();
      _processingGachaType = "Connecting...";
      _processingCurrentPage = 0; // Reset for new import
      _totalEntriesFetched = 0; // Reset for new import
    });

    try {
      // 1. Panggil Rust untuk Fetch data dan simpan ke JSON
      final progressStream = RustLib.instance.api.crateApiApiPerformWishImport(
        url: _urlController.text,
        storageDir: widget.storageDir,
        game: _selectedGame,
      );

      // Dengarkan stream untuk update progres
      await for (final update in progressStream) {
        setState(() {
          _processingGachaType = update.gachaType;
          _processingCurrentPage = update.currentPage;
          _totalEntriesFetched = update.totalEntriesFetched.toInt();
          _completedBannerDetails = update.completedBannerDetails; // Assign the new list
        });
      }

      setState(() => _stage = WishStage.completed);
    } catch (e) {
      setState(() => _stage = WishStage.input);
      showErrorDialog("Import Failed", e.toString());
    }
  }

  Future<void> _loadResults() async {
    try {
      final summaries = await RustLib.instance.api.crateApiApiGetWishSummary(
        storageDir: widget.storageDir,
        game: _selectedGame,
      );

      setState(() {
        _bannerResults.clear();
        for (var s in summaries) {
          BannerType type;
          if (s.title.contains("Weapon") || s.title.contains("W-Engine") || s.title.contains("Light Cone")) {
            type = BannerType.weapon;
          } else if (s.title.contains("Standard") || s.title.contains("Stable") || s.title.contains("Stellar")) {
            type = BannerType.standard;
          } else if (s.title.contains("Chronicled")) {
            type = BannerType.chronicled;
          } else {
            type = BannerType.character;
          }

          _bannerResults.add(WishBanner(
            title: s.title,
            type: type,
            pity: s.pity,
            last5StarPity: s.last5StarPity,
            last5Star: s.last5Star,
            isGuaranteed: s.isGuaranteed,
            totalWishes: s.totalWishes,
            history5Star: s.history5Star,
            history4Star: s.history4Star,
            avgPity: s.avgPity,
            total4Star: s.total4Star,
            pity4Star: s.pity4Star,
            monthlyStats: s.monthlyStats,
          ));
        }
        _stage = WishStage.results;
      });
    } catch (e) {
      setState(() {
        _bannerResults.clear();
        _stage = WishStage.input;
      });
      showErrorDialog("Load Failed", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wish Counter", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_stage == WishStage.results)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() => _stage = WishStage.input),
            )
        ],
      ),
      drawer: MainDrawer(storageDir: widget.storageDir),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStage(),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_stage) {
      case WishStage.input:
        return _buildInputSection();
      case WishStage.processing:
        return _buildProcessingSection();
      case WishStage.completed:
        return _buildCompletedSection();
      case WishStage.results:
        return WishResultWrapper(
          results: _bannerResults,
          selectedGame: _selectedGame,
          onGameChanged: (game) {
            setState(() => _selectedGame = game);
            _loadResults();
          },
          onReset: () => setState(() => _stage = WishStage.input),
        );
    }
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Game Selector Dropdown sebelum import
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
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: "Paste your gacha link here",
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _startImport,
              child: const Text("IMPORT DATA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadResults,
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text("View Data"),
          ),
          const SizedBox(height: 20),
          const Opacity(
            opacity: 0.6,
            child: Text(
              "Hint: You can get this link by performing a SCAN in the Home tab and copying the result.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFD1C4E9)),
            const SizedBox(height: 24),
            Text(
              "Processing $_processingGachaType banner",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              "Reading page $_processingCurrentPage...",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              "Total fetched: $_totalEntriesFetched entries",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 32),
            if (_completedBannerDetails.isNotEmpty) ...[ // Use the new list
              const Divider(color: Colors.white10),
              const Text("Completed Banners:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ..._completedBannerDetails.map((bInfo) => Padding( // Iterate over the new struct
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${bInfo.gachaType} (${bInfo.entriesCount} entries)", style: const TextStyle(fontSize: 18)),
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFAEEA00), size: 80),
            const SizedBox(height: 24),
            const Text(
              "Import Complete!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Successfully fetched $_totalEntriesFetched entries.",
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            if (_completedBannerDetails.isNotEmpty) ...[ // Use the new list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column( // Iterate over the new struct
                  children: [
                    for (var bInfo in _completedBannerDetails)
                      Text("${bInfo.gachaType} (${bInfo.entriesCount} entries)", 
                      style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loadResults,
                child: const Text("VIEW RESULT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}