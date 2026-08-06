import 'app_models.dart';

/// Direct port of utils/limits.ts. `num` (not `int`) for the limit fields
/// so `double.infinity` — Dart's equivalent of JS's `Infinity` — can
/// represent "no cap" the same way the RN app does, and still compares
/// correctly against an int currentCount (`3 < double.infinity` is valid
/// Dart and evaluates true).
class TierLimits {
  final num maxBlockedApps;
  final num maxBlockedWebsites;
  final num maxKeywords;
  final num maxProfiles;
  final num maxAppsPerProfile;
  final int maxStrictDays;

  const TierLimits({
    required this.maxBlockedApps,
    required this.maxBlockedWebsites,
    required this.maxKeywords,
    required this.maxProfiles,
    required this.maxAppsPerProfile,
    required this.maxStrictDays,
  });
}

const _freeLimits = TierLimits(
  maxBlockedApps: 3,
  maxBlockedWebsites: 3,
  maxKeywords: 3,
  maxProfiles: 1,
  maxAppsPerProfile: 3,
  maxStrictDays: 1,
);

const _premiumLimits = TierLimits(
  maxBlockedApps: double.infinity,
  maxBlockedWebsites: double.infinity,
  maxKeywords: double.infinity,
  maxProfiles: double.infinity,
  maxAppsPerProfile: double.infinity,
  maxStrictDays: 30,
);

bool isPremium(UserPlan plan) => plan != UserPlan.free;

TierLimits limitsFor(UserPlan plan) => isPremium(plan) ? _premiumLimits : _freeLimits;

bool canAddBlockedApp(UserPlan plan, int currentCount) => currentCount < limitsFor(plan).maxBlockedApps;

bool canCreateProfile(UserPlan plan, int currentCount) => currentCount < limitsFor(plan).maxProfiles;

bool canAddBlockedWebsite(UserPlan plan, int currentCount) => currentCount < limitsFor(plan).maxBlockedWebsites;

bool canActivateStrictMode(UserPlan plan, int days) => days <= limitsFor(plan).maxStrictDays;

int maxStrictSecondsFor(UserPlan plan) => limitsFor(plan).maxStrictDays * 86400;
