import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class _ReasonMeta {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descKey;
  final String badgeKey;
  final String reasonKey;
  const _ReasonMeta({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.descKey,
    required this.badgeKey,
    required this.reasonKey,
  });
}

const _reasonMeta = {
  'app': _ReasonMeta(icon: Icons.lock_outline_rounded, color: Color(0xFFFB7185), titleKey: 'restrictedAccess', descKey: 'focusDesc', badgeKey: 'focusBadge', reasonKey: 'keywordReason'),
  'keyword': _ReasonMeta(icon: Icons.lock_outline_rounded, color: Color(0xFFFB7185), titleKey: 'restrictedAccess', descKey: 'keywordDesc', badgeKey: 'keywordBadge', reasonKey: 'keywordReason'),
  'adult': _ReasonMeta(icon: Icons.shield_moon_outlined, color: Color(0xFFFB7185), titleKey: 'adultBlocked', descKey: 'adultDesc', badgeKey: 'adultBadge', reasonKey: 'adultReason'),
  'daily': _ReasonMeta(icon: Icons.wb_sunny_outlined, color: Color(0xFFFBBF24), titleKey: 'dailyTitle', descKey: 'dailyDesc', badgeKey: 'dailyBadge', reasonKey: 'dailyReason'),
  'hourly': _ReasonMeta(icon: Icons.access_time_rounded, color: Color(0xFF60A5FA), titleKey: 'hourlyTitle', descKey: 'hourlyDesc', badgeKey: 'hourlyBadge', reasonKey: 'hourlyReason'),
  'weekly': _ReasonMeta(icon: Icons.calendar_month_outlined, color: Color(0xFFA78BFA), titleKey: 'weeklyTitle', descKey: 'weeklyDesc', badgeKey: 'weeklyBadge', reasonKey: 'weeklyReason'),
  'interval': _ReasonMeta(icon: Icons.shield_outlined, color: Color(0xFFFB7185), titleKey: 'intervalTitle', descKey: 'intervalDesc', badgeKey: 'intervalBadge', reasonKey: 'intervalReason'),
};

const _quoteCount = 10;

/// Port of app/blocked.tsx — a JS-rendered blocked screen kept for parity
/// with the RN route table. NOTE: on Android, real app-block enforcement
/// no longer routes here at all — it's handled entirely natively by a
/// WebView overlay (see android/.../blocker/BlockOverlay.kt) that draws
/// directly on top of the blocked app without any Activity/route
/// involved. This screen exists only as a reachable route for parity /
/// possible future use (e.g. a "preview my block screen" settings entry),
/// not as part of the live blocking path.
class BlockedScreen extends ConsumerStatefulWidget {
  final String reason;
  final String value;
  const BlockedScreen({super.key, this.reason = 'app', this.value = 'Instagram'});

  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _glow;
  late final AnimationController _badge;
  late final AnimationController _dot;
  late final int _quoteIndex;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _badge = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _dot = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _quoteIndex = Random().nextInt(_quoteCount) + 1;
  }

  @override
  void dispose() {
    _float.dispose();
    _glow.dispose();
    _badge.dispose();
    _dot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('blocked', key, vars: vars);

    final meta = _reasonMeta[widget.reason] ?? _reasonMeta['app']!;
    final isProfileType = ['daily', 'hourly', 'weekly', 'interval'].contains(widget.reason);
    final description = isProfileType ? t(meta.descKey, {'name': widget.value}) : t(meta.descKey);
    final quote = t('quote_${_quoteIndex}_desc');
    final quoteAuthor = t('quote_${_quoteIndex}_author');

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (context, child) => Opacity(
                            opacity: 0.1 + _glow.value * 0.15,
                            child: Transform.scale(
                              scale: 0.95 + _glow.value * 0.15,
                              child: Container(width: 140, height: 140, decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle)),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _float,
                          builder: (context, child) => Transform.translate(offset: Offset(0, -12 * _float.value), child: child),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: colors.card.withOpacity(0.7),
                              border: Border.all(color: colors.border),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(meta.icon, size: 36, color: meta.color),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 0,
                          child: AnimatedBuilder(
                            animation: _badge,
                            builder: (context, child) => Transform.translate(offset: Offset(0, -4 * _badge.value), child: child),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.card,
                                border: Border.all(color: colors.border),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _dot,
                                    builder: (context, child) => Opacity(
                                      opacity: 1 - _dot.value * 0.6,
                                      child: Container(width: 5, height: 5, decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle)),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(t(meta.badgeKey), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: meta.color)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(t(meta.titleKey), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.foreground)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.45, color: colors.mutedForeground)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card.withOpacity(0.5),
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('securityDetails').toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: colors.mutedForeground)),
                        const SizedBox(height: 12),
                        _DetailRow(color: meta.color, label: widget.reason == 'keyword' ? t('detectedKeyword') : 'Application', value: widget.value),
                        const SizedBox(height: 12),
                        _DetailRow(color: meta.color, label: t('blockingReason'), value: t(meta.reasonKey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.primaryForeground,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(t('goBack')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/blocklists'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.border),
                        foregroundColor: colors.foreground,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(t('manageRules')),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('"$quote"',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colors.mutedForeground)),
                  if (quoteAuthor.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('— $quoteAuthor', style: TextStyle(fontSize: 11, color: colors.mutedForeground.withOpacity(0.7))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DetailRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: colors.mutedForeground))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: colors.foreground)),
      ],
    );
  }
}
