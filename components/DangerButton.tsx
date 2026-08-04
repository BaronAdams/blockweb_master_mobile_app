import { Pressable } from 'react-native'
import type { LucideIcon } from 'lucide-react-native'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

type Props = {
  label: string
  icon: LucideIcon
  onPress?: () => void
  disabled?: boolean
}

// Destructive action button — bordered, transparent background, red text
// (mirrors the extension's danger-zone buttons, e.g. Account.tsx's
// "deleteMyAccount" idle-state button), instead of a plain text row.
export function DangerButton({ label, icon: Icon, onPress, disabled }: Props) {
  const red = useColor('red')

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => ({
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        paddingVertical: 13,
        borderRadius: 10,
        borderWidth: 1,
        borderColor: red + (pressed ? '80' : '4D'),
        backgroundColor: pressed ? red + '14' : 'transparent',
        opacity: disabled ? 0.4 : 1,
      })}
    >
      <Icon size={15} color={red} />
      <Text style={{ fontSize: 13, fontWeight: '600', color: red }}>{label}</Text>
    </Pressable>
  )
}
