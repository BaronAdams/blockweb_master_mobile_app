import 'dart:io';
import 'package:flutter/services.dart';

import '../models/installed_app.dart';

/// Dart-side port of modules/blocker/index.ts. Talks to the native Android
/// engine (android/app/.../blocker/BlockerBridge.kt — a straight Kotlin
/// port of the old Expo module of the same responsibilities) over a single
/// MethodChannel instead of an Expo native module. Same contract, same
/// "always degrade to a safe default instead of throwing" policy: every
/// call site in the RN app assumed this could silently no-op (missing
/// permission, non-Android platform, service not yet linked), and that
/// assumption carries over unchanged.
class BlockerBridge {
  BlockerBridge._();
  static const _channel = MethodChannel('com.blockwebmaster.app/blocker');

  static bool get _supported => Platform.isAndroid;

  static Future<bool> isAccessibilityServiceEnabled() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isOverlayPermissionGranted() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isOverlayPermissionGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBlockedPackages(List<String> packages) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('setBlockedPackages', {'packages': packages});
    } catch (_) {}
  }

  static Future<void> setBlockedDomains(List<String> domains) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('setBlockedDomains', {'domains': domains});
    } catch (_) {}
  }

  static Future<void> setBlockedKeywords(List<String> keywords) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('setBlockedKeywords', {'keywords': keywords});
    } catch (_) {}
  }

  /// { [date]: { [packageName]: minutes } }
  static Future<Map<String, Map<String, double>>> getUsageStats() async {
    if (!_supported) return {};
    try {
      final raw = await _channel.invokeMethod<Map>('getUsageStats');
      return _decodeNestedDoubleMap(raw);
    } catch (_) {
      return {};
    }
  }

  /// { [date]: { [hour]: { [packageName]: minutes } } }
  static Future<Map<String, Map<String, Map<String, double>>>> getHourlyUsageStats() async {
    if (!_supported) return {};
    try {
      final raw = await _channel.invokeMethod<Map>('getHourlyUsageStats');
      if (raw == null) return {};
      return raw.map((day, hours) => MapEntry(
            day as String,
            _decodeNestedDoubleMap(hours as Map?),
          ));
    } catch (_) {
      return {};
    }
  }

  static Future<bool> isDeviceAdminActive() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestDeviceAdmin(String explanation) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('requestDeviceAdmin', {'explanation': explanation});
    } catch (_) {}
  }

  /// Opens a system Settings screen by action string, e.g.
  /// "android.settings.ACCESSIBILITY_SETTINGS" — used by
  /// AccessibilityWarningBanner's "Enable" button.
  static Future<void> openAndroidSettings(String action) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('openAndroidSettings', {'action': action});
    } catch (_) {}
  }

  /// Pushes the block overlay's localized strings bundle — see
  /// lib/blockedScreenStrings.ts for the RN-side equivalent this needs to
  /// be re-implemented as once screens are ported (phase 2).
  static Future<void> setBlockScreenStrings(String json) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('setBlockScreenStrings', {'json': json});
    } catch (_) {}
  }

  /// Real installed-apps listing (Android only) — port of the RN app's
  /// react-native-launcher-kit usage in hooks/useInstalledApps.ts, done
  /// natively instead (see BlockerBridge.kt's getInstalledApps). Returns an
  /// empty list on iOS/web or on any native failure; callers fall back to a
  /// curated popular-apps list the same way the RN hook does — see
  /// lib/state/installed_apps.dart.
  static Future<List<InstalledApp>> getInstalledApps() async {
    if (!_supported) return [];
    try {
      final raw = await _channel.invokeMethod<List>('getInstalledApps');
      if (raw == null) return [];
      return raw
          .cast<Map>()
          .map((m) => InstalledApp(
                packageName: m['packageName'] as String,
                appName: m['appName'] as String,
                icon: m['icon'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, Map<String, double>> _decodeNestedDoubleMap(Map? raw) {
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(
          k as String,
          (v as Map).map((k2, v2) => MapEntry(k2 as String, (v2 as num).toDouble())),
        ));
  }
}
