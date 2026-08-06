import { useEffect, useMemo, useState } from 'react'
import { Platform, ScrollView } from 'react-native'
import { useTranslation } from 'react-i18next'
import Animated, { useSharedValue, useAnimatedStyle, withRepeat, withTiming, Easing } from 'react-native-reanimated'
import { Trash2, Pencil, ShieldOff, ShieldX, ShieldCheck, Hourglass, ShieldAlert } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Picker } from '@/components/ui/picker'
import { FaqAccordion } from '@/components/FaqAccordion'
import { CountdownCell } from '@/components/CountdownCell'
import { SectionTitle } from '@/components/SectionTitle'
import { AppHeader } from '@/components/AppHeader'
import { AccessibilityWarningBanner } from '@/components/AccessibilityWarningBanner'
import { useColor } from '@/hooks/useColor'
import { useStrictMode } from '@/hooks/useStrictMode'
import { useAppStore } from '@/store/useAppStore'
import * as Blocker from '@/modules/blocker'
import { isPremium, maxStrictSecondsFor } from '@/utils/limits'

const RESTRICTION_ICONS = [Trash2, Pencil, ShieldOff, ShieldX]
const TIP_KEYS = ['tip1', 'tip2', 'tip3', 'tip4']

const pad2 = (n: number) => String(n).padStart(2, '0')

