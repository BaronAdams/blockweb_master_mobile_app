import { Plus } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useColor } from '@/hooks/useColor'

// Small presentational pieces shared by the blocklist sub-screens (websites,
// keywords, whitelist) — mirrors the extension's BlockLists.tsx patterns
// (LimitBadge, EmptyState, the input+add row) without duplicating them per screen.

export function LimitBadge({ count, max }: { count: number; max: number }) {
  const primary = useColor('primary')
  const card = useColor('card')
  const border = useColor('border')
  const atLimit = Number.isFinite(max) && count >= max

  return (
    <View
      style={{
        alignSelf: 'flex-start',
        paddingHorizontal: 10,
        paddingVertical: 3,
        borderRadius: 6,
        backgroundColor: atLimit ? primary + '1A' : card,
        borderWidth: 1,
        borderColor: atLimit ? primary + '40' : border,
      }}
    >
      <Text style={{ fontSize: 12, fontWeight: '700', color: atLimit ? primary : undefined }}>
        {count}{Number.isFinite(max) ? `/${max}` : ''}
      </Text>
    </View>
  )
}

export function EmptyState({ icon, label }: { icon: React.ReactNode; label: string }) {
  const border = useColor('border')
  return (
    <View
      style={{
        alignItems: 'center',
        justifyContent: 'center',
        paddingVertical: 32,
        gap: 8,
        borderWidth: 1,
        borderStyle: 'dashed',
        borderColor: border,
        borderRadius: 12,
      }}
    >
      {icon}
      <Text variant="caption" style={{ fontSize: 12 }}>{label}</Text>
    </View>
  )
}

export function AddRow({
  value, onChangeText, onAdd, placeholder, disabled, autoCapitalize,
}: {
  value: string
  onChangeText: (v: string) => void
  onAdd: () => void
  placeholder: string
  disabled?: boolean
  autoCapitalize?: 'none' | 'sentences'
}) {
  const primaryForeground = useColor('primaryForeground')
  return (
    <View style={{ flexDirection: 'row', gap: 10, marginBottom: 16 }}>
      <Input
        containerStyle={{ flex: 1 }}
        placeholder={placeholder}
        autoCapitalize={autoCapitalize ?? 'none'}
        value={value}
        onChangeText={onChangeText}
        onSubmitEditing={onAdd}
        editable={!disabled}
        disabled={disabled}
      />
      <Button size="icon" onPress={onAdd} disabled={disabled}>
        <Plus color={primaryForeground} size={20} />
      </Button>
    </View>
  )
}
