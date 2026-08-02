import { Card } from '@/components/ui/card'
import { Icon } from '@/components/ui/icon'
import { Text } from '@/components/ui/text'
import { View } from '@/components/ui/view'
import { LucideProps } from 'lucide-react-native'
import { ViewStyle } from 'react-native'

type Props = {
  label: string
  value: string
  icon: React.ComponentType<LucideProps>
  color: string
  style?: ViewStyle
}

export function StatCard({ label, value, icon, color, style }: Props) {
  return (
    <Card style={{ width: '100%', padding: 16, ...style }}>
      <View
        style={{
          width: 36,
          height: 36,
          borderRadius: 10,
          backgroundColor: color + '26',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: 10,
        }}
      >
        <Icon name={icon} color={color} size={18} />
      </View>
      <Text
        style={{
          fontSize: 11,
          fontWeight: '500',
          color: '#71717a',
          textTransform: 'uppercase',
          letterSpacing: 0.6,
          marginBottom: 4,
        }}
        numberOfLines={2}
      >
        {label}
      </Text>
      <Text style={{ fontSize: 24, fontWeight: '700' }} numberOfLines={1}>
        {value}
      </Text>
    </Card>
  )
}
