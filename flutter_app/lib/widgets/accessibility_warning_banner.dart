import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../native/blocker_bridge.dart';
import '../state/app_settings.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';

/// Port of components/AccessibilityWarningBanner.tsx. Surfaced wherever a
/// blocking rule exists but might not actually be enforced — two
/// independent things can be missing: the AccessibilityService itself, and
/// the "draw over other apps" permission (checked in that order, since
/// accessibility is the more fundamental one).
class AccessibilityWarningBanner extends ConsumerWidget {
  final bool active;
  const AccessibilityWarningBanner({super.key, required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid || !active) return const SizedBox.shrink();

    final store = ref.watch(appStoreProvider);
    if (store.isAccessibilityEnabled && store.isOverlayPermissionGranted) return const SizedBox.shrink();

    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('common', key);

    final missingAccessibility = !store.isAccessibilityEnabled;
    final message = missingAccessibility ? t('accessibilityDisabledWarning') : t('overlayDisabledWarning');
    final settingsAction = missingAccessibility
        ? 'android.settings.ACCESSIBILITY_SETTINGS'
        : 'android.settings.action.MANAGE_OVERLAY_PERMISSION';

    const red = Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: red.withOpacity(0.08),
        border: Border.all(color: red.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.shield_moon_outlined, size: 18, color: red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, height: 1.3, color: colors.foreground)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => BlockerBridge.openAndroidSettings(settingsAction),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.border),
              foregroundColor: colors.foreground,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(t('permissionsEnable'), style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
