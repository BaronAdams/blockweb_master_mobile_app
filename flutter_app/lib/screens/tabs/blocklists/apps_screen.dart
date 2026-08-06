import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/app_models.dart';
import '../../../models/installed_app.dart';
import '../../../models/limits.dart';
import '../../../state/app_settings.dart';
import '../../../state/app_store.dart';
import '../../../state/installed_apps.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/accessibility_warning_banner.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/blocklist_ui.dart';
import '../../../widgets/section_title.dart';
import '../../../widgets/sub_screen_header.dart';

/// Port of app/(tabs)/blocklists/apps.tsx. Installed-apps picker: browse
/// every app on the phone (real apps + icons on Android, via
/// BlockerBridge.getInstalledApps — see lib/state/installed_apps.dart's
/// doc comment for the iOS/fallback story), tap to stage a selection, then
/// confirm to commit it as the blocked-apps set.
class AppsScreen extends ConsumerStatefulWidget {
  const AppsScreen({super.key});

  @override
  ConsumerState<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends ConsumerState<AppsScreen> {
  final _search = TextEditingController();
  Set<String>? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('blockLists', key, vars: vars);
    String tc(String key) => i18n.t('common', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);
    final installedAppsAsync = ref.watch(installedAppsProvider);

    // Staged selection, seeded once from the store's committed blocked
    // apps — matches the RN screen's `useState(() => new Set(...))` lazy
    // initializer (seed once, not on every store change).
    _selected ??= store.blockedApps.map((a) => a.packageName).toSet();
    final selected = _selected!;

    final limits = limitsFor(store.plan);
    final atLimit = !isPremium(store.plan) && selected.length >= limits.maxBlockedApps;
    final strictActive = store.strictMode.isActive;

    void onDelete(String id, String packageName) {
      notifier.removeBlockedApp(id);
      setState(() => selected.remove(packageName));
    }

    void toggle(String packageName) {
      setState(() {
        if (selected.contains(packageName)) {
          if (strictActive) return;
          selected.remove(packageName);
        } else {
          if (!isPremium(store.plan) && selected.length >= limits.maxBlockedApps) return;
          selected.add(packageName);
        }
      });
    }

    void onConfirm() {
      final installedApps = installedAppsAsync.value ?? [];
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final app in installedApps) {
        final isSelected = selected.contains(app.packageName);
        BlockedApp? existing;
        for (final b in store.blockedApps) {
          if (b.packageName == app.packageName) {
            existing = b;
            break;
          }
        }
        if (isSelected && existing == null) {
          notifier.addBlockedApp(BlockedApp(
            id: '$now-${app.packageName}',
            packageName: app.packageName,
            appName: app.appName,
            isBlocked: true,
            addedAt: now,
          ));
        } else if (!isSelected && existing != null) {
          notifier.removeBlockedApp(existing.id);
        }
      }
      context.pop();
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(title: t('applications')),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(t('applicationsDesc'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                  ),
                  AccessibilityWarningBanner(active: selected.isNotEmpty),
                  if (store.blockedApps.isNotEmpty) ...[
                    SectionTitle(t('blockedApps')),
                    for (final app in store.blockedApps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BlockListRow(
                          icon: AppIcon(
                            appName: app.appName,
                            icon: _findIcon(installedAppsAsync.value, app.packageName),
                            size: 28,
                          ),
                          label: app.appName,
                          locked: strictActive,
                          onRemove: strictActive ? null : () => onDelete(app.id, app.packageName),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: colors.foreground, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: t('searchApp'),
                      hintStyle: TextStyle(color: colors.mutedForeground),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.mutedForeground),
                      filled: true,
                      fillColor: colors.input,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: installedAppsAsync.when(
                      loading: () => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: colors.primary),
                            const SizedBox(height: 12),
                            Text(tc('loading'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                          ],
                        ),
                      ),
                      error: (err, st) => Center(child: Text(t('noApp'), style: TextStyle(color: colors.mutedForeground))),
                      data: (apps) {
                        final query = _search.text.toLowerCase();
                        final filtered = query.isEmpty
                            ? apps
                            : apps.where((a) => a.appName.toLowerCase().contains(query)).toList();
                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Text(t('noApp'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final app = filtered[index];
                            final isSelected = selected.contains(app.packageName);
                            final lockedByStrict = isSelected && strictActive;
                            final disabled = (!isSelected && atLimit) || lockedByStrict;
                            return Opacity(
                              opacity: disabled ? 0.4 : 1,
                              child: InkWell(
                                onTap: disabled ? null : () => toggle(app.packageName),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    border: Border.all(color: isSelected ? colors.primary : colors.border),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      AppIcon(appName: app.appName, icon: app.icon, size: 36),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(app.appName,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.foreground)),
                                      ),
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isSelected ? colors.primary : colors.border, width: 1.5),
                                          color: isSelected ? colors.primary : Colors.transparent,
                                        ),
                                        alignment: Alignment.center,
                                        child: isSelected ? Icon(Icons.check_rounded, size: 14, color: colors.primaryForeground) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.background, border: Border(top: BorderSide(color: colors.border))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.primaryForeground,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(t('confirmSelection', {'n': selected.length})),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _findIcon(List<InstalledApp>? apps, String packageName) {
    if (apps == null) return null;
    for (final a in apps) {
      if (a.packageName == packageName) return a.icon;
    }
    return null;
  }
}
