import { Pressable } from 'react-native'
import { Trash2 } from 'lucide-react-native'
import { Switch } from '@/components/ui/switch'
import { Text } from '@/components/ui/text'
import { View } from '@/components/ui/view'
import { useColor } from '@/hooks/useColor'

type Props = {
  appName: string
  isBlocked: boolean
  onToggle?: (value: boolean) => void
  onRemove?: () => void
}

export function AppRow({ appName, isBlocked, onToggle, onRemove }: Props) {
  const card = useColor('card')
  const border = useColor('border')
  const background = useColor('background')

  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingVertical: 10,
        paddingHorizontal: 12,
        backgroundColor: card,
        borderWidth: 1,
        borderColor: border,
        borderRadius: 10,
      }}
    >
      <View
        style={{
          width: 36,
          height: 36,
          borderRadius: 8,
          backgroundColor: background,
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Text style={{ fontWeight: '700', fontSize: 14 }}>
          {appName.charAt(0).toUpperCase()}
        </Text>
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ fontSize: 14, fontWeight: '600' }}>{appName}</Text>
        <Text variant="caption" style={{ fontSize: 11 }}>
          {isBlocked ? 'Bloquée' : 'Autorisée'}
        </Text>
      </View>
      {onToggle && <Switch value={isBlocked} onValueChange={onToggle} />}
      {onRemove && (
        <Pressable onPress={onRemove} style={{ padding: 6 }}>
          <Trash2 size={16} color="#71717a" />
        </Pressable>
      )}
    </View>
  )
}
