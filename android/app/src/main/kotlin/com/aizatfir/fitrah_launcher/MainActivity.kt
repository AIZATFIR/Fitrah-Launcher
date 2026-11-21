package com.aizatfir.fitrah_launcher

import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import android.view.Gravity
import android.view.MotionEvent
import android.widget.TextView
import android.os.Handler
import android.os.Looper
import android.util.LruCache
import android.util.TypedValue
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fitrah_launcher/apps"
    private var homeChannel: MethodChannel? = null
    private var screenTimeView: TextView? = null
    private val screenTimeHandler = Handler(Looper.getMainLooper())
    private var screenTimeEnabled = false
    private var screenTimeTucked = false
    private var screenTimeOnLeft = false
    private var screenTimeLabel = ""
    private val screenTimeRefresh = object : Runnable {
        override fun run() {
            if (!screenTimeEnabled || !Settings.canDrawOverlays(this@MainActivity)) {
                removeScreenTimeCue()
                return
            }
            refreshScreenTimeCue()
            screenTimeHandler.postDelayed(this, 60_000L)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_HOME)) {
            homeChannel?.invokeMethod("home", null)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        homeChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // By default, never show over lockscreen unless explicitly requested by an active timer
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }
        window.clearFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
    }

    override fun onResume() {
        super.onResume()
        if (screenTimeEnabled) {
            if (!Settings.canDrawOverlays(this)) {
                removeScreenTimeCue()
            } else {
                refreshScreenTimeCue()
            }
        }
    }

    override fun onDestroy() {
        screenTimeHandler.removeCallbacks(screenTimeRefresh)
        removeScreenTimeCue()
        super.onDestroy()
    }

    private fun hasUsageAccess(): Boolean = try {
        val appOps = getSystemService(android.content.Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        mode == android.app.AppOpsManager.MODE_ALLOWED
    } catch (_: Exception) { false }

    private fun todayUsageMinutes(): Int? {
        if (!hasUsageAccess()) return null
        return try {
            val calendar = java.util.Calendar.getInstance()
            calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
            calendar.set(java.util.Calendar.MINUTE, 0)
            calendar.set(java.util.Calendar.SECOND, 0)
            calendar.set(java.util.Calendar.MILLISECOND, 0)
            val manager = getSystemService(android.content.Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
            val rows = manager.queryUsageStats(android.app.usage.UsageStatsManager.INTERVAL_DAILY, calendar.timeInMillis, System.currentTimeMillis())
            if (rows.isNullOrEmpty()) return null
            (rows.sumOf { it.totalTimeInForeground } / 60_000L).toInt()
        } catch (_: Exception) { null }
    }

    private fun refreshScreenTimeCue() {
        val view = screenTimeView ?: return
        val minutes = todayUsageMinutes()
        screenTimeLabel = if (minutes == null) "— mnt · Tujuan" else "${minutes} mnt · Tujuan"
        if (!screenTimeTucked) view.text = screenTimeLabel
        view.contentDescription = if (minutes == null) {
            "Data waktu layar tidak tersedia. Ketuk untuk kembali ke tujuan."
        } else {
            "Waktu layar hari ini: $minutes menit. Ketuk untuk kembali ke tujuan."
        }
        view.alpha = if (minutes == null) 0.82f else 1f
    }

    private fun removeScreenTimeCue() {
        screenTimeView?.let { view -> try { (getSystemService(WINDOW_SERVICE) as WindowManager).removeView(view) } catch (_: Exception) {} }
        screenTimeView = null
        screenTimeTucked = false
    }

    private fun syncScreenTimeCue(enabled: Boolean): Boolean {
        screenTimeEnabled = enabled
        screenTimeHandler.removeCallbacks(screenTimeRefresh)
        if (!enabled || !Settings.canDrawOverlays(this) || !hasUsageAccess()) {
            removeScreenTimeCue()
            return false
        }
        if (screenTimeView == null) {
            val view = TextView(this).apply {
                setTextSize(TypedValue.COMPLEX_UNIT_DIP, 11f)
                setTextColor(0xFFF5EEE0.toInt())
                gravity = Gravity.CENTER
                isFocusable = true
                setPadding(10, 6, 10, 6)
                background = GradientDrawable().apply {
                    setColor(0xEE23222B.toInt())
                    cornerRadius = 28f
                    setStroke(1, 0x88F0C987.toInt())
                }
                setOnClickListener {
                    if (screenTimeTucked) {
                        screenTimeTucked = false
                        text = screenTimeLabel
                        setPadding(14, 10, 14, 10)
                        val restored = (layoutParams as WindowManager.LayoutParams).apply {
                            width = WindowManager.LayoutParams.WRAP_CONTENT
                            x = 0
                        }
                        try { (getSystemService(WINDOW_SERVICE) as WindowManager).updateViewLayout(this, restored) } catch (_: Exception) {}
                        return@setOnClickListener
                    }
                    val intent = Intent(this@MainActivity, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    startActivity(intent)
                }
            }
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                android.graphics.PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.END
                x = (resources.displayMetrics.density * 8).toInt()
                // Keep the cue below the launcher header instead of covering its
                // clock/prayer action on devices with different screen densities.
                y = (resources.displayMetrics.density * 88).toInt()
            }
            var startY = 0
            var touchX = 0f
            var touchY = 0f
            var dragged = false
            view.setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        startY = params.y
                        touchX = event.rawX
                        touchY = event.rawY
                        dragged = false
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        if (kotlin.math.abs(event.rawX - touchX) > 12f || kotlin.math.abs(event.rawY - touchY) > 12f) dragged = true
                        val screenWidth = resources.displayMetrics.widthPixels
                        screenTimeOnLeft = event.rawX < screenWidth / 2f
                        params.gravity = Gravity.TOP or if (screenTimeOnLeft) Gravity.START else Gravity.END
                        params.x = if (screenTimeOnLeft) event.rawX.toInt() else (screenWidth - event.rawX).toInt()
                        params.y = (startY + (event.rawY - touchY).toInt()).coerceAtLeast(0)
                        try { (getSystemService(WINDOW_SERVICE) as WindowManager).updateViewLayout(view, params) } catch (_: Exception) {}
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!dragged) {
                            view.performClick()
                        } else {
                            screenTimeTucked = true
                            view.text = if (screenTimeOnLeft) "‹" else "›"
                            view.setPadding(0, 8, 0, 8)
                            params.width = (resources.displayMetrics.density * 44).toInt()
                            params.x = 8
                            try { (getSystemService(WINDOW_SERVICE) as WindowManager).updateViewLayout(view, params) } catch (_: Exception) {}
                        }
                        true
                    }
                    else -> false
                }
            }
            try {
                (getSystemService(WINDOW_SERVICE) as WindowManager).addView(view, params)
                screenTimeView = view
            } catch (_: Exception) { return false }
        }
        refreshScreenTimeCue()
        screenTimeHandler.postDelayed(screenTimeRefresh, 60_000L)
        return screenTimeView != null
    }

    // In-memory icon cache to prevent frame drops during list scrolling (1/8 max heap)
    private val iconCache = object : LruCache<String, ByteArray>((Runtime.getRuntime().maxMemory() / 1024 / 8).toInt()) {
        override fun sizeOf(key: String, value: ByteArray): Int {
            return value.size / 1024
        }
    }

    private fun resolvesDefaultHome(): Boolean {
        val home = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
        val resolved = packageManager.resolveActivity(home, PackageManager.MATCH_DEFAULT_ONLY)
        return resolved?.activityInfo?.packageName == packageName
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        homeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fitrah_launcher/home")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimerClockSnapshot" -> {
                    val bootCount = Settings.Global.getInt(
                        contentResolver,
                        Settings.Global.BOOT_COUNT,
                        -1
                    )
                    if (bootCount < 0) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "bootCount" to bootCount,
                                "elapsedRealtimeMillis" to android.os.SystemClock.elapsedRealtime()
                            )
                        )
                    }
                }
                "setLockscreenFocus" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    try {
                        if (enabled) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                                setShowWhenLocked(true)
                                setTurnScreenOn(true)
                            }
                            window.addFlags(
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            )
                        } else {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                                setShowWhenLocked(false)
                                setTurnScreenOn(false)
                            }
                            window.clearFlags(
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR_SETTING_LOCKSCREEN_FOCUS", e.message, null)
                    }
                }
                "getInstalledApps" -> {
                    try {
                        // A refreshed listing can follow reinstall or an icon update.
                        iconCache.evictAll()
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
                "getAppIcon" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        val cached = iconCache.get(pkg)
                        if (cached != null) {
                            result.success(cached)
                            return@setMethodCallHandler
                        }
                        try {
                            val drawable = packageManager.getApplicationIcon(pkg)
                            val bitmap = when (drawable) {
                                is BitmapDrawable -> drawable.bitmap
                                else -> {
                                    val w = drawable.intrinsicWidth.coerceAtLeast(72)
                                    val h = drawable.intrinsicHeight.coerceAtLeast(72)
                                    val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                                    val canvas = Canvas(bmp)
                                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                                    drawable.draw(canvas)
                                    bmp
                                }
                            }
                            val scaled = Bitmap.createScaledBitmap(bitmap, 96, 96, true)
                            val stream = ByteArrayOutputStream()
                            scaled.compress(Bitmap.CompressFormat.PNG, 100, stream)
                            val bytes = stream.toByteArray()
                            iconCache.put(pkg, bytes)
                            result.success(bytes)
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "expandNotificationsPanel" -> {
                    try {
                        val statusBarService = getSystemService("statusbar")
                        val statusBarManager = Class.forName("android.app.StatusBarManager")
                        val expandMethod = statusBarManager.getMethod("expandNotificationsPanel")
                        expandMethod.invoke(statusBarService)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
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
                "isDefaultHome" -> {
                    try {
                        val held = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roles = getSystemService(RoleManager::class.java)
                            if (roles != null && roles.isRoleAvailable(RoleManager.ROLE_HOME)) {
                                roles.isRoleHeld(RoleManager.ROLE_HOME)
                            } else {
                                resolvesDefaultHome()
                            }
                        } else {
                            resolvesDefaultHome()
                        }
                        result.success(held)
                    } catch (e: Exception) {
                        result.error("ERROR_READING_DEFAULT_HOME", e.message, null)
                    }
                }
                "requestDefaultHome" -> {
                    try {
                        var opened = false
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roles = getSystemService(RoleManager::class.java)
                            if (roles != null && roles.isRoleAvailable(RoleManager.ROLE_HOME)) {
                                try {
                                    startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_HOME), 1001)
                                    opened = true
                                } catch (_: Exception) {
                                    // Some devices expose the role but cannot open its request.
                                }
                            }
                        }
                        if (!opened) startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR_REQUESTING_DEFAULT_HOME", e.message, null)
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
                "openNotificationListenerSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
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
                            result.error("ERROR_OPENING_NOTIF_SETTINGS", e2.message, null)
                        }
                    }
                }
                "launchClock" -> {
                    try {
                        val intent = Intent(android.provider.AlarmClock.ACTION_SHOW_ALARMS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val fallback = Intent(android.provider.AlarmClock.ACTION_SET_TIMER).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(fallback)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR_LAUNCHING_CLOCK", e.message, null)
                        }
                    }
                }
                "launchCalendar" -> {
                    try {
                        val intent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_APP_CALENDAR)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val builder = android.net.Uri.parse("content://com.android.calendar/time/").buildUpon()
                            android.content.ContentUris.appendId(builder, System.currentTimeMillis())
                            val fallback = Intent(Intent.ACTION_VIEW).apply {
                                data = builder.build()
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(fallback)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR_LAUNCHING_CALENDAR", e.message, null)
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
                    result.success(hasUsageAccess())
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
                "checkOverlayPermission" -> result.success(Settings.canDrawOverlays(this))
                "openOverlaySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR_OPENING_OVERLAY_SETTINGS", e.message, null)
                    }
                }
                "getTodayScreenTimeMinutes" -> result.success(todayUsageMinutes())
                "syncScreenTimeCue" -> {
                    result.success(syncScreenTimeCue(call.argument<Boolean>("enabled") ?: false))
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
