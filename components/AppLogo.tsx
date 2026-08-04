import { Image } from 'react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

type Props = {
  /** Icon box side, in px. The wordmark and inner image scale off it. */
  size?: number
}

// The icon + "BlockWeb Master" wordmark lockup, shared by AppHeader (the
// tab bar) and any screen that needs the same brand mark standalone (e.g.
// centered above the login/register form instead of in a full-width bar).
export function AppLogo({ size = 44 }: Props) {
  const primary = useColor('primary')
  const text = useColor('text')
  const imageSize = Math.round(size * 0.82)

  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
      <View
        style={{
          width: size,
          height: size,
          borderRadius: Math.round(size * 0.27),
          backgroundColor: primary + '1A',
          borderWidth: 1,
          borderColor: primary + '40',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Image
          source={require('@/assets/android-icon-foreground.png')}
          style={{ width: imageSize, height: imageSize }}
          resizeMode="contain"
        />
      </View>
      <Text
        style={{
          fontSize: Math.round(size * 0.34),
          fontFamily: 'Montserrat_700Bold',
          color: text,
          letterSpacing: -0.2,
        }}
      >
        BlockWeb Master
      </Text>
    </View>
  )
}
