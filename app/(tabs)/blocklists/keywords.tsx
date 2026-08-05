import { useState } from 'react'
import { FlatList } from 'react-native'
import { useTranslation } from 'react-i18next'
import { Hash } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { AppHeader } from '@/components/AppHeader'
import { SubScreenHeader } from '@/components/SubScreenHeader'
import { BlockListRow } from '@/components/BlockListRow'
import { LimitBadge, EmptyState, AddRow } from '@/components/blocklist-ui'
import { AccessibilityWarningBanner } from '@/components/AccessibilityWarningBanner'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { limitsFor, isPremium } from '@/utils/limits'

export default function KeywordsBlockListScreen() {
  const { t } = useTranslation('blockLists')
  const background = useColor('background')
  const mutedForeground = useColor('mutedForeground')

  const plan = useAppStore(s => s.plan)
  const limits = limitsFor(plan)
  const keywords = useAppStore(s => s.blockedKeywords)
  const addKeyword = useAppStore(s => s.addKeyword)
  const removeKeyword = useAppStore(s => s.removeKeyword)

  const [input, setInput] = useState('')
  const atLimit = !isPremium(plan) && keywords.length >= limits.maxKeywords

  const onAdd = () => {
    if (atLimit) return
    const trimmed = input.trim()
    if (!trimmed) return
    addKeyword(trimmed)
    setInput('')
  }

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <SubScreenHeader title={t('blockedKeywords')} right={<LimitBadge count={keywords.length} max={limits.maxKeywords} />} />
      <View style={{ flex: 1, paddingHorizontal: 20, paddingTop: 8 }}>
        <AccessibilityWarningBanner active={keywords.length > 0} />
        <AddRow
          value={input}
          onChangeText={setInput}
          onAdd={onAdd}
          placeholder={atLimit ? t('limitReached') : t('keywordPlaceholder')}
          disabled={atLimit}
        />
        <FlatList
          data={keywords}
          keyExtractor={item => item.id}
          contentContainerStyle={{ gap: 8, paddingBottom: 24 }}
          renderItem={({ item }) => (
            <BlockListRow
              icon={<Text style={{ color: mutedForeground, fontFamily: 'monospace', fontSize: 13 }}>#</Text>}
              label={item.keyword}
              onRemove={() => removeKeyword(item.id)}
            />
          )}
          ListEmptyComponent={<EmptyState icon={<Hash size={28} color={mutedForeground} />} label={t('noKeyword')} />}
        />
      </View>
    </View>
  )
}
