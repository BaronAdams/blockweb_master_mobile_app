import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'
import { TextStyle } from 'react-native'

type Props = {
  children: string
  style?: TextStyle
}

export function SectionTitle({ children, style }: Props) {
  const mutedForeground = useColor('mutedForeground')

  return (
    <Text
      style={[
        {
          fontSize: 10,
          fontWeight: '600',
          textTransform: 'uppercase',
          letterSpacing: 1.2,
          color: mutedForeground,
        },
        style,
      ]}
    >
      {children}
    </Text>
  )
}
