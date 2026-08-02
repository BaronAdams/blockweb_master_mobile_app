import { useEffect } from 'react'
import { useAppStore } from '@/store/useAppStore'

export function useStrictMode() {
  const { strictMode, checkStrictExpiry, activateStrictMode } = useAppStore()

  useEffect(() => {
    checkStrictExpiry()
    const id = setInterval(checkStrictExpiry, 60_000)
    return () => clearInterval(id)
  }, [])

  const getRemainingTime = () => {
    if (!strictMode.isActive || !strictMode.expiresAt) return null
    const diff = strictMode.expiresAt - Date.now()
    if (diff <= 0) return null
    return {
      days: Math.floor(diff / (86400 * 1000)),
      hours: Math.floor((diff % (86400 * 1000)) / (3600 * 1000)),
      minutes: Math.floor((diff % (3600 * 1000)) / (60 * 1000)),
      seconds: Math.floor((diff % (60 * 1000)) / 1000),
    }
  }

  const activate = (days: number) => {
    activateStrictMode(days)
  }

  return {
    isActive: strictMode.isActive,
    getRemainingTime,
    activate,
    expiresAt: strictMode.expiresAt,
  }
}
