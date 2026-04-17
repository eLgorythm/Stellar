import 'package:flutter/material.dart';
import 'package:stellar/widgets/wish_banner.dart';
import 'package:stellar/native/wish_parser.dart';

class GIWishResultView extends StatelessWidget {
  final List<WishBanner> results;

  const GIWishResultView({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      itemCount: results.isEmpty ? 2 : results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Summary Card: Total Pulls & Primos
          final totalPulls = results.fold<int>(0, (sum, e) => sum + e.totalWishes);
          final totalPrimos = totalPulls * 160;

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildSummaryItem(
                    context,
                    "Total Wishes",
                    totalPulls.toString(),
                    Icons.auto_awesome_motion_rounded,
                  ),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildSummaryItem(
                    context,
                    "Primogems Spent",
                    totalPrimos.toString(),
                    Icons.savings_rounded,
                    color: const Color(0xFFAEEA00),
                  ),
                ],
              ),
            ),
          );
        }

        if (results.isEmpty && index == 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Text(
                "No data found for this game.\nPlease import your history first.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          );
        }

        final data = results[index - 1];
        // Anggap kartu "kosong" jika pity 0 dan tidak ada nama karakter bintang 5
        final bool isEmpty = data.pity == 0 && (data.last5Star == "None" || data.last5Star == "---");

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(isEmpty ? 0.5 : 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showDetailDialog(context, data),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: !isEmpty && data.isGuaranteed
                            ? Colors.orangeAccent.withOpacity(0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEmpty
                            ? '---'
                            : (data.isGuaranteed
                                ? 'Guaranteed'
                                : (data.type == BannerType.weapon ? '75/25' : '50/50')),
                        style: TextStyle(
                            fontSize: 11,
                            color: !isEmpty && data.isGuaranteed
                                ? Colors.orangeAccent
                                : Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildPityCircle(
                      data.pity,
                      data.type == BannerType.weapon ? 80 : 90,
                      isEmpty: isEmpty,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Last 5-Star:",
                              style: TextStyle(fontSize: 12, color: Colors.white54)),
                          Text(
                              isEmpty ? data.last5Star : "${data.last5Star} (${data.last5StarPity} Pity)",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: isEmpty ? Colors.white24 : Colors.orangeAccent, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Lifetime Pulls",
                            style: TextStyle(fontSize: 11, color: Colors.white38)),
                        Text(
                          "${data.totalWishes}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  void _showDetailDialog(BuildContext context, WishBanner data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF24243D), // Sesuai warna di gambar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white10, height: 24),
            _buildDetailRow("5 ★", data.history5Star.length.toString(), "${((data.history5Star.length / data.totalWishes) * 100).toStringAsFixed(2)}%", data.avgPity.toStringAsFixed(1)),
            const SizedBox(height: 20),
            const Text("History", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.history5Star.map((h) => _buildPill(h)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String total, String percent, String avg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        Text(total, style: const TextStyle(color: Colors.white)),
        Text(percent, style: const TextStyle(color: Colors.orangeAccent)),
        Text(avg, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPill(FiveStarHistory h) {
    Color pityColor = h.pity < 30 ? Colors.greenAccent : (h.pity > 75 ? Colors.redAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(h.name, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(width: 6),
          Text(h.pity.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pityColor)),
        ],
      ),
    );
  }
  Widget _buildPityCircle(int pity, int maxPity, {bool isEmpty = false}) {
    // Soft pity biasanya dimulai pada ~74 untuk banner 90, dan ~63 untuk banner 80
    final bool isNearSoftPity = pity >= (maxPity == 80 ? 63 : 74);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: isEmpty ? 0 : pity / maxPity,
            backgroundColor: Colors.white10,
            color: isEmpty ? Colors.white10 : (isNearSoftPity ? Colors.orangeAccent : const Color(0xFFAEEA00)),
            strokeWidth: 6,
          ),
        ),
        Text("$pity",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isEmpty ? Colors.white24 : Colors.white)),
      ],
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'VT323', color: color),
          ),
        ],
      ),
    );
  }
}