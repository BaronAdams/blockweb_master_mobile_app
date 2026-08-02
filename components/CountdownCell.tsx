import { Text } from '@/components/ui/text'
import { View } from '@/components/ui/view'
import { useColor } from '@/hooks/useColor'

type Props = {
  value: number
  label: string
}

export function CountdownCell({ value, label }: Props) {
  const background = useColor('background')
  const border = useColor('border')

  return (
    <View
      style={{
        flex: 1,
        backgroundColor: background,
        borderWidth: 1,
        borderColor: border,
        borderRadius: 10,
        padding: 12,
        alignItems: 'center',
      }}
    >
      <Text
        style={{
          fontSize: 28,
          fontWeight: '700',
          fontVariant: ['tabular-nums'],
          fontFamily: 'monospace',
        }}
      >
        {String(value).padStart(2, '0')}
      </Text>
      <Text
        style={{
          fontSize: 9,
          fontWeight: '600',
          textTransform: 'uppercase',
          color: '#71717a',
          marginTop: 2,
        }}
      >
        {label}
      </Text>
    </View>
  )
}
