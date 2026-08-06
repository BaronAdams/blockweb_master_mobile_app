import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/limits.dart';
import '../../../state/app_settings.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/blocklist_ui.dart';
import '../../../widgets/entry_icon.dart';
import '../../../widgets/sub_screen_header.dart';
import '../../../widgets/toast.dart';

/// Port of app/(tabs)/blocklists/whitelist.tsx — a Premium-only feature;
/// Free plan sees a locked upsell card instead of the list.
class WhitelistScreen extends ConsumerStatefulWidget {
  const WhitelistScreen({super.key});

  @override
  ConsumerState<WhitelistScreen> createState() => _WhitelistScreenState();
}

class _WhitelistScreenState extends ConsumerState<WhitelistScreen> {
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
    String tc(String key) => i18n.t('common', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final premium = isPremium(store.plan);
    final whitelist = store.whitelistedSites;

    void onAdd() {
      final trimmed = _input.text.trim().toLowerCase();
      if (trimmed.isEmpty) return;
      notifier.addWhitelistedSite(trimmed);
      _input.clear();
    }

    void onRemove(String id) {
      if (!notifier.removeWhitelistedSite(id)) showWarningToast(context, t('strictBlocked'));
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(
            title: t('whitelist'),
            right: premium ? LimitBadge(count: whitelist.length, max: double.infinity) : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: !premium
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.05),
                        border: Border.all(color: colors.primary.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 20, color: colors.primary),
                          const SizedBox(height: 8),
                          Text(t('whitelistPremium'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.foreground)),
                          const SizedBox(height: 4),
                          Text(t('whitelistPremiumDesc'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                          const SizedBox(height: 12),
                          AppButton(label: tc('upgrade'), onPressed: () => context.push('/pricing')),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        AddRow(controller: _input, onAdd: onAdd, placeholder: t('whitePlaceholder')),
                        Expanded(
                          child: whitelist.isEmpty
                              ? BlocklistEmptyState(icon: Icons.public_outlined, label: t('noWhite'))
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: whitelist.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = whitelist[index];
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
