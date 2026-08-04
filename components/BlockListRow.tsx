import { Pressable } from 'react-native'
import { Trash2, LockKeyhole } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

type Props = {
  icon: React.ReactNode
  label: string
  onRemove?: () => void
  locked?: boolean
}

// One list row for the domains/keywords/whitelist sections — mirrors the
// extension's rounded card rows (icon, label, trash button on the right).
export function BlockListRow({ icon, label, onRemove, locked }: Props) {
  const card = useColor('card')
  const border = useColor('border')
  const red = useColor('red')
  const primary = useColor('primary')

  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        paddingVertical: 10,
        paddingHorizontal: 12,
        backgroundColor: card,
        borderWidth: 1,
        borderColor: border,
        borderRadius: 10,
        opacity: locked ? 0.6 : 1,
      }}
    >
      {icon}
      <Text style={{ flex: 1, fontSize: 13 }} numberOfLines={1}>{label}</Text>
      {locked ? (
        <LockKeyhole size={15} color={primary} />
      ) : onRemove ? (
        <Pressable onPress={onRemove} hitSlop={8}>
          <Trash2 size={16} color={red} />
        </Pressable>
      ) : null}
    </View>
  )
}
