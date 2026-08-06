import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_models.dart';
import '../../../models/limits.dart';
import '../../../state/app_settings.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/accessibility_warning_banner.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/blocklist_ui.dart';
import '../../../widgets/entry_icon.dart';
import '../../../widgets/sub_screen_header.dart';
import '../../../widgets/toast.dart';

/// Port of app/(tabs)/blocklists/websites.tsx.
class WebsitesScreen extends ConsumerStatefulWidget {
  const WebsitesScreen({super.key});

  @override
  ConsumerState<WebsitesScreen> createState() => _WebsitesScreenState();
}

class _WebsitesScreenState extends ConsumerState<WebsitesScreen> {
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
    final websites = store.blockedWebsites;
    final atLimit = !isPremium(store.plan) && websites.length >= limits.maxBlockedWebsites;

    void onAdd() {
      if (atLimit) return;
      final trimmed = _input.text.trim().toLowerCase();
      if (trimmed.isEmpty) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      notifier.addBlockedWebsite(BlockedWebsite(id: '$now', domain: trimmed, isBlocked: true, addedAt: now));
      _input.clear();
    }

    void onRemove(String id) {
      if (!notifier.removeBlockedWebsite(id)) showWarningToast(context, t('strictBlocked'));
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(
            title: t('blockedDomains'),
            right: LimitBadge(count: websites.length, max: limits.maxBlockedWebsites),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  AccessibilityWarningBanner(active: websites.any((w) => w.isBlocked)),
                  AddRow(
                    controller: _input,
                    onAdd: onAdd,
                    placeholder: atLimit ? t('limitReached') : t('domainPlaceholder'),
                    disabled: atLimit,
                  ),
                  Expanded(
                    child: websites.isEmpty
                        ? BlocklistEmptyState(icon: Icons.public_outlined, label: t('noDomain'))
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: websites.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = websites[index];
                              return BlockListRow(
                                icon: EntryIcon(name: item.domain, type: EntryIconType.site, color: colors.mutedForeground, size: 24),
                                label: item.domain,
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
