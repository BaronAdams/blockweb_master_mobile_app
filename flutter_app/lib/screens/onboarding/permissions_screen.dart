import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../native/blocker_bridge.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

class _PermissionRow {
  final String key;
  final IconData icon;
  final String titleKey;
  final String descKey;
  final VoidCallback onEnable;
  _PermissionRow({required this.key, required this.icon, required this.titleKey, required this.descKey, required this.onEnable});
}

/// Port of components/PermissionsOnboarding.tsx. Every row here deep-links
/// to a system Settings screen via BlockerBridge.openAndroidSettings —
/// including notifications, unlike the RN version's real
/// Notifications.requestPermissionsAsync() runtime dialog. Wiring an
/// actual in-app permission request needs the Activity to implement
/// Flutter's PluginRegistry.RequestPermissionsResultListener, which isn't
/// set up yet; deep-linking to notification settings is a reasonable
/// stand-in for now and reuses the exact same mechanism as the other
/// three rows instead of adding a second, less-verified code path.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  final Set<String> _requested = {};

  void _markRequested(String key) => setState(() => _requested.add(key));

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('common', key);
    final notifier = ref.read(appStoreProvider.notifier);

    final rows = <_PermissionRow>[
      _PermissionRow(
        key: 'notifications',
        icon: Icons.notifications_outlined,
        titleKey: 'permissionsNotifTitle',
        descKey: 'permissionsNotifDesc',
        onEnable: () {
          _markRequested('notifications');
          BlockerBridge.openAndroidSettings('android.settings.APP_NOTIFICATION_SETTINGS');
        },
      ),
      if (Platform.isAndroid) ...[
        _PermissionRow(
          key: 'accessibility',
          icon: Icons.accessibility_new_rounded,
          titleKey: 'permissionsAccessibilityTitle',
          descKey: 'permissionsAccessibilityDesc',
          onEnable: () {
            _markRequested('accessibility');
            BlockerBridge.openAndroidSettings('android.settings.ACCESSIBILITY_SETTINGS');
          },
        ),
        _PermissionRow(
          key: 'usage',
          icon: Icons.visibility_outlined,
          titleKey: 'permissionsUsageTitle',
          descKey: 'permissionsUsageDesc',
          onEnable: () {
            _markRequested('usage');
            BlockerBridge.openAndroidSettings('android.settings.USAGE_ACCESS_SETTINGS');
          },
        ),
        _PermissionRow(
          key: 'overlay',
          icon: Icons.layers_outlined,
          titleKey: 'permissionsOverlayTitle',
          descKey: 'permissionsOverlayDesc',
          onEnable: () {
            _markRequested('overlay');
            BlockerBridge.openAndroidSettings('android.settings.action.MANAGE_OVERLAY_PERMISSION');
          },
        ),
      ],
    ];

    void onDone() {
      notifier.completePermissionsOnboarding();
      // Continues wherever the user was headed before the router's
      // redirect diverted them here (e.g. Paywall's "See Premium plans"
      // wants /pricing) — see router/app_router.dart's `next` param.
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      context.go(next != null && next.isNotEmpty ? Uri.decodeComponent(next) : '/');
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          children: [
            Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    border: Border.all(color: colors.primary.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.verified_user_outlined, size: 26, color: colors.primary),
                ),
                const SizedBox(height: 12),
                Text(t('permissionsTitle'), textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.foreground)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 320,
                  child: Text(t('permissionsIntro'), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: colors.mutedForeground)),
                ),
              ],
            ),
            const SizedBox(height: 28),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Icon(row.icon, size: 19, color: colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t(row.titleKey), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.foreground)),
                            const SizedBox(height: 2),
                            Text(t(row.descKey), style: TextStyle(fontSize: 11, height: 1.3, color: colors.mutedForeground)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _requested.contains(row.key)
                          ? OutlinedButton(
                              onPressed: row.onEnable,
                              style: OutlinedButton.styleFrom(side: BorderSide(color: colors.border), foregroundColor: colors.foreground),
                              child: Text(t('permissionsRequested'), style: const TextStyle(fontSize: 12)),
                            )
                          : ElevatedButton(
                              onPressed: row.onEnable,
                              style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: colors.primaryForeground),
                              child: Text(t('permissionsEnable'), style: const TextStyle(fontSize: 12)),
                            ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.primaryForeground,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(t('continue')),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onDone,
                child: Text(t('permissionsSkip'), style: TextStyle(color: colors.mutedForeground)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
