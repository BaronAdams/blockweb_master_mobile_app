import { useState } from 'react'
import { FlatList } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { Plus, X, Eye, Lock } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Separator } from '@/components/ui/separator'
import { SearchBar } from '@/components/ui/searchbar'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { AppRow } from '@/components/AppRow'
import { useColor } from '@/hooks/useColor'
import { useInstalledApps } from '@/hooks/useInstalledApps'
import { useAppStore } from '@/store/useAppStore'
import { canAddBlockedApp, limitsFor, isPremium } from '@/utils/limits'

export default function BlockListsScreen() {
  const { t } = useTranslation('blockLists')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const primary = useColor('primary')
  const card = useColor('card')
  const border = useColor('border')

  const plan = useAppStore(s => s.plan)
  const limits = limitsFor(plan)

  const blockedApps = useAppStore(s => s.blockedApps)
  const addBlockedApp = useAppStore(s => s.addBlockedApp)
  const removeBlockedApp = useAppStore(s => s.removeBlockedApp)

  const keywords = useAppStore(s => s.blockedKeywords)
  const addKeyword = useAppStore(s => s.addKeyword)
  const removeKeyword = useAppStore(s => s.removeKeyword)

  const websites = useAppStore(s => s.blockedWebsites)
  const addBlockedWebsite = useAppStore(s => s.addBlockedWebsite)
  const removeBlockedWebsite = useAppStore(s => s.removeBlockedWebsite)
  const toggleBlockedWebsite = useAppStore(s => s.toggleBlockedWebsite)

  const whitelist = useAppStore(s => s.whitelistedSites)
  const addWhitelistedSite = useAppStore(s => s.addWhitelistedSite)
  const removeWhitelistedSite = useAppStore(s => s.removeWhitelistedSite)

  const { apps: installedApps } = useInstalledApps()
  const [appSearch, setAppSearch] = useState('')
  const [keywordInput, setKeywordInput] = useState('')
  const [websiteInput, setWebsiteInput] = useState('')
  const [whitelistInput, setWhitelistInput] = useState('')

  const atAppLimit = !isPremium(plan) && blockedApps.length >= limits.maxBlockedApps
  const atKeywordLimit = !isPremium(plan) && keywords.length >= limits.maxKeywords

  const filteredInstalledApps = installedApps.filter(a =>
    a.appName.toLowerCase().includes(appSearch.toLowerCase())
  )

  const onToggleInstalledApp = (packageName: string, appName: string) => {
    const existing = blockedApps.find(b => b.packageName === packageName)
    if (existing) {
      removeBlockedApp(existing.id)
      return
    }
    if (!canAddBlockedApp(plan, blockedApps.length)) return
    addBlockedApp({
      id: Date.now().toString(),
      packageName,
      appName,
      isBlocked: true,
      addedAt: Date.now(),
    })
  }

  const onAddKeyword = () => {
    if (atKeywordLimit) return
    const trimmed = keywordInput.trim()
    if (!trimmed) return
    addKeyword(trimmed)
    setKeywordInput('')
  }

  const onAddWebsite = () => {
    const trimmed = websiteInput.trim().toLowerCase()
    if (!trimmed) return
    addBlockedWebsite({ id: Date.now().toString(), domain: trimmed, isBlocked: true, addedAt: Date.now() })
    setWebsiteInput('')
  }

  const onAddWhitelist = () => {
    const trimmed = whitelistInput.trim().toLowerCase()
    if (!trimmed) return
    addWhitelistedSite(trimmed)
    setWhitelistInput('')
  }

  return (
    <View style={{ flex: 1, backgroundColor: background, paddingTop: 60, paddingHorizontal: 20 }}>
      <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
        <Text variant="title">{t('title')}</Text>
        <Button
          variant="ghost"
          size="sm"
          onPress={() => router.push({ pathname: '/blocked', params: { reason: 'app', value: blockedApps[0]?.appName ?? 'Instagram' } })}
        >
          <Eye size={18} color="#71717a" />
        </Button>
      </View>

      <Tabs defaultValue="apps" style={{ marginTop: 16, flex: 1 }}>
        <TabsList>
          <TabsTrigger value="apps">Applications</TabsTrigger>
          <TabsTrigger value="keywords">{t('blockedKeywords')}</TabsTrigger>
          <TabsTrigger value="websites">{t('blockedDomains')}</TabsTrigger>
          <TabsTrigger value="whitelist">{t('whitelist')}</TabsTrigger>
        </TabsList>

        <TabsContent value="apps" style={{ flex: 1 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
            <LimitBadge current={blockedApps.length} max={limits.maxBlockedApps} atLimit={atAppLimit} primary={primary} card={card} border={border} />
          </View>
          <SearchBar
            placeholder="Rechercher une application..."
            value={appSearch}
            onChangeText={setAppSearch}
            containerStyle={{ marginBottom: 12 }}
          />

          <FlatList
            data={filteredInstalledApps}
            keyExtractor={item => item.packageName}
            contentContainerStyle={{ gap: 8 }}
            renderItem={({ item }) => {
              const existing = blockedApps.find(b => b.packageName === item.packageName)
              return (
                <AppRow
                  appName={item.appName}
                  isBlocked={existing?.isBlocked ?? false}
                  onToggle={() => onToggleInstalledApp(item.packageName, item.appName)}
                />
              )
            }}
            ListEmptyComponent={
              <Text variant="caption" style={{ textAlign: 'center', marginTop: 24 }}>
                Aucune application trouvée.
              </Text>
            }
          />
        </TabsContent>

        <TabsContent value="keywords" style={{ flex: 1 }}>
          <LimitBadge current={keywords.length} max={limits.maxKeywords} atLimit={atKeywordLimit} primary={primary} card={card} border={border} style={{ marginBottom: 8, alignSelf: 'flex-start' }} />
          <View style={{ flexDirection: 'row', gap: 10, marginBottom: 16 }}>
            <Input
              containerStyle={{ flex: 1 }}
              placeholder={t('keywordPlaceholder')}
              value={keywordInput}
              onChangeText={setKeywordInput}
              onSubmitEditing={onAddKeyword}
              editable={!atKeywordLimit}
            />
            <Button size="icon" onPress={onAddKeyword} disabled={atKeywordLimit}>
              <Plus color="#09090b" size={20} />
            </Button>
          </View>

          <FlatList
            data={keywords}
            keyExtractor={item => item.id}
            ItemSeparatorComponent={() => <Separator />}
            renderItem={({ item }) => (
              <View style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 12 }}>
                <Text style={{ flex: 1, fontSize: 14 }}>{item.keyword}</Text>
                <Button size="icon" variant="ghost" onPress={() => removeKeyword(item.id)}>
                  <X size={18} color="#71717a" />
                </Button>
              </View>
            )}
            ListEmptyComponent={
              <Text variant="caption" style={{ textAlign: 'center', marginTop: 24 }}>{t('noKeyword')}</Text>
            }
          />
        </TabsContent>

        <TabsContent value="websites" style={{ flex: 1 }}>
          <View style={{ flexDirection: 'row', gap: 10, marginBottom: 16 }}>
            <Input
              containerStyle={{ flex: 1 }}
              placeholder={t('domainPlaceholder')}
              autoCapitalize="none"
              value={websiteInput}
              onChangeText={setWebsiteInput}
              onSubmitEditing={onAddWebsite}
            />
            <Button size="icon" onPress={onAddWebsite}>
              <Plus color="#09090b" size={20} />
            </Button>
          </View>

          <FlatList
            data={websites}
            keyExtractor={item => item.id}
            contentContainerStyle={{ gap: 8 }}
            renderItem={({ item }) => (
              <AppRow
                appName={item.domain}
                isBlocked={item.isBlocked}
                onToggle={() => toggleBlockedWebsite(item.id)}
                onRemove={() => removeBlockedWebsite(item.id)}
              />
            )}
            ListEmptyComponent={
              <Text variant="caption" style={{ textAlign: 'center', marginTop: 24 }}>{t('noDomain')}</Text>
            }
          />
        </TabsContent>

        <TabsContent value="whitelist" style={{ flex: 1 }}>
          {!isPremium(plan) ? (
            <View style={{ backgroundColor: primary + '0D', borderColor: primary + '26', borderWidth: 1, borderRadius: 14, padding: 16, alignItems: 'center', gap: 8 }}>
              <Lock size={20} color={primary} />
              <Text style={{ fontSize: 14, fontWeight: '700' }}>{t('whitelistPremium')}</Text>
              <Text variant="caption" style={{ fontSize: 12, textAlign: 'center' }}>{t('whitelistPremiumDesc')}</Text>
              <Button size="sm" style={{ marginTop: 8 }} onPress={() => router.push('/pricing')}>{tc('upgrade')}</Button>
            </View>
          ) : (
            <>
              <View style={{ flexDirection: 'row', gap: 10, marginBottom: 16 }}>
                <Input
                  containerStyle={{ flex: 1 }}
                  placeholder={t('whitePlaceholder')}
                  autoCapitalize="none"
                  value={whitelistInput}
                  onChangeText={setWhitelistInput}
                  onSubmitEditing={onAddWhitelist}
                />
                <Button size="icon" onPress={onAddWhitelist}>
                  <Plus color="#09090b" size={20} />
                </Button>
              </View>

              <FlatList
                data={whitelist}
                keyExtractor={item => item.id}
                ItemSeparatorComponent={() => <Separator />}
                renderItem={({ item }) => (
                  <View style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 12 }}>
                    <Text style={{ flex: 1, fontSize: 14 }}>{item.domain}</Text>
                    <Button size="icon" variant="ghost" onPress={() => removeWhitelistedSite(item.id)}>
                      <X size={18} color="#71717a" />
                    </Button>
                  </View>
                )}
                ListEmptyComponent={
                  <Text variant="caption" style={{ textAlign: 'center', marginTop: 24 }}>{t('noWhite')}</Text>
                }
              />
            </>
          )}
        </TabsContent>
      </Tabs>
    </View>
  )
}

function LimitBadge({
  current, max, atLimit, primary, card, border, style,
}: {
  current: number
  max: number
  atLimit: boolean
  primary: string
  card: string
  border: string
  style?: object
}) {
  if (!Number.isFinite(max)) return null
  return (
    <View
      style={[{
        alignSelf: 'flex-start',
        paddingHorizontal: 10,
        paddingVertical: 3,
        borderRadius: 6,
        backgroundColor: atLimit ? primary + '1A' : card,
        borderWidth: 1,
        borderColor: atLimit ? primary + '40' : border,
      }, style]}
    >
      <Text style={{ fontSize: 12, fontWeight: '700', color: atLimit ? primary : undefined }}>
        {current}/{max}
      </Text>
    </View>
  )
}
