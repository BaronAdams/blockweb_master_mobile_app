import '../models/categories.dart';

/// Port of utils/analytics.ts's getCategoryBreakdown(). `adult` is folded
/// into `other`, matching the RN version (Analytics doesn't have a
/// separate adult-content bucket in the 4-category breakdown it charts).
class CategoryBreakdown {
  final double distraction;
  final double productivity;
  final double entertainment;
  final double other;
  const CategoryBreakdown({
    required this.distraction,
    required this.productivity,
    required this.entertainment,
    required this.other,
  });

  double operator [](SiteCategory cat) => switch (cat) {
        SiteCategory.distraction => distraction,
        SiteCategory.productivity => productivity,
        SiteCategory.entertainment => entertainment,
        SiteCategory.other || SiteCategory.adult => other,
      };
}

CategoryBreakdown getCategoryBreakdown(Map<String, double> appUsage, List<String> productiveApps) {
  double distraction = 0, productivity = 0, entertainment = 0, other = 0;
  for (final entry in appUsage.entries) {
    final category = productiveApps.contains(entry.key) ? SiteCategory.productivity : categorizeApp(entry.key);
    switch (category) {
      case SiteCategory.distraction:
        distraction += entry.value;
      case SiteCategory.productivity:
        productivity += entry.value;
      case SiteCategory.entertainment:
        entertainment += entry.value;
      case SiteCategory.other:
      case SiteCategory.adult:
        other += entry.value;
    }
  }
  return CategoryBreakdown(distraction: distraction, productivity: productivity, entertainment: entertainment, other: other);
}
