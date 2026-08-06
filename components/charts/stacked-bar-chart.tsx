import { useColor } from '@/hooks/useColor';
import React, { useEffect, useState } from 'react';
import { LayoutChangeEvent, View, ViewStyle } from 'react-native';
import Animated, {
  SharedValue,
  useAnimatedProps,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import Svg, { G, Rect, Text as SvgText } from 'react-native-svg';

// A local extension of components/charts/bar-chart.tsx (the real BNA UI
// component, kept as-is elsewhere) for the one case it doesn't cover: a
// fixed-height translucent "track" per bar, filled from the bottom up by
// colored category segments — used for the hourly usage chart. Same visual
// language (rounded rects, animated reveal, SVG) as the upstream component.
const AnimatedRect = Animated.createAnimatedComponent(Rect);

type StackedSegment = { key: string; value: number; color: string };
type StackedBarDataPoint = { label: string; segments: StackedSegment[] };

type AnimatedSegmentProps = {
  x: number;
  width: number;
  segmentHeight: number;
  y: number;
  fill: string;
  animationProgress: SharedValue<number>;
};

const AnimatedSegment = React.memo(
  ({ x, width, segmentHeight, y, fill, animationProgress }: AnimatedSegmentProps) => {
    const animatedProps = useAnimatedProps(() => ({
      height: animationProgress.value * segmentHeight,
      y: y + segmentHeight - animationProgress.value * segmentHeight,
    }));

    return <AnimatedRect x={x} width={width} fill={fill} animatedProps={animatedProps} />;
  }
);

interface ChartConfig {
  width?: number;
  height?: number;
  padding?: number;
  showLabels?: boolean;
  labelEvery?: number;
  animated?: boolean;
  duration?: number;
}

type Props = {
  data: StackedBarDataPoint[];
  config?: ChartConfig;
  style?: ViewStyle;
  selectedIndex?: number | null;
  onBarPress?: (index: number, item: StackedBarDataPoint) => void;
};

export const StackedBarChart = ({ data, config = {}, style, selectedIndex = null, onBarPress }: Props) => {
  const [containerWidth, setContainerWidth] = useState(300);

  const {
    height = 160,
    padding = 20,
    showLabels = true,
    labelEvery = 1,
    animated = true,
    duration = 700,
  } = config;

  const chartWidth = containerWidth || config.width || 300;
  const mutedColor = useColor('mutedForeground');
  const animationProgress = useSharedValue(0);

  const handleLayout = (event: LayoutChangeEvent) => {
    const { width: measuredWidth } = event.nativeEvent.layout;
    if (measuredWidth > 0) setContainerWidth(measuredWidth);
  };

  useEffect(() => {
    animationProgress.value = animated ? withTiming(1, { duration }) : 1;
  }, [data, animated, duration]);

  if (!data.length) return null;

  const totals = data.map(d => d.segments.reduce((sum, s) => sum + s.value, 0));
  const maxTotal = Math.max(...totals);

  const innerChartWidth = chartWidth - padding * 2;
  const chartHeight = height - padding * 2 - 14; // leaves room for the hour label below
  const barWidth = (innerChartWidth / data.length) * 0.7;
  const barSpacing = (innerChartWidth / data.length) * 0.3;
  const trackTop = padding;
  const trackBottom = padding + chartHeight;

  return (
    <View
      style={[{ width: '100%', height }, style]}
      onLayout={handleLayout}
      accessibilityRole='image'
      accessibilityLabel={`Bar chart with ${data.length} bars`}
    >
      <Svg width={chartWidth} height={height}>
        {data.map((item, index) => {
          const total = totals[index];
          const x = padding + index * (barWidth + barSpacing) + barSpacing / 2;
          const isDimmed = selectedIndex != null && selectedIndex !== index;
          const trackOpacity = isDimmed ? 0.06 : 0.12;
          const fillOpacity = isDimmed ? 0.35 : 1;

          let cumulativeY = trackBottom;
          const segmentRects = maxTotal > 0 && total > 0
            ? item.segments
                .filter(s => s.value > 0)
                .map(seg => {
                  const segHeight = (seg.value / maxTotal) * chartHeight;
                  cumulativeY -= segHeight;
                  return { seg, y: cumulativeY, segHeight };
                })
            : [];

          return (
            <G key={`bar-${index}`}>
              {/* Full-height translucent track — always visible, even at zero. */}
              <Rect
                x={x}
                y={trackTop}
                width={barWidth}
                height={chartHeight}
                rx={4}
                fill={mutedColor}
                opacity={trackOpacity}
              />

              <G opacity={fillOpacity}>
                {segmentRects.map(({ seg, y, segHeight }) => (
                  <AnimatedSegment
                    key={seg.key}
                    x={x}
                    width={barWidth}
                    y={y}
                    segmentHeight={segHeight}
                    fill={seg.color}
                    animationProgress={animationProgress}
                  />
                ))}
              </G>

              {onBarPress && (
                <Rect
                  x={x - barSpacing / 2}
                  y={0}
                  width={barWidth + barSpacing}
                  height={height}
                  fill='transparent'
                  onPress={() => onBarPress(index, item)}
                />
              )}

              {showLabels && index % labelEvery === 0 && (
                <SvgText
                  x={x + barWidth / 2}
                  y={height - 3}
                  textAnchor='middle'
                  fontSize={9}
                  fill={mutedColor}
                  opacity={isDimmed ? 0.5 : 1}
                >
                  {item.label}
                </SvgText>
              )}
            </G>
          );
        })}
      </Svg>
    </View>
  );
};
