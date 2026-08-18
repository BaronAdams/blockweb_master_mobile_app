import '../models/app_models.dart';
import '../state/app_store.dart';

/// Decides which apps/domains/keywords a LimiterProfile is CURRENTLY
/// blocking, on top of the flat blockedApps/blockedWebsites/blockedKeywords
/// lists. Neither the RN app nor the original Flutter port ever computed
/// this anywhere — LimiterProfile carried limit/used-minutes fields and an
/// isActive flag, but nothing read them to decide what native should
/// actually enforce, so "scheduled" profiles never blocked anything no
/// matter how they were configured.
///
/// - daily/hourly/weekly: blocking starts once usedMinutes (kept fresh by
///   AppStoreNotifier.syncProfileUsage, computed from real tracked usage)
///   reaches the limit — i.e. the profile's apps/sites/keywords are exactly
///   as available as the plain "budget" describes, up to the limit, then
///   blocked until the next day/hour/week's usage window.
/// - interval: blocking is on for exactly the configured time-of-day
///   window on the configured days, independent of any usage — this one
///   doesn't need syncProfileUsage at all.
class ProfileBlockTargets {
  final Set<String> apps;
  final Set<String> domains;
  final Set<String> keywords;
  const ProfileBlockTargets({required this.apps, required this.domains, required this.keywords});
  static const empty = ProfileBlockTargets(apps: {}, domains: {}, keywords: {});
}

ProfileBlockTargets computeProfileBlockTargets(AppStoreState state, {DateTime? now}) {
  final apps = <String>{};
  final domains = <String>{};
  final keywords = <String>{};

  for (final profile in state.limiterProfiles) {
    if (!profile.isActive) continue;
    if (_isProfileBlocking(profile, now ?? DateTime.now())) {
      apps.addAll(profile.apps);
      domains.addAll(profile.websites);
      keywords.addAll(profile.keywords);
    }
  }

  return ProfileBlockTargets(apps: apps, domains: domains, keywords: keywords);
}

class ProfileCountdown {
  final String profileName;
  final int remainingMinutes;
  const ProfileCountdown({required this.profileName, required this.remainingMinutes});
}

/// For every app covered by an ACTIVE profile that isn't blocking it right
/// now but is about to, the countdown to show once the user is actually
/// inside that app:
/// - daily/hourly/weekly: minutes left in the usage budget.
/// - interval: minutes until today's configured window starts (nothing is
///   shown once the window has already started today — at that point the
///   profile is blocking, per _isProfileBlocking, so the user can't be
///   "inside" the app to see a countdown anyway; and nothing is shown for a
///   window later than today, to avoid multi-day-lookahead math for a
///   countdown that's only useful once it's actually imminent).
/// If more than one active profile covers the same package, the one
/// closest to triggering wins — that's the one about to actually matter to
/// the user.
Map<String, ProfileCountdown> computeProfileCountdowns(AppStoreState state, {DateTime? now}) {
  final result = <String, ProfileCountdown>{};
  final nowResolved = now ?? DateTime.now();

  void record(LimiterProfile profile, int remaining) {
    for (final pkg in profile.apps) {
      final existing = result[pkg];
      if (existing == null || remaining < existing.remainingMinutes) {
        result[pkg] = ProfileCountdown(profileName: profile.name, remainingMinutes: remaining);
      }
    }
  }

  for (final profile in state.limiterProfiles) {
    if (!profile.isActive) continue;
    if (_isProfileBlocking(profile, nowResolved)) continue;

    if (profile.type == LimiterType.interval) {
      final cfg = profile.intervalConfig;
      if (cfg == null) continue;
      if (!cfg.days.contains(DayOfWeek.values[nowResolved.weekday - 1])) continue;
      final start = _minutesOfDay(cfg.startTime);
      if (start == null) continue;
      final nowMinutes = nowResolved.hour * 60 + nowResolved.minute;
      if (start <= nowMinutes) continue;
      record(profile, start - nowMinutes);
      continue;
    }

    if (!_isActiveToday(profile, nowResolved)) continue;

    final (limit, used) = switch (profile.type) {
      LimiterType.daily => (profile.dailyLimitMinutes, profile.dailyUsedMinutes ?? 0),
      LimiterType.hourly => (profile.hourlyLimitMinutes, profile.hourlyUsedMinutes ?? 0),
      LimiterType.weekly => (profile.weeklyLimitMinutes, profile.weeklyUsedMinutes ?? 0),
      LimiterType.interval => (null, 0),
    };
    if (limit == null || limit <= 0) continue;
    final remaining = limit - used;
    if (remaining <= 0) continue;
    record(profile, remaining);
  }

  return result;
}

bool _isProfileBlocking(LimiterProfile profile, DateTime now) {
  switch (profile.type) {
    case LimiterType.daily:
      if (!_isActiveToday(profile, now)) return false;
      final limit = profile.dailyLimitMinutes;
      if (limit == null || limit <= 0) return false;
      return (profile.dailyUsedMinutes ?? 0) >= limit;
    case LimiterType.hourly:
      if (!_isActiveToday(profile, now)) return false;
      final limit = profile.hourlyLimitMinutes;
      if (limit == null || limit <= 0) return false;
      return (profile.hourlyUsedMinutes ?? 0) >= limit;
    case LimiterType.weekly:
      final limit = profile.weeklyLimitMinutes;
      if (limit == null || limit <= 0) return false;
      return (profile.weeklyUsedMinutes ?? 0) >= limit;
    case LimiterType.interval:
      final cfg = profile.intervalConfig;
      if (cfg == null) return false;
      if (!cfg.days.contains(DayOfWeek.values[now.weekday - 1])) return false;
      return _isWithinTimeRange(now, cfg.startTime, cfg.endTime);
  }
}

/// null/empty activeDays means "every day" (matches the "Leave empty = every
/// day" copy shown next to the day picker on daily/hourly profiles).
bool _isActiveToday(LimiterProfile profile, DateTime now) {
  final days = profile.activeDays;
  if (days == null || days.isEmpty) return true;
  return days.contains(DayOfWeek.values[now.weekday - 1]);
}

/// Minutes since midnight for a "HH:mm" string — returns null for anything
/// that doesn't parse (a free-text field, not a picker; defensively treated
/// as "not in range" rather than crashing).
int? _minutesOfDay(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

bool _isWithinTimeRange(DateTime now, String startTime, String endTime) {
  final start = _minutesOfDay(startTime);
  final end = _minutesOfDay(endTime);
  if (start == null || end == null) return false;
  final nowMinutes = now.hour * 60 + now.minute;
  if (start <= end) {
    // Same-day window, e.g. 09:00-17:30.
    return nowMinutes >= start && nowMinutes < end;
  }
  // Wraps past midnight, e.g. 22:00-06:00.
  return nowMinutes >= start || nowMinutes < end;
}
