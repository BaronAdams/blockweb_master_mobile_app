import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile_types.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/sub_screen_header.dart';

/// Port of app/profiles/create/index.tsx — first step of profile creation:
/// pick a type, then move to its dedicated form.
class ChooseProfileTypeScreen extends ConsumerWidget {
  const ChooseProfileTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('profiles', key);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          SubScreenHeader(title: t('newProfile')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(t('chooseTypeDesc'), style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                ),
                for (final pt in profileTypeOrder) ...[
                  _TypeRow(
                    meta: profileTypeMeta[pt]!,
                    label: t(profileTypeMeta[pt]!.labelKey),
                    desc: t(profileTypeMeta[pt]!.createDescKey),
                    onTap: () => context.push('/profiles/create/${pt.name}'),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final ProfileTypeMeta meta;
  final String label;
  final String desc;
  final VoidCallback onTap;
  const _TypeRow({required this.meta, required this.label, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: meta.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(meta.icon, size: 22, color: meta.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.foreground)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12, height: 1.3, color: colors.mutedForeground)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
