import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/blocked_screen.dart';
import '../screens/onboarding/build_up_flow_screen.dart';
import '../screens/onboarding/paywall_screen.dart';
import '../screens/onboarding/permissions_screen.dart';
import '../screens/pricing_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tabs/analytics_screen.dart';
import '../screens/tabs/blocklists/apps_screen.dart';
import '../screens/tabs/blocklists/blocklists_index_screen.dart';
import '../screens/tabs/blocklists/keywords_screen.dart';
import '../screens/tabs/blocklists/websites_screen.dart';
import '../screens/tabs/blocklists/whitelist_screen.dart';
import '../screens/tabs/account_screen.dart';
import '../screens/tabs/strict_mode_screen.dart';
import '../screens/profiles/choose_type_screen.dart';
import '../screens/profiles/create_profile_screen.dart';
import '../screens/profiles/profile_detail_screen.dart';
import '../screens/profiles/profiles_list_screen.dart';
import '../state/app_store.dart';
import '../state/session_sync.dart';
import '../theme/app_theme.dart';

/// A ChangeNotifier that only exists to satisfy go_router's
/// `refreshListenable` — it re-evaluates `redirect` whenever notified,
/// which is how the gating below (onboarding/permissions/session) reacts
/// to store changes without recreating the GoRouter itself (recreating it
/// would blow away the navigation stack on every state change).
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final notifier = _RouterRefresh();
  ref.listen(sessionLoadedProvider, (_, __) => notifier.ping());
  ref.listen(appStoreProvider.select((s) => (s.hasCompletedOnboarding, s.hasSeenPermissionsOnboarding)), (_, __) => notifier.ping());
  return notifier;
});

/// Route map — a straight translation of the RN app's file-based routes
/// (app/(auth)/*, app/(tabs)/*, app/profiles/create/[type], app/blocked,
/// app/pricing) into go_router's declarative form, PLUS the gating logic
/// from app/_layout.tsx's RootLayoutNav (session load → onboarding →
/// permissions → tabs), reimplemented as a `redirect` callback instead of
/// RN's conditional-render tree — the idiomatic go_router way to do this,
/// and it composes cleanly with normal `context.go()` navigation instead
/// of needing a separate "pendingRoute" deferral mechanism the RN version
/// needed (see the `next` query param below for the one place that still
/// needs an explicit "where was I headed" handoff, across the permissions
/// gate).
///
/// initialLocation is the tabs shell, NOT /login: the RN app's
/// app/_layout.tsx never gates the tabs behind auth (see task history —
/// "Usage anonyme: retirer le mur d'authentification"). Login/register are
/// reachable but optional, reached from the Account screen. Font loading
/// (the RN version's other startup gate) has no Flutter equivalent —
/// fonts declared in pubspec.yaml are bundled at compile time, nothing to
/// wait on at runtime.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final sessionLoaded = ref.read(sessionLoadedProvider);
      if (!sessionLoaded) return loc == '/splash' ? null : '/splash';

      final store = ref.read(appStoreProvider);
      final onOnboardingRoute = loc.startsWith('/onboarding');

      if (loc == '/splash') {
        if (!store.hasCompletedOnboarding) return '/onboarding/build-up';
        if (!store.hasSeenPermissionsOnboarding) return '/onboarding/permissions';
        return '/';
      }
      if (!store.hasCompletedOnboarding) {
        return onOnboardingRoute ? null : '/onboarding/build-up';
      }
      if (!store.hasSeenPermissionsOnboarding) {
        if (loc == '/onboarding/permissions') return null;
        // Preserve where the user was headed (e.g. Paywall's "See Premium
        // plans" wants /pricing) so PermissionsScreen can continue there
        // once done, instead of always landing on the tabs.
        return '/onboarding/permissions?next=${Uri.encodeComponent(loc)}';
      }
      if (onOnboardingRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/onboarding/permissions', builder: (context, state) => const PermissionsScreen()),
      GoRoute(path: '/onboarding/build-up', builder: (context, state) => const BuildUpFlowScreen()),
      GoRoute(
        path: '/onboarding/paywall',
        builder: (context, state) => PaywallScreen(reclaimedHours: state.extra as int? ?? 0),
      ),
      GoRoute(path: '/pricing', builder: (context, state) => const PricingScreen()),
      GoRoute(
        path: '/blocked',
        builder: (context, state) => BlockedScreen(
          reason: state.uri.queryParameters['reason'] ?? 'app',
          value: state.uri.queryParameters['value'] ?? 'Instagram',
        ),
      ),
      // Outside the ShellRoute on purpose — like the RN app's Stack.Screen
      // siblings of (tabs), these render full-screen without the bottom nav.
      GoRoute(path: '/profiles/create', builder: (context, state) => const ChooseProfileTypeScreen()),
      GoRoute(
        path: '/profiles/create/:type',
        builder: (context, state) => CreateProfileScreen(typeParam: state.pathParameters['type'] ?? 'daily'),
      ),
      GoRoute(
        path: '/profiles/:id',
        builder: (context, state) => ProfileDetailScreen(id: state.pathParameters['id']!),
      ),

      ShellRoute(
        builder: (context, state, child) => _TabsShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const AnalyticsScreen()),
          GoRoute(path: '/blocklists', builder: (context, state) => const BlocklistsIndexScreen()),
          GoRoute(path: '/blocklists/apps', builder: (context, state) => const AppsScreen()),
          GoRoute(path: '/blocklists/keywords', builder: (context, state) => const KeywordsScreen()),
          GoRoute(path: '/blocklists/websites', builder: (context, state) => const WebsitesScreen()),
          GoRoute(path: '/blocklists/whitelist', builder: (context, state) => const WhitelistScreen()),
          GoRoute(path: '/profiles', builder: (context, state) => const ProfilesListScreen()),
          GoRoute(path: '/strictmode', builder: (context, state) => const StrictModeScreen()),
          GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
        ],
      ),
    ],
  );
});

class _TabsShell extends StatelessWidget {
  final Widget child;
  const _TabsShell({required this.child});

  static const _tabs = [
    (path: '/', icon: Icons.bar_chart_rounded, label: 'Analytics'),
    (path: '/blocklists', icon: Icons.block_rounded, label: 'Block Lists'),
    (path: '/profiles', icon: Icons.person_outline_rounded, label: 'Profiles'),
    (path: '/strictmode', icon: Icons.shield_outlined, label: 'Strict Mode'),
    (path: '/account', icon: Icons.settings_outlined, label: 'Account'),
  ];

  int _indexFor(String location) {
    final index = _tabs.indexWhere((t) => t.path == location || (t.path != '/' && location.startsWith(t.path)));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: colors.background,
      body: child,
      // Matches app/(tabs)/_layout.tsx's tabBarActiveTintColor (primary) /
      // tabBarInactiveTintColor (mutedForeground) — NavigationBar's default
      // Material3 theme colors selected/unselected icons too similarly, so
      // both icon and label are colored explicitly per destination instead
      // of relying on the ambient theme.
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected) ? colors.primary : colors.mutedForeground,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _indexFor(location),
          backgroundColor: colors.card,
          indicatorColor: colors.primary.withOpacity(0.15),
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.icon, color: colors.mutedForeground),
                selectedIcon: Icon(tab.icon, color: colors.primary),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
