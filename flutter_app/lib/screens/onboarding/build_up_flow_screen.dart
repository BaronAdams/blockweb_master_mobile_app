import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/choice_card.dart';

enum _Step { welcome, stat, q1, q2, q3, q4, building, reveal }

const _progressSteps = [_Step.stat, _Step.q1, _Step.q2, _Step.q3, _Step.q4];
const _timeRangeHours = {'under1h': 0.5, 'oneToThree': 2.0, 'threeToFive': 4.0, 'over5h': 6.0};

/// Port of components/onboarding/BuildUpFlow.tsx — the first-launch
/// personalization "build up" flow. Reanimated spring/easing curves are
/// replaced with plain Flutter built-ins (TweenAnimationBuilder,
/// AnimatedSwitcher) — same beats (fade between steps, scale-in icon/stat,
/// progress bar, auto-advancing "building" step), not a pixel match of the
/// RN easing curves.
class BuildUpFlowScreen extends ConsumerStatefulWidget {
  const BuildUpFlowScreen({super.key});

  @override
  ConsumerState<BuildUpFlowScreen> createState() => _BuildUpFlowScreenState();
}

class _BuildUpFlowScreenState extends ConsumerState<BuildUpFlowScreen> {
  _Step _step = _Step.welcome;
  String? _app;
  String? _timeRange;
  String? _goal;
  int? _days;

  int get _reclaimedHours =>
      math.max(1, ((_timeRangeHours[_timeRange ?? 'oneToThree']!) * 7 * 0.6).round());

  void _goTo(_Step next) => setState(() => _step = next);

  void _selectAndAdvance(_Step next) {
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _goTo(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('onboarding', key, vars: vars);
    String tc(String key) => i18n.t('common', key);

    final progressIndex = _progressSteps.indexOf(_step);

    Widget content;
    switch (_step) {
      case _Step.welcome:
        content = _WelcomeStep(t: t, onNext: () => _goTo(_Step.stat));
      case _Step.stat:
        content = _StatStep(t: t, tc: tc, onNext: () => _goTo(_Step.q1));
      case _Step.q1:
        content = _QuestionStep(
          title: t('q1Title'),
          options: [('Instagram', t('q1Instagram')), ('TikTok', t('q1TikTok')), ('YouTube', t('q1YouTube')), ('other', t('q1Other'))],
          selected: _app,
          onSelect: (v) {
            setState(() => _app = v);
            _selectAndAdvance(_Step.q2);
          },
        );
      case _Step.q2:
        content = _QuestionStep(
          title: t('q2Title'),
          options: [
            ('under1h', t('q2Under1h')),
            ('oneToThree', t('q2OneToThree')),
            ('threeToFive', t('q2ThreeToFive')),
            ('over5h', t('q2Over5h')),
          ],
          selected: _timeRange,
          onSelect: (v) {
            setState(() => _timeRange = v);
            _selectAndAdvance(_Step.q3);
          },
        );
      case _Step.q3:
        content = _QuestionStep(
          title: t('q3Title'),
          options: [('sleep', t('q3Sleep')), ('productive', t('q3Productive')), ('people', t('q3People')), ('learn', t('q3Learn'))],
          selected: _goal,
          onSelect: (v) {
            setState(() => _goal = v);
            _selectAndAdvance(_Step.q4);
          },
        );
      case _Step.q4:
        content = _QuestionStep(
          title: t('q4Title'),
          options: [
            ('7', t('q4Days', {'count': 7})),
            ('14', t('q4Days', {'count': 14})),
            ('30', t('q4Days', {'count': 30})),
          ],
          selected: _days?.toString(),
          onSelect: (v) {
            setState(() => _days = int.parse(v));
            _selectAndAdvance(_Step.building);
          },
        );
      case _Step.building:
        content = _BuildingStep(t: t, onDone: () => _goTo(_Step.reveal));
      case _Step.reveal:
        content = _RevealStep(
          t: t,
          appLabel: _app == 'other' ? t('q1Other') : (_app ?? ''),
          days: _days ?? 7,
          reclaimedHours: _reclaimedHours,
          onNext: () => context.go('/onboarding/paywall', extra: _reclaimedHours),
        );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (progressIndex >= 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (progressIndex + 1) / _progressSteps.length),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(key: ValueKey(_step), child: content),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  const _StepLayout({required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          Expanded(child: Center(child: child)),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final String Function(String) t;
  final VoidCallback onNext;
  const _WelcomeStep({required this.t, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _StepLayout(
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.primaryForeground,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(t('welcomeCta')),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                border: Border.all(color: colors.primary.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.smartphone_outlined, size: 36, color: colors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(t('welcomeTitle'),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: colors.foreground)),
          const SizedBox(height: 10),
          SizedBox(
            width: 300,
            child: Text(t('welcomeSubtitle'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: colors.mutedForeground)),
          ),
        ],
      ),
    );
  }
}

class _StatStep extends StatelessWidget {
  final String Function(String) t;
  final String Function(String) tc;
  final VoidCallback onNext;
  const _StatStep({required this.t, required this.tc, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _StepLayout(
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.primaryForeground,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(tc('continue')),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Text(t('statValue'), style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: colors.primary)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 280,
            child: Text(t('statLabel'), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.4, color: colors.foreground)),
          ),
          const SizedBox(height: 8),
          Text(t('statSource'), style: TextStyle(fontSize: 11, color: colors.mutedForeground.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  final String title;
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _QuestionStep({required this.title, required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _StepLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w600, color: colors.foreground)),
          const SizedBox(height: 24),
          for (final (value, label) in options) ...[
            ChoiceCard(label: label, selected: selected == value, onPressed: () => onSelect(value)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _BuildingStep extends StatefulWidget {
  final String Function(String) t;
  final VoidCallback onDone;
  const _BuildingStep({required this.t, required this.onDone});

  @override
  State<_BuildingStep> createState() => _BuildingStepState();
}

class _BuildingStepState extends State<_BuildingStep> {
  int _statusIndex = 0;
  final _statusKeys = ['buildingStep1', 'buildingStep2', 'buildingStep3'];
  Timer? _t1, _t2, _t3;

  @override
  void initState() {
    super.initState();
    _t1 = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _statusIndex = 1);
    });
    _t2 = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _statusIndex = 2);
    });
    _t3 = Timer(const Duration(milliseconds: 2500), widget.onDone);
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    _t3?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _StepLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 40, color: colors.primary),
          const SizedBox(height: 24),
          Text(widget.t('buildingTitle'), textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.foreground)),
          const SizedBox(height: 24),
          Text(widget.t(_statusKeys[_statusIndex]), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2400),
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealStep extends StatelessWidget {
  final String Function(String, [Map<String, dynamic>?]) t;
  final String appLabel;
  final int days;
  final int reclaimedHours;
  final VoidCallback onNext;
  const _RevealStep({required this.t, required this.appLabel, required this.days, required this.reclaimedHours, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return _StepLayout(
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(t('planReadyCta')),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.primaryForeground,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up_rounded, size: 14, color: colors.primary),
                const SizedBox(width: 6),
                Text(t('planReadyBadge'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('${reclaimedHours}h', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: colors.primary)),
                const SizedBox(height: 8),
                Text(t('planReadyStat', {'hours': reclaimedHours}),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.foreground)),
                const SizedBox(height: 4),
                Text(t('planReadySummary', {'app': appLabel, 'days': days, 'hours': reclaimedHours}),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.4, color: colors.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
