import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Port of components/onboarding/Paywall.tsx — the soft-paywall moment
/// shown once right after the Build Up flow. Not a hard gate: both CTAs
/// proceed (see onSeePlans/onContinueFree below), matching the RN
/// component's "no in-app purchase mechanism, real plans activate
/// externally" posture (see PricingScreen's paymentInstructions).
class PaywallScreen extends ConsumerWidget {
  final int reclaimedHours;
  const PaywallScreen({super.key, this.reclaimedHours = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('onboarding', key, vars: vars);
    final notifier = ref.read(appStoreProvider.notifier);

    void finish() {
      notifier.completeOnboarding();
    }

    void onSeePlans() {
      finish();
      context.go('/pricing');
    }

    void onContinueFree() {
      finish();
      context.go('/');
    }

    final features = [t('paywallFeature1'), t('paywallFeature2'), t('paywallFeature3'), t('paywallFeature4')];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            border: Border.all(color: colors.primary.withOpacity(0.25)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.auto_awesome_rounded, size: 28, color: colors.primary),
                        ),
                        const SizedBox(height: 14),
                        Text(t('paywallTitle'),
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.foreground)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 300,
                          child: Text(t('paywallSubtitle'),
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: colors.mutedForeground)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.card,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reclaimedHours > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(t('planReadyStat', {'hours': reclaimedHours}),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
                            ),
                          for (final feature in features)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.check_rounded, size: 12, color: colors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(feature, style: TextStyle(fontSize: 13, color: colors.foreground))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSeePlans,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.primaryForeground,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(t('paywallSeePlans')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onContinueFree,
                    child: Text(t('paywallContinueFree'), style: TextStyle(color: colors.mutedForeground)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
