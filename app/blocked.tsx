import { useEffect, useMemo } from 'react'
import { useLocalSearchParams, useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { Lock, ShieldAlert, Sun, Clock, Calendar, Shield, ShieldCheck, type LucideIcon } from 'lucide-react-native'
import Animated, { Easing, useAnimatedStyle, useSharedValue, withRepeat, withTiming } from 'react-native-reanimated'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { useColor } from '@/hooks/useColor'

// Mirrors the extension's blocked page (blocked/App.css): the lock icon
// floats (.lock-float, 6s), the glow behind it pulses (.glow-pulse, 4s),
// and the badge bounces with its dot pulsing (Tailwind `animate-[bounce_5s]`
// + `animate-pulse`). Reimplemented here with reanimated shared values since
// there's no CSS keyframes equivalent in React Native.
function useFloat() {
  const translateY = useSharedValue(0)
  useEffect(() => {
    translateY.value = withRepeat(withTiming(-12, { duration: 3000, easing: Easing.inOut(Easing.ease) }), -1, true)
  }, [])
  return useAnimatedStyle(() => ({ transform: [{ translateY: translateY.value }] }))
}

function useGlowPulse() {
  const progress = useSharedValue(0)
  useEffect(() => {
    progress.value = withRepeat(withTiming(1, { duration: 2000, easing: Easing.inOut(Easing.ease) }), -1, true)
  }, [])
  return useAnimatedStyle(() => ({
    opacity: 0.1 + progress.value * 0.15,
    transform: [{ scale: 0.95 + progress.value * 0.15 }],
  }))
}

function useBadgeBounce() {
  const translateY = useSharedValue(0)
  useEffect(() => {
    translateY.value = withRepeat(withTiming(-4, { duration: 2500, easing: Easing.inOut(Easing.ease) }), -1, true)
  }, [])
  return useAnimatedStyle(() => ({ transform: [{ translateY: translateY.value }] }))
}

function useDotPulse() {
  const opacity = useSharedValue(1)
  useEffect(() => {
    opacity.value = withRepeat(withTiming(0.4, { duration: 1000, easing: Easing.inOut(Easing.ease) }), -1, true)
  }, [])
  return useAnimatedStyle(() => ({ opacity: opacity.value }))
}

type BlockReason = 'app' | 'keyword' | 'adult' | 'daily' | 'hourly' | 'weekly' | 'interval'

const REASON_META: Record<BlockReason, {
  icon: LucideIcon
  color: string
  titleKey: string
  descKey: string
  badgeKey: string
  reasonKey: string
}> = {
  app: { icon: Lock, color: '#fb7185', titleKey: 'restrictedAccess', descKey: 'focusDesc', badgeKey: 'focusBadge', reasonKey: 'keywordReason' },
  keyword: { icon: Lock, color: '#fb7185', titleKey: 'restrictedAccess', descKey: 'keywordDesc', badgeKey: 'keywordBadge', reasonKey: 'keywordReason' },
  adult: { icon: ShieldAlert, color: '#fb7185', titleKey: 'adultBlocked', descKey: 'adultDesc', badgeKey: 'adultBadge', reasonKey: 'adultReason' },
  daily: { icon: Sun, color: '#fbbf24', titleKey: 'dailyTitle', descKey: 'dailyDesc', badgeKey: 'dailyBadge', reasonKey: 'dailyReason' },
  hourly: { icon: Clock, color: '#60a5fa', titleKey: 'hourlyTitle', descKey: 'hourlyDesc', badgeKey: 'hourlyBadge', reasonKey: 'hourlyReason' },
  weekly: { icon: Calendar, color: '#a78bfa', titleKey: 'weeklyTitle', descKey: 'weeklyDesc', badgeKey: 'weeklyBadge', reasonKey: 'weeklyReason' },
  interval: { icon: Shield, color: '#fb7185', titleKey: 'intervalTitle', descKey: 'intervalDesc', badgeKey: 'intervalBadge', reasonKey: 'intervalReason' },
}

const QUOTE_COUNT = 10

export default function BlockedScreen() {
  const { t } = useTranslation('blocked')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const params = useLocalSearchParams<{ reason?: string; value?: string }>()

  const reason: BlockReason = (params.reason as BlockReason) in REASON_META ? (params.reason as BlockReason) : 'app'
  const value = params.value ?? 'Instagram'
  const meta = REASON_META[reason]
  const Icon = meta.icon

  const quoteIndex = useMemo(() => Math.floor(Math.random() * QUOTE_COUNT) + 1, [])
  const quote = t(`quote_${quoteIndex}_desc`)
  const quoteAuthor = t(`quote_${quoteIndex}_author`)

  const description = ['daily', 'hourly', 'weekly', 'interval'].includes(reason)
    ? t(meta.descKey, { name: value })
    : t(meta.descKey)

  const floatStyle = useFloat()
  const glowStyle = useGlowPulse()
  const badgeStyle = useBadgeBounce()
  const dotStyle = useDotPulse()

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <View style={{ flex: 1, padding: 24, paddingTop: 60, alignItems: 'center' }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 40 }}>
          <View
            style={{
              width: 26, height: 26, borderRadius: 7,
              backgroundColor: '#f59e0b1A',
              alignItems: 'center', justifyContent: 'center',
            }}
          >
            <ShieldCheck size={14} color="#f59e0b" />
          </View>
          <Text style={{ fontSize: 13, fontWeight: '700' }}>{tc('appName')}</Text>
        </View>

        <View style={{ alignItems: 'center', marginBottom: 28 }}>
          <Animated.View
            style={[
              {
                position: 'absolute',
                width: 140, height: 140, borderRadius: 70,
                backgroundColor: meta.color,
              },
              glowStyle,
            ]}
          />
          <Animated.View
            style={[
              {
                width: 88, height: 88, borderRadius: 44,
                backgroundColor: '#ffffff0D',
                borderWidth: 1, borderColor: '#ffffff1A',
                alignItems: 'center', justifyContent: 'center',
              },
              floatStyle,
            ]}
          >
            <Icon size={36} color={meta.color} strokeWidth={1.6} />
          </Animated.View>
          <Animated.View
            style={[
              {
                position: 'absolute', top: -6, right: -18,
                flexDirection: 'row', alignItems: 'center', gap: 5,
                backgroundColor: '#18181b', borderWidth: 1, borderColor: '#27272a',
                borderRadius: 999, paddingHorizontal: 8, paddingVertical: 4,
              },
              badgeStyle,
            ]}
          >
            <Animated.View style={[{ width: 5, height: 5, borderRadius: 3, backgroundColor: meta.color }, dotStyle]} />
            <Text style={{ fontSize: 9, fontWeight: '600', color: meta.color }}>{t(meta.badgeKey)}</Text>
          </Animated.View>
        </View>

        <Text variant="title" style={{ textAlign: 'center', marginBottom: 10 }}>{t(meta.titleKey)}</Text>
        <Text variant="caption" style={{ textAlign: 'center', fontSize: 13, lineHeight: 19, marginBottom: 24, maxWidth: 300 }}>
          {description}
        </Text>

        <View
          style={{
            width: '100%',
            backgroundColor: '#18181b80',
            borderWidth: 1, borderColor: '#ffffff0D',
            borderRadius: 14, padding: 16, gap: 12, marginBottom: 24,
          }}
        >
          <Text style={{ fontSize: 10, fontWeight: '600', color: '#71717a', textTransform: 'uppercase', letterSpacing: 0.6 }}>
            {t('securityDetails')}
          </Text>
          <DetailRow color={meta.color} label={reason === 'keyword' ? t('detectedKeyword') : 'Application'} value={value} />
          <DetailRow color={meta.color} label={t('blockingReason')} value={t(meta.reasonKey)} />
        </View>

        <View style={{ width: '100%', gap: 10 }}>
          <Button onPress={() => router.back()}>{t('goBack')}</Button>
          <Button variant="outline" onPress={() => router.push('/(tabs)/blocklists')}>{t('manageRules')}</Button>
        </View>
      </View>

      <View style={{ padding: 24, paddingBottom: 32, alignItems: 'center' }}>
        <Text style={{ fontStyle: 'italic', fontSize: 12, color: '#52525b', textAlign: 'center', maxWidth: 280 }}>
          “{quote}”
        </Text>
        {!!quoteAuthor && (
          <Text style={{ fontSize: 11, color: '#3f3f46', marginTop: 6 }}>— {quoteAuthor}</Text>
        )}
      </View>
    </View>
  )
}

function DetailRow({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
      <View style={{ width: 6, height: 6, borderRadius: 3, backgroundColor: color }} />
      <Text variant="caption" style={{ fontSize: 11, flex: 1 }}>{label}</Text>
      <Text style={{ fontSize: 12, fontWeight: '600', fontFamily: 'monospace' }}>{value}</Text>
    </View>
  )
}
