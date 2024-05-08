package com.example.flutter_echo_sync_app

import io.flutter.embedding.android.FlutterActivity
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WEAR_CHANNEL = "flutter_echo_sync_app/isWatch"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val isWatch = packageManager.hasSystemFeature(PackageManager.FEATURE_WATCH)

        flutterEngine?.dartExecutor?.binaryMessenger?.let {
            MethodChannel(it, WEAR_CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "updateIsWatch") {
                    result.success(isWatch)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

}

