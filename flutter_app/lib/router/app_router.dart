import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/placeholder_screen.dart';
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
import '../theme/app_theme.dart';

/// Route map — a straight translation of the RN app's file-based routes
/// (app/(auth)/*, app/(tabs)/*, app/profiles/create/[type], app/blocked,
/// app/pricing) into go_router's declarative form. Every screen is a
/// PlaceholderScreen until it's ported (phase 2) — this file's job is to
/// prove the navigation graph now, not to finish the app.
///
/// initialLocation is the tabs shell, NOT /login: the RN app's
/// app/_layout.tsx never gates the tabs behind auth (see task history —
/// "Usage anonyme: retirer le mur d'authentification"). Login/register are
/// reachable but optional, reached from the Account screen.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/onboarding/permissions', builder: (context, state) => const PlaceholderScreen(title: 'Permissions')),
    GoRoute(path: '/onboarding/build-up', builder: (context, state) => const PlaceholderScreen(title: 'Build Up')),
    GoRoute(path: '/onboarding/paywall', builder: (context, state) => const PlaceholderScreen(title: 'Paywall')),
    GoRoute(path: '/pricing', builder: (context, state) => const PlaceholderScreen(title: 'Pricing')),
    GoRoute(path: '/blocked', builder: (context, state) => const PlaceholderScreen(title: 'Blocked')),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        backgroundColor: colors.card,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final tab in _tabs) NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
