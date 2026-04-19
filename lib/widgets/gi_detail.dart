import 'package:flutter/material.dart';
import 'package:stellar/widgets/wish_banner.dart';
import 'package:stellar/native/wish_parser.dart';

class GIDetailPage extends StatelessWidget {
  final WishBanner banner;

  const GIDetailPage({super.key, required this.banner});

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
            _buildStatsGrid(),
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

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatTile("Average 5★", "${banner.avgPity.toStringAsFixed(1)} pulls"),
        _buildStatTile("Luck Rate (5★)", "${((banner.history5Star.length / banner.totalWishes) * 100).toStringAsFixed(2)}%"),
        _buildStatTile("Luck Rate (4★)", "${((banner.total4Star / banner.totalWishes) * 100).toStringAsFixed(2)}%"),
        _buildStatTile("Next Status", banner.isGuaranteed ? "Guaranteed" : "50/50 Chance"),
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
      children: banner.history5Star.map((h) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.white.withOpacity(0.02),
        child: ListTile(
          leading: const Icon(Icons.stars, color: Colors.orangeAccent),
          title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(h.time, style: const TextStyle(fontSize: 11, color: Colors.white38)),
          trailing: Text(
            "${h.pity} Pity",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: h.pity < 30
                  ? Colors.greenAccent
                  : (h.pity > 75 ? Colors.redAccent : Colors.orangeAccent),
            ),
          ),
        ),
      )).toList(),
    );
  }
}