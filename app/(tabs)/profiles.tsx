import { FlatList, Pressable } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { Clock3 } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { formatMinutes } from '@/utils/analytics'
import { PROFILE_TYPE_META } from '@/lib/profileTypes'
import { AppHeader } from '@/components/AppHeader'
import type { LimiterProfile } from '@/types'

export default function ProfilesScreen() {
  const { t } = useTranslation('profiles')
  const router = useRouter()
  const background = useColor('background')
  const profiles = useAppStore(s => s.limiterProfiles)

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <View style={{ flex: 1, paddingTop: 20, paddingHorizontal: 20 }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <Text variant="title">{t('title')}</Text>
          <Button variant="outline" size="sm" onPress={() => router.push('/profiles/create')}>
            {t('create')}
          </Button>
        </View>

        <FlatList
          data={profiles}
          keyExtractor={item => item.id}
          contentContainerStyle={{ gap: 12, paddingBottom: 40 }}
          ItemSeparatorComponent={() => <View style={{ height: 12 }} />}
          renderItem={({ item }) => <ProfileCard profile={item} onPress={() => router.push(`/profiles/${item.id}`)} />}
          ListEmptyComponent={
            <Text variant="caption" style={{ textAlign: 'center', marginTop: 40 }}>
              {t('noProfileDesc')}
            </Text>
          }
        />
      </View>
    </View>
  )
}

function ProfileCard({ profile, onPress }: { profile: LimiterProfile; onPress: () => void }) {
  const { t } = useTranslation('profiles')
  const { t: ts } = useTranslation('strictMode')
  const meta = PROFILE_TYPE_META[profile.type]
  const Icon = meta.icon

  const usedMinutes =
    profile.type === 'daily' ? profile.dailyUsedMinutes ?? 0 :
    profile.type === 'hourly' ? profile.hourlyUsedMinutes ?? 0 :
    profile.weeklyUsedMinutes ?? 0
  const limitMinutes =
    profile.type === 'daily' ? profile.dailyLimitMinutes ?? 0 :
    profile.type === 'hourly' ? profile.hourlyLimitMinutes ?? 0 :
    profile.weeklyLimitMinutes ?? 0
  const progressValue = limitMinutes > 0 ? Math.min(100, (usedMinutes / limitMinutes) * 100) : 0
  const hasBudget = profile.type !== 'interval'

  return (
    <Pressable onPress={onPress}>
    <Card style={{ overflow: 'hidden', position: 'relative', paddingLeft: 21 }}>
      <View style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: 3, backgroundColor: meta.color }} />

      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 12 }}>
        <View
          style={{
            width: 32,
            height: 32,
            borderRadius: 8,
            backgroundColor: meta.color + '26',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Icon color={meta.color} size={16} strokeWidth={1.8} />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={{ fontSize: 14, fontWeight: '700' }}>{profile.name}</Text>
          <Text variant="caption" style={{ fontSize: 11 }}>
            {`${t(profile.apps.length === 1 ? 'getSiteCount_one' : 'getSiteCount_other', { count: profile.apps.length })} · ${t(meta.labelKey)}`}
          </Text>
        </View>
        <Badge variant="outline">{profile.isActive ? ts('activeShrt') : t('waiting')}</Badge>
      </View>

      {hasBudget && (
        <View>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 }}>
            <Text variant="caption" style={{ fontSize: 10, fontFamily: 'monospace' }}>{formatMinutes(usedMinutes)}</Text>
            <Text variant="caption" style={{ fontSize: 10, fontFamily: 'monospace' }}>{formatMinutes(limitMinutes)}</Text>
          </View>
          <Progress value={progressValue} height={8} />
        </View>
      )}

      {profile.type === 'interval' && profile.intervalConfig && (
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <Clock3 size={14} color="#71717a" />
          <Text variant="caption" style={{ fontSize: 12 }}>
            {`${profile.intervalConfig.startTime}–${profile.intervalConfig.endTime} · ${profile.intervalConfig.days.join(' ')}`}
          </Text>
        </View>
      )}
    </Card>
    </Pressable>
  )
}
