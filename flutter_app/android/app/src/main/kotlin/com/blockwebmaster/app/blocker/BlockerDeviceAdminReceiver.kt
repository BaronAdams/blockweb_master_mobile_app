package com.blockwebmaster.app.blocker

import android.app.admin.DeviceAdminReceiver

/**
 * Registers this app as an active Android "Device Administrator" — the
 * only uninstall-friction mechanism available to a normal Play Store app
 * (Device Owner / Profile Owner, which support a true unremovable lock via
 * DevicePolicyManager.setUninstallBlocked, both require special enterprise
 * provisioning that isn't available to a regular installed app).
 *
 * While active, Android requires deactivating device admin (Settings >
 * Security > Device admin apps) as an explicit extra step before this app
 * can be uninstalled — a real, standard speed bump (the same one other
 * screen-time/parental-control apps on the Play Store use), not a
 * bypass-proof lock: both the user and this app itself can still call
 * DevicePolicyManager.removeActiveAdmin() at any time, since we are not a
 * device/profile owner. No custom device policies are requested — this
 * exists purely to be "an active admin," nothing else.
 */
class BlockerDeviceAdminReceiver : DeviceAdminReceiver()
