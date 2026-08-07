import 'dart:convert';

import '../l10n/i18n_service.dart';

/// Port of lib/blockedScreenStrings.ts — builds the full set of localized
/// strings the native block overlay needs (see
/// android/.../blocker/BlockOverlay.kt), pushed via
/// BlockerBridge.setBlockScreenStrings() whenever the app's language
/// changes (see native/app_monitor.dart). Native only ever substitutes a
/// single "{{value}}" token per description, so templated strings are
/// pre-rendered here with the real i18n interpolation passed the literal
/// token itself, rather than reimplementing the {{var}} syntax in Kotlin.
const _reasonKeys = ['app', 'site', 'keyword', 'adult', 'daily', 'hourly', 'weekly', 'interval'];

String buildBlockScreenStringsJson(I18nService i18n) {
  String t(String key, [Map<String, dynamic>? vars]) => i18n.t('blocked', key, vars: vars);
  String withPlaceholder(String key, String varName) => t(key, {varName: '{{value}}'});

  Map<String, String> reason({
    required String title,
    required String desc,
    required String badge,
    required String detailLabel,
    required String reasonLabel,
  }) =>
      {'title': title, 'desc': desc, 'badge': badge, 'detailLabel': detailLabel, 'reasonLabel': reasonLabel};

  final bundle = {
    'common': {
      'securityDetails': t('securityDetails'),
      'blockingReason': t('blockingReason'),
      'goBack': t('goBack'),
      'manageRules': t('manageRules'),
    },
    'reasons': {
      'app': reason(
        title: t('appBlockedTitle'),
        desc: withPlaceholder('appBlockedDesc', 'name'),
        badge: t('focusBadge'),
        detailLabel: t('blockedApplication'),
        reasonLabel: t('appBlockedReason'),
      ),
      'site': reason(
        title: t('restrictedAccess'),
        desc: t('focusDesc'),
        badge: t('focusBadge'),
        detailLabel: t('targetDomain'),
        reasonLabel: t('focusMode'),
      ),
      'keyword': reason(
        title: t('restrictedAccess'),
        desc: withPlaceholder('keywordDesc', 'keyword'),
        badge: t('keywordBadge'),
        detailLabel: t('detectedKeyword'),
        reasonLabel: t('keywordReason'),
      ),
      'adult': reason(
        title: t('adultBlocked'),
        desc: t('adultDesc'),
        badge: t('adultBadge'),
        detailLabel: t('adultBlockedSite'),
        reasonLabel: t('adultReason'),
      ),
      'daily': reason(
        title: t('dailyTitle'),
        desc: withPlaceholder('dailyDesc', 'name'),
        badge: t('dailyBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('dailyReason'),
      ),
      'hourly': reason(
        title: t('hourlyTitle'),
        desc: withPlaceholder('hourlyDesc', 'name'),
        badge: t('hourlyBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('hourlyReason'),
      ),
      'weekly': reason(
        title: t('weeklyTitle'),
        desc: withPlaceholder('weeklyDesc', 'name'),
        badge: t('weeklyBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('weeklyReason'),
      ),
      'interval': reason(
        title: t('intervalTitle'),
        desc: withPlaceholder('intervalDesc', 'name'),
        badge: t('intervalBadge'),
        detailLabel: t('activeProfile'),
        reasonLabel: t('intervalReason'),
      ),
    },
    'quotes': [
      for (var i = 1; i <= 10; i++) {'text': t('quote_${i}_desc'), 'author': t('quote_${i}_author')},
    ],
  };

  assert(_reasonKeys.every((k) => (bundle['reasons'] as Map).containsKey(k)));
  return jsonEncode(bundle);
}
