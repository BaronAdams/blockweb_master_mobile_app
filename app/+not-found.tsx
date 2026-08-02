import { Link, Stack } from 'expo-router'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

export default function NotFoundScreen() {
  const background = useColor('background')
  const primary = useColor('primary')

  return (
    <>
      <Stack.Screen options={{ title: 'Introuvable' }} />
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12, backgroundColor: background }}>
        <Text variant="title">Cet écran n'existe pas.</Text>
        <Link href="/(tabs)">
          <Text style={{ color: primary, fontWeight: '600' }}>Retour à l'accueil</Text>
        </Link>
      </View>
    </>
  )
}
