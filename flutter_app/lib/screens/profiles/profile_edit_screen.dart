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
import '../../widgets/danger_button.dart';
import '../../widgets/section_title.dart';
import '../../widgets/sub_screen_header.dart';
import '../../widgets/unit_picker.dart';

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

/// Edit an existing LimiterProfile — same fields as CreateProfileScreen
/// (kept as a separate screen rather than sharing one widget with two
/// modes, matching how the chrome extension keeps TimerProfileCreate and
/// TimerProfileEdit as separate files). Reachable from ProfileDetailScreen's
/// edit button.
class ProfileEditScreen extends ConsumerStatefulWidget {
  final String id;
  const ProfileEditScreen({super.key, required this.id});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _name;
  final _websiteInput = TextEditingController();
  final _keywordInput = TextEditingController();
  int _limitHours = 1;
  int _limitMinutesVal = 0;
  int _startHour = 9;
  int _startMinute = 0;
  int _endHour = 17;
  int _endMinute = 30;

  late List<String> _websites;
  late List<String> _keywords;
  late Set<String> _selectedApps;
  late List<DayOfWeek> _selectedDays;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _websiteInput.dispose();
    _keywordInput.dispose();
    super.dispose();
  }

  void _initFrom(LimiterProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _name = TextEditingController(text: profile.name)..addListener(() => setState(() {}));
    final limit = switch (profile.type) {
          LimiterType.daily => profile.dailyLimitMinutes,
          LimiterType.hourly => profile.hourlyLimitMinutes,
          LimiterType.weekly => profile.weeklyLimitMinutes,
          LimiterType.interval => null,
        } ??
        (profile.type == LimiterType.hourly ? 30 : 60);
    _limitHours = limit ~/ 60;
    _limitMinutesVal = limit % 60;
    final start = (profile.intervalConfig?.startTime ?? '09:00').split(':');
    final end = (profile.intervalConfig?.endTime ?? '17:30').split(':');
    _startHour = int.tryParse(start[0]) ?? 9;
    _startMinute = int.tryParse(start[1]) ?? 0;
    _endHour = int.tryParse(end[0]) ?? 17;
    _endMinute = int.tryParse(end[1]) ?? 30;
    _websites = List.of(profile.websites);
    _keywords = List.of(profile.keywords);
    _selectedApps = profile.apps.toSet();
    _selectedDays = List.of(
      profile.type == LimiterType.interval
          ? (profile.intervalConfig?.days ?? DayOfWeek.values)
          : (profile.activeDays?.isNotEmpty == true ? profile.activeDays! : DayOfWeek.values),
    );
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
    final installedAppsAsync = ref.watch(installedAppsProvider);

    LimiterProfile? profile;
    for (final p in store.limiterProfiles) {
      if (p.id == widget.id) {
        profile = p;
        break;
      }
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: Text(t('profileNotExists'), style: TextStyle(color: colors.mutedForeground))),
      );
    }
    _initFrom(profile);
    final type = profile.type;
    final meta = profileTypeMeta[type]!;
    final strictActive = store.strictMode.isActive;

    final limits = limitsFor(store.plan);
    final totalElements = _selectedApps.length + _websites.length + _keywords.length;
    final atLimit = !isPremium(store.plan) && totalElements >= limits.maxAppsPerProfile;
    final canSubmit = _name.text.trim().isNotEmpty && totalElements > 0 && !strictActive;

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
        _selectedDays =
            _selectedDays.contains(day) ? _selectedDays.where((d) => d != day).toList() : [..._selectedDays, day];
      });
    }

    void onSave() {
      if (!canSubmit) return;
      final id = profile!.id;
      final limitMinutes = type == LimiterType.hourly ? _limitMinutesVal : (_limitHours * 60 + _limitMinutesVal);

      notifier.updateProfile(id, (p) => LimiterProfile(
            id: p.id,
            name: _name.text.trim(),
            type: p.type,
            apps: _selectedApps.toList(),
            websites: _websites,
            keywords: _keywords,
            isActive: p.isActive,
            createdAt: p.createdAt,
            dailyLimitMinutes: type == LimiterType.daily ? limitMinutes : p.dailyLimitMinutes,
            dailyUsedMinutes: p.dailyUsedMinutes,
            dailyResetAt: p.dailyResetAt,
            hourlyLimitMinutes: type == LimiterType.hourly ? limitMinutes : p.hourlyLimitMinutes,
            hourlyUsedMinutes: p.hourlyUsedMinutes,
            weeklyLimitMinutes: type == LimiterType.weekly ? limitMinutes : p.weeklyLimitMinutes,
            weeklyUsedMinutes: p.weeklyUsedMinutes,
            weeklyResetAt: p.weeklyResetAt,
            activeDays: (type == LimiterType.daily || type == LimiterType.hourly) && _selectedDays.isNotEmpty
                ? _selectedDays
                : null,
            intervalConfig: type == LimiterType.interval
                ? IntervalConfig(
                    startTime: '${_startHour.toString().padLeft(2, '0')}:${_startMinute.toString().padLeft(2, '0')}',
                    endTime: '${_endHour.toString().padLeft(2, '0')}:${_endMinute.toString().padLeft(2, '0')}',
                    days: _selectedDays,
                  )
                : null,
          ));

      if (context.canPop()) context.pop();
    }

    void onDelete() {
      notifier.deleteProfile(profile!.id);
      while (context.canPop()) {
        context.pop();
      }
      context.go('/blocklists');
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(title: t('editTitle')),
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
                AppInput(icon: Icons.badge_outlined, placeholder: t('namePlaceholder'), controller: _name, textCapitalization: TextCapitalization.sentences, enabled: !strictActive),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionTitle(tb('applications')),
                    LimitBadge(count: totalElements, max: isPremium(store.plan) ? double.infinity : limits.maxAppsPerProfile),
                  ],
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(color: colors.card, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: installedAppsAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(color: colors.primary)),
                    ),
                    error: (err, st) => Padding(padding: const EdgeInsets.all(16), child: Text(tb('noApp'), style: TextStyle(fontSize: 12, color: colors.mutedForeground))),
                    data: (apps) => ListView.builder(
                      shrinkWrap: true,
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        final isSelected = _selectedApps.contains(app.packageName);
                        final disabled = strictActive || (!isSelected && atLimit);
                        return Opacity(
                          opacity: disabled ? 0.4 : 1,
                          child: InkWell(
                            onTap: disabled ? null : () => toggleApp(app.packageName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              decoration: BoxDecoration(border: index == 0 ? null : Border(top: BorderSide(color: colors.border))),
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
                AddRow(controller: _websiteInput, onAdd: addWebsite, placeholder: atLimit ? t('limitReached') : tb('domainPlaceholder'), disabled: atLimit || strictActive),
                if (_websites.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final domain in _websites)
                          _Chip(label: domain, onRemove: strictActive ? null : () => setState(() => _websites.remove(domain))),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SectionTitle(tb('blockedKeywords')),
                AddRow(controller: _keywordInput, onAdd: addKeyword, placeholder: atLimit ? t('limitReached') : tb('keywordPlaceholder'), disabled: atLimit || strictActive),
                if (_keywords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final keyword in _keywords)
                          _Chip(label: keyword, onRemove: strictActive ? null : () => setState(() => _keywords.remove(keyword))),
                      ],
                    ),
                  ),
                if (type == LimiterType.daily || type == LimiterType.hourly || type == LimiterType.weekly) ...[
                  const SizedBox(height: 12),
                  SectionTitle(t(_limitKeyByType[type]!)),
                  Row(
                    children: [
                      if (type != LimiterType.hourly) ...[
                        Expanded(
                          child: UnitPicker(
                            value: _limitHours,
                            max: type == LimiterType.weekly ? 167 : 23,
                            suffix: tc('hourShrt'),
                            enabled: !strictActive,
                            onChanged: (v) => setState(() => _limitHours = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: UnitPicker(
                          value: _limitMinutesVal,
                          max: 59,
                          suffix: tc('minuteShrt'),
                          enabled: !strictActive,
                          onChanged: (v) => setState(() => _limitMinutesVal = v),
                        ),
                      ),
                    ],
                  ),
                ],
                if (type == LimiterType.daily || type == LimiterType.hourly) ...[
                  const SizedBox(height: 16),
                  SectionTitle(t('appDays')),
                  Text(t('emptyDays'), style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (day, key) in _days)
                        _DayChip(label: tc(key), active: _selectedDays.contains(day), onTap: strictActive ? null : () => toggleDay(day)),
                    ],
                  ),
                ],
                if (type == LimiterType.interval) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionTitle(t('timeRanges')),
                            Row(
                              children: [
                                Expanded(child: UnitPicker(value: _startHour, max: 23, suffix: tc('hourShrt'), enabled: !strictActive, onChanged: (v) => setState(() => _startHour = v))),
                                const SizedBox(width: 6),
                                Expanded(child: UnitPicker(value: _startMinute, max: 59, suffix: tc('minuteShrt'), enabled: !strictActive, onChanged: (v) => setState(() => _startMinute = v))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: UnitPicker(value: _endHour, max: 23, suffix: tc('hourShrt'), enabled: !strictActive, onChanged: (v) => setState(() => _endHour = v))),
                                const SizedBox(width: 6),
                                Expanded(child: UnitPicker(value: _endMinute, max: 59, suffix: tc('minuteShrt'), enabled: !strictActive, onChanged: (v) => setState(() => _endMinute = v))),
                              ],
                            ),
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
                        _DayChip(label: tc(key), active: _selectedDays.contains(day), onTap: strictActive ? null : () => toggleDay(day)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit ? onSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.primaryForeground,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(t('saveChanges')),
                  ),
                ),
                const SizedBox(height: 12),
                DangerButton(
                  label: strictActive ? t('strictBlocked') : t('deleteProfile'),
                  icon: Icons.delete_outline_rounded,
                  onPressed: strictActive ? null : onDelete,
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
  final VoidCallback? onRemove;
  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: colors.card, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.foreground)),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(onTap: onRemove, child: Icon(Icons.close_rounded, size: 12, color: colors.mutedForeground)),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
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
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? colors.primaryForeground : colors.foreground)),
      ),
    );
  }
}
