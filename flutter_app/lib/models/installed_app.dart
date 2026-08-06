/// Port of hooks/useInstalledApps.ts's InstalledApp type. `icon`, when
/// present, is a "data:image/png;base64,..." URI built natively (see
/// BlockerBridge.kt's getInstalledApps) — unlike the RN app's file:// path
/// from react-native-launcher-kit, so lib/widgets/app_icon.dart decodes it
/// directly instead of loading a file URI.
class InstalledApp {
  final String packageName;
  final String appName;
  final String? icon;

  const InstalledApp({required this.packageName, required this.appName, this.icon});
}
