package com.aizatfir.focus_clock

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fitrah_launcher/apps"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable Show when locked and Turn screen on for lockscreen focus mode
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val resolvedInfos = pm.queryIntentActivities(mainIntent, 0)
                        val appsList = ArrayList<Map<String, Any>>()

                        for (info in resolvedInfos) {
                            val pkg = info.activityInfo.packageName
                            if (pkg == packageName) continue // Skip self

                            val label = info.loadLabel(pm).toString()
                            val isSystem = (info.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                            val appMap = HashMap<String, Any>()
                            appMap["appName"] = label
                            appMap["packageName"] = pkg
                            appMap["isSystem"] = isSystem
                            appsList.add(appMap)
                        }

                        // Sort alphabetically case-insensitively
                        appsList.sortBy { (it["appName"] as String).lowercase() }
                        result.success(appsList)
                    } catch (e: Exception) {
                        result.error("ERROR_GETTING_APPS", e.message, null)
                    }
                }
                "launchApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        try {
                            val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                            if (launchIntent != null) {
                                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(launchIntent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR_LAUNCHING_APP", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "openAppDetails" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", pkg, null)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR_OPENING_SETTINGS", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "openHomeSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_HOME_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val fallbackIntent = Intent(Settings.ACTION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(fallbackIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR_OPENING_HOME_SETTINGS", e2.message, null)
                        }
                    }
                }
                "launchDialer" -> {
                    try {
                        val intent = Intent(Intent.ACTION_DIAL).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR_LAUNCHING_DIALER", e.message, null)
                    }
                }
                "launchCamera" -> {
                    try {
                        val intent = Intent(android.provider.MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val fallbackIntent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(fallbackIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR_LAUNCHING_CAMERA", e2.message, null)
                        }
                    }
                }
                "uninstallApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        try {
                            val intent = Intent(Intent.ACTION_DELETE).apply {
                                data = Uri.fromParts("package", pkg, null)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR_UNINSTALLING_APP", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "checkUsageStatsPermission" -> {
                    try {
                        val appOps = getSystemService(android.content.Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            appOps.unsafeCheckOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
                        } else {
                            appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
                        }
                        result.success(mode == android.app.AppOpsManager.MODE_ALLOWED)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openUsageStatsSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR_OPENING_USAGE_SETTINGS", e.message, null)
                    }
                }
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "openOverlaySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR_OPENING_OVERLAY_SETTINGS", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "getForegroundApp" -> {
                    try {
                        val usm = getSystemService(android.content.Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
                        val time = System.currentTimeMillis()
                        val appList = usm.queryUsageStats(android.app.usage.UsageStatsManager.INTERVAL_DAILY, time - 1000 * 10, time)
                        var foreground = ""
                        if (appList != null && appList.isNotEmpty()) {
                            val sortedMap = java.util.TreeMap<Long, android.app.usage.UsageStats>()
                            for (usageStats in appList) {
                                sortedMap[usageStats.lastTimeUsed] = usageStats
                            }
                            if (sortedMap.isNotEmpty()) {
                                foreground = sortedMap[sortedMap.lastKey()]?.packageName ?: ""
                            }
                        }
                        result.success(foreground)
                    } catch (e: Exception) {
                        result.success("")
                    }
                }
                "bringAppToFront" -> {
                    try {
                        val intent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR_BRINGING_TO_FRONT", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
