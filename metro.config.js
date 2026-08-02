const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// zustand's ESM build (middleware.mjs) contains a raw `import.meta.env`
// reference for Vite compatibility. Metro bundles that file as-is into a
// classic (non-module) script, which throws a SyntaxError at parse time.
// Disabling package-exports resolution makes Metro fall back to zustand's
// CommonJS build instead.
config.resolver.unstable_enablePackageExports = false;

module.exports = config;
