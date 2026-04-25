import 'package:flutter/material.dart';
import 'package:stellar/widgets/wish_banner.dart';
import 'package:stellar/widgets/genshin/gi_wish_result_view.dart';
import 'package:stellar/widgets/hsr/hsr_wish_result_view.dart';

class WishResultWrapper extends StatelessWidget {
  final List<WishBanner> results;
  final String selectedGame;
  final Function(String) onGameChanged;
  final VoidCallback onReset;

  const WishResultWrapper({
    super.key,
    required this.results,
    required this.selectedGame,
    required this.onGameChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dropdown Card Global
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedGame,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(20),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'gi', child: Text("Genshin Impact")),
                    DropdownMenuItem(value: 'hsr', child: Text("Honkai: Star Rail")),
                    DropdownMenuItem(value: 'zzz', child: Text("Zenless Zone Zero")),
                  ],
                  onChanged: (v) => onGameChanged(v!),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildGameSpecificView(),
        ),
      ],
    );
  }

  Widget _buildGameSpecificView() {
    switch (selectedGame) {
      case 'gi':
        return GIWishResultView(results: results);
      case 'hsr':
        return HsrWishResultView(results: results);
      case 'zzz':
        return const Center(child: Text("ZZZ View (Coming Soon)", style: TextStyle(fontFamily: 'VT323', fontSize: 20)));
      default:
        return GIWishResultView(results: results);
    }
  }
}
