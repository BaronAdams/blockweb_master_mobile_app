import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/placeholder_screen.dart';
import '../theme/app_theme.dart';

/// Route map — a straight translation of the RN app's file-based routes
/// (app/(auth)/*, app/(tabs)/*, app/profiles/create/[type], app/blocked,
/// app/pricing) into go_router's declarative form. Every screen is a
/// PlaceholderScreen until it's ported (phase 2) — this file's job is to
/// prove the navigation graph now, not to finish the app.
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const PlaceholderScreen(title: 'Login')),
    GoRoute(path: '/register', builder: (context, state) => const PlaceholderScreen(title: 'Register')),
    GoRoute(path: '/onboarding/permissions', builder: (context, state) => const PlaceholderScreen(title: 'Permissions')),
    GoRoute(path: '/onboarding/build-up', builder: (context, state) => const PlaceholderScreen(title: 'Build Up')),
    GoRoute(path: '/onboarding/paywall', builder: (context, state) => const PlaceholderScreen(title: 'Paywall')),
    GoRoute(path: '/pricing', builder: (context, state) => const PlaceholderScreen(title: 'Pricing')),
    GoRoute(path: '/blocked', builder: (context, state) => const PlaceholderScreen(title: 'Blocked')),
    GoRoute(
      path: '/profiles/type',
      builder: (context, state) => const PlaceholderScreen(title: 'Choose profile type'),
    ),
    GoRoute(
      path: '/profiles/create/:type',
      builder: (context, state) => PlaceholderScreen(title: 'Create profile — ${state.pathParameters['type']}'),
    ),

    ShellRoute(
      builder: (context, state, child) => _TabsShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const PlaceholderScreen(title: 'Analytics')),
        GoRoute(path: '/blocklists', builder: (context, state) => const PlaceholderScreen(title: 'Block Lists')),
        GoRoute(path: '/blocklists/apps', builder: (context, state) => const PlaceholderScreen(title: 'Blocked Apps')),
        GoRoute(path: '/blocklists/keywords', builder: (context, state) => const PlaceholderScreen(title: 'Blocked Keywords')),
        GoRoute(path: '/blocklists/websites', builder: (context, state) => const PlaceholderScreen(title: 'Blocked Websites')),
        GoRoute(path: '/blocklists/whitelist', builder: (context, state) => const PlaceholderScreen(title: 'Whitelist')),
        GoRoute(path: '/profiles', builder: (context, state) => const PlaceholderScreen(title: 'Limiter Profiles')),
        GoRoute(path: '/strictmode', builder: (context, state) => const PlaceholderScreen(title: 'Strict Mode')),
        GoRoute(path: '/account', builder: (context, state) => const PlaceholderScreen(title: 'Account')),
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
