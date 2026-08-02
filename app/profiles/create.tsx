import { useState } from 'react'
import { Pressable, ScrollView } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { SectionTitle } from '@/components/SectionTitle'
import { useColor } from '@/hooks/useColor'
import { useInstalledApps } from '@/hooks/useInstalledApps'
import { useAppStore } from '@/store/useAppStore'
import { PROFILE_TYPE_META, PROFILE_TYPE_ORDER } from '@/lib/profileTypes'
import type { DayOfWeek, LimiterType } from '@/types'

const DAYS: { value: DayOfWeek; key: string }[] = [
  { value: 'mon', key: 'Mon' },
  { value: 'tue', key: 'Tue' },
  { value: 'wed', key: 'Wed' },
  { value: 'thu', key: 'Thu' },
  { value: 'fri', key: 'Fri' },
  { value: 'sat', key: 'Sat' },
  { value: 'sun', key: 'Sun' },
]

const LIMIT_KEY_BY_TYPE: Record<'daily' | 'hourly' | 'weekly', string> = {
  daily: 'dailyLimit',
  hourly: 'hourlyLimit',
  weekly: 'weeklyLimit',
}

export default function CreateProfileScreen() {
  const { t } = useTranslation('profiles')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const card = useColor('card')
  const primary = useColor('primary')
  const border = useColor('border')

  const { apps } = useInstalledApps()
  const addProfile = useAppStore(s => s.addProfile)

  const [name, setName] = useState('')
  const [type, setType] = useState<LimiterType>('daily')
  const [selectedApps, setSelectedApps] = useState<string[]>([])
  const [limitMinutes, setLimitMinutes] = useState('60')
  const [startTime, setStartTime] = useState('09:00')
  const [endTime, setEndTime] = useState('17:30')
  const [days, setDays] = useState<DayOfWeek[]>(['mon', 'tue', 'wed', 'thu', 'fri'])

  const toggleApp = (packageName: string) => {
    setSelectedApps(prev =>
      prev.includes(packageName) ? prev.filter(p => p !== packageName) : [...prev, packageName]
    )
  }

  const toggleDay = (day: DayOfWeek) => {
    setDays(prev => (prev.includes(day) ? prev.filter(d => d !== day) : [...prev, day]))
  }

  const canSubmit = name.trim().length > 0 && selectedApps.length > 0

  const onSubmit = () => {
    if (!canSubmit) return

    addProfile({
      id: Date.now().toString(),
      name: name.trim(),
      type,
      apps: selectedApps,
      keywords: [],
      isActive: true,
      createdAt: Date.now(),
      ...(type === 'daily' && {
        dailyLimitMinutes: Number(limitMinutes) || 60,
        dailyUsedMinutes: 0,
        dailyResetAt: Date.now(),
      }),
      ...(type === 'hourly' && {
        hourlyLimitMinutes: Number(limitMinutes) || 30,
        hourlyUsedMinutes: 0,
      }),
      ...(type === 'weekly' && {
        weeklyLimitMinutes: Number(limitMinutes) || 60,
        weeklyUsedMinutes: 0,
        weeklyResetAt: Date.now(),
      }),
      ...(type === 'interval' && {
        intervalConfig: { startTime, endTime, days },
      }),
    })

    router.back()
  }

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: background }}
      contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 60, gap: 20 }}
    >
      <Text variant="title">{t('newProfile')}</Text>

      <View>
        <SectionTitle style={{ marginBottom: 8 }}>{t('profileName')}</SectionTitle>
        <Input placeholder={t('namePlaceholder')} value={name} onChangeText={setName} />
      </View>

      <View>
        <SectionTitle style={{ marginBottom: 8 }}>{t('step1')}</SectionTitle>
        <Tabs value={type} onValueChange={v => setType(v as LimiterType)}>
          <TabsList>
            {PROFILE_TYPE_ORDER.map(pt => (
              <TabsTrigger key={pt} value={pt}>{t(PROFILE_TYPE_META[pt].labelKey)}</TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
      </View>

      <View>
        <SectionTitle style={{ marginBottom: 8 }}>Applications</SectionTitle>
        <View style={{ backgroundColor: card, borderRadius: 14, borderWidth: 1, borderColor: border, overflow: 'hidden' }}>
          {apps.map((app, i) => {
            const selected = selectedApps.includes(app.packageName)
            return (
              <Pressable
                key={app.packageName}
                onPress={() => toggleApp(app.packageName)}
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  gap: 10,
                  paddingVertical: 12,
                  paddingHorizontal: 14,
                  borderTopWidth: i === 0 ? 0 : 1,
                  borderTopColor: border,
                }}
              >
                <View
                  style={{
                    width: 20,
                    height: 20,
                    borderRadius: 5,
                    borderWidth: 1.5,
                    borderColor: selected ? primary : border,
                    backgroundColor: selected ? primary : 'transparent',
                  }}
                />
                <Text style={{ fontSize: 14 }}>{app.appName}</Text>
              </Pressable>
            )
          })}
        </View>
      </View>

      {(type === 'daily' || type === 'hourly' || type === 'weekly') && (
        <View>
          <SectionTitle style={{ marginBottom: 8 }}>{t(LIMIT_KEY_BY_TYPE[type])}</SectionTitle>
          <Input
            keyboardType="number-pad"
            placeholder="60"
            value={limitMinutes}
            onChangeText={setLimitMinutes}
          />
        </View>
      )}

      {type === 'interval' && (
        <View style={{ gap: 16 }}>
          <View style={{ flexDirection: 'row', gap: 12 }}>
            <View style={{ flex: 1 }}>
              <SectionTitle style={{ marginBottom: 8 }}>{t('timeRanges')}</SectionTitle>
              <Input placeholder="09:00" value={startTime} onChangeText={setStartTime} />
            </View>
            <View style={{ flex: 1 }}>
              <SectionTitle style={{ marginBottom: 8, opacity: 0 }}>{t('timeRanges')}</SectionTitle>
              <Input placeholder="17:30" value={endTime} onChangeText={setEndTime} />
            </View>
          </View>

          <View>
            <SectionTitle style={{ marginBottom: 8 }}>{t('activeDays')}</SectionTitle>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
              {DAYS.map(d => {
                const active = days.includes(d.value)
                return (
                  <Pressable
                    key={d.value}
                    onPress={() => toggleDay(d.value)}
                    style={{
                      paddingVertical: 8,
                      paddingHorizontal: 14,
                      borderRadius: 999,
                      backgroundColor: active ? primary : card,
                      borderWidth: 1,
                      borderColor: active ? primary : border,
                    }}
                  >
                    <Text style={{ fontSize: 12, fontWeight: '600', color: active ? '#09090b' : undefined }}>
                      {tc(d.key)}
                    </Text>
                  </Pressable>
                )
              })}
            </View>
          </View>
        </View>
      )}

      <Button onPress={onSubmit} disabled={!canSubmit}>
        {t('create')}
      </Button>
    </ScrollView>
  )
}
