import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import Animated, { Easing, FadeInDown, useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated'
import { Check, Sparkles } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { useColor } from '@/hooks/useColor'

type Props = {
  reclaimedHours: number
  onSeePlans: () => void
  onContinueFree: () => void
}

// The soft-paywall moment: shown once, right after the Build Up flow, while
// motivation is highest. Deliberately not a hard gate (no free trial timer,
// no fake "processing payment" flow) — there's no in-app purchase mechanism
// in this app (real plans are activated externally, see app/pricing.tsx's
// paymentInstructions), so this only ever routes to that honest screen or
// lets the user continue on Free. Skippable at any time.
export function Paywall({ reclaimedHours, onSeePlans, onContinueFree }: Props) {
  const { t } = useTranslation('onboarding')
  const background = useColor('background')
  const primary = useColor('primary')
  const card = useColor('card')
  const border = useColor('border')

  const glow = useSharedValue(0.4)
  useEffect(() => {
    glow.value = withTiming(1, { duration: 1400, easing: Easing.inOut(Easing.ease) })
  }, [])
  const glowStyle = useAnimatedStyle(() => ({ opacity: glow.value }))

  const features = [
    t('paywallFeature1'),
    t('paywallFeature2'),
    t('paywallFeature3'),
    t('paywallFeature4'),
  ]

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <View style={{ flex: 1, paddingHorizontal: 24, paddingTop: 64, paddingBottom: 28, justifyContent: 'space-between' }}>
        <View>
          <Animated.View entering={FadeInDown.duration(400)} style={{ alignItems: 'center', gap: 14, marginBottom: 28 }}>
            <Animated.View
              style={[
                { width: 64, height: 64, borderRadius: 20, backgroundColor: primary + '1A', borderWidth: 1, borderColor: primary + '40', alignItems: 'center', justifyContent: 'center' },
                glowStyle,
              ]}
            >
              <Sparkles size={28} color={primary} />
            </Animated.View>
            <Text variant="title" style={{ fontSize: 24, textAlign: 'center', lineHeight: 30 }}>{t('paywallTitle')}</Text>
            <Text variant="caption" style={{ fontSize: 13, textAlign: 'center', lineHeight: 19, maxWidth: 300 }}>
              {t('paywallSubtitle')}
            </Text>
          </Animated.View>

          <Animated.View
            entering={FadeInDown.delay(120).duration(400)}
            style={{ backgroundColor: card, borderWidth: 1, borderColor: border, borderRadius: 16, padding: 18, gap: 14 }}
          >
            {reclaimedHours > 0 && (
              <Badge style={{ alignSelf: 'flex-start', backgroundColor: primary + '1A' }} textStyle={{ color: primary }}>
                {t('planReadyStat', { hours: reclaimedHours })}
              </Badge>
            )}
            {features.map(feature => (
              <View key={feature} style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
                <View style={{ width: 20, height: 20, borderRadius: 10, backgroundColor: primary + '1A', alignItems: 'center', justifyContent: 'center' }}>
                  <Check size={12} color={primary} />
                </View>
                <Text style={{ fontSize: 13, flex: 1 }}>{feature}</Text>
              </View>
            ))}
          </Animated.View>
        </View>

        <Animated.View entering={FadeInDown.delay(200).duration(400)} style={{ gap: 10 }}>
          <Button onPress={onSeePlans}>{t('paywallSeePlans')}</Button>
          <Button variant="ghost" onPress={onContinueFree}>{t('paywallContinueFree')}</Button>
        </Animated.View>
      </View>
    </View>
  )
}
