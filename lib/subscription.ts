import { supabase } from '@/lib/supabase'
import type { SubscriptionState, UserPlan } from '@/types'

// Mirrors the Chrome extension's lib/database.types.ts — single source of
// truth for the `subscriptions` table shape. Do not redeclare elsewhere.
type SupabasePlan = 'FREE' | 'MONTHLY' | 'YEARLY' | 'LIFETIME'

const PLAN_MAP: Record<SupabasePlan, UserPlan> = {
  FREE: 'free',
  MONTHLY: 'monthly',
  YEARLY: 'yearly',
  LIFETIME: 'lifetime',
}

const DEFAULT_SUBSCRIPTION: SubscriptionState = { plan: 'free', expiresAt: null, isValid: true }

/** Same rule as the extension's isSubActive(): lifetime never expires,
 *  otherwise active while now <= expiresAt (or a grace period, if any). */
function isSubActive(plan: UserPlan, expiresAt: number | null, graceUntil: number | null): boolean {
  if (plan === 'lifetime') return true
  const now = Date.now()
  if (expiresAt !== null && now <= expiresAt) return true
  if (graceUntil !== null && now <= graceUntil) return true
  return false
}

/** Reads the real subscription plan from Supabase's `subscriptions` table
 *  (RLS-scoped to the signed-in user), the same source the Chrome extension
 *  uses. Falls back to 'free' if no row exists or the plan has expired.
 *
 *  `maybeSingle()` returns `data: null, error: null` for a genuine "no
 *  subscription row" — so `error` set here means something actually went
 *  wrong (RLS, malformed query, or the network being down). A network
 *  failure must not be reported as "no subscription": that would silently
 *  downgrade an offline premium user to free. So it's thrown instead,
 *  letting the caller (app/_layout.tsx) fall back to the cached plan
 *  during its own offline grace period — only a confirmed empty result is
 *  treated as a real free user. */
export async function fetchSubscription(userId: string): Promise<SubscriptionState> {
  const { data, error } = await supabase
    .from('subscriptions')
    .select('plan, is_valid, expires_at, grace_until')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) throw error
  if (!data) return DEFAULT_SUBSCRIPTION

  const plan = PLAN_MAP[data.plan as SupabasePlan] ?? 'free'
  const expiresAt = data.expires_at ? new Date(data.expires_at).getTime() : null
  const graceUntil = data.grace_until ? new Date(data.grace_until).getTime() : null
  const active = Boolean(data.is_valid) && isSubActive(plan, expiresAt, graceUntil)

  return {
    plan: active ? plan : 'free',
    expiresAt,
    isValid: active,
  }
}
