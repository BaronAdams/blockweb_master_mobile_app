import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/i18n_service.dart';
import '../state/app_settings.dart';
import '../state/app_store.dart';
import 'block_screen_strings.dart';
import 'blocker_bridge.dart';
import 'profile_enforcement.dart';

/// Port of hooks/useAppMonitor.ts — bridges the store's blocklists/analytics
/// to the real native blocking engine (android/.../blocker/). Started once
/// from main.dart, for the lifetime of the app, the same fire-and-forget
/// static-service pattern as SessionSyncService.
///
/// - Pushes the current blocked apps/domains/keywords to native whenever
///   they change, so the AccessibilityService always enforces the latest
///   rules. WITHOUT this, native keeps enforcing whatever was last written
///   to SharedPreferences (nothing, on a fresh install) no matter what the
///   Dart-side blocklists say — this was previously never wired up, which
///   is why blocking silently did nothing.
/// - Also folds in whatever active LimiterProfiles are currently blocking
///   (see profile_enforcement.dart) — daily/hourly/weekly profiles once
///   their usage hits the limit, interval profiles during their configured
///   window — so "scheduled" profiles actually enforce anything, which
///   neither this port nor the original RN app ever did.
/// - Pushes the block overlay's localized strings bundle on init and
///   whenever the app's language changes, so BlockOverlay.kt's WebView has
///   real text to render instead of an empty strings bundle.
/// - Pulls real usage stats (daily + hourly) from native on init and
///   whenever the app returns to the foreground, merging them into the
///   store's analytics, and refreshes the accessibility/overlay/device-admin
///   permission flags the same way — previously never pulled either, so
///   Analytics always showed zero regardless of real native tracking.
class AppMonitorService {
  AppMonitorService._();

  static ProviderContainer? _container;
  // ignore: unused_field — kept alive for the app's lifetime, closed never
  // (matches SessionSyncService's auth subscription: a single static
  // service running for as long as the process does).
  static AppLifecycleListener? _lifecycleListener;
  static Timer? _periodicTimer;
  static String? _lastSyncedApps;
  static String? _lastSyncedDomains;
  static String? _lastSyncedKeywords;
  static String? _lastSyncedLanguage;

  /// Call once at startup with the app's ProviderContainer (see main.dart),
  /// alongside SessionSyncService.init.
  static void init(ProviderContainer container) {
    _container = container;

    container.listen<AppStoreState>(appStoreProvider, (previous, next) {
      _syncAll(next);
    }, fireImmediately: true);

    container.listen<I18nService>(i18nProvider, (previous, next) {
      _syncBlockScreenStrings(next);
    }, fireImmediately: true);

    _refresh();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) _refresh();
      },
    );

    // Interval-type profiles start/stop blocking purely because wall-clock
    // time passed (entering/exiting the configured window) or a
    // daily/hourly/weekly profile's usage crossed its limit — neither
    // happens via a store mutation the listener above would catch, so this
    // re-evaluates on a plain timer too.
    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final c = _container;
      if (c == null) return;
      c.read(appStoreProvider.notifier).syncProfileUsage();
      _syncAll(c.read(appStoreProvider));
    });
  }

  static void _syncAll(AppStoreState state) {
    final profileTargets = computeProfileBlockTargets(state);
    _syncBlockedApps(state, profileTargets.apps);
    _syncBlockedDomains(state, profileTargets.domains);
    _syncBlockedKeywords(state, profileTargets.keywords);
  }

  static void _syncBlockedApps(AppStoreState state, Set<String> profileApps) {
    final effective = <String>{
      ...state.blockedApps.where((a) => a.isBlocked).map((a) => a.packageName),
      ...profileApps,
    };
    final key = (effective.toList()..sort()).join(',');
    if (_lastSyncedApps == key) return;
    _lastSyncedApps = key;
    BlockerBridge.setBlockedPackages(key.isEmpty ? [] : key.split(','));
  }

  static void _syncBlockedDomains(AppStoreState state, Set<String> profileDomains) {
    final effective = <String>{
      ...state.blockedWebsites.where((w) => w.isBlocked).map((w) => w.domain),
      ...profileDomains,
    };
    final key = (effective.toList()..sort()).join(',');
    if (_lastSyncedDomains == key) return;
    _lastSyncedDomains = key;
    BlockerBridge.setBlockedDomains(key.isEmpty ? [] : key.split(','));
  }

  static void _syncBlockedKeywords(AppStoreState state, Set<String> profileKeywords) {
    final effective = <String>{
      ...state.blockedKeywords.map((k) => k.keyword),
      ...profileKeywords,
    };
    final key = (effective.toList()..sort()).join(',');
    if (_lastSyncedKeywords == key) return;
    _lastSyncedKeywords = key;
    BlockerBridge.setBlockedKeywords(key.isEmpty ? [] : key.split(','));
  }

  static void _syncBlockScreenStrings(I18nService i18n) {
    if (_lastSyncedLanguage == i18n.language) return;
    _lastSyncedLanguage = i18n.language;
    BlockerBridge.setBlockScreenStrings(buildBlockScreenStringsJson(i18n));
  }

  static Future<void> _refresh() async {
    final container = _container;
    if (container == null) return;

    final enabled = await BlockerBridge.isAccessibilityServiceEnabled();
    final overlayGranted = await BlockerBridge.isOverlayPermissionGranted();
    final deviceAdminActive = await BlockerBridge.isDeviceAdminActive();
    final stats = await BlockerBridge.getUsageStats();
    final hourlyStats = await BlockerBridge.getHourlyUsageStats();

    final notifier = container.read(appStoreProvider.notifier);
    notifier.setAccessibilityEnabled(enabled);
    notifier.setOverlayPermissionGranted(overlayGranted);
    notifier.setDeviceAdminActive(deviceAdminActive);
    if (stats.isNotEmpty) notifier.mergeUsageStats(stats);
    if (hourlyStats.isNotEmpty) notifier.mergeHourlyUsageStats(hourlyStats);
    // Recomputes profile usedMinutes from whatever analytics just landed —
    // the appStoreProvider listener above then re-syncs blocking on its own
    // once this mutates state.
    notifier.syncProfileUsage();
  }
}
