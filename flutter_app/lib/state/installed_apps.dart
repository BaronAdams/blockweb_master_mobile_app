import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/installed_app.dart';
import '../native/blocker_bridge.dart';

/// Port of hooks/useInstalledApps.ts. Real installed-apps list on Android
/// (via BlockerBridge.getInstalledApps — see that file's doc comment);
/// falls back to the same curated "popular apps" list the RN app uses on
/// iOS/web or if the native call fails for any reason, so the picker UI
/// always has something to show rather than an empty screen.
class InstalledAppsNotifier extends StateNotifier<AsyncValue<List<InstalledApp>>> {
  InstalledAppsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    if (Platform.isAndroid) {
      final apps = await BlockerBridge.getInstalledApps();
      if (apps.isNotEmpty) {
        state = AsyncValue.data(apps);
        return;
      }
    }
    state = AsyncValue.data(Platform.isAndroid ? _popularAndroid : _popularIOS);
  }
}

final installedAppsProvider = StateNotifierProvider<InstalledAppsNotifier, AsyncValue<List<InstalledApp>>>(
  (ref) => InstalledAppsNotifier(),
);

const _popularAndroid = [
  InstalledApp(packageName: 'com.instagram.android', appName: 'Instagram'),
  InstalledApp(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
  InstalledApp(packageName: 'com.facebook.katana', appName: 'Facebook'),
  InstalledApp(packageName: 'com.twitter.android', appName: 'X (Twitter)'),
  InstalledApp(packageName: 'com.google.android.youtube', appName: 'YouTube'),
  InstalledApp(packageName: 'com.reddit.frontpage', appName: 'Reddit'),
  InstalledApp(packageName: 'com.snapchat.android', appName: 'Snapchat'),
  InstalledApp(packageName: 'com.discord', appName: 'Discord'),
  InstalledApp(packageName: 'com.pinterest', appName: 'Pinterest'),
  InstalledApp(packageName: 'com.linkedin.android', appName: 'LinkedIn'),
  InstalledApp(packageName: 'com.whatsapp', appName: 'WhatsApp'),
  InstalledApp(packageName: 'org.telegram.messenger', appName: 'Telegram'),
];

const _popularIOS = [
  InstalledApp(packageName: 'com.burbn.instagram', appName: 'Instagram'),
  InstalledApp(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
  InstalledApp(packageName: 'com.facebook.Facebook', appName: 'Facebook'),
  InstalledApp(packageName: 'com.atebits.Tweetie2', appName: 'X (Twitter)'),
  InstalledApp(packageName: 'com.google.ios.youtube', appName: 'YouTube'),
  InstalledApp(packageName: 'com.reddit.Reddit', appName: 'Reddit'),
  InstalledApp(packageName: 'com.toyopagroup.picaboo', appName: 'Snapchat'),
  InstalledApp(packageName: 'com.hammerandchisel.discord', appName: 'Discord'),
  InstalledApp(packageName: 'pinterest', appName: 'Pinterest'),
  InstalledApp(packageName: 'com.linkedin.LinkedIn', appName: 'LinkedIn'),
];