export default function StrictModeScreen() {
  const { t } = useTranslation('strictMode')
  const { t: tc } = useTranslation('common')
  const { t: tp } = useTranslation('profiles')
  const background = useColor('background')
  const red = useColor('red')
  const primary = useColor('primary')
  const { isActive, getRemainingTime, activate } = useStrictMode()
  const plan = useAppStore(s => s.plan)
  const blockedApps = useAppStore(s => s.blockedApps)
  const isDeviceAdminActive = useAppStore(s => s.isDeviceAdminActive)
  const premium = isPremium(plan)
  const maxSeconds = maxStrictSecondsFor(plan)
  const maxDaysExtra = Math.max(0, Math.floor(maxSeconds / 86400) - 1)

  const [extraDays, setExtraDays] = useState('0')
  const [hours, setHours] = useState('1')
  const [minutes, setMinutes] = useState('0')
  const [seconds, setSeconds] = useState('0')
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

  const unlockDate = remaining
    ? new Date(Date.now() + ((remaining.days * 24 + remaining.hours) * 3600 + remaining.minutes * 60 + remaining.seconds) * 1000)
    : null

  const dayOptions = useMemo(() => Array.from({ length: maxDaysExtra + 1 }, (_, i) => ({
    label: `${i} ${tc('days')}`,
    value: String(i),
  })), [maxDaysExtra])
  const hourOptions = useMemo(() => Array.from({ length: 24 }, (_, i) => ({ label: `${pad2(i)} ${tc('hours')}`, value: String(i) })), [])
  const minuteOptions = useMemo(() => Array.from({ length: 60 }, (_, i) => ({ label: `${pad2(i)} ${tc('minutes')}`, value: String(i) })), [])
  const secondOptions = useMemo(() => Array.from({ length: 60 }, (_, i) => ({ label: `${pad2(i)} ${tc('seconds')}`, value: String(i) })), [])

  const totalSeconds = Math.min(
    maxSeconds,
    Number(extraDays) * 86400 + Number(hours) * 3600 + Number(minutes) * 60 + Number(seconds)
  )
  const canActivate = totalSeconds > 0

  const restrictions = [t('r1'), t('r2'), tp('unableDeactivateStrict'), t('uninstallRestriction')]

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ padding: 20, paddingBottom: 40, gap: 20 }}
      >
      <AccessibilityWarningBanner active={isActive || blockedApps.length > 0} />
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

      {Platform.OS === 'android' && (
        <View
          style={{
            flexDirection: 'row', alignItems: 'center', gap: 10,
            padding: 12, borderRadius: 12,
            backgroundColor: isDeviceAdminActive ? '#34d399' + '14' : red + '14',
            borderWidth: 1, borderColor: isDeviceAdminActive ? '#34d399' + '33' : red + '33',
          }}
        >
          {isDeviceAdminActive ? <ShieldCheck size={18} color="#34d399" /> : <ShieldX size={18} color={red} />}
          <View style={{ flex: 1 }}>
            <Text style={{ fontSize: 12, fontWeight: '600' }}>
              {isDeviceAdminActive ? t('deviceAdminActive') : t('deviceAdminInactive')}
            </Text>
            {!isDeviceAdminActive && (
              <Text variant="caption" style={{ fontSize: 11, marginTop: 2, lineHeight: 15 }}>
                {t('deviceAdminDesc')}
              </Text>
            )}
          </View>
          {!isDeviceAdminActive && (
            <Button size="sm" variant="outline" onPress={() => Blocker.requestDeviceAdmin(t('deviceAdminExplanation'))}>
              {t('deviceAdminEnable')}
            </Button>
          )}
        </View>
      )}

      {isActive && remaining ? (
        <Card style={{ borderColor: red + '33', borderWidth: 1, gap: 16 }}>
          <Badge variant="destructive" style={{ alignSelf: 'flex-start' }}>
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
            <Text variant="caption" style={{ fontSize: 12, textAlign: 'center' }}>
              {t('willDeactivate')}
              {' — '}
              {unlockDate.toLocaleDateString(undefined, { day: 'numeric', month: 'long', year: 'numeric' })}
            </Text>
          )}
        </Card>
      ) : (
        <Card style={{ backgroundColor: primary + '0D', borderColor: primary + '26', borderWidth: 1, gap: 16 }}>
          <View>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <Hourglass size={16} color={primary} />
              <Text style={{ fontSize: 14, fontWeight: '700' }}>{t('activate')}</Text>
            </View>
            <Text variant="caption" style={{ fontSize: 12 }}>{t('desc')}</Text>
          </View>

          <View style={{ gap: 10 }}>
            <Text variant="caption" style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: 0.5 }}>
              {t('duration')}
            </Text>
            <View style={{ flexDirection: 'row', gap: 8 }}>
              {premium && (
                <View style={{ flex: 1 }}>
                  <Picker
                    variant="outline"
                    options={dayOptions}
                    value={extraDays}
                    onValueChange={setExtraDays}
                    modalTitle={tc('days')}
                  />
                </View>
              )}
              <View style={{ flex: 1 }}>
                <Picker
                  variant="outline"
                  options={hourOptions}
                  value={hours}
                  onValueChange={setHours}
                  modalTitle={tc('hours')}
                />
              </View>
              <View style={{ flex: 1 }}>
                <Picker
                  variant="outline"
                  options={minuteOptions}
                  value={minutes}
                  onValueChange={setMinutes}
                  modalTitle={tc('minutes')}
                />
              </View>
              <View style={{ flex: 1 }}>
                <Picker
                  variant="outline"
                  options={secondOptions}
                  value={seconds}
                  onValueChange={setSeconds}
                  modalTitle={tc('seconds')}
                />
              </View>
            </View>
          </View>

          <View
            style={{
              flexDirection: 'row', alignItems: 'flex-start', gap: 8,
              padding: 10, borderRadius: 10,
              backgroundColor: red + '14', borderWidth: 1, borderColor: red + '26',
            }}
          >
            <ShieldAlert size={14} color={red} style={{ marginTop: 1 }} />
            <Text variant="caption" style={{ fontSize: 11, flex: 1, lineHeight: 16 }}>
              {t('onceActivated').replace(/<[^>]+>/g, '')}
            </Text>
          </View>

          <Button onPress={() => activate(totalSeconds)} disabled={!canActivate}>
            {t('activate')}
          </Button>
        </Card>
      )}

      <View>
        <SectionTitle style={{ marginBottom: 8 }}>{t('tipsTitle')}</SectionTitle>
        <FaqAccordion
          items={TIP_KEYS.map(key => ({ id: key, question: t(`${key}Title`), answer: t(`${key}Desc`) }))}
        />
      </View>
      </ScrollView>
    </View>
  )
}
