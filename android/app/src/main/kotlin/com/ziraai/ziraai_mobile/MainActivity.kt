package com.ziraai.ziraai_mobile

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // SOLUTION: Remove telephony plugin override entirely
    // Let permission_handler manage all permissions without interference
    // The telephony plugin conflict is resolved by not using onRequestPermissionsResult override
}
