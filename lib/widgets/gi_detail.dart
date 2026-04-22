import 'package:flutter/material.dart';
import 'package:stellar/widgets/wish_banner.dart';
import 'package:stellar/native/wish_parser.dart';

class GIDetailPage extends StatelessWidget {
  final WishBanner banner;

  const GIDetailPage({super.key, required this.banner});
  bool get _isEventBanner =>
      banner.title.contains("Character") || banner.title.contains("Weapon");

  @override
  Widget build(BuildContext context) {
    // Threshold Pity untuk Genshin Impact
    final int maxPity5 = banner.title.contains("Weapon") ? 80 : 90;
    final int maxPity4 = 10;

    // Logika warna untuk Pity Tracking
    final bool isNearSoftPity = banner.pity >= (maxPity5 == 80 ? 63 : 74);
    final Color pity5Color = isNearSoftPity ? Colors.orangeAccent : const Color(0xFFAEEA00);
    final Color pity4Color = banner.pity4Star >= 8 ? Colors.orangeAccent : Colors.purpleAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1625),
      appBar: AppBar(
        title: Text("${banner.title} Analysis", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryHeader(context),
            const SizedBox(height: 32),
            const Text("Pity Tracking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPityBar("5-Star Pity", banner.pity, maxPity5, pity5Color),
            const SizedBox(height: 16),
            // Menampilkan info Bintang 4 (B4)
            _buildPityBar("4-Star Pity", banner.pity4Star, maxPity4, pity4Color),
            const SizedBox(height: 32),
            const Text("Detailed Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatsGrid(maxPity5),
            const SizedBox(height: 32),
            const Text("5-Star Pull Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric("Total Pulls", banner.totalWishes.toString(), Icons.history),
          _buildMetric("5★ Items", banner.history5Star.length.toString(), Icons.star, Colors.orangeAccent),
          _buildMetric("4★ Items", banner.total4Star.toString(), Icons.star_border, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white54, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'VT323')),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  Widget _buildPityBar(String title, int current, int max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text("$current / $max", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: current / max,
            minHeight: 10,
            backgroundColor: Colors.white10,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int maxPity5) {
    // Hitung Win Rate 50/50
    String winRate = "N/A";
    if (_isEventBanner && banner.history5Star.isNotEmpty) {
      int totalFlips = 0;
      int wins = 0;

      for (int i = 0; i < banner.history5Star.length; i++) {
        // Jika pull sebelumnya (i+1) adalah item standar, maka pull saat ini adalah jaminan (guaranteed).
        // Menghitung rate saat pemain tidak dalam kondisi guaranteed.
        bool wasGuaranteed = i + 1 < banner.history5Star.length && banner.history5Star[i + 1].isStandard;
        
        if (!wasGuaranteed) {
          totalFlips++;
          if (!banner.history5Star[i].isStandard) {
            wins++;
          }
        }
      }
      if (totalFlips > 0) {
        winRate = "${((wins / totalFlips) * 100).toStringAsFixed(1)}%";
      }
    }

    final int totalPrimos = banner.totalWishes * 160;
    final int toHardPityPrimos = (maxPity5 - banner.pity) * 160;
    
    // Formatter sederhana untuk angka ribuan
    String formatNumber(int number) => number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatTile("Average 5★", "${banner.avgPity.toStringAsFixed(1)} pulls"),
        _buildStatTile("Luck Rate (5★)", "${((banner.history5Star.length / banner.totalWishes) * 100).toStringAsFixed(2)}%"),
        _buildStatTile(_isEventBanner && banner.title.contains("Weapon") ? "75/25 Win Rate" : "50/50 Win Rate", winRate),
        _buildStatTile("Next Status", banner.isGuaranteed ? "Guaranteed" : "50/50 Chance"),
        _buildStatTile("Primogems Spent", "${formatNumber(totalPrimos)} ✦"),
        _buildStatTile("To Hard Pity", "${formatNumber(toHardPityPrimos)} ✦"),
      ],
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (banner.history5Star.isEmpty) return const Text("No 5-star history found.", style: TextStyle(color: Colors.white24));

    return Column(
      children: List.generate(
        banner.history5Star.length,
        (index) {
        final h = banner.history5Star[index];

        // Logika detail kemenangan 50/50
        bool isRateUp = !h.isStandard;
        // Jika item setelahnya di history adalah standar, berarti item ini hasil guaranteed
        bool wasGuaranteed = index + 1 < banner.history5Star.length && banner.history5Star[index + 1].isStandard;
        bool showWinLabel = _isEventBanner && isRateUp && !wasGuaranteed;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: showWinLabel
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                )
              : null,
          child: Card(
            margin: EdgeInsets.zero,
            color: const Color(0xFF15121F), // Warna solid agar glow shadow tidak masuk ke body
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.orangeAccent),
              title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(h.time, style: const TextStyle(fontSize: 11, color: Colors.white38)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${h.pity} Pity",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: h.pity < 30
                          ? Colors.greenAccent
                          : (h.pity > 75 ? Colors.redAccent : Colors.orangeAccent),
                    ),
                  ),
                  if (showWinLabel) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                      ),
                      child: const Text(
                        "WIN",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ], // Menutup children: [ dari trailing Column
              ),
            ),
          ),
        ); // Menutup return Container
      }), // Menutup lambda (index) {} dan List.generate()
    ); // Menutup Column()
  }
}