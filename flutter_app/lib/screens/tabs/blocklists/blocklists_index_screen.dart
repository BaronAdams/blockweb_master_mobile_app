import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/limits.dart';
import '../../../state/app_settings.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/accessibility_warning_banner.dart';
import '../../../widgets/app_header.dart';

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
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return InkWell(
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
                        );
                      },
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
