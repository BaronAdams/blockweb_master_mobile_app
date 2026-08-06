import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Port of lib/i18n.ts. Reuses the exact same locale JSON files (copied
/// verbatim into assets/locales/) as the single source of truth for
/// translations, rather than re-keying strings by hand for Flutter — the
/// namespace/key structure and the `{{var}}` interpolation syntax the RN
/// app uses are both replicated here so no locale file needs to change.
class I18nService extends ChangeNotifier {
  static const List<String> supportedLanguages = [
    'ar', 'de', 'en', 'es', 'fr', 'hi', 'it', 'ja', 'ko', 'nl', 'pl', 'pt_PT', 'ru', 'zh_CN',
  ];
  static const String fallbackLanguage = 'en';

  final Map<String, Map<String, dynamic>> _resources = {};
  String _language = fallbackLanguage;

  String get language => _language;

  Future<void> init() async {
    _language = resolveDeviceLanguage();
    await _loadLanguage(_language);
    if (_language != fallbackLanguage) await _loadLanguage(fallbackLanguage);
  }

  Future<void> setLanguage(String lang) async {
    if (!supportedLanguages.contains(lang)) return;
    await _loadLanguage(lang);
    _language = lang;
    notifyListeners();
  }

  Future<void> _loadLanguage(String lang) async {
    if (_resources.containsKey(lang)) return;
    final raw = await rootBundle.loadString('assets/locales/$lang/messages.json');
    _resources[lang] = json.decode(raw) as Map<String, dynamic>;
  }

  /// t('namespace', 'key', vars: {'name': 'Alice', 'count': 3}) — mirrors
  /// react-i18next's t(key, options) called as useTranslation(namespace).t(key, options)
  /// in the RN app. `count` triggers `${key}_one` / `${key}_other` plural
  /// selection when those variants exist (English/French pluralization:
  /// singular only for count == 1), matching the plural keys already
  /// present in the locale files (e.g. onboarding.q4Days_one/_other).
  String t(String namespace, String key, {Map<String, dynamic>? vars}) {
    var resolvedKey = key;
    final count = vars?['count'];
    if (count is num) {
      final pluralKey = count == 1 ? '${key}_one' : '${key}_other';
      if (_lookup(_language, namespace, pluralKey) != null) resolvedKey = pluralKey;
    }

    var value = _lookup(_language, namespace, resolvedKey) ??
        _lookup(fallbackLanguage, namespace, resolvedKey) ??
        key;

    if (vars != null) {
      for (final entry in vars.entries) {
        value = value.replaceAll('{{${entry.key}}}', '${entry.value}');
      }
    }
    return value;
  }

  String? _lookup(String lang, String namespace, String key) {
    final ns = _resources[lang]?[namespace];
    if (ns is Map) {
      final value = ns[key];
      if (value is String) return value;
    }
    return null;
  }

  /// Port of resolveDeviceLanguage() in lib/i18n.ts — same tag
  /// normalization (Chrome-extension-style pt_PT/zh_CN vs device-reported
  /// pt-PT/zh-CN) against the same supported-language set.
  static String resolveDeviceLanguage() {
    for (final locale in ui.PlatformDispatcher.instance.locales) {
      final tag = locale.toLanguageTag();
      final underscored = tag.replaceAll('-', '_');
      if (supportedLanguages.contains(underscored)) return underscored;
      final bare = tag.split('-').first;
      if (supportedLanguages.contains(bare)) return bare;
    }
    return fallbackLanguage;
  }
}
