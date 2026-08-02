import { ScrollView } from 'react-native'
import { useTranslation } from 'react-i18next'
import { Check } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Accordion, AccordionItem, AccordionTrigger, AccordionContent } from '@/components/ui/accordion'
import { SectionTitle } from '@/components/SectionTitle'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import type { UserPlan } from '@/types'

const FAQ_KEYS = ['faqQ1', 'faqQ2', 'faqQ3', 'faqQ4', 'faqQ5', 'faqQ6']

type PlanCardData = {
  plan: UserPlan
  nameKey: string
  price: string
  suffixKey?: string
  strikePrice?: string
  descKey: string
  popular?: boolean
  accent: string
}

const PLANS: PlanCardData[] = [
  { plan: 'free', nameKey: 'freePlan', price: '$0', descKey: 'freeDesc', accent: '#71717a' },
  { plan: 'monthly', nameKey: 'monthly', price: '$5', suffixKey: 'byMonth', descKey: 'monthlyDesc', accent: '#a1a1aa' },
  { plan: 'yearly', nameKey: 'yearly', price: '$27', suffixKey: 'byYear', strikePrice: '$60', descKey: 'yearlyDesc', popular: true, accent: '#f59e0b' },
  { plan: 'lifetime', nameKey: 'lifetime', price: '$45', descKey: 'lifetimeDesc', accent: '#34d399' },
]

export default function PricingScreen() {
  const { t } = useTranslation('pricing')
  const background = useColor('background')
  const border = useColor('border')
  const currentPlan = useAppStore(s => s.plan)

  const featureRows: { labelKey: string; free: string; premium: string }[] = [
    { labelKey: 'blockedSites', free: t('getSites', { n: 3 }), premium: t('unlimited') },
    { labelKey: 'blockedKeywords', free: t('getKeywords', { n: 3 }), premium: t('unlimited') },
    { labelKey: 'profiles', free: t('getProfiles', { n: 1 }), premium: t('unlimited') },
    { labelKey: 'strictMode', free: t('freeMaxDay'), premium: t('proMaxDay') },
  ]

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: background }}
      contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 60, gap: 20 }}
    >
      <View>
        <Text variant="title">{t('title')}</Text>
        <Text variant="caption" style={{ marginTop: 2 }}>{t('takeControl')}</Text>
      </View>

      <View style={{ gap: 14 }}>
        {PLANS.map(p => {
          const isCurrent = currentPlan === p.plan
          return (
            <Card
              key={p.plan}
              style={{
                position: 'relative',
                borderWidth: p.popular ? 1.5 : 1,
                borderColor: isCurrent ? p.accent : p.popular ? p.accent + '80' : border,
              }}
            >
              {p.popular && (
                <Badge
                  style={{ position: 'absolute', top: -12, alignSelf: 'center', backgroundColor: p.accent }}
                  textStyle={{ color: '#09090b' }}
                >
                  {t('popular')}
                </Badge>
              )}

              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginTop: p.popular ? 6 : 0 }}>
                <Text style={{ fontSize: 15, fontWeight: '700' }}>{t(p.nameKey)}</Text>
                {isCurrent && <Badge variant="outline">{t('currentPlan')}</Badge>}
              </View>

              <View style={{ flexDirection: 'row', alignItems: 'baseline', gap: 6, marginTop: 8 }}>
                <Text style={{ fontSize: 28, fontWeight: '800' }}>{p.price}</Text>
                {p.suffixKey && <Text variant="caption" style={{ fontSize: 12 }}>{t(p.suffixKey)}</Text>}
                {p.strikePrice && (
                  <Text variant="caption" style={{ fontSize: 11, textDecorationLine: 'line-through' }}>
                    {p.strikePrice}{p.suffixKey ? t(p.suffixKey) : ''}
                  </Text>
                )}
              </View>

              <Text variant="caption" style={{ fontSize: 12, marginTop: 6, marginBottom: 14 }}>
                {t(p.descKey)}
              </Text>

              {isCurrent ? (
                <Button variant="secondary" disabled>{t('currentPlan')}</Button>
              ) : p.plan === 'free' ? null : (
                <Text variant="caption" style={{ fontSize: 11, lineHeight: 16 }}>
                  {t('paymentInstructions')}
                </Text>
              )}
            </Card>
          )
        })}
      </View>

      <Card>
        <SectionTitle style={{ marginBottom: 12 }}>{t('included')}</SectionTitle>
        {featureRows.map((row, i) => (
          <View
            key={row.labelKey}
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              paddingVertical: 10,
              borderTopWidth: i === 0 ? 0 : 1,
              borderTopColor: border,
            }}
          >
            <Text style={{ flex: 1, fontSize: 12 }}>{t(row.labelKey)}</Text>
            <Text variant="caption" style={{ fontSize: 11, width: 70, textAlign: 'right' }}>{row.free}</Text>
            <View style={{ width: 70, flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', gap: 4 }}>
              <Check size={12} color="#34d399" />
              <Text style={{ fontSize: 11, color: '#34d399' }}>{row.premium}</Text>
            </View>
          </View>
        ))}
      </Card>

      <View>
        <SectionTitle style={{ marginBottom: 8 }}>{t('faq')}</SectionTitle>
        <Accordion type="single" collapsible>
          {FAQ_KEYS.map((qKey, i) => (
            <AccordionItem key={qKey} value={String(i)}>
              <AccordionTrigger>{t(qKey)}</AccordionTrigger>
              <AccordionContent>
                <Text variant="caption" style={{ fontSize: 12 }}>{t(`faqA${i + 1}`)}</Text>
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </View>
    </ScrollView>
  )
}
