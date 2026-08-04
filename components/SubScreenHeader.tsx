import { Pressable } from 'react-native'
import { useRouter } from 'expo-router'
import { ChevronLeft } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

type Props = {
  title: string
  right?: React.ReactNode
}

// Back-nav row for screens pushed on top of a tab (e.g. blocklists/apps),
// sitting right under AppHeader which has no back button of its own.
export function SubScreenHeader({ title, right }: Props) {
  const router = useRouter()
  const text = useColor('text')

  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12, paddingHorizontal: 20, paddingTop: 16, paddingBottom: 8 }}>
      <Pressable onPress={() => router.back()} hitSlop={10} style={{ padding: 2 }}>
        <ChevronLeft size={24} color={text} />
      </Pressable>
      <Text variant="title" style={{ fontSize: 20, flex: 1 }}>{title}</Text>
      {right}
    </View>
  )
}
