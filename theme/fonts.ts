import { TextStyle } from 'react-native'

const INTER_BY_WEIGHT: Record<string, string> = {
  '100': 'Inter_400Regular',
  '200': 'Inter_400Regular',
  '300': 'Inter_400Regular',
  '400': 'Inter_400Regular',
  normal: 'Inter_400Regular',
  '500': 'Inter_500Medium',
  '600': 'Inter_600SemiBold',
  '700': 'Inter_700Bold',
  bold: 'Inter_700Bold',
  '800': 'Inter_800ExtraBold',
  '900': 'Inter_800ExtraBold',
}

/**
 * Inter is loaded (app/_layout.tsx) for every platform. Custom font files
 * each encode a single weight, so the RN `fontWeight` must be dropped once
 * `fontFamily` is set, or the OS will try (and fail, or double-bold) to
 * synthesize a bold variant of that font file.
 *
 * Styles that already declare an explicit `fontFamily` (e.g. `monospace`
 * for aligned numeric/time values) are left untouched.
 */
export function withInterFont(style: TextStyle): TextStyle {
  if (style.fontFamily) return style

  const weight = String(style.fontWeight ?? '400')
  const fontFamily = INTER_BY_WEIGHT[weight] ?? 'Inter_400Regular'

  return { ...style, fontFamily, fontWeight: undefined }
}
