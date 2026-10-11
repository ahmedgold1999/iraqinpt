package com.inpt.ahmeed.iraqinpt

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.inpt.ahmeed.iraqinpt/app_icon"

    private val aliases = listOf(
        "MainActivity",
        "MainActivityWinter",
        "MainActivityNewYear",
        "MainActivityRamadan",
        "MainActivityIraq"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "changeIcon" -> {
                    val iconKey = call.argument<String>("iconKey") ?: "default"
                    val success = setAppIcon(iconKey)
                    result.success(success)
                }
                "getCurrentIcon" -> {
                    result.success(getCurrentIcon())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setAppIcon(iconKey: String): Boolean {
        val targetAlias = when (iconKey.lowercase()) {
            "winter" -> "MainActivityWinter"
            "newyear" -> "MainActivityNewYear"
            "ramadan", "ramdan" -> "MainActivityRamadan"
            "iraq" -> "MainActivityIraq"
            else -> "MainActivity"
        }

        try {
            val pm = packageManager
            val pkg = packageName

            for (alias in aliases) {
                val componentName = ComponentName(pkg, "$pkg.$alias")
                val isTarget = alias == targetAlias
                val state = if (isTarget) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                }

                pm.setComponentEnabledSetting(
                    componentName,
                    state,
                    PackageManager.DONT_KILL_APP
                )
            }
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun getCurrentIcon(): String {
        try {
            val pm = packageManager
            val pkg = packageName

            for (alias in aliases) {
                val componentName = ComponentName(pkg, "$pkg.$alias")
                val state = pm.getComponentEnabledSetting(componentName)
                if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                    return when (alias) {
                        "MainActivityWinter" -> "winter"
                        "MainActivityNewYear" -> "newyear"
                        "MainActivityRamadan" -> "ramadan"
                        "MainActivityIraq" -> "iraq"
                        else -> "default"
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return "default"
    }
}

