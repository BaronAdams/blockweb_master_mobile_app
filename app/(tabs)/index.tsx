import { ScrollView } from 'react-native'
import Animated, { FadeInDown } from 'react-native-reanimated'
import { useTranslation } from 'react-i18next'
import { Ban, Globe, Hash, Hourglass, Eye } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Separator } from '@/components/ui/separator'
import { StatCard } from '@/components/StatCard'
import { BarChart } from '@/components/charts/bar-chart'
import { DoughnutChart } from '@/components/charts/doughnut-chart'
import { ChartContainer } from '@/components/charts/chart-container'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { formatMinutes } from '@/utils/analytics'
import { CATEGORY_META, CATEGORY_ORDER } from '@/lib/categories'
import type { SiteCategory } from '@/lib/categories'

const HOURLY_DATA = Array.from({ length: 24 }, (_, h) => {
  let minutes = 0
  if (h >= 19 && h <= 22) minutes = 22
  else if (h >= 12 && h <= 14) minutes = 14
  else if (h >= 8 && h <= 11) minutes = 8
  return { label: `${h}h`, value: minutes }
})

// Demo split across the 5 real categories — adult included so the layout
// and warning banners are representative even with mocked data.
const CATEGORY_VALUES: Record<string, number> = {
  distraction: 38,
  productivity: 41,
  entertainment: 9,
  other: 6,
  adult: 6,
}
// Static demo total until real usage-tracking is wired (LOGIC.md phase 2).
const VISITS_TODAY = 9

// Combined app + website browsing history — mirrors the extension's
// Analytics history table (site/app, category, time). Minutes are split
// to match CATEGORY_VALUES above; real per-item tracking lands in a later
// phase (see LOGIC.md — mock data first).
type HistoryEntry = { name: string; type: 'app' | 'site'; category: SiteCategory; minutes: number }
const HISTORY_ENTRIES_UNSORTED: HistoryEntry[] = [
  { name: 'Instagram', type: 'app', category: 'distraction', minutes: 34 },
  { name: 'Notion', type: 'app', category: 'productivity', minutes: 40 },
  { name: 'YouTube', type: 'app', category: 'entertainment', minutes: 14 },
  { name: 'tiktok.com', type: 'site', category: 'distraction', minutes: 27 },
  { name: 'github.com', type: 'site', category: 'productivity', minutes: 26 },
  { name: 'weather.com', type: 'site', category: 'other', minutes: 10 },
  { name: 'site-restreint.com', type: 'site', category: 'adult', minutes: 10 },
]
const HISTORY_ENTRIES = [...HISTORY_ENTRIES_UNSORTED].sort((a, b) => b.minutes - a.minutes)

