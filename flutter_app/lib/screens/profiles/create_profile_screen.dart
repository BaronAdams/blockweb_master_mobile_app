import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_models.dart';
import '../../models/limits.dart';
import '../../models/profile_types.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../state/installed_apps.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_input.dart';
import '../../widgets/blocklist_ui.dart';
import '../../widgets/section_title.dart';
import '../../widgets/sub_screen_header.dart';

const List<(DayOfWeek, String)> _days = [
  (DayOfWeek.mon, 'Mon'),
  (DayOfWeek.tue, 'Tue'),
  (DayOfWeek.wed, 'Wed'),
  (DayOfWeek.thu, 'Thu'),
  (DayOfWeek.fri, 'Fri'),
  (DayOfWeek.sat, 'Sat'),
  (DayOfWeek.sun, 'Sun'),
];

const Map<LimiterType, String> _limitKeyByType = {
  LimiterType.daily: 'dailyLimit',
  LimiterType.hourly: 'hourlyLimit',
  LimiterType.weekly: 'weeklyLimit',
};

/// Port of app/profiles/create/[type].tsx.
class CreateProfileScreen extends ConsumerStatefulWidget {
  final String typeParam;
  const CreateProfileScreen({super.key, required this.typeParam});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _name = TextEditingController();
  final _websiteInput = TextEditingController();
  final _keywordInput = TextEditingController();
  final _limitMinutes = TextEditingController(text: '60');
  final _startTime = TextEditingController(text: '09:00');
  final _endTime = TextEditingController(text: '17:30');

  final List<String> _websites = [];
  final List<String> _keywords = [];
  final Set<String> _selectedApps = {};
  List<DayOfWeek> _selectedDays = [DayOfWeek.mon, DayOfWeek.tue, DayOfWeek.wed, DayOfWeek.thu, DayOfWeek.fri];

  @override
  void initState() {
    super.initState();
    // canSubmit depends on _name.text — rebuild as the user types so the
    // Create button's enabled state stays live, matching the RN screen's
    // `useState` reactivity.
    _name.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _websiteInput.dispose();
    _keywordInput.dispose();
    _limitMinutes.dispose();
    _startTime.dispose();
    _endTime.dispose();
    super.dispose();
  }

