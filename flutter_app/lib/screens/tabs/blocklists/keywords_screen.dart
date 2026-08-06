import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/limits.dart';
import '../../../state/app_settings.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/accessibility_warning_banner.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/blocklist_ui.dart';
import '../../../widgets/sub_screen_header.dart';
import '../../../widgets/toast.dart';

/// Port of app/(tabs)/blocklists/keywords.tsx.
class KeywordsScreen extends ConsumerStatefulWidget {
  const KeywordsScreen({super.key});

  @override
  ConsumerState<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends ConsumerState<KeywordsScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('blockLists', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final limits = limitsFor(store.plan);
    final keywords = store.blockedKeywords;
    final atLimit = !isPremium(store.plan) && keywords.length >= limits.maxKeywords;

    void onAdd() {
      if (atLimit) return;
      final trimmed = _input.text.trim();
      if (trimmed.isEmpty) return;
      notifier.addKeyword(trimmed);
      _input.clear();
    }

    void onRemove(String id) {
      if (!notifier.removeKeyword(id)) showWarningToast(context, t('strictBlocked'));
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(title: t('blockedKeywords'), right: LimitBadge(count: keywords.length, max: limits.maxKeywords)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  AccessibilityWarningBanner(active: keywords.isNotEmpty),
                  AddRow(
                    controller: _input,
                    onAdd: onAdd,
                    placeholder: atLimit ? t('limitReached') : t('keywordPlaceholder'),
                    disabled: atLimit,
                  ),
                  Expanded(
                    child: keywords.isEmpty
                        ? BlocklistEmptyState(icon: Icons.tag_rounded, label: t('noKeyword'))
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: keywords.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = keywords[index];
                              return BlockListRow(
                                icon: Text('#', style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: colors.mutedForeground)),
                                label: item.keyword,
                                onRemove: () => onRemove(item.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
