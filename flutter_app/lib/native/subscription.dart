import '../models/app_models.dart';
import 'supabase_client.dart';

/// Port of lib/subscription.ts. Mirrors the Chrome extension's
/// lib/database.types.ts `subscriptions` table shape — do not redeclare
/// elsewhere.
const Map<String, UserPlan> _planMap = {
  'FREE': UserPlan.free,
  'MONTHLY': UserPlan.monthly,
  'YEARLY': UserPlan.yearly,
  'LIFETIME': UserPlan.lifetime,
};

/// Same rule as the extension's isSubActive(): lifetime never expires,
/// otherwise active while now <= expiresAt (or a grace period, if any).
bool _isSubActive(UserPlan plan, int? expiresAt, int? graceUntil) {
  if (plan == UserPlan.lifetime) return true;
  final now = DateTime.now().millisecondsSinceEpoch;
  if (expiresAt != null && now <= expiresAt) return true;
  if (graceUntil != null && now <= graceUntil) return true;
  return false;
}

/// Reads the real subscription plan from Supabase's `subscriptions` table
/// (RLS-scoped to the signed-in user) — the same source the Chrome
/// extension and the RN app use. Falls back to 'free' if no row exists.
/// Throws on a genuine query failure (network, RLS, malformed query) —
/// the caller (session_sync.dart) is the one that decides whether that
/// falls back to a cached plan during the offline grace period or signs
/// the user out for real; this function must never silently downgrade an
/// offline premium user to free by swallowing the error.
Future<SubscriptionState> fetchSubscription(String userId) async {
  final data = await supabase
      .from('subscriptions')
      .select('plan, is_valid, expires_at, grace_until')
      .eq('user_id', userId)
      .maybeSingle();

  if (data == null) return SubscriptionState.initial;

  final plan = _planMap[data['plan'] as String? ?? 'FREE'] ?? UserPlan.free;
  final expiresAt = data['expires_at'] != null ? DateTime.parse(data['expires_at'] as String).millisecondsSinceEpoch : null;
  final graceUntil = data['grace_until'] != null ? DateTime.parse(data['grace_until'] as String).millisecondsSinceEpoch : null;
  final active = (data['is_valid'] as bool? ?? false) && _isSubActive(plan, expiresAt, graceUntil);

  return SubscriptionState(plan: active ? plan : UserPlan.free, expiresAt: expiresAt, isValid: active);
}
