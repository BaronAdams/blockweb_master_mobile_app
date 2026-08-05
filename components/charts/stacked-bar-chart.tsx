import { useColor } from '@/hooks/useColor';
import React, { useEffect, useState } from 'react';
import { LayoutChangeEvent, View, ViewStyle } from 'react-native';
import Animated, {
  SharedValue,
  useAnimatedProps,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import Svg, { G, Line, Rect, Text as SvgText } from 'react-native-svg';

// A local extension of components/charts/bar-chart.tsx (the real BNA UI
// component, kept as-is elsewhere) for the one case it doesn't cover:
// each bar split into colored segments — used for the hourly usage chart,
// one segment per category. Same visual language (rounded rect bars,
// animated reveal, SVG) and animation approach as the upstream component.
const AnimatedRect = Animated.createAnimatedComponent(Rect);

type StackedSegment = { key: string; value: number; color: string };
type StackedBarDataPoint = { label: string; segments: StackedSegment[] };

type AnimatedSegmentProps = {
  x: number;
  width: number;
  segmentHeight: number;
  y: number;
  fill: string;
  opacity: number;
  animationProgress: SharedValue<number>;
};

const AnimatedSegment = React.memo(
  ({ x, width, segmentHeight, y, fill, opacity, animationProgress }: AnimatedSegmentProps) => {
    const animatedProps = useAnimatedProps(() => ({
      height: animationProgress.value * segmentHeight,
      y: y + segmentHeight - animationProgress.value * segmentHeight,
    }));

    return <AnimatedRect x={x} width={width} fill={fill} opacity={opacity} animatedProps={animatedProps} />;
  }
);

interface ChartConfig {
  width?: number;
  height?: number;
  padding?: number;
  showGrid?: boolean;
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
    showGrid = false,
    showLabels = true,
    labelEvery = 1,
    animated = true,
    duration = 700,
  } = config;

  const chartWidth = containerWidth || config.width || 300;
  const mutedColor = useColor('mutedForeground');
  const border = useColor('border');
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
  if (maxTotal === 0) return null;

  const innerChartWidth = chartWidth - padding * 2;
  const chartHeight = height - padding * 2;
  const barWidth = (innerChartWidth / data.length) * 0.7;
  const barSpacing = (innerChartWidth / data.length) * 0.3;

  return (
    <View
      style={[{ width: '100%', height }, style]}
      onLayout={handleLayout}
      accessibilityRole='image'
      accessibilityLabel={`Bar chart with ${data.length} bars`}
    >
      <Svg width={chartWidth} height={height}>
        {showGrid && (
          <G>
            {[0, 0.25, 0.5, 0.75, 1].map((ratio, index) => (
              <Line
                key={`grid-${index}`}
                x1={padding}
                y1={padding + ratio * chartHeight}
                x2={chartWidth - padding}
                y2={padding + ratio * chartHeight}
                stroke={mutedColor}
                strokeWidth={0.5}
                opacity={0.3}
              />
            ))}
          </G>
        )}

        {data.map((item, index) => {
          const total = totals[index];
          const x = padding + index * (barWidth + barSpacing) + barSpacing / 2;
          const bottomY = height - padding;
          const isDimmed = selectedIndex != null && selectedIndex !== index;

          let cumulativeY = bottomY;
          const segmentRects = total > 0
            ? item.segments
                .filter(s => s.value > 0)
                .map(seg => {
                  const segHeight = (seg.value / maxTotal) * chartHeight;
                  cumulativeY -= segHeight;
                  return { seg, y: cumulativeY, segHeight };
                })
            : [{ seg: { key: 'empty', value: 0, color: border }, y: bottomY - 2, segHeight: 2 }];

          return (
            <G key={`bar-${index}`}>
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

              {segmentRects.map(({ seg, y, segHeight }) => (
                <AnimatedSegment
                  key={seg.key}
                  x={x}
                  width={barWidth}
                  y={y}
                  segmentHeight={segHeight}
                  fill={seg.color}
                  opacity={isDimmed ? 0.3 : 1}
                  animationProgress={animationProgress}
                />
              ))}

              {showLabels && index % labelEvery === 0 && (
                <SvgText
                  x={x + barWidth / 2}
                  y={height - 5}
                  textAnchor='middle'
                  fontSize={9}
                  fill={mutedColor}
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
