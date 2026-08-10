/// Curated domain/keyword lists pushed to native only while their
/// corresponding toggle in BlocklistsIndexScreen is on. Ported from the
/// chrome extension's lib/constants.ts PREDEFINED_ADULT_DOMAINS — the
/// extension additionally does live page-content analysis
/// (content/adultContentScript.ts) to catch adult sites NOT in this list,
/// which isn't something this app can replicate: it only ever sees the
/// browser's address bar text via the accessibility tree (BrowserUrlWatcher.kt),
/// never the page's actual DOM/content. So adult blocking here is
/// domain-list-only — a real but strictly narrower net than the extension's.
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
/// search), so no native changes were needed to support this toggle. Only
/// covers these platforms used THROUGH A BROWSER — TikTok/Instagram/
/// Facebook/YouTube used as native Android apps aren't reachable this way
/// (no browser address bar to read); blocking those natively would need to
/// fully block the app instead, which is a different, coarser tool
/// (Block Lists > Applications).
const List<String> reelsShortsUrlPatterns = [
  'youtube.com/shorts',
  'm.youtube.com/shorts',
  'instagram.com/reels',
  'instagram.com/reel/',
  'facebook.com/reel',
  'tiktok.com',
];
