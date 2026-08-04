import { useEffect, useState } from 'react';
import { useColorScheme as useRNColorScheme } from 'react-native';
import { useAppStore } from '@/store/useAppStore';

/**
 * To support static rendering, this value needs to be re-calculated on the client side for web.
 * An explicit user choice ('light'/'dark') wins over the browser's setting; absent that (or
 * before hydration) it falls back to 'dark', matching the splash screen default.
 */
export function useColorScheme() {
  const [hasHydrated, setHasHydrated] = useState(false);
  useEffect(() => {
    setHasHydrated(true);
  }, []);

  const preference = useAppStore(s => s.themePreference);
  const system = useRNColorScheme();

  if (!hasHydrated) return 'dark';
  if (preference === 'light' || preference === 'dark') return preference;
  return system ?? 'dark';
}
