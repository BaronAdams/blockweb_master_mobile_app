import { Tabs } from 'expo-router'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { BarChart3, Ban, Timer, Shield, User } from 'lucide-react-native'
import { useColor } from '@/hooks/useColor'

export default function TabLayout() {
  const background = useColor('background')
  const border = useColor('border')
  const primary = useColor('primary')
  const mutedForeground = useColor('mutedForeground')
  const insets = useSafeAreaInsets()
  // A fixed paddingBottom sat under the 3-button nav bar on devices using
  // that gesture style (its inset is taller than a gesture-nav pill's) —
  // use the real inset so the bar always clears the system nav buttons.
  const bottomPadding = Math.max(insets.bottom, 10)

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: background,
          borderTopColor: border,
          borderTopWidth: 0.5,
          height: 60 + bottomPadding,
          paddingBottom: bottomPadding,
          paddingTop: 10,
        },
        tabBarLabelStyle: {
          fontSize: 10,
          fontWeight: '500',
        },
        tabBarActiveTintColor: primary,
        tabBarInactiveTintColor: mutedForeground,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Analytics',
          tabBarIcon: ({ color, size }) => <BarChart3 color={color} size={size} strokeWidth={2} />,
        }}
      />
      <Tabs.Screen
        name="blocklists"
        options={{
          title: 'Block Lists',
          tabBarIcon: ({ color, size }) => <Ban color={color} size={size} strokeWidth={2} />,
        }}
      />
      <Tabs.Screen
        name="profiles"
        options={{
          title: 'Profiles',
          tabBarIcon: ({ color, size }) => <Timer color={color} size={size} strokeWidth={2} />,
        }}
      />
      <Tabs.Screen
        name="strictmode"
        options={{
          title: 'Strict Mode',
          tabBarIcon: ({ color, size }) => <Shield color={color} size={size} strokeWidth={2} />,
        }}
      />
      <Tabs.Screen
        name="account"
        options={{
          title: 'Account',
          tabBarIcon: ({ color, size }) => <User color={color} size={size} strokeWidth={2} />,
        }}
      />
    </Tabs>
  )
}
