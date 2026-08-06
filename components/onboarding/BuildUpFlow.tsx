import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import Animated, {
  Easing,
  FadeIn,
  FadeOut,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withTiming,
} from 'react-native-reanimated'
import { ArrowRight, Smartphone, Sparkles, TrendingUp } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { Button } from '@/components/ui/button'
import { ChoiceCard } from './ChoiceCard'
import { useColor } from '@/hooks/useColor'

const STEPS = ['welcome', 'stat', 'q1', 'q2', 'q3', 'q4', 'building', 'reveal'] as const
type Step = (typeof STEPS)[number]
// Steps that count toward the visible progress bar — welcome/building/reveal
// are transitional, not "questions", so they don't advance it.
const PROGRESS_STEPS: Step[] = ['stat', 'q1', 'q2', 'q3', 'q4']

type Answers = {
  app: string | null
  timeRange: string | null
  goal: string | null
  days: number | null
}

const TIME_RANGE_HOURS: Record<string, number> = {
  under1h: 0.5,
  oneToThree: 2,
  threeToFive: 4,
  over5h: 6,
}

export function BuildUpFlow({ onFinish }: { onFinish: (reclaimedHoursPerWeek: number) => void }) {
  const { t } = useTranslation('onboarding')
  const background = useColor('background')
  const [step, setStep] = useState<Step>('welcome')
  const [answers, setAnswers] = useState<Answers>({ app: null, timeRange: null, goal: null, days: null })

  const goTo = (next: Step) => setStep(next)

  const selectAndAdvance = (patch: Partial<Answers>, next: Step) => {
    setAnswers(prev => ({ ...prev, ...patch }))
    setTimeout(() => goTo(next), 260)
  }

  const reclaimedHours = Math.max(1, Math.round((TIME_RANGE_HOURS[answers.timeRange ?? 'oneToThree'] * 7 * 0.6)))

  const progressIndex = PROGRESS_STEPS.indexOf(step)

  return (
    <View style={{ flex: 1, backgroundColor: background }}>
      {progressIndex >= 0 && (
        <View style={{ paddingHorizontal: 24, paddingTop: 60, paddingBottom: 8 }}>
          <ProgressBar progress={(progressIndex + 1) / PROGRESS_STEPS.length} />
        </View>
      )}

      <Animated.View key={step} entering={FadeIn.duration(260)} exiting={FadeOut.duration(150)} style={{ flex: 1 }}>
        {step === 'welcome' && <WelcomeStep onNext={() => goTo('stat')} />}
        {step === 'stat' && <StatStep onNext={() => goTo('q1')} />}
        {step === 'q1' && (
          <QuestionStep
            title={t('q1Title')}
            options={[
              { value: 'Instagram', label: t('q1Instagram') },
              { value: 'TikTok', label: t('q1TikTok') },
              { value: 'YouTube', label: t('q1YouTube') },
              { value: 'other', label: t('q1Other') },
            ]}
            selected={answers.app}
            onSelect={(value) => selectAndAdvance({ app: value }, 'q2')}
          />
        )}
        {step === 'q2' && (
          <QuestionStep
            title={t('q2Title')}
            options={[
              { value: 'under1h', label: t('q2Under1h') },
              { value: 'oneToThree', label: t('q2OneToThree') },
              { value: 'threeToFive', label: t('q2ThreeToFive') },
              { value: 'over5h', label: t('q2Over5h') },
            ]}
            selected={answers.timeRange}
            onSelect={(value) => selectAndAdvance({ timeRange: value }, 'q3')}
          />
        )}
        {step === 'q3' && (
          <QuestionStep
            title={t('q3Title')}
            options={[
              { value: 'sleep', label: t('q3Sleep') },
              { value: 'productive', label: t('q3Productive') },
              { value: 'people', label: t('q3People') },
              { value: 'learn', label: t('q3Learn') },
            ]}
            selected={answers.goal}
            onSelect={(value) => selectAndAdvance({ goal: value }, 'q4')}
          />
        )}
        {step === 'q4' && (
          <QuestionStep
            title={t('q4Title')}
            options={[
              { value: '7', label: `🌱 ${t('q4Days', { count: 7 })}` },
              { value: '14', label: `🌿 ${t('q4Days', { count: 14 })}` },
              { value: '30', label: `🌳 ${t('q4Days', { count: 30 })}` },
            ]}
            selected={answers.days != null ? String(answers.days) : null}
            onSelect={(value) => selectAndAdvance({ days: Number(value) }, 'building')}
          />
        )}
        {step === 'building' && <BuildingStep onDone={() => goTo('reveal')} />}
        {step === 'reveal' && (
          <RevealStep
            appLabel={answers.app === 'other' ? t('q1Other') : (answers.app ?? '')}
            days={answers.days ?? 7}
            reclaimedHours={reclaimedHours}
            onNext={() => onFinish(reclaimedHours)}
          />
        )}
      </Animated.View>
    </View>
  )
}

