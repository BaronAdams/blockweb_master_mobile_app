import { useState } from 'react'
import { FlatList } from 'react-native'
import { useTranslation } from 'react-i18next'
import { Globe } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { AppHeader } from '@/components/AppHeader'
import { SubScreenHeader } from '@/components/SubScreenHeader'
import { BlockListRow } from '@/components/BlockListRow'
import { EntryIcon } from '@/components/EntryIcon'
import { LimitBadge, EmptyState, AddRow } from '@/components/blocklist-ui'
import { AccessibilityWarningBanner } from '@/components/AccessibilityWarningBanner'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { useToast } from '@/components/ui/toast'
import { limitsFor, isPremium } from '@/utils/limits'

export default function WebsitesBlockListScreen() {
  const { t } = useTranslation('blockLists')
  const background = useColor('background')
  const mutedForeground = useColor('mutedForeground')
  const toast = useToast()

  const plan = useAppStore(s => s.plan)
  const limits = limitsFor(plan)
  const websites = useAppStore(s => s.blockedWebsites)
  const addBlockedWebsite = useAppStore(s => s.addBlockedWebsite)
  const removeBlockedWebsite = useAppStore(s => s.removeBlockedWebsite)

  const onRemove = (id: string) => {
    if (!removeBlockedWebsite(id)) toast.warning(t('strictBlocked'))
  }

  const [input, setInput] = useState('')
  const atLimit = !isPremium(plan) && websites.length >= limits.maxBlockedWebsites

  const onAdd = () => {
    if (atLimit) return
    const trimmed = input.trim().toLowerCase()
    if (!trimmed) return
    addBlockedWebsite({ id: Date.now().toString(), domain: trimmed, isBlocked: true, addedAt: Date.now() })
    setInput('')
  }

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <SubScreenHeader title={t('blockedDomains')} right={<LimitBadge count={websites.length} max={limits.maxBlockedWebsites} />} />
      <View style={{ flex: 1, paddingHorizontal: 20, paddingTop: 8 }}>
        <AccessibilityWarningBanner active={websites.some(w => w.isBlocked)} />
        <AddRow
          value={input}
          onChangeText={setInput}
          onAdd={onAdd}
          placeholder={atLimit ? t('limitReached') : t('domainPlaceholder')}
          disabled={atLimit}
        />
        <FlatList
          data={websites}
          keyExtractor={item => item.id}
          contentContainerStyle={{ gap: 8, paddingBottom: 24 }}
          renderItem={({ item }) => (
            <BlockListRow
              icon={<EntryIcon name={item.domain} type="site" color={mutedForeground} size={24} />}
              label={item.domain}
              onRemove={() => onRemove(item.id)}
            />
          )}
          ListEmptyComponent={<EmptyState icon={<Globe size={28} color={mutedForeground} />} label={t('noDomain')} />}
        />
      </View>
    </View>
  )
}
