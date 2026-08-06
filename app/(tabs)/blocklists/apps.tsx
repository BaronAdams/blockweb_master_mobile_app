import { useState } from 'react'
import { FlatList, Pressable } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { Check } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { SearchBar } from '@/components/ui/searchbar'
import { Spinner } from '@/components/ui/spinner'
import { AppHeader } from '@/components/AppHeader'
import { SubScreenHeader } from '@/components/SubScreenHeader'
import { SectionTitle } from '@/components/SectionTitle'
import { AppIcon } from '@/components/AppIcon'
import { BlockListRow } from '@/components/BlockListRow'
import { AccessibilityWarningBanner } from '@/components/AccessibilityWarningBanner'
import { useColor } from '@/hooks/useColor'
import { useInstalledApps } from '@/hooks/useInstalledApps'
import { useAppStore } from '@/store/useAppStore'
import { limitsFor, isPremium } from '@/utils/limits'

// Installed-apps picker: browse every app on the phone (real apps + icons
// on Android via react-native-launcher-kit, see hooks/useInstalledApps.ts),
// tap to stage a selection, then confirm to commit it as the blocked-apps
// set. iOS has no equivalent listing API, so it still shows the curated
// demo list there.
export default function AppsBlockListScreen() {
  const { t } = useTranslation('blockLists')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const card = useColor('card')
  const border = useColor('border')
  const primary = useColor('primary')
  const primaryForeground = useColor('primaryForeground')

  const plan = useAppStore(s => s.plan)
  const limits = limitsFor(plan)
  const blockedApps = useAppStore(s => s.blockedApps)
  const addBlockedApp = useAppStore(s => s.addBlockedApp)
  const removeBlockedApp = useAppStore(s => s.removeBlockedApp)
  const strictMode = useAppStore(s => s.strictMode)

  const { apps: installedApps, loading: appsLoading } = useInstalledApps()
  const [search, setSearch] = useState('')
  const [selected, setSelected] = useState<Set<string>>(
    () => new Set(blockedApps.map(a => a.packageName))
  )

  const filtered = installedApps.filter(a => a.appName.toLowerCase().includes(search.toLowerCase()))
  const atLimit = !isPremium(plan) && selected.size >= limits.maxBlockedApps

  // Deletes both the committed store entry and the in-progress selection —
  // otherwise onConfirm's diff below would see `isSelected && !existing`
  // and silently re-add the app that was just removed here.
  const onDelete = (id: string, packageName: string) => {
    removeBlockedApp(id)
    setSelected(prev => {
      const next = new Set(prev)
      next.delete(packageName)
      return next
    })
  }

  const toggle = (packageName: string) => {
    setSelected(prev => {
      const next = new Set(prev)
      if (next.has(packageName)) {
        // Already-blocked apps can't be unchecked while Strict Mode is
        // active — matches the store's own removeBlockedApp guard, kept
        // here too since this only ever mutates local staged selection,
        // not the store directly.
        if (strictMode.isActive) return prev
        next.delete(packageName)
      } else {
        if (!isPremium(plan) && next.size >= limits.maxBlockedApps) return prev
        next.add(packageName)
      }
      return next
    })
  }

  const onConfirm = () => {
    for (const app of installedApps) {
      const isSelected = selected.has(app.packageName)
      const existing = blockedApps.find(b => b.packageName === app.packageName)
      if (isSelected && !existing) {
        addBlockedApp({
          id: `${Date.now()}-${app.packageName}`,
          packageName: app.packageName,
          appName: app.appName,
          isBlocked: true,
          addedAt: Date.now(),
        })
      } else if (!isSelected && existing) {
        removeBlockedApp(existing.id)
      }
    }
    router.back()
  }

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <SubScreenHeader title={t('applications')} />
      <View style={{ flex: 1, paddingHorizontal: 20 }}>
        <Text variant="caption" style={{ marginBottom: 12 }}>{t('applicationsDesc')}</Text>
        <AccessibilityWarningBanner active={selected.size > 0} />

        {blockedApps.length > 0 && (
          <View style={{ marginBottom: 16 }}>
            <SectionTitle style={{ marginBottom: 8 }}>{t('blockedApps')}</SectionTitle>
            <View style={{ gap: 8 }}>
              {blockedApps.map(app => {
                const installed = installedApps.find(a => a.packageName === app.packageName)
                return (
                  <BlockListRow
                    key={app.id}
                    icon={<AppIcon appName={app.appName} icon={installed?.icon} size={28} />}
                    label={app.appName}
                    locked={strictMode.isActive}
                    onRemove={() => onDelete(app.id, app.packageName)}
                  />
                )
              })}
            </View>
          </View>
        )}

        <SearchBar
          placeholder={t('searchApp')}
          value={search}
          onChangeText={setSearch}
          containerStyle={{ marginBottom: 12 }}
        />

        {appsLoading ? (
          <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', paddingBottom: 80 }}>
            <Spinner variant="circle" label={tc('loading')} showLabel />
          </View>
        ) : (
        <FlatList
          data={filtered}
          keyExtractor={item => item.packageName}
          contentContainerStyle={{ gap: 8, paddingBottom: 100 }}
          renderItem={({ item }) => {
            const isSelected = selected.has(item.packageName)
            const lockedByStrictMode = isSelected && strictMode.isActive
            const disabled = (!isSelected && atLimit) || lockedByStrictMode
            return (
              <Pressable
                onPress={() => toggle(item.packageName)}
                disabled={disabled}
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  gap: 12,
                  paddingVertical: 10,
                  paddingHorizontal: 12,
                  backgroundColor: card,
                  borderWidth: 1,
                  borderColor: isSelected ? primary : border,
                  borderRadius: 10,
                  opacity: disabled ? 0.4 : 1,
                }}
              >
                <AppIcon appName={item.appName} icon={item.icon} size={36} />
                <Text style={{ flex: 1, fontSize: 14, fontWeight: '600' }}>{item.appName}</Text>
                <View
                  style={{
                    width: 22, height: 22, borderRadius: 11,
                    borderWidth: 1.5,
                    borderColor: isSelected ? primary : border,
                    backgroundColor: isSelected ? primary : 'transparent',
                    alignItems: 'center', justifyContent: 'center',
                  }}
                >
                  {isSelected && <Check size={14} color={primaryForeground} />}
                </View>
              </Pressable>
            )
          }}
          ListEmptyComponent={
            <Text variant="caption" style={{ textAlign: 'center', marginTop: 24 }}>{t('noApp')}</Text>
          }
        />
        )}
      </View>

      <View style={{ padding: 20, borderTopWidth: 1, borderTopColor: border, backgroundColor: background }}>
        <Button onPress={onConfirm}>{t('confirmSelection', { n: selected.size })}</Button>
      </View>
    </View>
  )
}
