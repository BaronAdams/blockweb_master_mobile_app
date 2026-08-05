// Must match app.json's android.package / ios.bundleIdentifier. Used to
// exclude BlockWeb Master itself from the installed-apps list and from
// usage tracking — blocking or tracking ourselves makes no sense and
// would let a user accidentally lock themselves out of the app.
export const OWN_PACKAGE_NAME = 'com.blockwebmaster.app'