export default function AnalyticsScreen() {
  const { t } = useTranslation('analytics')
  const { t: tc, i18n } = useTranslation('common')
  const background = useColor('background')
  const violet = CATEGORY_META.distraction.color

  const blockedApps = useAppStore(s => s.blockedApps)
  const blockedKeywords = useAppStore(s => s.blockedKeywords)
  const blockedWebsites = useAppStore(s => s.blockedWebsites)
  const limiterProfiles = useAppStore(s => s.limiterProfiles)
  const activeProfileCount = limiterProfiles.filter(p => p.isActive).length

  const todayLabel = new Date().toLocaleDateString(i18n.language, { day: 'numeric', month: 'long' })
  const categoryData = CATEGORY_ORDER
    .filter(cat => CATEGORY_VALUES[cat] > 0)
    .map(cat => ({ label: tc(CATEGORY_META[cat].labelKey), value: CATEGORY_VALUES[cat], color: CATEGORY_META[cat].color }))
  const distractionPct = CATEGORY_VALUES.distraction

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: background }}
      contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 40, gap: 20 }}
    >
      <View>
        <Text variant="title">{t('title')}</Text>
        <Text variant="caption" style={{ marginTop: 2 }}>{`${tc('today')} · ${todayLabel}`}</Text>
      </View>

      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 12, justifyContent: 'space-between' }}>
        <Animated.View entering={FadeInDown.delay(0).duration(400)} style={{ width: '48%' }}>
          <StatCard label="Apps bloquées" value={String(blockedApps.length)} icon={Ban} color="#f43f5e" />
        </Animated.View>
        <Animated.View entering={FadeInDown.delay(60).duration(400)} style={{ width: '48%' }}>
          <StatCard label="Sites bloqués" value={String(blockedWebsites.length)} icon={Globe} color="#8b5cf6" />
        </Animated.View>
        <Animated.View entering={FadeInDown.delay(120).duration(400)} style={{ width: '48%' }}>
          <StatCard label={t('keywords')} value={String(blockedKeywords.length)} icon={Hash} color="#f59e0b" />
        </Animated.View>
        <Animated.View entering={FadeInDown.delay(180).duration(400)} style={{ width: '48%' }}>
          <StatCard label={t('activeProfiles')} value={String(activeProfileCount)} icon={Hourglass} color="#34d399" />
        </Animated.View>
        <Animated.View entering={FadeInDown.delay(240).duration(400)} style={{ width: '48%' }}>
          <StatCard label={t('visits')} value={String(VISITS_TODAY)} icon={Eye} color="#60a5fa" />
        </Animated.View>
      </View>

      <Animated.View entering={FadeInDown.delay(320).duration(400)}>
        <ChartContainer title={t('hourlyChart')} description={t('hourlyDesc')}>
          <BarChart
            data={HOURLY_DATA.map(d => ({ ...d, color: CATEGORY_META.productivity.color }))}
            config={{ height: 180, showLabels: false }}
          />
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginTop: 4 }}>
            {['00h', '06h', '12h', '18h', '23h'].map(h => (
              <Text key={h} variant="caption" style={{ fontSize: 10 }}>{h}</Text>
            ))}
          </View>
        </ChartContainer>
      </Animated.View>

      <Animated.View entering={FadeInDown.delay(400).duration(400)}>
        <ChartContainer title={t('whereTime')}>
          <View style={{ alignItems: 'center' }}>
            <View>
              <DoughnutChart
                data={categoryData}
                config={{ height: 200, width: 200, showLabels: false, showLegend: false }}
              />
              <View
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
                pointerEvents="none"
              >
                <Text style={{ fontSize: 24, fontWeight: '700' }}>{CATEGORY_VALUES.productivity}%</Text>
                <Text variant="caption" style={{ fontSize: 10, textTransform: 'uppercase' }}>{t('productif')}</Text>
              </View>
            </View>
          </View>

          <View style={{ marginTop: 16, gap: 10 }}>
            {CATEGORY_ORDER.filter(cat => CATEGORY_VALUES[cat] > 0).map(cat => (
              <View key={cat} style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <Text style={{ fontSize: 13 }}>{CATEGORY_META[cat].emoji}</Text>
                <Text style={{ flex: 1, fontSize: 13 }}>{tc(CATEGORY_META[cat].labelKey)}</Text>
                <Text variant="caption" style={{ fontSize: 12, fontFamily: 'monospace' }}>{CATEGORY_VALUES[cat]}%</Text>
              </View>
            ))}
          </View>

          <Separator style={{ marginVertical: 16 }} />

          <Text style={{ fontSize: 12, fontWeight: '600', textTransform: 'uppercase', letterSpacing: 0.6 }}>
            {t('history')}
          </Text>
          <View style={{ marginTop: 12, gap: 4 }}>
            {HISTORY_ENTRIES.map(entry => {
              const meta = CATEGORY_META[entry.category]
              const EntryIcon = entry.type === 'site' ? Globe : null
              return (
                <View key={entry.name} style={{ flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 8 }}>
                  <View
                    style={{
                      width: 28, height: 28, borderRadius: 8,
                      backgroundColor: meta.color + '1A',
                      alignItems: 'center', justifyContent: 'center',
                    }}
                  >
                    {EntryIcon ? (
                      <EntryIcon size={14} color={meta.color} />
                    ) : (
                      <Text style={{ fontSize: 11, fontWeight: '700', color: meta.color }}>
                        {entry.name.charAt(0).toUpperCase()}
                      </Text>
                    )}
                  </View>
                  <Text style={{ flex: 1, fontSize: 13 }} numberOfLines={1}>{entry.name}</Text>
                  <Text style={{ fontSize: 13 }}>{meta.emoji}</Text>
                  <Text variant="caption" style={{ fontSize: 12, fontFamily: 'monospace', width: 44, textAlign: 'right' }}>
                    {formatMinutes(entry.minutes)}
                  </Text>
                </View>
              )
            })}
          </View>
        </ChartContainer>
      </Animated.View>

      {distractionPct >= 40 && (
        <Animated.View entering={FadeInDown.delay(480).duration(400)}>
          <View
            style={{
              backgroundColor: violet + '1A',
              borderWidth: 1,
              borderColor: violet + '33',
              borderLeftWidth: 3,
              borderLeftColor: violet,
              borderRadius: 10,
              padding: 12,
              flexDirection: 'row',
              gap: 8,
            }}
          >
            <Text style={{ fontSize: 12 }}>📱</Text>
            <Text style={{ fontSize: 12, color: '#c4b5fd', flex: 1 }}>
              {t('distractionWarning', { pct: distractionPct })}
            </Text>
          </View>
        </Animated.View>
      )}
    </ScrollView>
  )
}
