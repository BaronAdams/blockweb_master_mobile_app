import { useMemo, useState } from 'react'
import { Pressable, ScrollView } from 'react-native'
import Animated, { FadeInDown } from 'react-native-reanimated'
import { useTranslation } from 'react-i18next'
import { Ban, Globe, Hash, Hourglass } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { StatCard } from '@/components/StatCard'
import { AppHeader } from '@/components/AppHeader'
import { AccessibilityWarningBanner } from '@/components/AccessibilityWarningBanner'
import { AppIcon } from '@/components/AppIcon'
import { LineChart } from '@/components/charts/line-chart'
import { DoughnutChart } from '@/components/charts/doughnut-chart'
import { StackedBarChart } from '@/components/charts/stacked-bar-chart'
import { ChartContainer } from '@/components/charts/chart-container'
import { useColor } from '@/hooks/useColor'
import { useInstalledApps } from '@/hooks/useInstalledApps'
import { useAppStore } from '@/store/useAppStore'
import { formatMinutes, getCategoryBreakdown } from '@/utils/analytics'
import { CATEGORY_META, categorizeApp } from '@/lib/categories'

const pad2 = (n: number) => String(n).padStart(2, '0')
const dateKey = (d: Date) => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`

const CATEGORY_ORDER_4 = ['distraction', 'entertainment', 'productivity', 'other'] as const

export default function AnalyticsScreen() {
  const { t } = useTranslation('analytics')
  const { t: tc, i18n } = useTranslation('common')
  const background = useColor('background')
  const border = useColor('border')
  const violet = CATEGORY_META.distraction.color

  const blockedApps = useAppStore(s => s.blockedApps)
  const blockedKeywords = useAppStore(s => s.blockedKeywords)
  const blockedWebsites = useAppStore(s => s.blockedWebsites)
  const limiterProfiles = useAppStore(s => s.limiterProfiles)
  const analytics = useAppStore(s => s.analytics)
  const activeProfileCount = limiterProfiles.filter(p => p.isActive).length

  const { apps: installedApps } = useInstalledApps()
  const appInfo = useMemo(() => {
    const map = new Map<string, { appName: string; icon?: string }>()
    for (const a of installedApps) map.set(a.packageName, { appName: a.appName, icon: a.icon })
    return map
  }, [installedApps])
  const resolveAppName = (pkg: string) =>
    appInfo.get(pkg)?.appName ?? blockedApps.find(a => a.packageName === pkg)?.appName ?? pkg

  const [selectedHour, setSelectedHour] = useState<number | null>(null)

  const todayLabel = new Date().toLocaleDateString(i18n.language, { day: 'numeric', month: 'long' })
  const today = dateKey(new Date())
  // `analytics` is populated by mergeUsageStats()/mergeHourlyUsageStats()
  // (see hooks/useAppMonitor.ts), fed by the real native
  // AccessibilityService (modules/blocker) — it's empty until that service
  // is enabled and has observed some usage, not mock data standing in for
  // it. Every section below shows an honest "not tracked" state instead of
  // fabricated numbers when it's empty.
  const todayRecord = analytics.find(a => a.date === today) ?? null

  const categoryTotals = todayRecord ? getCategoryBreakdown(todayRecord.appUsage, []) : null
  const categoryTotal = categoryTotals ? Object.values(categoryTotals).reduce((a, b) => a + b, 0) : 0
  const categoryData = categoryTotals
    ? CATEGORY_ORDER_4
        .filter(cat => categoryTotals[cat] > 0)
        .map(cat => ({
          cat,
          label: tc(CATEGORY_META[cat].labelKey),
          emoji: CATEGORY_META[cat].emoji,
          value: categoryTotals[cat],
          color: CATEGORY_META[cat].color,
        }))
    : []
  const productivityPct = categoryTotal > 0 ? Math.round(((categoryTotals?.productivity ?? 0) / categoryTotal) * 100) : 0
  const distractionPct = categoryTotal > 0 ? Math.round(((categoryTotals?.distraction ?? 0) / categoryTotal) * 100) : 0

  const hourlyBars = useMemo(() => {
    const hourlyUsage = todayRecord?.hourlyUsage ?? {}
    return Array.from({ length: 24 }, (_, h) => {
      const usageForHour = hourlyUsage[String(h)] ?? {}
      const totals = getCategoryBreakdown(usageForHour, [])
      const segments = CATEGORY_ORDER_4
        .filter(cat => totals[cat] > 0)
        .map(cat => ({ key: cat, value: totals[cat], color: CATEGORY_META[cat].color }))
      return { label: String(h), segments }
    })
  }, [todayRecord])
  const hasHourlyData = hourlyBars.some(b => b.segments.length > 0)
  const totalDailyMinutes = todayRecord?.totalMinutes ?? 0

  const onHourPress = (index: number) => {
    if (hourlyBars[index].segments.length === 0) return
    setSelectedHour(prev => (prev === index ? null : index))
  }

  const historyEntries = useMemo(() => {
    if (!todayRecord) return []
    const source = selectedHour != null
      ? (todayRecord.hourlyUsage?.[String(selectedHour)] ?? {})
      : todayRecord.appUsage
    return Object.entries(source)
      .map(([packageName, minutes]) => {
        const category = categorizeApp(packageName)
        return {
          packageName,
          name: resolveAppName(packageName),
          icon: appInfo.get(packageName)?.icon,
          minutes,
          category,
        }
      })
      .sort((a, b) => b.minutes - a.minutes)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [todayRecord, selectedHour, appInfo, blockedApps])

  const last7Days = useMemo(() => Array.from({ length: 7 }, (_, i) => {
    const d = new Date()
    d.setDate(d.getDate() - (6 - i))
    const key = dateKey(d)
    const record = analytics.find(a => a.date === key)
    return {
      x: key,
      y: record?.totalMinutes ?? 0,
      label: d.toLocaleDateString(i18n.language, { weekday: 'short' }),
    }
  }), [analytics, i18n.language])
  const hasWeeklyData = last7Days.some(d => d.y > 0)

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ padding: 20, paddingBottom: 40 }}
      >
      {/* A tap anywhere that isn't a bar (or another touchable) resets the
          hour filter — the bars' own SVG onPress claims the touch first,
          so this only fires on genuine "empty space" taps. */}
      <Pressable onPress={() => setSelectedHour(null)} style={{ gap: 20 }}>
        <View>
          <Text variant="title">{t('title')}</Text>
          <Text variant="caption" style={{ marginTop: 2 }}>{`${tc('today')} · ${todayLabel}`}</Text>
        </View>

        <AccessibilityWarningBanner active={blockedApps.length > 0} />

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
      </View>

      {/* Utilisation heure par heure — barres empilées par catégorie, réelles (todayRecord.hourlyUsage) */}
      <Animated.View entering={FadeInDown.delay(220).duration(400)}>
        <ChartContainer title={t('hourlyChart')} description={t('hourlyDesc')}>
          {!hasHourlyData ? (
            <EmptyChartState label={t('noData')} hint={t('trackingHint')} borderColor={border} />
          ) : (
            <>
              <Text style={{ fontSize: 22, fontWeight: '800', textAlign: 'center', marginBottom: 12 }}>
                {formatMinutes(totalDailyMinutes)}
              </Text>
              <StackedBarChart
                data={hourlyBars}
                config={{ height: 150, labelEvery: 4 }}
                selectedIndex={selectedHour}
                onBarPress={(index) => onHourPress(index)}
              />
            </>
          )}
        </ChartContainer>
      </Animated.View>

      {/* Historique de navigation — données réelles (store.analytics), alimentées par le vrai moteur natif (modules/blocker) via mergeUsageStats() */}
      <Animated.View entering={FadeInDown.delay(260).duration(400)}>
        <ChartContainer
          title={t('history')}
          description={selectedHour != null ? t('filteredByHour', { hour: selectedHour }) : `${tc('today')} · ${todayLabel}`}
        >
          {historyEntries.length === 0 ? (
            <EmptyChartState label={t('noNavigation')} hint={t('trackingHint')} borderColor={border} />
          ) : (
            <View style={{ gap: 4 }}>
              {historyEntries.map(entry => {
                const categoryMeta = CATEGORY_META[entry.category]
                return (
                  <View key={entry.packageName} style={{ flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 8 }}>
                    <AppIcon appName={entry.name} icon={entry.icon} size={30} />
                    <View style={{ flex: 1 }}>
                      <Text style={{ fontSize: 13 }} numberOfLines={1}>{entry.name}</Text>
                      <Text style={{ fontSize: 10, marginTop: 1, color: categoryMeta.color }}>
                        {categoryMeta.emoji} {tc(categoryMeta.labelKey)}
                      </Text>
                    </View>
                    <Text variant="caption" style={{ fontSize: 12, fontFamily: 'monospace' }}>{formatMinutes(entry.minutes)}</Text>
                  </View>
                )
              })}
            </View>
          )}
        </ChartContainer>
      </Animated.View>

      <Animated.View entering={FadeInDown.delay(320).duration(400)}>
        <ChartContainer title={t('whereTime')}>
          {categoryData.length === 0 ? (
            <EmptyChartState label={t('noData')} hint={t('trackingHint')} borderColor={border} />
          ) : (
            <>
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
                    <Text style={{ fontSize: 24, fontWeight: '700' }}>{productivityPct}%</Text>
                    <Text variant="caption" style={{ fontSize: 10, textTransform: 'uppercase' }}>{t('productif')}</Text>
                  </View>
                </View>
              </View>

              <View style={{ marginTop: 16, gap: 10 }}>
                {categoryData.map(c => (
                  <View key={c.cat} style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                    <Text style={{ fontSize: 13 }}>{c.emoji}</Text>
                    <Text style={{ flex: 1, fontSize: 13 }}>{c.label}</Text>
                    <Text variant="caption" style={{ fontSize: 12, fontFamily: 'monospace' }}>{formatMinutes(c.value)}</Text>
                  </View>
                ))}
              </View>
            </>
          )}
        </ChartContainer>
      </Animated.View>

      {/* Comparaison entre jours — LineChart (composant BNA UI, comme l'extension) */}
      <Animated.View entering={FadeInDown.delay(380).duration(400)}>
        <ChartContainer title={t('evolution7d')} description={t('evolution7dDesc')}>
          {hasWeeklyData ? (
            <LineChart
              data={last7Days}
              config={{ height: 180, gradient: true }}
            />
          ) : (
            <EmptyChartState label={t('notEnoughData')} hint={t('trackingHint')} borderColor={border} />
          )}
        </ChartContainer>
      </Animated.View>

      {distractionPct >= 40 && (
        <Animated.View entering={FadeInDown.delay(440).duration(400)}>
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
      </Pressable>
      </ScrollView>
    </View>
  )
}

function EmptyChartState({ label, hint, borderColor }: { label: string; hint: string; borderColor: string }) {
  return (
    <View
      style={{
        alignItems: 'center', justifyContent: 'center',
        paddingVertical: 28, gap: 6,
        borderWidth: 1, borderStyle: 'dashed', borderColor,
        borderRadius: 12,
      }}
    >
      <Text variant="caption" style={{ fontSize: 13, textAlign: 'center' }}>{label}</Text>
      <Text variant="caption" style={{ fontSize: 11, textAlign: 'center', opacity: 0.7, maxWidth: 260, lineHeight: 15 }}>
        {hint}
      </Text>
    </View>
  )
}
