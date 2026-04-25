import 'package:flutter/material.dart';
import 'package:stellar/widgets/wish_banner.dart';

class HsrWishResultView extends StatelessWidget {
  final List<WishBanner> results;

  const HsrWishResultView({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final item = results[index];
          return _buildWishCard(item);
        },
      ),
    );
  }

  Widget _buildWishCard(WishBanner item) {
    // Warna aksen berdasarkan tipe banner
    final Color accentColor = item.type == BannerType.character
        ? const Color(0xFFFFD700) // Gold untuk Character
        : item.type == BannerType.weapon
            ? const Color(0xFFA335EE) // Purple untuk Light Cone
            : const Color(0xFF4FA7FF); // Blue untuk Standard

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D273F), // Sesuai dengan surfaceContainer di main.dart
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentColor.withOpacity(0.15), Colors.transparent],
                ),
              ),
              child: Center(
                child: Icon(
                  item.type == BannerType.character ? Icons.person_rounded : Icons.auto_awesome_motion_rounded,
                  size: 64,
                  color: accentColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Column(
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Pity: ${item.pity}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}