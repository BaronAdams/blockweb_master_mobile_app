import { Pressable } from 'react-native'
import { useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { ChevronRight, Smartphone, Globe, Hash, CircleCheck, Lock } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { AppHeader } from '@/components/AppHeader'
import { useColor } from '@/hooks/useColor'
import { useAppStore } from '@/store/useAppStore'
import { isPremium } from '@/utils/limits'

// Menu of the 4 blockable categories, replacing the old tabs UI — mirrors
// the extension's BlockLists sections (Domaines / Mots-clés / Whitelist),
// with "Applications" added since this is the mobile app.
export default function BlockListsMenuScreen() {
  const { t } = useTranslation('blockLists')
  const router = useRouter()
  const background = useColor('background')
  const card = useColor('card')
  const border = useColor('border')
  const mutedForeground = useColor('mutedForeground')

  const plan = useAppStore(s => s.plan)
  const blockedApps = useAppStore(s => s.blockedApps)
  const blockedWebsites = useAppStore(s => s.blockedWebsites)
  const keywords = useAppStore(s => s.blockedKeywords)
  const whitelist = useAppStore(s => s.whitelistedSites)

  const items = [
    { key: 'apps', icon: Smartphone, color: '#fb7185', label: t('applications'), count: blockedApps.length, route: '/(tabs)/blocklists/apps' as const },
    { key: 'websites', icon: Globe, color: '#8b5cf6', label: t('blockedDomains'), count: blockedWebsites.length, route: '/(tabs)/blocklists/websites' as const },
    { key: 'keywords', icon: Hash, color: '#f59e0b', label: t('blockedKeywords'), count: keywords.length, route: '/(tabs)/blocklists/keywords' as const },
    { key: 'whitelist', icon: CircleCheck, color: '#34d399', label: t('whitelist'), count: whitelist.length, route: '/(tabs)/blocklists/whitelist' as const, locked: !isPremium(plan) },
  ]

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      <AppHeader />
      <View style={{ flex: 1, padding: 20 }}>
        <Text variant="title" style={{ marginBottom: 16 }}>{t('title')}</Text>
        <View style={{ gap: 10 }}>
          {items.map(item => {
            const Icon = item.icon
            return (
              <Pressable
                key={item.key}
                onPress={() => router.push(item.route)}
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
                    width: 40, height: 40, borderRadius: 10,
                    backgroundColor: item.color + '1A',
                    alignItems: 'center', justifyContent: 'center',
                  }}
                >
                  <Icon size={20} color={item.color} />
                </View>
                <Text style={{ flex: 1, fontSize: 15, fontWeight: '600' }}>{item.label}</Text>
                {item.locked ? (
                  <Lock size={16} color={mutedForeground} />
                ) : (
                  <Text variant="caption" style={{ fontSize: 13, fontFamily: 'monospace' }}>{item.count}</Text>
                )}
                <ChevronRight size={18} color={mutedForeground} />
              </Pressable>
            )
          })}
        </View>
      </View>
    </View>
  )
}
