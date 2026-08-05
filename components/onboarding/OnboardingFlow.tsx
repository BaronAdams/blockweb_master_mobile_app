import { useState } from 'react'
import { BuildUpFlow } from './BuildUpFlow'
import { Paywall } from './Paywall'

// First-launch flow: a short personalization "build up" (marketing/psych
// hook — see BuildUpFlow) followed by a soft paywall, then handed off to
// the caller. `onDone` takes an optional route to navigate to right after
// (used for "See Premium plans" → /pricing) — deferred to the caller
// because at this point in app/_layout.tsx the real <Stack> isn't mounted
// yet, so there's no navigator to push into until onboarding completes.
export function OnboardingFlow({ onDone }: { onDone: (pendingRoute?: string) => void }) {
  const [phase, setPhase] = useState<'buildup' | 'paywall'>('buildup')
  const [reclaimedHours, setReclaimedHours] = useState(0)

  if (phase === 'buildup') {
    return (
      <BuildUpFlow
        onFinish={(hours) => {
          setReclaimedHours(hours)
          setPhase('paywall')
        }}
      />
    )
  }

  return (
    <Paywall
      reclaimedHours={reclaimedHours}
      onSeePlans={() => onDone('/pricing')}
      onContinueFree={() => onDone()}
    />
  )
}
