import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';
import '../native/subscription.dart';
import '../native/supabase_client.dart';
import 'app_store.dart';

/// Port of app/_layout.tsx's RootLayoutNav session-sync effect. True once
/// the initial Supabase session check has resolved (success or handled
/// failure) — the router's redirect logic (see router/app_router.dart)
/// shows a splash screen until this flips true, then routes onward.
final sessionLoadedProvider = StateProvider<bool>((ref) => false);

const _sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

/// Mirrors the Chrome extension's syncAuth: a network failure must never
/// sign the user out.
bool _isNetworkError(Object err) {
  final msg = err.toString().toLowerCase();
  return msg.contains('fetch') || msg.contains('network') || msg.contains('failed') || msg.contains('offline') || msg.contains('socket');
}

class SessionSyncService {
  SessionSyncService._();

  static StreamSubscription<AuthState>? _authSub;

  /// Call once at startup with the app's ProviderContainer (see main.dart)
  /// — a no-op (session immediately marked "loaded", no user) if Supabase
  /// isn't configured, matching the RN app's "usage works anonymously"
  /// posture when there's nothing to sync against.
  static Future<void> init(ProviderContainer container) async {
    if (!isSupabaseConfigured) {
      container.read(sessionLoadedProvider.notifier).state = true;
      return;
    }

    Future<void> syncUser(Session? session) async {
      final notifier = container.read(appStoreProvider.notifier);
      final user = session?.user;
      if (user == null) {
        notifier.logout();
        return;
      }
      final email = user.email ?? '';
      notifier.setUser(AppUser(email: email, username: email.isNotEmpty ? email.split('@').first : ''));
      // Real plan always comes from Supabase's `subscriptions` table — may
      // throw on a network failure; handleSyncError below decides what to
      // do with that.
      final subscription = await fetchSubscription(user.id);
      notifier.setSubscription(subscription);
      notifier.setAuthCachedAt(DateTime.now().millisecondsSinceEpoch);
    }

    // A network failure falls back to whatever is already cached in the
    // store (from the last successful sync) as long as it's less than 7
    // days old — otherwise, or on a confirmed invalid session, sign out
    // for real.
    void handleSyncError(Object err) {
      final store = container.read(appStoreProvider);
      final withinGrace =
          store.user != null && store.authCachedAt != null && DateTime.now().millisecondsSinceEpoch - store.authCachedAt! < _sevenDaysMs;
      if (_isNetworkError(err) && withinGrace) return;
      container.read(appStoreProvider.notifier).logout();
    }

    try {
      await syncUser(supabase.auth.currentSession);
    } catch (e) {
      handleSyncError(e);
    } finally {
      container.read(sessionLoadedProvider.notifier).state = true;
    }

    _authSub?.cancel();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      syncUser(data.session).catchError(handleSyncError);
    });
  }
}
