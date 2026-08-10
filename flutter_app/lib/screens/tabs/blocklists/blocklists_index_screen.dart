import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/limits.dart';
import '../../../state/app_settings.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/accessibility_warning_banner.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/profile_list_section.dart';

class _MenuItem {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final String route;
  final bool locked;
  const _MenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.route,
    this.locked = false,
  });
}

/// Port of app/(tabs)/blocklists/index.tsx.
class BlocklistsIndexScreen extends ConsumerWidget {
  const BlocklistsIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('blockLists', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final items = [
      _MenuItem(
        icon: Icons.smartphone_outlined,
        color: const Color(0xFFFB7185),
        label: t('applications'),
        count: store.blockedApps.length,
        route: '/blocklists/apps',
      ),
      _MenuItem(
        icon: Icons.public_outlined,
        color: const Color(0xFF8B5CF6),
        label: t('blockedDomains'),
        count: store.blockedWebsites.length,
        route: '/blocklists/websites',
      ),
      _MenuItem(
        icon: Icons.tag_rounded,
        color: const Color(0xFFF59E0B),
        label: t('blockedKeywords'),
        count: store.blockedKeywords.length,
        route: '/blocklists/keywords',
      ),
      _MenuItem(
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF34D399),
        label: t('whitelist'),
        count: store.whitelistedSites.length,
        route: '/blocklists/whitelist',
        locked: !isPremium(store.plan),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('title'),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.foreground)),
                  const SizedBox(height: 16),
                  AccessibilityWarningBanner(active: store.blockedApps.isNotEmpty),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        // Blanket toggles — apply everywhere immediately,
                        // unlike the per-item quick-block menu below.
                        _ToggleRow(
                          icon: Icons.no_adult_content_rounded,
                          color: const Color(0xFFF43F5E),
                          label: t('adultBlocking'),
                          description: t('adultDesc'),
                          value: store.adultContentBlocked,
                          onChanged: notifier.setAdultContentBlocked,
                        ),
                        const SizedBox(height: 10),
                        _ToggleRow(
                          icon: Icons.smart_display_outlined,
                          color: const Color(0xFF9E4FE7),
                          label: t('reelsBlocking'),
                          description: t('reelsBlockingDesc'),
                          value: store.reelsShortsBlocked,
                          onChanged: notifier.setReelsShortsBlocked,
                        ),
                        const SizedBox(height: 20),
                        Text(t('quickBlocksTitle'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.mutedForeground)),
                        const SizedBox(height: 10),
                        for (final item in items) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => context.push(item.route),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.card,
                                border: Border.all(color: colors.border),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: item.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(item.icon, size: 20, color: item.color),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(item.label,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.foreground)),
                                  ),
                                  if (item.locked)
                                    Icon(Icons.lock_outline_rounded, size: 16, color: colors.mutedForeground)
                                  else
                                    Text('${item.count}',
                                        style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: colors.mutedForeground)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.mutedForeground),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Scheduled block profiles (daily/hourly/weekly/interval
                        // limits) right after the quick-block menu — was its
                        // own bottom-nav tab, now lives in the same place as
                        // the rest of "what's blocked and how".
                        const SizedBox(height: 14),
                        const AppSeparator(),
                        const SizedBox(height: 14),
                        const ProfileListSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.card, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.foreground)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged, activeColor: colors.primary),
        ],
      ),
    );
  }
}
