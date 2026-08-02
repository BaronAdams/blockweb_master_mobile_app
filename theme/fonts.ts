import { Platform, TextStyle } from 'react-native'

const INTER_BY_WEIGHT: Record<string, string> = {
  '400': 'Inter_400Regular',
  normal: 'Inter_400Regular',
  '500': 'Inter_500Medium',
  '600': 'Inter_600SemiBold',
  '700': 'Inter_700Bold',
  bold: 'Inter_700Bold',
  '800': 'Inter_800ExtraBold',
}

/**
 * Inter is loaded for Android only (app/_layout.tsx) — iOS keeps the native
 * system font. Custom font files each encode a single weight, so the RN
 * `fontWeight` must be dropped once `fontFamily` is set, or Android will
 * try (and fail) to synthesize a bold variant of that font file.
 */
export function withAndroidInterFont(style: TextStyle): TextStyle {
  if (Platform.OS !== 'android') return style

  const weight = String(style.fontWeight ?? '400')
  const fontFamily = INTER_BY_WEIGHT[weight] ?? 'Inter_400Regular'

  return { ...style, fontFamily, fontWeight: undefined }
}
