import { Platform } from 'react-native'

// JS bridge to the local Expo module in modules/blocker/android — the real
// blocking engine (AccessibilityService-based foreground-app detection,
// overlay-based blocking, and usage tracking). Android-only: iOS has no
// equivalent API surface for this (no public foreground-app-detection or
// app-blocking capability), so every export below is a safe no-op there
// instead of throwing.
type UsageStats = Record<string, Record<string, number>>
type HourlyUsageStats = Record<string, Record<string, Record<string, number>>>

type BlockerNativeModule = {
  isAccessibilityServiceEnabled(): Promise<boolean>
  isOverlayPermissionGranted(): Promise<boolean>
  setBlockedPackages(packages: string[]): Promise<void>
  setBlockedDomains(domains: string[]): Promise<void>
  setBlockedKeywords(keywords: string[]): Promise<void>
  getUsageStats(): Promise<UsageStats>
  getHourlyUsageStats(): Promise<HourlyUsageStats>
}

let native: BlockerNativeModule | null = null
if (Platform.OS === 'android') {
  try {
    // Lazy require: requireNativeModule throws immediately if the native
    // module isn't linked into this binary (e.g. Expo Go, or a build made
    // before this module existed) — caught here so the app degrades to
    // "no real blocking yet" instead of crashing on import. Imported from
    // 'expo' (which re-exports it), not 'expo-modules-core' directly — the
    // latter must not be a direct dependency (see `expo doctor`).
    const { requireNativeModule } = require('expo')
    native = requireNativeModule<BlockerNativeModule>('Blocker')
  } catch {
    native = null
  }
}

export async function isAccessibilityServiceEnabled(): Promise<boolean> {
  if (!native) return false
  try {
    return await native.isAccessibilityServiceEnabled()
  } catch {
    return false
  }
}

export async function isOverlayPermissionGranted(): Promise<boolean> {
  if (!native) return false
  try {
    return await native.isOverlayPermissionGranted()
  } catch {
    return false
  }
}

export async function setBlockedPackages(packages: string[]): Promise<void> {
  if (!native) return
  try {
    await native.setBlockedPackages(packages)
  } catch {
    // Best-effort — a failure here must not crash the app; blocking just
    // stays stale until the next successful sync.
  }
}

export async function setBlockedDomains(domains: string[]): Promise<void> {
  if (!native) return
  try {
    await native.setBlockedDomains(domains)
  } catch {
    // Best-effort, see setBlockedPackages.
  }
}

export async function setBlockedKeywords(keywords: string[]): Promise<void> {
  if (!native) return
  try {
    await native.setBlockedKeywords(keywords)
  } catch {
    // Best-effort, see setBlockedPackages.
  }
}

export async function getUsageStats(): Promise<UsageStats> {
  if (!native) return {}
  try {
    return await native.getUsageStats()
  } catch {
    return {}
  }
}

export async function getHourlyUsageStats(): Promise<HourlyUsageStats> {
  if (!native) return {}
  try {
    return await native.getHourlyUsageStats()
  } catch {
    return {}
  }
}