function ProgressBar({ progress }: { progress: number }) {
  const border = useColor('border')
  const primary = useColor('primary')
  const width = useSharedValue(0)

  useEffect(() => {
    width.value = withTiming(progress, { duration: 400, easing: Easing.out(Easing.cubic) })
  }, [progress])

  const style = useAnimatedStyle(() => ({ width: `${width.value * 100}%` }))

  return (
    <View style={{ height: 4, borderRadius: 2, backgroundColor: border, overflow: 'hidden' }}>
      <Animated.View style={[{ height: '100%', backgroundColor: primary, borderRadius: 2 }, style]} />
    </View>
  )
}

function StepLayout({
  children,
  footer,
}: {
  children: React.ReactNode
  footer?: React.ReactNode
}) {
  return (
    <View style={{ flex: 1, paddingHorizontal: 24, justifyContent: 'space-between', paddingBottom: 32 }}>
      <View style={{ flex: 1, justifyContent: 'center' }}>{children}</View>
      {footer}
    </View>
  )
}

function WelcomeStep({ onNext }: { onNext: () => void }) {
  const { t } = useTranslation('onboarding')
  const primary = useColor('primary')
  const scale = useSharedValue(0.85)
  const opacity = useSharedValue(0)

  useEffect(() => {
    scale.value = withTiming(1, { duration: 500, easing: Easing.out(Easing.back(1.4)) })
    opacity.value = withDelay(120, withTiming(1, { duration: 400 }))
  }, [])

  const iconStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }))
  const textStyle = useAnimatedStyle(() => ({ opacity: opacity.value }))

  return (
    <StepLayout
      footer={<Button onPress={onNext}>{t('welcomeCta')}</Button>}
    >
      <View style={{ alignItems: 'center', gap: 20 }}>
        <Animated.View
          style={[
            {
              width: 84, height: 84, borderRadius: 24,
              backgroundColor: primary + '1A', borderWidth: 1, borderColor: primary + '40',
              alignItems: 'center', justifyContent: 'center',
            },
            iconStyle,
          ]}
        >
          <Smartphone size={36} color={primary} strokeWidth={1.6} />
        </Animated.View>
        <Animated.View style={[{ alignItems: 'center', gap: 10 }, textStyle]}>
          <Text variant="title" style={{ fontSize: 26, textAlign: 'center', lineHeight: 32 }}>{t('welcomeTitle')}</Text>
          <Text variant="caption" style={{ fontSize: 14, textAlign: 'center', lineHeight: 20, maxWidth: 300 }}>
            {t('welcomeSubtitle')}
          </Text>
        </Animated.View>
      </View>
    </StepLayout>
  )
}

function StatStep({ onNext }: { onNext: () => void }) {
  const { t } = useTranslation('onboarding')
  const primary = useColor('primary')
  const scale = useSharedValue(0.7)

  useEffect(() => {
    scale.value = withTiming(1, { duration: 600, easing: Easing.out(Easing.back(1.6)) })
  }, [])

  const style = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }))

  return (
    <StepLayout
      footer={<Button onPress={onNext}>{t('continue')}</Button>}
    >
      <View style={{ alignItems: 'center', gap: 14 }}>
        <Animated.Text style={[{ fontSize: 56, fontWeight: '800', color: primary }, style]}>
          {t('statValue')}
        </Animated.Text>
        <Text style={{ fontSize: 16, textAlign: 'center', lineHeight: 22, maxWidth: 280 }}>
          {t('statLabel')}
        </Text>
        <Text variant="caption" style={{ fontSize: 11, opacity: 0.6 }}>{t('statSource')}</Text>
      </View>
    </StepLayout>
  )
}

