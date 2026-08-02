import { Pressable, ScrollView } from 'react-native'
import { useLocalSearchParams, useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { Clock3, Trash2 } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Card } from '@/components/ui/card'
import { Switch } from '@/components/ui/switch'
import { Progress } from '@/components/ui/progress'
import { Separator } from '@/components/ui/separator'
import { AlertDialog, useAlertDialog } from '@/components/ui/alert-dialog'
import { SectionTitle } from '@/components/SectionTitle'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { useInstalledApps } from '@/hooks/useInstalledApps'
import { formatMinutes } from '@/utils/analytics'
import { PROFILE_TYPE_META } from '@/lib/profileTypes'

export default function ProfileDetailScreen() {
  const { t } = useTranslation('profiles')
  const { t: ts } = useTranslation('strictMode')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const border = useColor('border')
  const red = useColor('red')

  const { id } = useLocalSearchParams<{ id: string }>()
  const profile = useAppStore(s => s.limiterProfiles.find(p => p.id === id))
  const activateProfile = useAppStore(s => s.activateProfile)
  const deleteProfile = useAppStore(s => s.deleteProfile)
  const strictModeActive = useAppStore(s => s.strictMode.isActive)
  const { apps: installedApps } = useInstalledApps()
  const deleteDialog = useAlertDialog()

  if (!profile) {
    return (
      <View style={{ flex: 1, backgroundColor: background, alignItems: 'center', justifyContent: 'center', padding: 20 }}>
        <Text variant="caption">{t('profileNotExists')}</Text>
      </View>
    )
  }

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
  const remainingMinutes = Math.max(0, limitMinutes - usedMinutes)

  const appNames = profile.apps.map(pkg => installedApps.find(a => a.packageName === pkg)?.appName ?? pkg)

  const onDelete = () => {
    deleteProfile(profile.id)
    router.back()
  }

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: background }}
      contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 60, gap: 20 }}
    >
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
        <View
          style={{
            width: 44, height: 44, borderRadius: 12,
            backgroundColor: meta.color + '26',
            alignItems: 'center', justifyContent: 'center',
          }}
        >
          <Icon color={meta.color} size={22} strokeWidth={1.8} />
        </View>
        <View style={{ flex: 1 }}>
          <Text variant="title" style={{ fontSize: 20 }}>{profile.name}</Text>
          <Text variant="caption" style={{ fontSize: 12 }}>{t(meta.labelKey)}</Text>
        </View>
      </View>

      <Card>
        <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
          <View>
            <Text style={{ fontSize: 14, fontWeight: '600' }}>Statut</Text>
            <Text variant="caption" style={{ fontSize: 11, marginTop: 2 }}>
              {profile.isActive ? ts('activeShrt') : t('waiting')}
            </Text>
          </View>
          <Switch
            value={profile.isActive}
            onValueChange={() => { if (!strictModeActive) activateProfile(profile.id) }}
            disabled={strictModeActive}
          />
        </View>
      </Card>

      {hasBudget ? (
        <Card>
          <SectionTitle style={{ marginBottom: 12 }}>{t('consumption')}</SectionTitle>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 }}>
            <Text variant="caption" style={{ fontSize: 11, fontFamily: 'monospace' }}>
              {formatMinutes(usedMinutes)} {t('timeUsed').toLowerCase()}
            </Text>
            <Text variant="caption" style={{ fontSize: 11, fontFamily: 'monospace' }}>
              {formatMinutes(limitMinutes)}
            </Text>
          </View>
          <Progress value={progressValue} height={10} />
          <Text variant="caption" style={{ fontSize: 11, marginTop: 10 }}>
            {t('remaining')}: {formatMinutes(remainingMinutes)}
          </Text>
        </Card>
      ) : (
        profile.intervalConfig && (
          <Card>
            <SectionTitle style={{ marginBottom: 12 }}>{t('timeRanges')}</SectionTitle>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              <Clock3 size={16} color={meta.color} />
              <Text style={{ fontSize: 13, fontWeight: '600' }}>
                {profile.intervalConfig.startTime}–{profile.intervalConfig.endTime}
              </Text>
            </View>
            <Text variant="caption" style={{ fontSize: 12, marginTop: 8 }}>
              {profile.intervalConfig.days.join(', ')}
            </Text>
          </Card>
        )
      )}

      <Card style={{ padding: 0 }}>
        <View style={{ padding: 16, paddingBottom: 8 }}>
          <SectionTitle>{t('watchedSites')}</SectionTitle>
        </View>
        {appNames.length === 0 ? (
          <Text variant="caption" style={{ fontSize: 12, padding: 16, paddingTop: 0 }}>{t('noSite')}</Text>
        ) : (
          appNames.map((name, i) => (
            <View key={name + i}>
              {i > 0 && <Separator />}
              <View style={{ paddingHorizontal: 16, paddingVertical: 12 }}>
                <Text style={{ fontSize: 14 }}>{name}</Text>
              </View>
            </View>
          ))
        )}
      </Card>

      <Pressable
        onPress={deleteDialog.open}
        disabled={strictModeActive}
      >
        <Card style={{ backgroundColor: red + '0D', borderColor: red + '33', borderWidth: 1 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
            <Trash2 size={16} color={red} />
            <Text style={{ color: red, fontSize: 14, fontWeight: '600' }}>
              {strictModeActive ? t('strictBlocked') : t('deleteProfile')}
            </Text>
          </View>
        </Card>
      </Pressable>

      <AlertDialog
        isVisible={deleteDialog.isVisible}
        onClose={deleteDialog.close}
        title={t('deleteProfile')}
        description={t('deleteDesc')}
        confirmText={tc('delete')}
        onConfirm={onDelete}
      />
    </ScrollView>
  )
}
