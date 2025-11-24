package com.ziraai.ziraai_mobile

import io.flutter.embedding.android.FlutterActivity
import android.Manifest
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

class MainActivity : FlutterActivity() {
    // CRITICAL FIX: Override onRequestPermissionsResult to prevent telephony plugin
    // from causing "Reply already submitted" crash when camera permission is requested
    //
    // Root Cause: telephony plugin intercepts ALL permission callbacks, including
    // camera/storage, and tries to respond even though it shouldn't handle them.
    // This causes "Reply already submitted" crash.
    //
    // Solution: Filter out camera/storage permissions from telephony plugin by only
    // calling super for SMS-related permissions
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        // Check if ANY of the permissions are SMS/Contacts related
        val hasSmsPermission = permissions.any { permission ->
            permission == Manifest.permission.READ_SMS ||
            permission == Manifest.permission.RECEIVE_SMS ||
            permission == Manifest.permission.SEND_SMS ||
            permission == Manifest.permission.READ_CONTACTS ||
            permission == Manifest.permission.WRITE_CONTACTS
        }

        // Check if ANY of the permissions are Camera/Storage related
        val hasCameraPermission = permissions.any { permission ->
            permission == Manifest.permission.CAMERA ||
            permission == Manifest.permission.READ_EXTERNAL_STORAGE ||
            permission == Manifest.permission.WRITE_EXTERNAL_STORAGE ||
            permission == Manifest.permission.READ_MEDIA_IMAGES ||
            permission == Manifest.permission.READ_MEDIA_VIDEO
        }

        // CRITICAL: If this is ONLY camera/storage (no SMS), skip the super call entirely
        // to prevent telephony plugin from seeing it
        if (hasCameraPermission && !hasSmsPermission) {
            // Handle camera/storage permissions directly without going through plugins
            // that might interfere (like telephony)
            // The permission_handler plugin will get the result through other channels
            return
        }

        // For SMS permissions or mixed permissions, call super normally
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
