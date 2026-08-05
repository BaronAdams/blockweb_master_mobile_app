import { Pressable } from 'react-native'
import { Check } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

export function ChoiceCard({ label, selected, onPress }: { label: string; selected: boolean; onPress: () => void }) {
  const card = useColor('card')
  const border = useColor('border')
  const primary = useColor('primary')
  const primaryForeground = useColor('primaryForeground')

  return (
    <Pressable
      onPress={onPress}
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingVertical: 16,
        paddingHorizontal: 18,
        borderRadius: 14,
        borderWidth: 1.5,
        borderColor: selected ? primary : border,
        backgroundColor: selected ? primary + '14' : card,
      }}
    >
      <Text style={{ fontSize: 15, fontWeight: '600' }}>{label}</Text>
      {selected && (
        <View style={{ width: 22, height: 22, borderRadius: 11, backgroundColor: primary, alignItems: 'center', justifyContent: 'center' }}>
          <Check size={13} color={primaryForeground} />
        </View>
      )}
    </Pressable>
  )
}
