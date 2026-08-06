import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../state/app_settings.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/faq_accordion.dart';
import '../widgets/section_title.dart';

class _PlanCardData {
  final UserPlan plan;
  final String nameKey;
  final String price;
  final String? suffixKey;
  final String? strikePrice;
  final String descKey;
  final bool popular;
  final Color accent;
  const _PlanCardData({
    required this.plan,
    required this.nameKey,
    required this.price,
    this.suffixKey,
    this.strikePrice,
    required this.descKey,
    this.popular = false,
    required this.accent,
  });
}

const _plans = [
  _PlanCardData(plan: UserPlan.free, nameKey: 'freePlan', price: '\$0', descKey: 'freeDesc', accent: Color(0xFF71717A)),
  _PlanCardData(plan: UserPlan.monthly, nameKey: 'monthly', price: '\$5', suffixKey: 'byMonth', descKey: 'monthlyDesc', accent: Color(0xFFA1A1AA)),
  _PlanCardData(
    plan: UserPlan.yearly,
    nameKey: 'yearly',
    price: '\$27',
    suffixKey: 'byYear',
    strikePrice: '\$60',
    descKey: 'yearlyDesc',
    popular: true,
    accent: Color(0xFFF59E0B),
  ),
  _PlanCardData(plan: UserPlan.lifetime, nameKey: 'lifetime', price: '\$45', descKey: 'lifetimeDesc', accent: Color(0xFF34D399)),
];

const _faqKeys = ['faqQ1', 'faqQ2', 'faqQ3', 'faqQ4', 'faqQ5', 'faqQ6'];

/// Port of app/pricing.tsx.
class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('pricing', key, vars: vars);
    final currentPlan = ref.watch(appStoreProvider).plan;

    final featureRows = [
      (labelKey: 'blockedSites', free: t('getSites', {'n': 3}), premium: t('unlimited')),
      (labelKey: 'blockedKeywords', free: t('getKeywords', {'n': 3}), premium: t('unlimited')),
      (labelKey: 'profiles', free: t('getProfiles', {'n': 1}), premium: t('unlimited')),
      (labelKey: 'strictMode', free: t('freeMaxDay'), premium: t('proMaxDay')),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          children: [
            Text(t('title'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.foreground)),
            Text(t('takeControl'), style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
            const SizedBox(height: 20),
            for (final p in _plans) ...[
              _PlanCard(data: p, isCurrent: currentPlan == p.plan, t: t),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            AppCard(
              padding: const EdgeInsets.all(16),
              children: [
                SectionTitle(t('included')),
                for (int i = 0; i < featureRows.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: colors.border))),
                    child: Row(
                      children: [
                        Expanded(child: Text(t(featureRows[i].labelKey), style: TextStyle(fontSize: 12, color: colors.foreground))),
                        SizedBox(
                          width: 70,
                          child: Text(featureRows[i].free, textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
                        ),
                        SizedBox(
                          width: 70,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.check_rounded, size: 12, color: Color(0xFF34D399)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(featureRows[i].premium,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF34D399)), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SectionTitle(t('faq')),
            FaqAccordion(items: [for (int i = 0; i < _faqKeys.length; i++) FaqItem(id: _faqKeys[i], question: t(_faqKeys[i]), answer: t('faqA${i + 1}'))]),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanCardData data;
  final bool isCurrent;
  final String Function(String, [Map<String, dynamic>?]) t;
  const _PlanCard({required this.data, required this.isCurrent, required this.t});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final borderColor = isCurrent ? data.accent : (data.popular ? data.accent.withOpacity(0.5) : colors.border);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16, data.popular ? 22 : 16, 16, 16),
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: borderColor, width: data.popular ? 1.5 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t(data.nameKey), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.foreground)),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(6)),
                      child: Text(t('currentPlan'), style: TextStyle(fontSize: 11, color: colors.foreground)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(data.price, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.foreground)),
                  if (data.suffixKey != null) ...[
                    const SizedBox(width: 6),
                    Text(t(data.suffixKey!), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                  ],
                  if (data.strikePrice != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${data.strikePrice}${data.suffixKey != null ? t(data.suffixKey!) : ''}',
                      style: TextStyle(fontSize: 11, color: colors.mutedForeground, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(t(data.descKey), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
              ),
              if (isCurrent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(backgroundColor: colors.secondary, foregroundColor: colors.secondaryForeground),
                    child: Text(t('currentPlan')),
                  ),
                )
              else if (data.plan != UserPlan.free)
                Text(t('paymentInstructions'), style: TextStyle(fontSize: 11, height: 1.3, color: colors.mutedForeground)),
            ],
          ),
        ),
        if (data.popular)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: data.accent, borderRadius: BorderRadius.circular(999)),
                child: Text(t('popular'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF09090B))),
              ),
            ),
          ),
      ],
    );
  }
}
