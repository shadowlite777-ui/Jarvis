package com.example.jarvis

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.jarvis/service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startServiceIntent()
                    result.success(true)
                }
                "stopService" -> {
                    stopServiceIntent()
                    result.success(true)
                }
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startServiceIntent() {
        val intent = Intent(this, ForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopServiceIntent() {
        val intent = Intent(this, ForegroundService::class.java)
        stopService(intent)
    }

    private fun requestBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent().apply {
                action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                data = Uri.parse("package:$packageName")
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
            }
        }
    }
}
