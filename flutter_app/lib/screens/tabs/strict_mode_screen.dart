import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/limits.dart';
import '../../native/blocker_bridge.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accessibility_warning_banner.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_header.dart';
import '../../widgets/countdown_cell.dart';
import '../../widgets/faq_accordion.dart';
import '../../widgets/section_title.dart';

const _red = Color(0xFFF43F5E);
const _green = Color(0xFF34D399);

class _Remaining {
  final int days, hours, minutes, seconds;
  const _Remaining(this.days, this.hours, this.minutes, this.seconds);
}

/// Port of app/(tabs)/strictmode.tsx.
class StrictModeScreen extends ConsumerStatefulWidget {
  const StrictModeScreen({super.key});

  @override
  ConsumerState<StrictModeScreen> createState() => _StrictModeScreenState();
}

class _StrictModeScreenState extends ConsumerState<StrictModeScreen> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late final AnimationController _pulseController;

  int _extraDays = 0;
  int _hours = 1;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    // checkStrictExpiry mirrors useStrictMode's own 60s interval — run it
    // once on mount, then every second alongside the countdown tick below
    // (cheap no-op when not active or not yet expired).
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(appStoreProvider.notifier).checkStrictExpiry());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(appStoreProvider.notifier).checkStrictExpiry();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  _Remaining? _remainingTime(DateTime now) {
    final strictMode = ref.read(appStoreProvider).strictMode;
    if (!strictMode.isActive || strictMode.expiresAt == null) return null;
    final diff = strictMode.expiresAt! - now.millisecondsSinceEpoch;
    if (diff <= 0) return null;
    return _Remaining(
      diff ~/ (86400 * 1000),
      (diff % (86400 * 1000)) ~/ (3600 * 1000),
      (diff % (3600 * 1000)) ~/ (60 * 1000),
      (diff % (60 * 1000)) ~/ 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('strictMode', key);
    String tc(String key) => i18n.t('common', key);
    String tp(String key) => i18n.t('profiles', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final isActive = store.strictMode.isActive;
    final remaining = _remainingTime(DateTime.now());
    final premium = isPremium(store.plan);
    final maxSeconds = maxStrictSecondsFor(store.plan);
    final maxDaysExtraRaw = (maxSeconds ~/ 86400) - 1;
    final maxDaysExtra = maxDaysExtraRaw < 0 ? 0 : maxDaysExtraRaw;

    final rawTotalSeconds = _extraDays * 86400 + _hours * 3600 + _minutes * 60 + _seconds;
    final totalSeconds = rawTotalSeconds > maxSeconds ? maxSeconds : rawTotalSeconds;
    final canActivate = totalSeconds > 0;

    final restrictions = [t('r1'), t('r2'), tp('unableDeactivateStrict'), t('uninstallRestriction')];
    const restrictionIcons = [Icons.delete_outline_rounded, Icons.edit_outlined, Icons.gpp_bad_outlined, Icons.block_rounded];

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                AccessibilityWarningBanner(active: isActive || store.blockedApps.isNotEmpty),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('title'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.foreground)),
                    _StatusBadge(isActive: isActive, pulse: _pulseController, label: isActive ? t('activeShrt') : t('inactiveShrt')),
                  ],
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionTitle(t('restrictions')),
                    for (int i = 0; i < restrictions.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Icon(restrictionIcons[i], size: 14, color: _red),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(restrictions[i], style: TextStyle(fontSize: 12, color: colors.foreground))),
                          ],
                        ),
                      ),
                  ],
                ),
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 20),
                  _DeviceAdminCard(active: store.isDeviceAdminActive, t: t),
                ],
                const SizedBox(height: 20),
                if (isActive && remaining != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      border: Border.all(color: _red.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusBadge(isActive: true, pulse: _pulseController, label: t('active'), destructive: true),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CountdownCell(value: remaining.days, label: tc('days')),
                            const SizedBox(width: 8),
                            CountdownCell(value: remaining.hours, label: tc('hours')),
                            const SizedBox(width: 8),
                            CountdownCell(value: remaining.minutes, label: tc('minutes')),
                            const SizedBox(width: 8),
                            CountdownCell(value: remaining.seconds, label: tc('seconds')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(t('willDeactivate'),
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.05),
                      border: Border.all(color: colors.primary.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.hourglass_empty_rounded, size: 16, color: colors.primary),
                          const SizedBox(width: 8),
                          Text(t('activate'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.foreground)),
                        ]),
                        const SizedBox(height: 4),
                        Text(t('desc'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                        const SizedBox(height: 16),
                        Text(t('duration').toUpperCase(),
                            style: TextStyle(fontSize: 11, letterSpacing: 0.5, color: colors.mutedForeground)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (premium) ...[
                              Expanded(
                                child: _UnitPicker(
                                  value: _extraDays,
                                  max: maxDaysExtra,
                                  suffix: tc('dayShrt'),
                                  onChanged: (v) => setState(() => _extraDays = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: _UnitPicker(value: _hours, max: 23, suffix: tc('hourShrt'), onChanged: (v) => setState(() => _hours = v)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _UnitPicker(value: _minutes, max: 59, suffix: tc('minuteShrt'), onChanged: (v) => setState(() => _minutes = v)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _UnitPicker(value: _seconds, max: 59, suffix: tc('secondShrt'), onChanged: (v) => setState(() => _seconds = v)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.08),
                            border: Border.all(color: _red.withOpacity(0.15)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 14, color: _red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t('onceActivated').replaceAll(RegExp(r'<[^>]+>'), ''),
                                  style: TextStyle(fontSize: 11, height: 1.3, color: colors.foreground),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: canActivate ? () => notifier.activateStrictMode(totalSeconds) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.primaryForeground,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(t('activate')),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SectionTitle(t('tipsTitle')),
                FaqAccordion(
                  items: [
                    for (final key in ['tip1', 'tip2', 'tip3', 'tip4'])
                      FaqItem(id: key, question: t('${key}Title'), answer: t('${key}Desc')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final AnimationController pulse;
  final String label;
  final bool destructive;
  const _StatusBadge({required this.isActive, required this.pulse, required this.label, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final active = isActive || destructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? _red : Colors.transparent,
        border: active ? null : Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active)
            FadeTransition(
              opacity: pulse,
              child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ),
          if (active) const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : colors.primary)),
        ],
      ),
    );
  }
}

class _DeviceAdminCard extends StatelessWidget {
  final bool active;
  final String Function(String) t;
  const _DeviceAdminCard({required this.active, required this.t});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final color = active ? _green : _red;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(active ? Icons.verified_user_outlined : Icons.gpp_bad_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active ? t('deviceAdminActive') : t('deviceAdminInactive'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.foreground)),
                if (!active) ...[
                  const SizedBox(height: 2),
                  Text(t('deviceAdminDesc'), style: TextStyle(fontSize: 11, height: 1.3, color: colors.mutedForeground)),
                ],
              ],
            ),
          ),
          if (!active)
            OutlinedButton(
              onPressed: () => BlockerBridge.requestDeviceAdmin(t('deviceAdminExplanation')),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.border),
                foregroundColor: colors.foreground,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(t('deviceAdminEnable'), style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _UnitPicker extends StatelessWidget {
  final int value;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;
  const _UnitPicker({required this.value, required this.max, required this.suffix, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: colors.card,
          style: TextStyle(fontSize: 13, color: colors.foreground),
          items: [
            for (int i = 0; i <= max; i++)
              DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}$suffix')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