  LimiterType get _type {
    try {
      return LimiterType.values.byName(widget.typeParam);
    } catch (_) {
      return LimiterType.daily;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('profiles', key);
    String tb(String key) => i18n.t('blockLists', key);
    String tc(String key) => i18n.t('common', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final meta = profileTypeMeta[_type]!;
    final limits = limitsFor(store.plan);
    final totalElements = _selectedApps.length + _websites.length + _keywords.length;
    final atLimit = !isPremium(store.plan) && totalElements >= limits.maxAppsPerProfile;
    final canSubmit = _name.text.trim().isNotEmpty && totalElements > 0;
    final installedAppsAsync = ref.watch(installedAppsProvider);

    void toggleApp(String packageName) {
      setState(() {
        if (_selectedApps.contains(packageName)) {
          _selectedApps.remove(packageName);
        } else {
          if (!isPremium(store.plan) && totalElements >= limits.maxAppsPerProfile) return;
          _selectedApps.add(packageName);
        }
      });
    }

    void addWebsite() {
      if (atLimit) return;
      final trimmed = _websiteInput.text.trim().toLowerCase();
      if (trimmed.isEmpty || _websites.contains(trimmed)) return;
      setState(() {
        _websites.add(trimmed);
        _websiteInput.clear();
      });
    }

    void addKeyword() {
      if (atLimit) return;
      final trimmed = _keywordInput.text.trim();
      if (trimmed.isEmpty || _keywords.contains(trimmed)) return;
      setState(() {
        _keywords.add(trimmed);
        _keywordInput.clear();
      });
    }

    void toggleDay(DayOfWeek day) {
      setState(() {
        _selectedDays = _selectedDays.contains(day)
            ? _selectedDays.where((d) => d != day).toList()
            : [..._selectedDays, day];
      });
    }

    void onSubmit() {
      if (!canSubmit) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final limitMinutes = int.tryParse(_limitMinutes.text) ?? (_type == LimiterType.hourly ? 30 : 60);

      notifier.addProfile(LimiterProfile(
        id: '$now',
        name: _name.text.trim(),
        type: _type,
        apps: _selectedApps.toList(),
        websites: _websites,
        keywords: _keywords,
        isActive: true,
        createdAt: now,
        dailyLimitMinutes: _type == LimiterType.daily ? limitMinutes : null,
        dailyUsedMinutes: _type == LimiterType.daily ? 0 : null,
        dailyResetAt: _type == LimiterType.daily ? now : null,
        hourlyLimitMinutes: _type == LimiterType.hourly ? limitMinutes : null,
        hourlyUsedMinutes: _type == LimiterType.hourly ? 0 : null,
        weeklyLimitMinutes: _type == LimiterType.weekly ? limitMinutes : null,
        weeklyUsedMinutes: _type == LimiterType.weekly ? 0 : null,
        weeklyResetAt: _type == LimiterType.weekly ? now : null,
        intervalConfig: _type == LimiterType.interval
            ? IntervalConfig(startTime: _startTime.text, endTime: _endTime.text, days: _selectedDays)
            : null,
      ));

      while (context.canPop()) {
        context.pop();
      }
      context.go('/profiles');
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(title: t(meta.labelKey)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 60),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: meta.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Icon(meta.icon, size: 18, color: meta.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t(meta.createDescKey), style: TextStyle(fontSize: 12, height: 1.3, color: colors.mutedForeground)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionTitle(t('profileName')),
                AppInput(icon: Icons.badge_outlined, placeholder: t('namePlaceholder'), controller: _name, textCapitalization: TextCapitalization.sentences),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionTitle(tb('applications')),
                    LimitBadge(count: totalElements, max: isPremium(store.plan) ? double.infinity : limits.maxAppsPerProfile),
                  ],
                ),
                // Bounded height so a long installed-apps list doesn't push
                // the rest of the form off screen — scrolls independently.
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: installedAppsAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(color: colors.primary)),
                    ),
                    error: (err, st) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(tb('noApp'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                    ),
                    data: (apps) => ListView.builder(
                      shrinkWrap: true,
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        final isSelected = _selectedApps.contains(app.packageName);
                        final disabled = !isSelected && atLimit;
                        return Opacity(
                          opacity: disabled ? 0.4 : 1,
                          child: InkWell(
                            onTap: disabled ? null : () => toggleApp(app.packageName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              decoration: BoxDecoration(
                                border: index == 0 ? null : Border(top: BorderSide(color: colors.border)),
                              ),
                              child: Row(
                                children: [
                                  AppIcon(appName: app.appName, icon: app.icon, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(app.appName, style: TextStyle(fontSize: 14, color: colors.foreground))),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: isSelected ? colors.primary : colors.border, width: 1.5),
                                      color: isSelected ? colors.primary : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionTitle(tb('blockedDomains')),
                AddRow(
                  controller: _websiteInput,
                  onAdd: addWebsite,
                  placeholder: atLimit ? t('limitReached') : tb('domainPlaceholder'),
                  disabled: atLimit,
                ),
                if (_websites.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final domain in _websites)
                          _Chip(label: domain, onRemove: () => setState(() => _websites.remove(domain))),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SectionTitle(tb('blockedKeywords')),
                AddRow(
                  controller: _keywordInput,
                  onAdd: addKeyword,
                  placeholder: atLimit ? t('limitReached') : tb('keywordPlaceholder'),
                  disabled: atLimit,
                ),
                if (_keywords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final keyword in _keywords)
                          _Chip(label: keyword, onRemove: () => setState(() => _keywords.remove(keyword))),
                      ],
                    ),
                  ),
                if (_type == LimiterType.daily || _type == LimiterType.hourly || _type == LimiterType.weekly) ...[
                  const SizedBox(height: 12),
                  SectionTitle(t(_limitKeyByType[_type]!)),
                  AppInput(
                    icon: Icons.timer_outlined,
                    placeholder: '60',
                    controller: _limitMinutes,
                    keyboardType: TextInputType.number,
                    textCapitalization: TextCapitalization.none,
                  ),
                ],
                if (_type == LimiterType.interval) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionTitle(t('timeRanges')),
                            AppInput(icon: Icons.schedule_outlined, placeholder: '09:00', controller: _startTime, textCapitalization: TextCapitalization.none),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 18),
                            AppInput(icon: Icons.schedule_outlined, placeholder: '17:30', controller: _endTime, textCapitalization: TextCapitalization.none),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SectionTitle(t('activeDays')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (day, key) in _days)
                        _DayChip(
                          label: tc(key),
                          active: _selectedDays.contains(day),
                          onTap: () => toggleDay(day),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit ? onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.primaryForeground,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(t('create')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.foreground)),
          const SizedBox(width: 6),
          InkWell(onTap: onRemove, child: Icon(Icons.close_rounded, size: 12, color: colors.mutedForeground)),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DayChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.card,
          border: Border.all(color: active ? colors.primary : colors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? colors.primaryForeground : colors.foreground)),
      ),
    );
  }
}
