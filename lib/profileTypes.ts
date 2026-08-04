import { Sun, Clock, Calendar, Shield, type LucideIcon } from 'lucide-react-native'

export type LimiterType = 'daily' | 'hourly' | 'weekly' | 'interval'

type ProfileTypeMeta = {
  labelKey: string
  createDescKey: string
  color: string
  icon: LucideIcon
}

// Exact colors/icons from the Chrome extension's TimerProfile pages:
// daily = amber-400, hourly = blue-400, weekly = violet-400, interval = rose-400.
export const PROFILE_TYPE_META: Record<LimiterType, ProfileTypeMeta> = {
  daily: { labelKey: 'daily', createDescKey: 'dailyCreateDesc', color: '#fbbf24', icon: Sun },
  hourly: { labelKey: 'hourly', createDescKey: 'hourlyCreateDesc', color: '#60a5fa', icon: Clock },
  weekly: { labelKey: 'weekly', createDescKey: 'weeklyCreateDesc', color: '#a78bfa', icon: Calendar },
  interval: { labelKey: 'interval', createDescKey: 'intervalCreateDesc', color: '#fb7185', icon: Shield },
}

export const PROFILE_TYPE_ORDER: LimiterType[] = ['daily', 'hourly', 'weekly', 'interval']
