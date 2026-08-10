import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/categories.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_header.dart';
import '../../widgets/sub_screen_header.dart';
import '../../widgets/toast.dart';

/// Reached by tapping an app in Analytics history — lets the user override
/// categorizeApp()'s curated-list guess for that one app (see
/// models/categories.dart's resolveAppCategory / AppStoreState.categoryOverrides).
class CategoryPickerScreen extends ConsumerWidget {
  final String packageName;
  final String appName;
  final String? icon;
  const CategoryPickerScreen({super.key, required this.packageName, required this.appName, this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('analytics', key);
    String tc(String key) => i18n.t('common', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);
    final current = resolveAppCategory(packageName, store.categoryOverrides);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(title: t('chooseCategoryTitle')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    AppIcon(appName: appName, icon: (icon?.isEmpty ?? true) ? null : icon, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(appName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.foreground)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(t('chooseCategoryDesc'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                const SizedBox(height: 20),
                for (final cat in categoryOrder) ...[
                  _CategoryTile(
                    category: cat,
                    selected: current == cat,
                    label: tc(categoryMeta[cat]!.labelKey),
                    onTap: () {
                      notifier.setCategoryOverride(packageName, cat.name);
                      showWarningToast(context, t('categorySaved'));
                      context.pop();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final SiteCategory category;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.selected, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final meta = categoryMeta[category]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: selected ? meta.color : colors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(meta.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.foreground))),
            if (selected) Icon(Icons.check_circle_rounded, size: 20, color: meta.color),
          ],
        ),
      ),
    );
  }
}
