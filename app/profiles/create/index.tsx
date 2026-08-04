import { Pressable, ScrollView } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { ChevronRight } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { AppHeader } from '@/components/AppHeader'
import { SubScreenHeader } from '@/components/SubScreenHeader'
import { useColor } from '@/hooks/useColor'
import { PROFILE_TYPE_META, PROFILE_TYPE_ORDER } from '@/lib/profileTypes'

// First step of profile creation: pick a type, then move to its dedicated
// form — mirrors the extension's TYPE_OPTIONS step (TimerProfileCreate.tsx)
// but as its own screen instead of a wizard step.
export default function ChooseProfileTypeScreen() {
  const { t } = useTranslation('profiles')
  const router = useRouter()
  const background = useColor('background')
  const card = useColor('card')
  const border = useColor('border')
  const mutedForeground = useColor('mutedForeground')

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <SubScreenHeader title={t('newProfile')} />
      <ScrollView contentContainerStyle={{ padding: 20, paddingTop: 4, gap: 12, paddingBottom: 40 }}>
        <Text variant="caption" style={{ marginBottom: 4 }}>{t('chooseTypeDesc')}</Text>
        {PROFILE_TYPE_ORDER.map(pt => {
          const meta = PROFILE_TYPE_META[pt]
          const Icon = meta.icon
          return (
            <Pressable
              key={pt}
              onPress={() => router.push(`/profiles/create/${pt}`)}
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                gap: 14,
                backgroundColor: card,
                borderWidth: 1,
                borderColor: border,
                borderRadius: 14,
                padding: 16,
              }}
            >
              <View
                style={{
                  width: 44, height: 44, borderRadius: 12,
                  backgroundColor: meta.color + '1A',
                  alignItems: 'center', justifyContent: 'center',
                }}
              >
                <Icon color={meta.color} size={22} strokeWidth={1.8} />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 15, fontWeight: '700' }}>{t(meta.labelKey)}</Text>
                <Text variant="caption" style={{ fontSize: 12, marginTop: 2, lineHeight: 16 }}>
                  {t(meta.createDescKey)}
                </Text>
              </View>
              <ChevronRight size={18} color={mutedForeground} />
            </Pressable>
          )
        })}
      </ScrollView>
    </View>
  )
}
