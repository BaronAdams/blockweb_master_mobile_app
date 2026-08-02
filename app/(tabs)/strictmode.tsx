import { useEffect, useState } from 'react'
import { ScrollView } from 'react-native'
import { useTranslation } from 'react-i18next'
import Animated, { useSharedValue, useAnimatedStyle, withRepeat, withTiming, Easing } from 'react-native-reanimated'
import { Trash2, Pencil, ShieldOff } from 'lucide-react-native'
import Slider from '@react-native-community/slider'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Accordion, AccordionItem, AccordionTrigger, AccordionContent } from '@/components/ui/accordion'
import { CountdownCell } from '@/components/CountdownCell'
import { SectionTitle } from '@/components/SectionTitle'
import { useColor } from '@/hooks/useColor'
import { useStrictMode } from '@/hooks/useStrictMode'
import { useAppStore } from '@/store/useAppStore'
import { canActivateStrictMode } from '@/utils/limits'

const RESTRICTION_ICONS = [Trash2, Pencil, ShieldOff]
const TIP_KEYS = ['tip1', 'tip2', 'tip3', 'tip4']

export default function StrictModeScreen() {
  const { t } = useTranslation('strictMode')
  const { t: tc } = useTranslation('common')
  const { t: tp } = useTranslation('profiles')
  const background = useColor('background')
  const red = useColor('red')
  const primary = useColor('primary')
  const { isActive, getRemainingTime, activate } = useStrictMode()
  const plan = useAppStore(s => s.plan)
  const [days, setDays] = useState(1)
  const [remaining, setRemaining] = useState(getRemainingTime())

  useEffect(() => {
    const id = setInterval(() => setRemaining(getRemainingTime()), 1000)
    return () => clearInterval(id)
  }, [isActive])

  const pulse = useSharedValue(1)
  useEffect(() => {
    pulse.value = withRepeat(withTiming(0.3, { duration: 1200, easing: Easing.inOut(Easing.ease) }), -1, true)
  }, [])
  const pulseStyle = useAnimatedStyle(() => ({ opacity: pulse.value }))

  const maxDays = canActivateStrictMode(plan, 30) ? 30 : 1
  const unlockDate = remaining
    ? new Date(Date.now() + ((remaining.days * 24 + remaining.hours) * 3600 + remaining.minutes * 60 + remaining.seconds) * 1000)
    : null

  const restrictions = [t('r1'), t('r2'), tp('unableDeactivateStrict')]

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: background }}
      contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 40, gap: 20 }}
    >
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
        <Text variant="title">{t('title')}</Text>
        <Badge variant={isActive ? 'destructive' : 'outline'}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            {isActive && <Animated.View style={[{ width: 6, height: 6, borderRadius: 3, backgroundColor: '#fff' }, pulseStyle]} />}
            <Text style={{ fontSize: 13, fontWeight: '600', color: isActive ? '#fff' : primary }}>
              {isActive ? t('activeShrt') : t('inactiveShrt')}
            </Text>
          </View>
        </Badge>
      </View>

      <Card>
        <SectionTitle style={{ marginBottom: 8 }}>{t('restrictions')}</SectionTitle>
        {restrictions.map((text, i) => {
          const Icon = RESTRICTION_ICONS[i]
          return (
            <View key={i} style={{ flexDirection: 'row', gap: 10, paddingVertical: 8, alignItems: 'center' }}>
              <View
                style={{
                  width: 28,
                  height: 28,
                  borderRadius: 8,
                  backgroundColor: red + '1A',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <Icon size={14} color={red} strokeWidth={1.8} />
              </View>
              <Text style={{ flex: 1, fontSize: 12 }}>{text}</Text>
            </View>
          )
        })}
      </Card>

      {isActive && remaining ? (
        <Card style={{ borderColor: red + '33', borderWidth: 1 }}>
          <Badge variant="destructive" style={{ alignSelf: 'flex-start', marginBottom: 16 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <Animated.View style={[{ width: 6, height: 6, borderRadius: 3, backgroundColor: '#fff' }, pulseStyle]} />
              <Text style={{ fontSize: 12, fontWeight: '600', color: '#fff' }}>{t('active')}</Text>
            </View>
          </Badge>

          <View style={{ flexDirection: 'row', gap: 8 }}>
            <CountdownCell value={remaining.days} label={tc('days')} />
            <CountdownCell value={remaining.hours} label={tc('hours')} />
            <CountdownCell value={remaining.minutes} label={tc('minutes')} />
            <CountdownCell value={remaining.seconds} label={tc('seconds')} />
          </View>

          {unlockDate && (
            <Text variant="caption" style={{ fontSize: 12, textAlign: 'center', marginTop: 16 }}>
              {t('willDeactivate')}
              {' — '}
              {unlockDate.toLocaleDateString(undefined, { day: 'numeric', month: 'long', year: 'numeric' })}
            </Text>
          )}
        </Card>
      ) : (
        <Card style={{ backgroundColor: primary + '0D', borderColor: primary + '26', borderWidth: 1 }}>
          <Text style={{ fontSize: 14, fontWeight: '700' }}>{t('activate')}</Text>
          <Text variant="caption" style={{ fontSize: 12, marginTop: 4, marginBottom: 20 }}>
            {t('desc')}
          </Text>

          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 }}>
            <Text variant="caption" style={{ fontSize: 11 }}>{t('duration')}</Text>
            <Text style={{ fontSize: 14, fontWeight: '700', color: primary }}>
              {`${days} ${tc('days')}`}
            </Text>
          </View>
          <Slider
            minimumValue={1}
            maximumValue={maxDays}
            step={1}
            value={days}
            onValueChange={setDays}
            minimumTrackTintColor="#f59e0b"
            maximumTrackTintColor="#27272a"
            thumbTintColor="#f59e0b"
          />

          <Button style={{ marginTop: 16 }} onPress={() => activate(days)}>
            {`${t('activate')} — ${days} ${tc('days')}`}
          </Button>

          <Text variant="caption" style={{ fontSize: 11, textAlign: 'center', marginTop: 12 }}>
            {t('onceActivated').replace(/<[^>]+>/g, '')}
          </Text>
        </Card>
      )}

      <View>
        <SectionTitle style={{ marginBottom: 8 }}>{t('tipsTitle')}</SectionTitle>
        <Accordion type="single" collapsible>
          {TIP_KEYS.map((key, i) => (
            <AccordionItem key={key} value={String(i)}>
              <AccordionTrigger>{t(`${key}Title`)}</AccordionTrigger>
              <AccordionContent>
                <Text variant="caption" style={{ fontSize: 12 }}>{t(`${key}Desc`)}</Text>
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </View>
    </ScrollView>
  )
}
