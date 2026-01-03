package com.ziraai.app

import io.flutter.embedding.android.FlutterActivity
import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Enable edge-to-edge display for Android 15+ (API 35+) compatibility
        // This is required by Google Play Store for apps targeting SDK 35+
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
