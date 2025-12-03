package com.example.openiptv

import android.util.Log
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Native Android HTTP client using OkHttp
 * This provides the exact same TLS/HTTP fingerprint as TiviMate
 */
class NativeHttpClient {
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .followRedirects(true)
        .build()

    companion object {
        private const val TAG = "NativeHttpClient"
        private const val CHANNEL = "com.example.openiptv/native_http"

        fun register(channel: MethodChannel) {
            val instance = NativeHttpClient()
            
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "testConnection" -> {
                        val url = call.argument<String>("url")
                        val headers = call.argument<Map<String, String>>("headers")
                        
                        if (url == null) {
                            result.error("INVALID_ARGUMENT", "URL is required", null)
                            return@setMethodCallHandler
                        }
                        
                        instance.testConnection(url, headers ?: emptyMap(), result)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun testConnection(
        url: String,
        headers: Map<String, String>,
        result: MethodChannel.Result
    ) {
        Thread {
            try {
                val requestBuilder = Request.Builder().url(url)
                
                // Add custom headers
                headers.forEach { (key, value) ->
                    requestBuilder.addHeader(key, value)
                }
                
                val request = requestBuilder.build()
                
                Log.d(TAG, "=== Native OkHttp Request ===")
                Log.d(TAG, "URL: $url")
                Log.d(TAG, "Headers: ${request.headers}")
                
                client.newCall(request).execute().use { response ->
                    Log.d(TAG, "Response: ${response.code} ${response.message}")
                    Log.d(TAG, "Headers: ${response.headers}")
                    
                    val resultMap = mapOf(
                        "statusCode" to response.code,
                        "statusMessage" to response.message,
                        "headers" to response.headers.toMultimap(),
                        "success" to response.isSuccessful
                    )
                    
                    result.success(resultMap)
                }
            } catch (e: IOException) {
                Log.e(TAG, "Connection failed", e)
                result.error("CONNECTION_ERROR", e.message, null)
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error", e)
                result.error("UNKNOWN_ERROR", e.message, null)
            }
        }.start()
    }
}
