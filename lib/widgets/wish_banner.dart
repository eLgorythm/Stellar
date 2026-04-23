import 'package:stellar/native/wish_parser.dart';

enum BannerType { character, weapon, standard, chronicled }

class WishBanner {
  final String title;
  final BannerType type;
  final int pity;
  final int last5StarPity;
  final String last5Star;
  final bool isGuaranteed;
  final int totalWishes;
  final List<FiveStarHistory> history5Star;
  final List<FiveStarHistory> history4Star;
  final double avgPity;
  final int total4Star;
  final int pity4Star;
  final List<MonthlyStat> monthlyStats;

  WishBanner({
    required this.title,
    required this.type,
    required this.pity,
    required this.last5StarPity,
    required this.last5Star,
    required this.isGuaranteed,
    required this.totalWishes,
    required this.history5Star,
    required this.history4Star,
    required this.avgPity,
    required this.total4Star,
    required this.pity4Star,
    required this.monthlyStats,
  });
}