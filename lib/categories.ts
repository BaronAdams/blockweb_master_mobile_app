export type SiteCategory = 'adult' | 'distraction' | 'entertainment' | 'productivity' | 'other'

type CategoryMeta = {
  labelKey: string
  descKey: string
  color: string
  emoji: string
}

// Exact colors/emojis from the Chrome extension's lib/constants.ts CATEGORY_META.
export const CATEGORY_META: Record<SiteCategory, CategoryMeta> = {
  adult: {
    labelKey: 'adultContent',
    descKey: 'adultContentDesc',
    color: '#f43f5e',
    emoji: '🔞',
  },
  distraction: {
    labelKey: 'distraction',
    descKey: 'distractionDesc',
    color: '#9e4fe7',
    emoji: '📱',
  },
  entertainment: {
    labelKey: 'entertainment',
    descKey: 'entertainmentDesc',
    color: '#fbbf24',
    emoji: '🎬',
  },
  productivity: {
    labelKey: 'productivity',
    descKey: 'productivityDesc',
    color: '#34d399',
    emoji: '💼',
  },
  other: {
    labelKey: 'other',
    descKey: 'otherDesc',
    color: '#60a5fa',
    emoji: '🌐',
  },
}

export const CATEGORY_ORDER: SiteCategory[] = ['adult', 'distraction', 'entertainment', 'productivity', 'other']

// Android package name -> category, for Analytics. Mirrors the Chrome
// extension's SITE_CATEGORIES domain lists (lib/constants.ts) but keyed by
// app package instead of website domain, since this is native app usage,
// not browser tab usage. Priority when checked: distraction > entertainment
// > productivity > other (see categorizeApp below).
const DISTRACTION_PACKAGES = [
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
  'com.facebook.orca', // Messenger
  'com.vkontakte.android',
  'com.quora.android',
  'com.sina.weibo',
  'com.bereal.ft',
  'com.ss.android.ugc.aweme', // TikTok (alt package on some builds)
]

const ENTERTAINMENT_PACKAGES = [
  'com.google.android.youtube', 'com.google.android.youtube.tv',
  'com.netflix.mediaclient',
  'com.spotify.music', 'com.spotify.lite',
  'tv.twitch.android.app',
  'deezer.android.app',
  'com.disney.disneyplus',
  'com.amazon.avod.thirdpartyclient', // Prime Video
  'com.hulu.plus',
  'com.wbd.stream', 'com.hbo.hbonow', // Max / HBO Max
  'jp.co.crunchyroll.crunchyroid',
  'com.soundcloud.android',
  'com.vimeo.android.videoapp',
  'air.tv.kick.app',
  'tv.danmaku.bili', // Bilibili
  'com.pandora.android',
  'com.clearchannel.iheartradio.controller',
  'com.peacocktv.peacockandroid',
  'com.cbs.app', // Paramount+
  'com.disney.datg.videoplatforms.android.disneynow',
]

const PRODUCTIVITY_PACKAGES = [
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
  'com.microsoft.office.officehubrow', // Microsoft 365
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
  'com.google.android.apps.meetings', // Google Meet
  'com.vercel.app',
  'com.netlify.app',
  'com.coursera.android',
  'com.udemy.android',
  'org.mozilla.focus', // treated as a productivity-leaning privacy browser
]

const CATEGORY_PACKAGE_LISTS: [SiteCategory, string[]][] = [
  ['distraction', DISTRACTION_PACKAGES],
  ['entertainment', ENTERTAINMENT_PACKAGES],
  ['productivity', PRODUCTIVITY_PACKAGES],
]

/** Best-effort classification for Analytics — apps not in any list above
 *  fall into 'other', which is the honest, expected outcome for the long
 *  tail of apps this curated list can't cover. */
export function categorizeApp(packageName: string): SiteCategory {
  for (const [category, packages] of CATEGORY_PACKAGE_LISTS) {
    if (packages.includes(packageName)) return category
  }
  return 'other'
}
