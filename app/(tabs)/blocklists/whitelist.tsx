import { useState } from 'react'
import { FlatList } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { Globe, Lock } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { AppHeader } from '@/components/AppHeader'
import { SubScreenHeader } from '@/components/SubScreenHeader'
import { BlockListRow } from '@/components/BlockListRow'
import { EntryIcon } from '@/components/EntryIcon'
import { LimitBadge, EmptyState, AddRow } from '@/components/blocklist-ui'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { isPremium } from '@/utils/limits'

export default function WhitelistBlockListScreen() {
  const { t } = useTranslation('blockLists')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const mutedForeground = useColor('mutedForeground')
  const primary = useColor('primary')

  const plan = useAppStore(s => s.plan)
  const whitelist = useAppStore(s => s.whitelistedSites)
  const addWhitelistedSite = useAppStore(s => s.addWhitelistedSite)
  const removeWhitelistedSite = useAppStore(s => s.removeWhitelistedSite)

  const [input, setInput] = useState('')

  const onAdd = () => {
    const trimmed = input.trim().toLowerCase()
    if (!trimmed) return
    addWhitelistedSite(trimmed)
    setInput('')
  }

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <SubScreenHeader title={t('whitelist')} right={isPremium(plan) ? <LimitBadge count={whitelist.length} max={Infinity} /> : undefined} />
      <View style={{ flex: 1, paddingHorizontal: 20, paddingTop: 8 }}>
        {!isPremium(plan) ? (
          <View
            style={{
              backgroundColor: primary + '0D',
              borderColor: primary + '26',
              borderWidth: 1,
              borderRadius: 14,
              padding: 16,
              alignItems: 'center',
              gap: 8,
            }}
          >
            <Lock size={20} color={primary} />
            <Text style={{ fontSize: 14, fontWeight: '700' }}>{t('whitelistPremium')}</Text>
            <Text variant="caption" style={{ fontSize: 12, textAlign: 'center' }}>{t('whitelistPremiumDesc')}</Text>
            <Button size="sm" style={{ marginTop: 8 }} onPress={() => router.push('/pricing')}>{tc('upgrade')}</Button>
          </View>
        ) : (
          <>
            <AddRow value={input} onChangeText={setInput} onAdd={onAdd} placeholder={t('whitePlaceholder')} />
            <FlatList
              data={whitelist}
              keyExtractor={item => item.id}
              contentContainerStyle={{ gap: 8, paddingBottom: 24 }}
              renderItem={({ item }) => (
                <BlockListRow
                  icon={<EntryIcon name={item.domain} type="site" color={mutedForeground} size={24} />}
                  label={item.domain}
                  onRemove={() => removeWhitelistedSite(item.id)}
                />
              )}
              ListEmptyComponent={<EmptyState icon={<Globe size={28} color={mutedForeground} />} label={t('noWhite')} />}
            />
          </>
        )}
      </View>
    </View>
  )
}
