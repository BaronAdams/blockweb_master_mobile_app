import { useEffect, useState } from 'react'
import { Pressable } from 'react-native'
import Animated, { Easing, FadeIn, FadeOut, LinearTransition, useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated'
import { ChevronDown } from 'lucide-react-native'
import { View } from '@/components/ui/view'
import { Text } from '@/components/ui/text'
import { useColor } from '@/hooks/useColor'

export type FaqAccordionItem = { id: string; question: string; answer: string }

// Custom accordion — not BNA UI's — built to match a reference design: one
// bordered rounded card per item (not a single card with separators
// between rows), a circular chevron that flips and inverts color when
// open, and a smooth expand/collapse. The card's height animates via
// reanimated's automatic layout transition (LinearTransition) rather than
// manual height measurement, which avoids the "flash of full height on
// first open" that naive onLayout-based measuring causes.
export function FaqAccordion({ items }: { items: FaqAccordionItem[] }) {
  const [openId, setOpenId] = useState<string | null>(null)

  return (
    <View style={{ gap: 10 }}>
      {items.map(item => (
        <FaqAccordionRow
          key={item.id}
          item={item}
          isOpen={openId === item.id}
          onToggle={() => setOpenId(prev => (prev === item.id ? null : item.id))}
        />
      ))}
    </View>
  )
}

function FaqAccordionRow({
  item,
  isOpen,
  onToggle,
}: {
  item: FaqAccordionItem
  isOpen: boolean
  onToggle: () => void
}) {
  const card = useColor('card')
  const border = useColor('border')
  const primary = useColor('primary')
  const primaryForeground = useColor('primaryForeground')
  const mutedForeground = useColor('mutedForeground')

  const progress = useSharedValue(0)
  useEffect(() => {
    progress.value = withTiming(isOpen ? 1 : 0, { duration: 300, easing: Easing.out(Easing.cubic) })
  }, [isOpen])

  const chevronStyle = useAnimatedStyle(() => ({
    transform: [{ rotate: `${progress.value * 180}deg` }],
  }))

  return (
    <Animated.View
      layout={LinearTransition.duration(250)}
      style={{
        borderWidth: 1,
        borderColor: isOpen ? primary + '66' : border,
        backgroundColor: card,
        borderRadius: 14,
        overflow: 'hidden',
      }}
    >
      <Pressable
        onPress={onToggle}
        style={{
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 12,
          paddingVertical: 14,
          paddingHorizontal: 16,
        }}
      >
        <Text style={{ flex: 1, fontSize: 13, fontWeight: '600', lineHeight: 18 }}>{item.question}</Text>
        <Animated.View
          style={[
            {
              width: 22,
              height: 22,
              borderRadius: 11,
              borderWidth: 1.5,
              alignItems: 'center',
              justifyContent: 'center',
              borderColor: isOpen ? primary : border,
              backgroundColor: isOpen ? primary : 'transparent',
            },
            chevronStyle,
          ]}
        >
          <ChevronDown size={12} color={isOpen ? primaryForeground : mutedForeground} />
        </Animated.View>
      </Pressable>

      {isOpen && (
        <Animated.View
          entering={FadeIn.duration(200)}
          exiting={FadeOut.duration(150)}
          style={{
            paddingHorizontal: 16,
            paddingBottom: 14,
            paddingTop: 4,
            borderTopWidth: 1,
            borderTopColor: border,
          }}
        >
          <Text variant="caption" style={{ fontSize: 12, lineHeight: 17 }}>{item.answer}</Text>
        </Animated.View>
      )}
    </Animated.View>
  )
}
