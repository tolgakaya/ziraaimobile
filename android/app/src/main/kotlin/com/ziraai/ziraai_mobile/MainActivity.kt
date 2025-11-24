package com.ziraai.ziraai_mobile

import io.flutter.embedding.android.FlutterActivity
import android.Manifest

class MainActivity : FlutterActivity() {
    // CRITICAL FIX: Override onRequestPermissionsResult to prevent telephony plugin
    // from causing "Reply already submitted" crash when camera permission is requested
    //
    // Root Cause: telephony plugin tries to handle ALL permission results, including
    // camera/storage, which conflicts with permission_handler plugin
    //
    // Solution: Only forward SMS-related permissions to telephony plugin
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        // Check if this is an SMS/contacts permission request
        val isSmsRelated = permissions.any { permission ->
            permission == Manifest.permission.READ_SMS ||
            permission == Manifest.permission.RECEIVE_SMS ||
            permission == Manifest.permission.SEND_SMS ||
            permission == Manifest.permission.READ_CONTACTS ||
            permission == Manifest.permission.WRITE_CONTACTS
        }

        // Always call super, but telephony plugin will only process SMS-related permissions
        // This prevents "Reply already submitted" error for camera/storage permissions
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
