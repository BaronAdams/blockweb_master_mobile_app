import { useState } from 'react'
import { Image } from 'expo-image'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

type Props = {
  appName: string
  /** File path from react-native-launcher-kit (Android only). */
  icon?: string
  size?: number
}

// Real app icon when available (installed-apps picker, Android), falling
// back to a colored initial-letter avatar — same fallback used everywhere
// else an app has no real icon (iOS/web demo list, or a load failure).
export function AppIcon({ appName, icon, size = 36 }: Props) {
  const [failed, setFailed] = useState(false)
  const background = useColor('background')

  const uri = icon
    ? (icon.startsWith('file://') || icon.startsWith('http') ? icon : `file://${icon}`)
    : undefined

  if (uri && !failed) {
    return (
      <Image
        source={{ uri }}
        style={{ width: size, height: size, borderRadius: Math.round(size * 0.22) }}
        onError={() => setFailed(true)}
      />
    )
  }

  return (
    <View
      style={{
        width: size, height: size, borderRadius: Math.round(size * 0.22),
        backgroundColor: background,
        alignItems: 'center', justifyContent: 'center',
      }}
    >
      <Text style={{ fontWeight: '700', fontSize: Math.round(size * 0.4) }}>
        {appName.charAt(0).toUpperCase()}
      </Text>
    </View>
  )
}
