/*
 * Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
 *                       <https://github.com/team113>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License v3.0 as published by the
 * Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
 * more details.
 *
 * You should have received a copy of the GNU Affero General Public License v3.0
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/agpl-3.0.html>.
 */

package com.team113.messenger

import android.app.AlertDialog
import android.content.Context
import android.content.ContextWrapper
import android.content.DialogInterface
import android.content.DialogInterface.OnClickListener
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import android.view.WindowManager
import android.app.KeyguardManager

class MainActivity: FlutterActivity() {
    private val UTILS_CHANNEL = "team113.flutter.dev/android_utils"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UTILS_CHANNEL,
        ).setMethodCallHandler {
            call, result ->
            if (call.method == "canDrawOverlays") {
                result.success(canDrawOverlays())
            } else if (call.method == "openOverlaySettings") {
                openOverlaySettings()
                result.success(null)
            } else if (call.method == "foregroundFromLockscreen") {
                foregroundFromLockscreen()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Inicates whether the device has a persmission to draw overlays or not.
     *
     * @return `true` if draw overlays permission is given, otherwise `false`.
     */
    private fun canDrawOverlays(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if ("xiaomi" == Build.MANUFACTURER.toLowerCase(Locale.ROOT)) {
                return Settings.canDrawOverlays(this);
            }
        }

        return true;
    }

    /**
     * Opens overlay settings of this device.
     */
    private fun openOverlaySettings() {
        if ("xiaomi" == Build.MANUFACTURER.toLowerCase(Locale.ROOT)) {
            val intent = Intent("miui.intent.action.APP_PERM_EDITOR")
            intent.setClassName("com.miui.securitycenter",
                "com.miui.permcenter.permissions.PermissionsEditorActivity")
            intent.putExtra("extra_pkgname", getPackageName())
            startActivity(intent)
        } else {
            val overlaySettings = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + getPackageName()),
            )
            startActivityForResult(overlaySettings, 251)
        }
    }

    /**
     * Requests the device to open this activity from a lockscreen.
     */
    private fun foregroundFromLockscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager: KeyguardManager? =
                getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager?
            if (keyguardManager != null)
                keyguardManager.requestDismissKeyguard(this, null)
        } else {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        }
    }
}
