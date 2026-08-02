import { Tabs } from 'expo-router'
import { BarChart3, Ban, Timer, Shield, User } from 'lucide-react-native'

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: '#09090b',
          borderTopColor: '#27272a',
          borderTopWidth: 0.5,
          height: 84,
          paddingBottom: 24,
          paddingTop: 10,
        },
        tabBarLabelStyle: {
          fontSize: 10,
          fontWeight: '500',
        },
        tabBarActiveTintColor: '#f59e0b',
        tabBarInactiveTintColor: '#71717a',
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
