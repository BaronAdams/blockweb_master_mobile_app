import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_models.dart';
import '../../models/categories.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../state/installed_apps.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_breakdown.dart';
import '../../utils/format.dart';
import '../../widgets/accessibility_warning_banner.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/chart_container.dart';
import '../../widgets/charts/doughnut_chart.dart';
import '../../widgets/charts/line_chart.dart';
import '../../widgets/charts/stacked_bar_chart.dart';
import '../../widgets/stat_card.dart';

const _categoryOrder4 = [SiteCategory.distraction, SiteCategory.entertainment, SiteCategory.productivity, SiteCategory.other];
const _weekdayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']; // DateTime.weekday is 1=Mon..7=Sun

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Port of app/(tabs)/index.tsx. `analytics` in the store is populated by
/// mergeUsageStats()/mergeHourlyUsageStats() — see hooks/useAppMonitor.ts
/// in the RN app (not yet ported: the periodic native-sync effect that
/// feeds this screen live data hasn't been wired into this Flutter build
/// yet, so these charts render whatever's already in the persisted store,
/// same "honest empty state instead of fabricated numbers" posture either
/// way).
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int? _selectedHour;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('analytics', key, vars: vars);
    String tc(String key) => i18n.t('common', key);
    final store = ref.watch(appStoreProvider);
    final installedApps = ref.watch(installedAppsProvider).value ?? const [];

    String resolveAppName(String pkg) {
      for (final a in installedApps) {
        if (a.packageName == pkg) return a.appName;
      }
      for (final b in store.blockedApps) {
        if (b.packageName == pkg) return b.appName;
      }
      return pkg;
    }

    String? resolveAppIcon(String pkg) {
      for (final a in installedApps) {
        if (a.packageName == pkg) return a.icon;
      }
      return null;
    }

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final todayLabel = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';

    DailyAnalytics? todayRecord;
    for (final a in store.analytics) {
      if (a.date == todayKey) {
        todayRecord = a;
        break;
      }
    }

    final categoryTotals = todayRecord != null ? getCategoryBreakdown(todayRecord.appUsage, const []) : null;
    final categoryTotal = categoryTotals == null
        ? 0.0
        : categoryTotals.distraction + categoryTotals.productivity + categoryTotals.entertainment + categoryTotals.other;

    final categoryData = <(SiteCategory cat, double value)>[
      if (categoryTotals != null)
        for (final cat in _categoryOrder4)
          if (categoryTotals[cat] > 0) (cat, categoryTotals[cat]),
    ];

    final productivityPct = categoryTotal > 0 ? ((categoryTotals?.productivity ?? 0) / categoryTotal * 100).round() : 0;
    final distractionPct = categoryTotal > 0 ? ((categoryTotals?.distraction ?? 0) / categoryTotal * 100).round() : 0;

    final hourlyBars = List.generate(24, (h) {
      final usageForHour = todayRecord?.hourlyUsage?['$h'] ?? const <String, double>{};
      final totals = getCategoryBreakdown(usageForHour, const []);
      final segments = [
        for (final cat in _categoryOrder4)
          if (totals[cat] > 0) StackedSegment(key: cat.name, value: totals[cat], color: categoryMeta[cat]!.color),
      ];
      return StackedBarDataPoint(label: '$h', segments: segments);
    });
    final hasHourlyData = hourlyBars.any((b) => b.segments.isNotEmpty);
    final totalDailyMinutes = todayRecord?.totalMinutes ?? 0.0;

    void onHourTap(int index) {
      if (hourlyBars[index].segments.isEmpty) return;
      setState(() => _selectedHour = _selectedHour == index ? null : index);
    }

    final historySource = _selectedHour != null
        ? (todayRecord?.hourlyUsage?['$_selectedHour'] ?? const <String, double>{})
        : (todayRecord?.appUsage ?? const <String, double>{});
    final historyEntries = historySource.entries
        .map((e) => (packageName: e.key, minutes: e.value, category: categorizeApp(e.key)))
        .toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    final last7Days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = _dateKey(d);
      DailyAnalytics? record;
      for (final a in store.analytics) {
        if (a.date == key) {
          record = a;
          break;
        }
      }
      return LinePoint(y: record?.totalMinutes ?? 0, label: tc(_weekdayKeys[d.weekday - 1]));
    });
    final hasWeeklyData = last7Days.any((d) => d.y > 0);

    final activeProfileCount = store.limiterProfiles.where((p) => p.isActive).length;
    const violet = Color(0xFF9E4FE7);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: GestureDetector(
              // A tap anywhere that isn't a bar resets the hour filter —
              // the stacked bar chart's own GestureDetector claims the
              // touch first when it lands on a bar (Flutter's default hit
              // testing already lets the innermost widget consume a tap),
              // so this only fires on genuine "empty space" taps.
              onTap: () => setState(() => _selectedHour = null),
              behavior: HitTestBehavior.translucent,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(t('title'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.foreground)),
                  const SizedBox(height: 2),
                  Text('${tc('today')} · $todayLabel', style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                  const SizedBox(height: 16),
                  AccessibilityWarningBanner(active: store.blockedApps.isNotEmpty),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // Was 1.4 — too short for a 2-line label + value at the
                    // new bottom padding, leaving no breathing room below
                    // the value text (looked like padding-bottom: 0).
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(label: 'Apps bloquées', value: '${store.blockedApps.length}', icon: Icons.block_rounded, color: const Color(0xFFF43F5E)),
                      StatCard(label: 'Sites bloqués', value: '${store.blockedWebsites.length}', icon: Icons.public_rounded, color: const Color(0xFF8B5CF6)),
                      StatCard(label: t('keywords'), value: '${store.blockedKeywords.length}', icon: Icons.tag_rounded, color: const Color(0xFFF59E0B)),
                      StatCard(label: t('activeProfiles'), value: '$activeProfileCount', icon: Icons.hourglass_empty_rounded, color: const Color(0xFF34D399)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ChartContainer(
                    title: t('hourlyChart'),
                    description: t('hourlyDesc'),
                    child: !hasHourlyData
                        ? EmptyChartState(label: t('noData'), hint: t('trackingHint'))
                        : Column(
                            children: [
                              Text(formatMinutes(totalDailyMinutes),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.foreground)),
                              const SizedBox(height: 12),
                              StackedBarChart(
                                data: hourlyBars,
                                height: 150,
                                labelEvery: 4,
                                selectedIndex: _selectedHour,
                                onBarTap: onHourTap,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  ChartContainer(
                    title: t('history'),
                    description: _selectedHour != null ? t('filteredByHour', {'hour': _selectedHour}) : '${tc('today')} · $todayLabel',
                    child: historyEntries.isEmpty
                        ? EmptyChartState(label: t('noNavigation'), hint: t('trackingHint'))
                        : Column(
                            children: [
                              for (final entry in historyEntries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      AppIcon(appName: resolveAppName(entry.packageName), icon: resolveAppIcon(entry.packageName), size: 30),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(resolveAppName(entry.packageName),
                                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: colors.foreground)),
                                            Text(
                                              '${categoryMeta[entry.category]!.emoji} ${tc(categoryMeta[entry.category]!.labelKey)}',
                                              style: TextStyle(fontSize: 10, color: categoryMeta[entry.category]!.color),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(formatMinutes(entry.minutes),
                                          style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colors.mutedForeground)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  ChartContainer(
                    title: t('whereTime'),
                    child: categoryData.isEmpty
                        ? EmptyChartState(label: t('noData'), hint: t('trackingHint'))
                        : Column(
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    DoughnutChart(
                                      data: [
                                        for (final (cat, value) in categoryData) DoughnutSegment(color: categoryMeta[cat]!.color, value: value),
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$productivityPct%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.foreground)),
                                        Text(t('productif').toUpperCase(), style: TextStyle(fontSize: 10, color: colors.mutedForeground)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (final (cat, value) in categoryData)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Text(categoryMeta[cat]!.emoji, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(tc(categoryMeta[cat]!.labelKey), style: TextStyle(fontSize: 13, color: colors.foreground))),
                                      Text(formatMinutes(value), style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colors.mutedForeground)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  ChartContainer(
                    title: t('evolution7d'),
                    description: t('evolution7dDesc'),
                    child: hasWeeklyData
                        ? AppLineChart(data: last7Days, height: 180)
                        : EmptyChartState(label: t('notEnoughData'), hint: t('trackingHint')),
                  ),
                  if (distractionPct >= 40) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: violet.withOpacity(0.1),
                        border: Border.all(color: violet.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📱', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t('distractionWarning', {'pct': distractionPct}),
                              style: const TextStyle(fontSize: 12, color: Color(0xFFC4B5FD)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