function QuestionStep({
  title,
  options,
  selected,
  onSelect,
}: {
  title: string
  options: { value: string; label: string }[]
  selected: string | null
  onSelect: (value: string) => void
}) {
  return (
    <StepLayout>
      <View style={{ gap: 24 }}>
        <Text variant="title" style={{ fontSize: 22, lineHeight: 28 }}>{title}</Text>
        <View style={{ gap: 10 }}>
          {options.map(opt => (
            <ChoiceCard key={opt.value} label={opt.label} selected={selected === opt.value} onPress={() => onSelect(opt.value)} />
          ))}
        </View>
      </View>
    </StepLayout>
  )
}

function BuildingStep({ onDone }: { onDone: () => void }) {
  const { t } = useTranslation('onboarding')
  const primary = useColor('primary')
  const border = useColor('border')
  const [statusIndex, setStatusIndex] = useState(0)
  const width = useSharedValue(0)

  const statusKeys = ['buildingStep1', 'buildingStep2', 'buildingStep3']

  useEffect(() => {
    width.value = withTiming(1, { duration: 2400, easing: Easing.inOut(Easing.ease) })

    const t1 = setTimeout(() => setStatusIndex(1), 800)
    const t2 = setTimeout(() => setStatusIndex(2), 1600)
    const t3 = setTimeout(onDone, 2500)
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3) }
  }, [])

  const barStyle = useAnimatedStyle(() => ({ width: `${width.value * 100}%` }))

  return (
    <StepLayout>
      <View style={{ alignItems: 'center', gap: 24 }}>
        <Sparkles size={40} color={primary} />
        <Text variant="title" style={{ fontSize: 20, textAlign: 'center' }}>{t('buildingTitle')}</Text>
        <Text variant="caption" style={{ fontSize: 13, textAlign: 'center' }}>{t(statusKeys[statusIndex])}</Text>
        <View style={{ width: '100%', height: 6, borderRadius: 3, backgroundColor: border, overflow: 'hidden' }}>
          <Animated.View style={[{ height: '100%', backgroundColor: primary, borderRadius: 3 }, barStyle]} />
        </View>
      </View>
    </StepLayout>
  )
}

function RevealStep({
  appLabel,
  days,
  reclaimedHours,
  onNext,
}: {
  appLabel: string
  days: number
  reclaimedHours: number
  onNext: () => void
}) {
  const { t } = useTranslation('onboarding')
  const primary = useColor('primary')
  const card = useColor('card')
  const border = useColor('border')

  return (
    <StepLayout
      footer={<Button onPress={onNext} icon={ArrowRight}>{t('planReadyCta')}</Button>}
    >
      <View style={{ alignItems: 'center', gap: 18 }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: primary + '1A', borderRadius: 999, paddingHorizontal: 12, paddingVertical: 6 }}>
          <TrendingUp size={14} color={primary} />
          <Text style={{ fontSize: 12, fontWeight: '700', color: primary }}>{t('planReadyBadge')}</Text>
        </View>

        <View
          style={{
            width: '100%', backgroundColor: card, borderWidth: 1, borderColor: border,
            borderRadius: 20, padding: 24, alignItems: 'center', gap: 8,
          }}
        >
          <Text style={{ fontSize: 40, fontWeight: '800', color: primary }}>{reclaimedHours}h</Text>
          <Text style={{ fontSize: 14, fontWeight: '600', textAlign: 'center' }}>
            {t('planReadyStat', { hours: reclaimedHours })}
          </Text>
          <Text variant="caption" style={{ fontSize: 12, textAlign: 'center', lineHeight: 17, marginTop: 4 }}>
            {t('planReadySummary', { app: appLabel, days, hours: reclaimedHours })}
          </Text>
        </View>
      </View>
    </StepLayout>
  )
}
