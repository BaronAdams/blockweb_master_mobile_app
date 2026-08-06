import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

/// Direct port of store/useAppStore.ts. A single immutable state class +
/// a StateNotifier holding all the mutating actions, persisted to
/// SharedPreferences as one JSON blob on every change — the same "whole
/// store snapshot" persistence model as Zustand's `persist` middleware
/// (a distinct, Flutter-local storage key; there is no shared storage with
/// the RN app's AsyncStorage — the two apps don't carry each other's data).
class AppStoreState {
  final List<BlockedApp> blockedApps;
  final List<BlockedKeyword> blockedKeywords;
  final List<BlockedWebsite> blockedWebsites;
  final List<WhitelistedSite> whitelistedSites;
  final List<LimiterProfile> limiterProfiles;
  final List<DailyAnalytics> analytics;
  final StrictModeState strictMode;
  final UserPlan plan;
  final SubscriptionState subscription;
  final AppUser? user;
  final int? authCachedAt;
  final bool hasSeenPermissionsOnboarding;
  final bool hasCompletedOnboarding;
  final bool isAccessibilityEnabled;
  final bool isOverlayPermissionGranted;
  final bool isDeviceAdminActive;
  final LanguagePreference languagePreference;

  const AppStoreState({
    this.blockedApps = const [],
    this.blockedKeywords = const [],
    this.blockedWebsites = const [],
    this.whitelistedSites = const [],
    this.limiterProfiles = const [],
    this.analytics = const [],
    this.strictMode = StrictModeState.initial,
    this.plan = UserPlan.free,
    this.subscription = SubscriptionState.initial,
    this.user,
    this.authCachedAt,
    this.hasSeenPermissionsOnboarding = false,
    this.hasCompletedOnboarding = false,
    this.isAccessibilityEnabled = false,
    this.isOverlayPermissionGranted = false,
    this.isDeviceAdminActive = false,
    this.languagePreference = LanguagePreference.device,
  });

  AppStoreState copyWith({
    List<BlockedApp>? blockedApps,
    List<BlockedKeyword>? blockedKeywords,
    List<BlockedWebsite>? blockedWebsites,
    List<WhitelistedSite>? whitelistedSites,
    List<LimiterProfile>? limiterProfiles,
    List<DailyAnalytics>? analytics,
    StrictModeState? strictMode,
    UserPlan? plan,
    SubscriptionState? subscription,
    Object? user = _unset,
    Object? authCachedAt = _unset,
    bool? hasSeenPermissionsOnboarding,
    bool? hasCompletedOnboarding,
    bool? isAccessibilityEnabled,
    bool? isOverlayPermissionGranted,
    bool? isDeviceAdminActive,
    LanguagePreference? languagePreference,
  }) {
    return AppStoreState(
      blockedApps: blockedApps ?? this.blockedApps,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
      whitelistedSites: whitelistedSites ?? this.whitelistedSites,
      limiterProfiles: limiterProfiles ?? this.limiterProfiles,
      analytics: analytics ?? this.analytics,
      strictMode: strictMode ?? this.strictMode,
      plan: plan ?? this.plan,
      subscription: subscription ?? this.subscription,
      user: identical(user, _unset) ? this.user : user as AppUser?,
      authCachedAt: identical(authCachedAt, _unset) ? this.authCachedAt : authCachedAt as int?,
      hasSeenPermissionsOnboarding: hasSeenPermissionsOnboarding ?? this.hasSeenPermissionsOnboarding,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isAccessibilityEnabled: isAccessibilityEnabled ?? this.isAccessibilityEnabled,
      isOverlayPermissionGranted: isOverlayPermissionGranted ?? this.isOverlayPermissionGranted,
      isDeviceAdminActive: isDeviceAdminActive ?? this.isDeviceAdminActive,
      languagePreference: languagePreference ?? this.languagePreference,
    );
  }

