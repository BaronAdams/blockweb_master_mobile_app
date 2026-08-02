import { Platform } from 'react-native';

export const Fonts = Platform.select({
  ios: {
    /** iOS `UIFontDescriptorSystemDesignDefault` */
    sans: 'system-ui',
    /** iOS `UIFontDescriptorSystemDesignSerif` */
    serif: 'ui-serif',
    /** iOS `UIFontDescriptorSystemDesignRounded` */
    rounded: 'ui-rounded',
    /** iOS `UIFontDescriptorSystemDesignMonospaced` */
    mono: 'ui-monospace',
  },
  default: {
    sans: 'normal',
    serif: 'serif',
    rounded: 'normal',
    mono: 'monospace',
  },
  web: {
    sans: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    serif: "Georgia, 'Times New Roman', serif",
    rounded:
      "'SF Pro Rounded', 'Hiragino Maru Gothic ProN', Meiryo, 'MS PGothic', sans-serif",
    mono: "SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace",
  },
});

export const lightColors = {
  // Base colors
  background: '#FFFFFF',
  foreground: '#000000',

  // Card colors
  card: '#F2F2F7',
  cardForeground: '#000000',

  // Popover colors
  popover: '#F2F2F7',
  popoverForeground: '#000000',

  // Primary colors
  primary: '#18181b',
  primaryForeground: '#FFFFFF',

  // Secondary colors
  secondary: '#F2F2F7',
  secondaryForeground: '#18181b',

  // Muted colors
  muted: '#78788033',
  mutedForeground: '#71717a',

  // Accent colors
  accent: '#F2F2F7',
  accentForeground: '#18181b',

  // Destructive colors
  destructive: '#ef4444',
  destructiveForeground: '#FFFFFF',

  // Border and input
  border: '#C6C6C8',
  input: '#e4e4e7',
  ring: '#a1a1aa',

  // Text colors
  text: '#000000',
  textMuted: '#71717a',

  // Legacy support for existing components
  tint: '#18181b',
  icon: '#71717a',
  tabIconDefault: '#71717a',
  tabIconSelected: '#18181b',

  // Default buttons, links, Send button, selected tabs
  blue: '#007AFF',

  // Success states, FaceTime buttons, completed tasks
  green: '#34C759',

  // Delete buttons, error states, critical alerts
  red: '#FF3B30',

  // VoiceOver highlights, warning states
  orange: '#FF9500',

  // Notes app accent, Reminders highlights
  yellow: '#FFCC00',

  // Pink accent color for various UI elements
  pink: '#FF2D92',

  // Purple accent for creative apps and features
  purple: '#AF52DE',

  // Teal accent for communication features
  teal: '#5AC8FA',

  // Indigo accent for system features
  indigo: '#5856D6',
};

export const darkColors = {
  // Base colors
  background: '#09090b',
  foreground: '#f4f4f5',

  // Card colors
  card: '#18181b',
  cardForeground: '#f4f4f5',

  // Popover colors
  popover: '#18181b',
  popoverForeground: '#f4f4f5',

  // Primary colors
  primary: '#f59e0b',
  primaryForeground: '#09090b',

  // Secondary colors
  secondary: '#27272a',
  secondaryForeground: '#a1a1aa',

  // Muted colors
  muted: '#27272a',
  mutedForeground: '#71717a',

  // Accent colors
  accent: '#27272a',
  accentForeground: '#f4f4f5',

  // Destructive colors
  destructive: '#f43f5e',
  destructiveForeground: '#ffffff',

  // Border and input
  border: '#27272a',
  input: '#18181b',
  ring: '#f59e0b',

  // Text colors
  text: '#f4f4f5',
  textMuted: '#a1a1aa',

  // Legacy support for existing components
  tint: '#f59e0b',
  icon: '#71717a',
  tabIconDefault: '#71717a',
  tabIconSelected: '#f59e0b',

  // Active states, emerald
  green: '#10b981',

  // Blocking, strict, rose
  red: '#f43f5e',

  orange: '#f59e0b',

  // Analytics, violet
  blue: '#8b5cf6',

  yellow: '#fbbf24',

  pink: '#f43f5e',

  purple: '#8b5cf6',

  teal: '#10b981',

  indigo: '#6366f1',
};

export const Colors = {
  light: lightColors,
  dark: darkColors,
};
