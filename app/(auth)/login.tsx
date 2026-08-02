import { useState } from 'react'
import { KeyboardAvoidingView, Platform, ScrollView } from 'react-native'
import { Link, useRouter } from 'expo-router'
import { useTranslation } from 'react-i18next'
import { Mail, Lock, ShieldCheck } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useColor } from '@/hooks/useColor'
import { supabase } from '@/lib/supabase'

export default function LoginScreen() {
  const { t } = useTranslation('auth')
  const { t: tc } = useTranslation('common')
  const router = useRouter()
  const background = useColor('background')
  const primary = useColor('primary')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const onSubmit = async () => {
    setError('')
    setLoading(true)
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    setLoading(false)
    if (error) {
      setError(t('invalidCredentials'))
      return
    }
    router.replace('/(tabs)')
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: background }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24 }}>
        <View style={{ alignItems: 'center', marginBottom: 40 }}>
          <View
            style={{
              width: 64,
              height: 64,
              borderRadius: 18,
              backgroundColor: primary + '26',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: 16,
            }}
          >
            <ShieldCheck color={primary} size={30} strokeWidth={1.8} />
          </View>
          <Text variant="title">{tc('appName')}</Text>
          <Text variant="caption" style={{ marginTop: 4 }}>{t('tagline')}</Text>
        </View>

        <View style={{ gap: 12 }}>
          <Input
            icon={Mail}
            placeholder={t('emailPlaceholder')}
            autoCapitalize="none"
            keyboardType="email-address"
            value={email}
            onChangeText={setEmail}
          />
          <Input
            icon={Lock}
            placeholder={t('password')}
            secureTextEntry
            value={password}
            onChangeText={setPassword}
          />

          {!!error && (
            <Text style={{ color: '#f43f5e', fontSize: 12 }}>{error}</Text>
          )}

          <Button
            onPress={onSubmit}
            loading={loading}
            style={{
              marginTop: 8,
              shadowColor: primary,
              shadowOpacity: 0.35,
              shadowRadius: 16,
              shadowOffset: { width: 0, height: 0 },
              elevation: 6,
            }}
          >
            {t('signIn')}
          </Button>
        </View>

        <View style={{ flexDirection: 'row', justifyContent: 'center', marginTop: 24 }}>
          <Link href="/(auth)/register">
            <Text style={{ color: primary, fontWeight: '600' }}>{t('createAccount')}</Text>
          </Link>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  )
}
