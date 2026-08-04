import { useState } from 'react'
import { Image } from 'expo-image'
import { Globe } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'

type Props = {
  name: string
  type: 'app' | 'site'
  color: string
  size?: number
}

// Mirrors the extension's SmartImage + globeIcon fallback: sites get their
// real favicon (Google's favicon service, same source the extension uses),
// falling back to a generic globe glyph on error. Apps get a colored
// initial-letter avatar — real package icons need a native module we don't
// have yet (see hooks/useInstalledApps.ts).
export function EntryIcon({ name, type, color, size = 28 }: Props) {
  const [failed, setFailed] = useState(false)

  const badge = {
    width: size,
    height: size,
    borderRadius: size * 0.28,
    backgroundColor: color + '1A',
    alignItems: 'center' as const,
    justifyContent: 'center' as const,
    overflow: 'hidden' as const,
  }

  if (type === 'site' && !failed) {
    return (
      <View style={badge}>
        <Image
          source={{ uri: `https://www.google.com/s2/favicons?domain=${name}&sz=64` }}
          style={{ width: size * 0.55, height: size * 0.55 }}
          contentFit="contain"
          onError={() => setFailed(true)}
        />
      </View>
    )
  }

  return (
    <View style={badge}>
      {type === 'site' ? (
        <Globe size={size * 0.5} color={color} />
      ) : (
        <Text style={{ fontSize: size * 0.4, fontWeight: '700', color }}>
          {name.charAt(0).toUpperCase()}
        </Text>
      )}
    </View>
  )
}
