/// Curated domain/keyword/package lists pushed to native only while their
/// corresponding toggle in BlocklistsIndexScreen is on. Ported from the
/// chrome extension's lib/constants.ts PREDEFINED_ADULT_DOMAINS.
///
/// Adult blocking has two layers natively: this curated domain list
/// (exact match, see BlockAccessibilityService.kt), plus a body-text
/// content-analysis fallback (AdultContentDetector.kt, ported from the
/// extension's content/adultContentScript.ts) for domains NOT in this
/// list. The content fallback only sees text actually rendered on screen
/// via the accessibility tree — no DOM, no <meta>/og: tags, no <title> —
/// so it's real but narrower than the extension's full-DOM analysis.
const List<String> adultDomains = [
  'xvideos.com', 'hotebonytube.com', 'mat6tube.com', 'playvids.com', 'wow.xxx',
  'xhand.net', 'thumbzilla.com', 'ebonygalore.com', 'analdin.com', 'xozilla.com',
  'upornia.com', 'mylust.com', 'xbabe.com', 'pornhub.com', 'redtube.com',
  'youporn.com', 'tube8.com', 'xnxx.com', 'xhamster.com', 'spankwire.com',
  'extremetube.com', 'tnaflix.com', 'eporner.com', 'beeg.com', 'hardsextube.com',
  'porntube.com', 'sunporno.com', 'vporn.com', 'slutload.com', 'drtuber.com',
  'fucktube.com', 'movporn.com', 'pornoxo.com', 'cliphunter.com',
  'livejasmine.com', 'camsoda.com', 'flirt4free.com', 'cam4.com', 'chaturbate.com',
  'myfreecams.com', 'stripchat.com', 'bongacams.com', 'cam.org', 'jerkmate.com',
];

/// URL substrings for short-form video feeds — matched against the full
/// address-bar text the same way user-added blocked keywords already are
/// (BlockAccessibilityService.kt's checkBrowserUrl does a plain substring
/// search), so no native changes were needed to support this toggle when
/// these platforms are used THROUGH A BROWSER.
const List<String> reelsShortsUrlPatterns = [
  'youtube.com/shorts',
  'm.youtube.com/shorts',
  'instagram.com/reels',
  'instagram.com/reel/',
  'facebook.com/reel',
];

/// TikTok's entire interface is short-form video, so there's no
/// "shorts vs. not shorts" distinction to detect within the app — blocking
/// the whole app (folded into the flat blocked-packages set, same as
/// Block Lists > Applications) achieves exactly the same result as
/// blocking "TikTok's shorts feed" would. International + some-region
/// package names.
const List<String> tiktokPackageNames = [
  'com.zhiliaoapp.musically',
  'com.ss.android.ugc.trill',
];

/// Instagram/Facebook/YouTube native-app package names the EXPERIMENTAL
/// in-app Reels/Shorts detector (ShortsFeedDetector.kt) applies to when
/// they're used as installed apps rather than through a browser — see
/// that file's doc comment for why this is best-effort/unverified.
const List<String> reelsShortsDetectablePackages = [
  'com.instagram.android',
  'com.facebook.katana',
  'com.facebook.lite',
  'com.google.android.youtube',
];