  Map<String, dynamic> toJson() => {
        'blockedApps': blockedApps.map((a) => a.toJson()).toList(),
        'blockedKeywords': blockedKeywords.map((k) => k.toJson()).toList(),
        'blockedWebsites': blockedWebsites.map((w) => w.toJson()).toList(),
        'whitelistedSites': whitelistedSites.map((w) => w.toJson()).toList(),
        'limiterProfiles': limiterProfiles.map((p) => p.toJson()).toList(),
        'analytics': analytics.map((a) => a.toJson()).toList(),
        'strictMode': strictMode.toJson(),
        'plan': plan.name,
        'subscription': subscription.toJson(),
        'user': user?.toJson(),
        'authCachedAt': authCachedAt,
        'hasSeenPermissionsOnboarding': hasSeenPermissionsOnboarding,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'languagePreference': languagePreference.name,
        // Permission flags are intentionally NOT persisted — they're
        // refreshed from native on every app-state change (see the
        // hook that will call setAccessibilityEnabled etc. once the
        // native bridge is wired into a screen, phase 2 continuation)
        // and a stale "true" surviving a restart would be misleading.
      };

  factory AppStoreState.fromJson(Map<String, dynamic> json) => AppStoreState(
        blockedApps: (json['blockedApps'] as List? ?? [])
            .map((e) => BlockedApp.fromJson(e as Map<String, dynamic>))
            .toList(),
        blockedKeywords: (json['blockedKeywords'] as List? ?? [])
            .map((e) => BlockedKeyword.fromJson(e as Map<String, dynamic>))
            .toList(),
        blockedWebsites: (json['blockedWebsites'] as List? ?? [])
            .map((e) => BlockedWebsite.fromJson(e as Map<String, dynamic>))
            .toList(),
        whitelistedSites: (json['whitelistedSites'] as List? ?? [])
            .map((e) => WhitelistedSite.fromJson(e as Map<String, dynamic>))
            .toList(),
        limiterProfiles: (json['limiterProfiles'] as List? ?? [])
            .map((e) => LimiterProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
        analytics: (json['analytics'] as List? ?? [])
            .map((e) => DailyAnalytics.fromJson(e as Map<String, dynamic>))
            .toList(),
        strictMode: json['strictMode'] != null
            ? StrictModeState.fromJson(json['strictMode'] as Map<String, dynamic>)
            : StrictModeState.initial,
        plan: json['plan'] != null ? UserPlan.values.byName(json['plan'] as String) : UserPlan.free,
        subscription: json['subscription'] != null
            ? SubscriptionState.fromJson(json['subscription'] as Map<String, dynamic>)
            : SubscriptionState.initial,
        user: json['user'] != null ? AppUser.fromJson(json['user'] as Map<String, dynamic>) : null,
        authCachedAt: json['authCachedAt'] as int?,
        hasSeenPermissionsOnboarding: json['hasSeenPermissionsOnboarding'] as bool? ?? false,
        hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
        languagePreference: json['languagePreference'] != null
            ? LanguagePreference.values.byName(json['languagePreference'] as String)
            : LanguagePreference.device,
      );
}

const _unset = Object();

class AppStoreNotifier extends StateNotifier<AppStoreState> {
  static const _prefsKey = 'blockweb_master.app_state';
  static const _defaultSubscription = SubscriptionState.initial;

