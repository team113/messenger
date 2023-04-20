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

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.Bundle
import android.provider.Settings
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val utilsChanel = "team113.flutter.dev/android_utils"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            utilsChanel,
        ).setMethodCallHandler { call, result ->
            if (call.method == "canDrawOverlays") {
                result.success(canDrawOverlays())
            } else if (call.method == "openOverlaySettings") {
                openOverlaySettings()
                result.success(null)
            } else if (call.method == "createNotificationChannel") {
                val argData =
                    call.arguments as java.util.HashMap<String, String>
                val completed = createNotificationChannel(argData)
                if (completed) {
                    result.success(null)
                } else {
                    result.error(
                        "CreateNotificationChannelError",
                        "NotificationChannel not created",
                        null,
                    )
                }
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Indicates whether the device has a permission to draw overlays or not.
     *
     * @return `true` if draw overlays permission is given, otherwise `false`.
     */
    private fun canDrawOverlays(): Boolean {
        if ("xiaomi" == Build.MANUFACTURER.lowercase(Locale.ROOT)) {
            return Settings.canDrawOverlays(this)
        }

        return true
    }

    /**
     * Opens overlay settings of this device.
     */
    private fun openOverlaySettings() {
        if ("xiaomi" == Build.MANUFACTURER.lowercase(Locale.ROOT)) {
            val intent = Intent("miui.intent.action.APP_PERM_EDITOR")
            intent.setClassName(
                "com.miui.securitycenter",
                "com.miui.permcenter.permissions.PermissionsEditorActivity",
            )
            intent.putExtra("extra_pkgname", packageName)
            startActivity(intent)
        } else {
            val overlaySettings = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"),
            )
            startActivityForResult(overlaySettings, 251)
        }
    }

    /**
     * Creates a new [NotificationChannel] with the provided parameters.
     */
    private fun createNotificationChannel(arguments: HashMap<String, String>): Boolean {
        val completed: Boolean
        if (VERSION.SDK_INT >= VERSION_CODES.O) {
            val id = arguments["id"]
            val name = arguments["name"]
            val descriptionText = arguments["description"]
            val sound = arguments["sound"]
            val importance = NotificationManager.IMPORTANCE_HIGH
            val nChannel = NotificationChannel(id, name, importance)
            nChannel.description = descriptionText

            val soundUri =
                Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + applicationContext.packageName + "/raw/" + sound)
            val att = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()

            nChannel.setSound(soundUri, att)
            val notificationManager =
                getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(nChannel)
            completed = true
        } else {
            completed = false
        }
        return completed
    }
}
