package com.example.openiptv

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register native HTTP client
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.openiptv/native_http"
        )
        NativeHttpClient.register(channel)
    }
}