  AppStoreNotifier() : super(const AppStoreState()) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = AppStoreState.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt/incompatible persisted state — start fresh rather than crash.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(state.toJson()));
  }

  void _set(AppStoreState Function(AppStoreState) updater) {
    state = updater(state);
    _persist();
  }

  // ---- Blocked apps --------------------------------------------------

  void addBlockedApp(BlockedApp app) => _set((s) => s.copyWith(blockedApps: [...s.blockedApps, app]));

  /// Returns false (no-op) when Strict Mode blocks the removal — callers
  /// use that to surface a "can't remove while Strict Mode is active" toast.
  bool removeBlockedApp(String id) {
    if (state.strictMode.isActive) return false;
    _set((s) => s.copyWith(blockedApps: s.blockedApps.where((a) => a.id != id).toList()));
    return true;
  }

  void toggleBlockedApp(String id) => _set((s) => s.copyWith(
        blockedApps: s.blockedApps.map((a) => a.id == id ? a.copyWith(isBlocked: !a.isBlocked) : a).toList(),
      ));

  // ---- Keywords --------------------------------------------------------

  void addKeyword(String keyword) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _set((s) => s.copyWith(
          blockedKeywords: [...s.blockedKeywords, BlockedKeyword(id: '$now', keyword: keyword, addedAt: now)],
        ));
  }

  bool removeKeyword(String id) {
    if (state.strictMode.isActive) return false;
    _set((s) => s.copyWith(blockedKeywords: s.blockedKeywords.where((k) => k.id != id).toList()));
    return true;
  }

  // ---- Websites ----------------------------------------------------------

  void addBlockedWebsite(BlockedWebsite website) =>
      _set((s) => s.copyWith(blockedWebsites: [...s.blockedWebsites, website]));

  bool removeBlockedWebsite(String id) {
    if (state.strictMode.isActive) return false;
    _set((s) => s.copyWith(blockedWebsites: s.blockedWebsites.where((w) => w.id != id).toList()));
    return true;
  }

  void toggleBlockedWebsite(String id) => _set((s) => s.copyWith(
        blockedWebsites:
            s.blockedWebsites.map((w) => w.id == id ? w.copyWith(isBlocked: !w.isBlocked) : w).toList(),
      ));

  // ---- Whitelist -----------------------------------------------------

  void addWhitelistedSite(String domain) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _set((s) => s.copyWith(
          whitelistedSites: [...s.whitelistedSites, WhitelistedSite(id: '$now', domain: domain, addedAt: now)],
        ));
  }

  bool removeWhitelistedSite(String id) {
    if (state.strictMode.isActive) return false;
    _set((s) => s.copyWith(whitelistedSites: s.whitelistedSites.where((w) => w.id != id).toList()));
    return true;
  }

  // ---- Limiter profiles ------------------------------------------------

  void addProfile(LimiterProfile profile) =>
      _set((s) => s.copyWith(limiterProfiles: [...s.limiterProfiles, profile]));

  bool updateProfile(String id, LimiterProfile Function(LimiterProfile) updater) {
    if (state.strictMode.isActive) return false;
    _set((s) => s.copyWith(
          limiterProfiles: s.limiterProfiles.map((p) => p.id == id ? updater(p) : p).toList(),
        ));
    return true;
  }

  bool deleteProfile(String id) {
    if (state.strictMode.isActive) return false;
    _set((s) => s.copyWith(limiterProfiles: s.limiterProfiles.where((p) => p.id != id).toList()));
    return true;
  }

  void activateProfile(String id) => _set((s) => s.copyWith(
        limiterProfiles: s.limiterProfiles.map((p) => p.id == id ? p.copyWith(isActive: !p.isActive) : p).toList(),
      ));

  // ---- Analytics -------------------------------------------------------

  static String _todayKey() => DateTime.now().toIso8601String().split('T')[0];

  void recordUsage(String packageName, double minutes) {
    final today = _todayKey();
    _set((s) {
      final idx = s.analytics.indexWhere((a) => a.date == today);
      if (idx == -1) {
        return s.copyWith(analytics: [
          ...s.analytics,
          DailyAnalytics(date: today, appUsage: {packageName: minutes}, totalMinutes: minutes, blockedAttempts: 0),
        ]);
      }
      final existing = s.analytics[idx];
      final updated = DailyAnalytics(
        date: today,
        appUsage: {...existing.appUsage, packageName: (existing.appUsage[packageName] ?? 0) + minutes},
        totalMinutes: existing.totalMinutes + minutes,
        blockedAttempts: existing.blockedAttempts,
        hourlyUsage: existing.hourlyUsage,
      );
      final list = [...s.analytics];
      list[idx] = updated;
      return s.copyWith(analytics: list);
    });
  }

  DailyAnalytics? getTodayStats() {
    final today = _todayKey();
    try {
      return state.analytics.firstWhere((a) => a.date == today);
    } catch (_) {
      return null;
    }
  }

  /// Overwrites each day's per-app usage with the native accessibility
  /// service's totals — those are already cumulative for the day, so days
  /// present in `stats` are replaced, not added to, avoiding double-counting.
  /// `blockedAttempts` is preserved.
  void mergeUsageStats(Map<String, Map<String, double>> stats) {
    if (stats.isEmpty) return;
    _set((s) {
      final byDate = {for (final a in s.analytics) a.date: a};
      for (final entry in stats.entries) {
        final date = entry.key;
        final appUsage = entry.value;
        final totalMinutes = appUsage.values.fold(0.0, (sum, m) => sum + m);
        final existing = byDate[date];
        byDate[date] = DailyAnalytics(
          date: date,
          appUsage: appUsage,
          totalMinutes: totalMinutes,
          blockedAttempts: existing?.blockedAttempts ?? 0,
          hourlyUsage: existing?.hourlyUsage,
        );
      }
      final list = byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
      return s.copyWith(analytics: list);
    });
  }

  /// Same idea as mergeUsageStats but for the hour-bucketed breakdown.
  void mergeHourlyUsageStats(Map<String, Map<String, Map<String, double>>> stats) {
    if (stats.isEmpty) return;
    _set((s) {
      final byDate = {for (final a in s.analytics) a.date: a};
      for (final entry in stats.entries) {
        final date = entry.key;
        final existing = byDate[date];
        byDate[date] = DailyAnalytics(
          date: date,
          appUsage: existing?.appUsage ?? {},
          totalMinutes: existing?.totalMinutes ?? 0,
          blockedAttempts: existing?.blockedAttempts ?? 0,
          hourlyUsage: entry.value,
        );
      }
      final list = byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
      return s.copyWith(analytics: list);
    });
  }

  // ---- Strict mode -------------------------------------------------------

  void activateStrictMode(int seconds) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _set((s) => s.copyWith(
          strictMode: StrictModeState(
            isActive: true,
            activatedAt: now,
            expiresAt: now + seconds * 1000,
            durationSeconds: seconds,
          ),
        ));
  }

  void checkStrictExpiry() {
    final sm = state.strictMode;
    if (sm.isActive && sm.expiresAt != null && DateTime.now().millisecondsSinceEpoch >= sm.expiresAt!) {
      _set((s) => s.copyWith(strictMode: StrictModeState.initial));
    }
  }

  // ---- Auth / subscription ------------------------------------------

  void setUser(AppUser? user) => _set((s) => s.copyWith(user: user));

  /// Single source of truth for the user's plan — populated from Supabase's
  /// `subscriptions` table, never set locally.
  void setSubscription(SubscriptionState subscription) =>
      _set((s) => s.copyWith(subscription: subscription, plan: subscription.plan));

  /// Marks user/subscription as freshly confirmed against Supabase — starts
  /// the 7-day offline grace window.
  void setAuthCachedAt(int timestamp) => _set((s) => s.copyWith(authCachedAt: timestamp));

  void logout() => _set((s) => s.copyWith(
        user: null,
        plan: UserPlan.free,
        subscription: _defaultSubscription,
        authCachedAt: null,
      ));

  void completePermissionsOnboarding() => _set((s) => s.copyWith(hasSeenPermissionsOnboarding: true));
  void completeOnboarding() => _set((s) => s.copyWith(hasCompletedOnboarding: true));
  void setAccessibilityEnabled(bool enabled) => _set((s) => s.copyWith(isAccessibilityEnabled: enabled));
  void setOverlayPermissionGranted(bool granted) => _set((s) => s.copyWith(isOverlayPermissionGranted: granted));
  void setDeviceAdminActive(bool active) => _set((s) => s.copyWith(isDeviceAdminActive: active));

  void setLanguagePreference(LanguagePreference pref) => _set((s) => s.copyWith(languagePreference: pref));
}

final appStoreProvider = StateNotifierProvider<AppStoreNotifier, AppStoreState>(
  (ref) => AppStoreNotifier(),
);
