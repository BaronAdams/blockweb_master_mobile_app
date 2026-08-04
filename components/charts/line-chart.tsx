import { useColor } from '@/hooks/useColor';
import { useEffect, useState } from 'react';
import { LayoutChangeEvent, View, ViewStyle } from 'react-native';
import Animated, {
  useAnimatedProps,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import Svg, { Circle, G, Line, Path, Text as SvgText } from 'react-native-svg';

// Mirrors the extension's recharts <LineChart> (Analytics.tsx "evolution7d"):
// a smooth stroke over a light horizontal grid, with a dot per point.
const AnimatedPath = Animated.createAnimatedComponent(Path);
const AnimatedCircle = Animated.createAnimatedComponent(Circle);

interface ChartConfig {
  width?: number;
  height?: number;
  padding?: number;
  showLabels?: boolean;
  showDots?: boolean;
  yTicks?: number;
  animated?: boolean;
  duration?: number;
  formatValue?: (value: number) => string;
}

interface ChartDataPoint {
  label: string;
  value: number;
}

type Props = {
  data: ChartDataPoint[];
  config?: ChartConfig;
  style?: ViewStyle;
  color?: string;
  selectedIndex?: number | null;
  onPointPress?: (index: number, item: ChartDataPoint) => void;
};

export const LineChart = ({ data, config = {}, style, color, selectedIndex = null, onPointPress }: Props) => {
  const [containerWidth, setContainerWidth] = useState(300);

  const {
    height = 180,
    padding = 24,
    showLabels = true,
    showDots = true,
    yTicks = 3,
    animated = true,
    duration = 800,
    formatValue = (v: number) => String(Math.round(v)),
  } = config;

  const chartWidth = containerWidth || config.width || 300;
  const lineColor = color || useColor('primary');
  const mutedColor = useColor('mutedForeground');
  const gridColor = useColor('border');

  const animationProgress = useSharedValue(0);

  const handleLayout = (event: LayoutChangeEvent) => {
    const { width: measuredWidth } = event.nativeEvent.layout;
    if (measuredWidth > 0) setContainerWidth(measuredWidth);
  };

  useEffect(() => {
    animationProgress.value = animated ? withTiming(1, { duration }) : 1;
  }, [data, animated, duration]);

  const pathAnimatedProps = useAnimatedProps(() => ({
    opacity: animationProgress.value,
  }));

  if (!data.length) return null;

  const maxValue = Math.max(...data.map(d => d.value), 1);
  const labelSpace = showLabels ? 18 : 0;
  const innerWidth = chartWidth - padding * 2;
  const innerHeight = height - padding * 2 - labelSpace;

  const points = data.map((d, i) => ({
    x: data.length > 1 ? padding + (i * innerWidth) / (data.length - 1) : padding + innerWidth / 2,
    y: padding + innerHeight - (d.value / maxValue) * innerHeight,
    ...d,
  }));

  const linePath = points.reduce((acc, p, i) => (i === 0 ? `M ${p.x} ${p.y}` : `${acc} L ${p.x} ${p.y}`), '');

  const gridLines = Array.from({ length: yTicks + 1 }, (_, i) => {
    const ratio = i / yTicks;
    const y = padding + innerHeight * ratio;
    const value = maxValue * (1 - ratio);
    return { y, value };
  });

  return (
    <View style={[{ width: '100%', height }, style]} onLayout={handleLayout}>
      <Svg width={chartWidth} height={height}>
        {gridLines.map((g, i) => (
          <G key={`grid-${i}`}>
            <Line x1={padding} x2={chartWidth - padding} y1={g.y} y2={g.y} stroke={gridColor} strokeWidth={1} />
            <SvgText x={0} y={g.y + 3} fontSize={9} fill={mutedColor}>
              {formatValue(g.value)}
            </SvgText>
          </G>
        ))}

        <AnimatedPath d={linePath} stroke={lineColor} strokeWidth={2.5} fill="none" animatedProps={pathAnimatedProps} />

        {points.map((p, index) => {
          const isSelected = selectedIndex === index;
          const dotAnimatedProps = useAnimatedProps(() => ({
            opacity: animationProgress.value,
          }));
          return (
            <G key={`point-${index}`}>
              {onPointPress && (
                <Circle
                  cx={p.x}
                  cy={p.y}
                  r={16}
                  fill="transparent"
                  onPress={() => onPointPress(index, p)}
                />
              )}
              {showDots && (
                <AnimatedCircle
                  cx={p.x}
                  cy={p.y}
                  r={isSelected ? 5 : 3.5}
                  fill={lineColor}
                  animatedProps={dotAnimatedProps}
                />
              )}
              {showLabels && (
                <SvgText x={p.x} y={height - 4} textAnchor="middle" fontSize={10} fill={mutedColor}>
                  {p.label}
                </SvgText>
              )}
            </G>
          );
        })}
      </Svg>
    </View>
  );
};
