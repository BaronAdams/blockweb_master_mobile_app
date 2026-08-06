import 'package:flutter/material.dart';

/// Direct port of lib/categories.ts — same curated package lists, same
/// colors/emojis, same priority order (distraction > entertainment >
/// productivity > other) when classifying an app for Analytics.
enum SiteCategory { adult, distraction, entertainment, productivity, other }

class CategoryMeta {
  final String labelKey;
  final String descKey;
  final Color color;
  final String emoji;

  const CategoryMeta({
    required this.labelKey,
    required this.descKey,
    required this.color,
    required this.emoji,
  });
}

const Map<SiteCategory, CategoryMeta> categoryMeta = {
  SiteCategory.adult: CategoryMeta(
    labelKey: 'adultContent', descKey: 'adultContentDesc', color: Color(0xFFF43F5E), emoji: '🔞',
  ),
  SiteCategory.distraction: CategoryMeta(
    labelKey: 'distraction', descKey: 'distractionDesc', color: Color(0xFF9E4FE7), emoji: '📱',
  ),
  SiteCategory.entertainment: CategoryMeta(
    labelKey: 'entertainment', descKey: 'entertainmentDesc', color: Color(0xFFFBBF24), emoji: '🎬',
  ),
  SiteCategory.productivity: CategoryMeta(
    labelKey: 'productivity', descKey: 'productivityDesc', color: Color(0xFF34D399), emoji: '💼',
  ),
  SiteCategory.other: CategoryMeta(
    labelKey: 'other', descKey: 'otherDesc', color: Color(0xFF60A5FA), emoji: '🌐',
  ),
};

const List<SiteCategory> categoryOrder = [
  SiteCategory.adult,
  SiteCategory.distraction,
  SiteCategory.entertainment,
  SiteCategory.productivity,
  SiteCategory.other,
];

const List<String> _distractionPackages = [
  'com.facebook.katana', 'com.facebook.lite',
  'com.instagram.android', 'com.instagram.lite',
  'com.zhiliaoapp.musically', 'com.ss.android.ugc.trill',
  'com.twitter.android', 'com.x.android',
  'com.snapchat.android',
  'com.reddit.frontpage',
  'com.pinterest',
  'com.linkedin.android',
  'com.tumblr',
  'com.discord',
  'org.telegram.messenger', 'org.telegram.messenger.web',
  'com.whatsapp', 'com.whatsapp.w4b',
  'com.facebook.orca',
  'com.vkontakte.android',
  'com.quora.android',
  'com.sina.weibo',
  'com.bereal.ft',
  'com.ss.android.ugc.aweme',
];

const List<String> _entertainmentPackages = [
  'com.google.android.youtube', 'com.google.android.youtube.tv',
  'com.netflix.mediaclient',
  'com.spotify.music', 'com.spotify.lite',
  'tv.twitch.android.app',
  'deezer.android.app',
  'com.disney.disneyplus',
  'com.amazon.avod.thirdpartyclient',
  'com.hulu.plus',
  'com.wbd.stream', 'com.hbo.hbonow',
  'jp.co.crunchyroll.crunchyroid',
  'com.soundcloud.android',
  'com.vimeo.android.videoapp',
  'air.tv.kick.app',
  'tv.danmaku.bili',
  'com.pandora.android',
  'com.clearchannel.iheartradio.controller',
  'com.peacocktv.peacockandroid',
  'com.cbs.app',
  'com.disney.datg.videoplatforms.android.disneynow',
];

const List<String> _productivityPackages = [
  'com.github.android',
  'com.gitlab.gitlab',
  'notion.id',
  'com.figma.mirror',
  'com.stackexchange.stackoverflow',
  'com.google.android.apps.docs', 'com.google.android.apps.docs.editors.docs',
  'com.google.android.apps.docs.editors.sheets',
  'com.google.android.apps.docs.editors.slides',
  'com.google.android.calendar',
  'com.google.android.gm',
  'com.microsoft.office.outlook',
  'com.microsoft.office.officehubrow',
  'com.microsoft.teams',
  'com.Slack',
  'com.atlassian.jira.core',
  'com.linear.android',
  'com.trello',
  'com.asana.app',
  'com.clickup.android',
  'com.formagrid.airtable',
  'com.miro.app',
  'com.loom.android',
  'us.zoom.videomeetings',
  'com.google.android.apps.meetings',
  'com.vercel.app',
  'com.netlify.app',
  'com.coursera.android',
  'com.udemy.android',
  'org.mozilla.focus',
];

/// Best-effort classification for Analytics — apps not in any list above
/// fall into `other`, which is the honest, expected outcome for the long
/// tail of apps this curated list can't cover.
SiteCategory categorizeApp(String packageName) {
  if (_distractionPackages.contains(packageName)) return SiteCategory.distraction;
  if (_entertainmentPackages.contains(packageName)) return SiteCategory.entertainment;
  if (_productivityPackages.contains(packageName)) return SiteCategory.productivity;
  return SiteCategory.other;
}
