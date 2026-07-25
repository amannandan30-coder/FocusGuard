package com.focusguard.app

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingIconPickerResult: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_ICON_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data?.data != null) {
                try {
                    val uri = data.data!!
                    val inputStream = contentResolver.openInputStream(uri)
                    val bitmap = android.graphics.BitmapFactory.decodeStream(inputStream)
                    inputStream?.close()

                    if (bitmap != null) {
                        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 128, 128, true)
                        val stream = ByteArrayOutputStream()
                        scaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                        val byteArray = stream.toByteArray()
                        pendingIconPickerResult?.success(byteArray)
                    } else {
                        pendingIconPickerResult?.error("IMAGE_DECODE_FAILED", "Failed to decode image", null)
                    }
                } catch (e: Exception) {
                    pendingIconPickerResult?.error("PICK_ICON_ERROR", e.localizedMessage, null)
                }
            } else {
                pendingIconPickerResult?.success(null)
            }
            pendingIconPickerResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel 1: App Selection
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_SELECTION_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "getSupportedInstalledApps" -> {
                        executor.execute {
                            try {
                                val apps = getSupportedInstalledApps()
                                mainHandler.post { result.success(apps) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("APP_QUERY_ERROR", e.localizedMessage, null) }
                            }
                        }
                    }
                    "getSelectedApps" -> result.success(loadSelectedApps())
                    "saveSelectedApps" -> {
                        val packageIds = (call.arguments as? List<*>)
                            ?.filterIsInstance<String>()
                            ?.toSet()
                            ?: emptySet()
                        getSharedPreferences(PREFERENCES, MODE_PRIVATE)
                            .edit()
                            .putStringSet(SELECTED_APPS_KEY, packageIds)
                            .commit()
                        result.success(null)
                    }
                    "changeAppIconAndName" -> {
                        val aliasName = call.argument<String>("aliasName") ?: "DefaultAlias"
                        val success = changeAppIconAndName(aliasName)
                        result.success(success)
                    }
                    "getActiveAppDisguise" -> {
                        result.success(getActiveAppDisguise())
                    }
                    "pickCustomIconImage" -> {
                        pendingIconPickerResult = result
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                        }
                        startActivityForResult(intent, PICK_ICON_REQUEST_CODE)
                    }
                    else -> result.notImplemented()
                }
            }

        // Channel 2: Real-time Device Usage Stats
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_STATS_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "hasUsagePermission" -> result.success(hasUsagePermission())
                    "requestUsagePermission" -> {
                        requestUsagePermission()
                        result.success(true)
                    }
                    "getTodayUsageStats" -> {
                        val dailyLimit = (call.argument<Int>("dailyLimitMinutes")) ?: 180
                        executor.execute {
                            try {
                                val stats = getTodayUsageStats(dailyLimit)
                                mainHandler.post { result.success(stats) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("USAGE_STATS_ERROR", e.localizedMessage, null) }
                            }
                        }
                    }
                    "getRangeUsageStats" -> {
                        val range = (call.argument<String>("range")) ?: "daily"
                        executor.execute {
                            try {
                                val stats = getRangeUsageStats(range)
                                mainHandler.post { result.success(stats) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("USAGE_STATS_ERROR", e.localizedMessage, null) }
                            }
                        }
                    }
                    "getDayUsageStats" -> {
                        val dayStartMs = call.argument<Long>("dayStartMs") ?: System.currentTimeMillis()
                        executor.execute {
                            try {
                                val stats = getDayUsageStats(dayStartMs)
                                mainHandler.post { result.success(stats) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("USAGE_STATS_ERROR", e.localizedMessage, null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Channel 3: Content Blocker & Accessibility Service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "isAccessibilityGranted" -> result.success(isAccessibilityGranted())
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    "getBlockerConfig" -> result.success(getBlockerConfig())
                    "saveBlockerConfig" -> {
                        val blockShorts = call.argument<Boolean>("blockYouTubeShorts") ?: true
                        val blockReels = call.argument<Boolean>("blockInstagramReels") ?: true
                        val action = call.argument<String>("blockingAction") ?: "go_back"

                        getSharedPreferences(PREFERENCES, MODE_PRIVATE)
                            .edit()
                            .putBoolean("block_youtube_shorts", blockShorts)
                            .putBoolean("block_instagram_reels", blockReels)
                            .putString("blocking_action", action)
                            .apply()

                        result.success(true)
                    }
                    "setFocusSessionActive" -> {
                        val active = call.argument<Boolean>("active") ?: false
                        getSharedPreferences(PREFERENCES, MODE_PRIVATE)
                            .edit()
                            .putBoolean("focus_session_active", active)
                            .commit()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Channel 4: Security & Biometrics
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "isBiometricAvailable" -> result.success(isBiometricAvailable())
                    "authenticateBiometric" -> authenticateBiometricNative(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun isBiometricAvailable(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val biometricManager = getSystemService(Context.BIOMETRIC_SERVICE) as? android.hardware.biometrics.BiometricManager
            if (biometricManager != null) {
                val res = biometricManager.canAuthenticate()
                if (res == android.hardware.biometrics.BiometricManager.BIOMETRIC_SUCCESS ||
                    res == android.hardware.biometrics.BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED) {
                    return true
                }
            }
        }
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? android.app.KeyguardManager
        val hasFingerprintHardware = packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_FINGERPRINT)
        return keyguardManager?.isKeyguardSecure == true || hasFingerprintHardware
    }

    private fun authenticateBiometricNative(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                val biometricPrompt = android.hardware.biometrics.BiometricPrompt.Builder(this)
                    .setTitle("Unlock FocusGuard")
                    .setSubtitle("Authenticate fingerprint or face to access app")
                    .setNegativeButton("Use PIN", mainExecutor) { _, _ ->
                        result.success(false)
                    }
                    .build()

                val cancellationSignal = android.os.CancellationSignal()
                biometricPrompt.authenticate(
                    cancellationSignal,
                    mainExecutor,
                    object : android.hardware.biometrics.BiometricPrompt.AuthenticationCallback() {
                        override fun onAuthenticationSucceeded(authResult: android.hardware.biometrics.BiometricPrompt.AuthenticationResult?) {
                            super.onAuthenticationSucceeded(authResult)
                            result.success(true)
                        }

                        override fun onAuthenticationError(errorCode: Int, errString: CharSequence?) {
                            super.onAuthenticationError(errorCode, errString)
                            result.success(false)
                        }
                    }
                )
            } catch (e: Exception) {
                result.success(false)
            }
        } else {
            result.success(false)
        }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsagePermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun getTodayUsageStats(dailyLimitMinutes: Int = 180): Map<String, Any> {
        if (!hasUsagePermission()) {
            return mapOf(
                "hasPermission" to false,
                "totalScreenTimeMinutes" to 0,
                "totalScreenTimeMs" to 0L,
                "weeklyDailyMinutes" to listOf(0, 0, 0, 0, 0, 0, 0),
                "currentStreak" to 0,
                "longestStreak" to 0,
                "weeklyStreak" to 0,
                "monthlyStreak" to 0,
                "productivityScore" to 85,
                "unlockCount" to 0,
                "appsControlledCount" to loadSelectedApps().size,
                "timeSavedMinutes" to 0,
                "appsUsage" to emptyList<Map<String, Any>>()
            )
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        val maxElapsedMs = Math.max(0L, endTime - startTime)

        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = packageManager.queryIntentActivities(launcherIntent, 0)
        val launchablePackages = resolveInfos.mapNotNull { it.activityInfo?.packageName }.toSet()

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        val appTimeMap = mutableMapOf<String, Long>()
        val appResumeMap = mutableMapOf<String, Long>()
        val appLastUsedMap = mutableMapOf<String, Long>()
        val appSessionMap = mutableMapOf<String, Int>()
        var unlockCount = 0
        var lastUnlockTimeStamp = 0L
        var isKeyguardLocked = true

        var currentForegroundPkg: String? = null
        var currentForegroundStartTime: Long = 0L
        var lastResumedPkg: String? = null
        var lastResumedTime: Long = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val eventType = event.eventType
            val timeStamp = event.timeStamp

            // Lock events: KEYGUARD_SHOWN (15) or SCREEN_NON_INTERACTIVE (26)
            if (eventType == 15 || eventType == 26 || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && eventType == UsageEvents.Event.KEYGUARD_SHOWN)) {
                isKeyguardLocked = true
                if (currentForegroundPkg != null) {
                    val duration = timeStamp - currentForegroundStartTime
                    if (duration > 0 && duration < 24 * 3600 * 1000L) {
                        appTimeMap[currentForegroundPkg!!] = (appTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                    }
                    currentForegroundPkg = null
                }
            }
            // Unlock events: KEYGUARD_HIDDEN (16) or KEYGUARD_GOING_AWAY (17)
            else if (eventType == 16 || eventType == 17 || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && eventType == UsageEvents.Event.KEYGUARD_HIDDEN)) {
                if (isKeyguardLocked && (timeStamp - lastUnlockTimeStamp > 2000L)) {
                    unlockCount++
                    lastUnlockTimeStamp = timeStamp
                    isKeyguardLocked = false
                }
            }

            val pkg = event.packageName ?: continue

            if (eventType == UsageEvents.Event.ACTIVITY_RESUMED || eventType == 1) {
                if (pkg != currentForegroundPkg) {
                    if (currentForegroundPkg != null) {
                        val duration = timeStamp - currentForegroundStartTime
                        if (duration > 0 && duration < 24 * 3600 * 1000L) {
                            appTimeMap[currentForegroundPkg!!] = (appTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                        }
                    }

                    if (pkg != lastResumedPkg || (timeStamp - lastResumedTime > 120000L)) {
                        appSessionMap[pkg] = (appSessionMap[pkg] ?: 0) + 1
                        lastResumedPkg = pkg
                        lastResumedTime = timeStamp
                    }

                    currentForegroundPkg = pkg
                    currentForegroundStartTime = Math.max(startTime, timeStamp)
                }
                appLastUsedMap[pkg] = timeStamp
            } else if (eventType == UsageEvents.Event.ACTIVITY_PAUSED || eventType == 2) {
                if (pkg == currentForegroundPkg) {
                    val duration = timeStamp - currentForegroundStartTime
                    if (duration > 0 && duration < 24 * 3600 * 1000L) {
                        appTimeMap[pkg] = (appTimeMap[pkg] ?: 0L) + duration
                    }
                    currentForegroundPkg = null
                }
                appLastUsedMap[pkg] = timeStamp
            }
        }

        if (currentForegroundPkg != null) {
            val duration = endTime - currentForegroundStartTime
            if (duration > 0 && duration < 24 * 3600 * 1000L) {
                appTimeMap[currentForegroundPkg!!] = (appTimeMap[currentForegroundPkg!!] ?: 0L) + duration
            }
        }

        var totalForegroundTimeMs = 0L
        val appUsageList = mutableListOf<Map<String, Any>>()

        for ((pkgName, rawDuration) in appTimeMap) {
            val durationMs = Math.min(rawDuration, maxElapsedMs)
            if (durationMs > 0) {
                val isLaunchable = launchablePackages.contains(pkgName) || pkgName == packageName

                if (isLaunchable) {
                    totalForegroundTimeMs += durationMs

                    val appLabel = try {
                        val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                        packageManager.getApplicationLabel(appInfo).toString()
                    } catch (_: Exception) {
                        pkgName
                    }

                    val iconDrawable = try {
                        val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                        appInfo.loadIcon(packageManager)
                    } catch (_: Exception) {
                        null
                    }
                    val iconBytes = iconDrawable?.let { drawableToPng(it) }

                    val appMap = mutableMapOf<String, Any>(
                        "packageName" to pkgName,
                        "appName" to appLabel,
                        "totalTimeInForegroundMs" to durationMs,
                        "totalTimeInForegroundMinutes" to (durationMs / 60000).toInt(),
                        "sessionCount" to (appSessionMap[pkgName] ?: 1),
                        "lastTimeUsed" to (appLastUsedMap[pkgName] ?: 0L)
                    )
                    if (iconBytes != null) {
                        appMap["icon"] = iconBytes
                    }
                    appUsageList.add(appMap)
                }
            }
        }

        val finalTotalScreenTimeMs = Math.min(totalForegroundTimeMs, maxElapsedMs)
        val totalMinutes = (finalTotalScreenTimeMs / 60000).toInt()

        val weeklyDailyMinutes = getRealWeeklyDailyMinutes(usageStatsManager, launchablePackages)
        val streakData = calculateRealStreak(usageStatsManager, launchablePackages, dailyLimitMinutes)
        val currentStreak = streakData["currentStreak"] ?: 0

        val productivityScore = calculateProductivityScore(totalMinutes, dailyLimitMinutes, currentStreak)
        val controlledAppsCount = loadSelectedApps().size
        val timeSavedMinutes = Math.max(0, dailyLimitMinutes - totalMinutes)

        return mapOf(
            "hasPermission" to true,
            "totalScreenTimeMinutes" to totalMinutes,
            "totalScreenTimeMs" to finalTotalScreenTimeMs,
            "weeklyDailyMinutes" to weeklyDailyMinutes,
            "currentStreak" to currentStreak,
            "longestStreak" to (streakData["longestStreak"] ?: 0),
            "weeklyStreak" to (streakData["weeklyStreak"] ?: 0),
            "monthlyStreak" to (streakData["monthlyStreak"] ?: 0),
            "productivityScore" to productivityScore,
            "unlockCount" to unlockCount,
            "appsControlledCount" to controlledAppsCount,
            "timeSavedMinutes" to timeSavedMinutes,
            "appsUsage" to appUsageList.sortedByDescending { (it["totalTimeInForegroundMs"] as Long) }
        )
    }

    private fun getRangeUsageStats(range: String): Map<String, Any> {
        if (!hasUsagePermission()) {
            return mapOf(
                "hasPermission" to false,
                "range" to range,
                "totalScreenTimeMinutes" to 0,
                "totalSessionsCount" to 0,
                "appsUsage" to emptyList<Map<String, Any>>()
            )
        }

        val now = System.currentTimeMillis()
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val daysToAggregate = mutableListOf<Long>()

        when (range.lowercase()) {
            "weekly" -> {
                val todayCal = Calendar.getInstance()
                val currentWeekday = todayCal.get(Calendar.DAY_OF_WEEK) // 1=Sun, 2=Mon...
                val daysSinceMonday = if (currentWeekday == Calendar.SUNDAY) 6 else currentWeekday - Calendar.MONDAY

                calendar.firstDayOfWeek = Calendar.MONDAY
                calendar.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
                if (calendar.timeInMillis > now) {
                    calendar.add(Calendar.DAY_OF_YEAR, -7)
                }

                for (i in 0..daysSinceMonday) {
                    val dayStart = calendar.timeInMillis + (i * 24 * 3600 * 1000L)
                    if (dayStart <= now) {
                        daysToAggregate.add(dayStart)
                    }
                }
            }
            "monthly" -> {
                val todayCal = Calendar.getInstance()
                val dayOfMonth = todayCal.get(Calendar.DAY_OF_MONTH)

                calendar.set(Calendar.DAY_OF_MONTH, 1)

                for (i in 0 until dayOfMonth) {
                    val dayStart = calendar.timeInMillis + (i * 24 * 3600 * 1000L)
                    if (dayStart <= now) {
                        daysToAggregate.add(dayStart)
                    }
                }
            }
            else -> {
                return getDayUsageStats(calendar.timeInMillis)
            }
        }

        val aggregatedAppTimeMap = mutableMapOf<String, Long>()
        val aggregatedAppLastUsedMap = mutableMapOf<String, Long>()
        val aggregatedAppSessionMap = mutableMapOf<String, Int>()
        var aggregatedTotalMinutes = 0
        var aggregatedTotalSessions = 0

        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = packageManager.queryIntentActivities(launcherIntent, 0)
        val launchablePackages = resolveInfos.mapNotNull { it.activityInfo?.packageName }.toSet()

        for (dayStartMs in daysToAggregate) {
            val dayStats = getDayUsageStats(dayStartMs)
            if (dayStats["hasPermission"] == true) {
                val dayMinutes = (dayStats["totalScreenTimeMinutes"] as? Int) ?: 0
                val daySessions = (dayStats["totalSessionsCount"] as? Int) ?: 0

                aggregatedTotalMinutes += dayMinutes
                aggregatedTotalSessions += daySessions

                val appsList = (dayStats["appsUsage"] as? List<*>)?.filterIsInstance<Map<String, Any>>() ?: emptyList()
                for (appMap in appsList) {
                    val pkg = appMap["packageName"] as? String ?: continue
                    val durationMs = (appMap["totalTimeInForegroundMs"] as? Long) ?: 0L
                    val sessions = (appMap["sessionCount"] as? Int) ?: 0
                    val lastUsed = (appMap["lastTimeUsed"] as? Long) ?: 0L

                    aggregatedAppTimeMap[pkg] = (aggregatedAppTimeMap[pkg] ?: 0L) + durationMs
                    aggregatedAppSessionMap[pkg] = (aggregatedAppSessionMap[pkg] ?: 0) + sessions
                    if (lastUsed > (aggregatedAppLastUsedMap[pkg] ?: 0L)) {
                        aggregatedAppLastUsedMap[pkg] = lastUsed
                    }
                }
            }
        }

        val appUsageList = mutableListOf<Map<String, Any>>()
        for ((pkgName, durationMs) in aggregatedAppTimeMap) {
            if (durationMs > 0 && (launchablePackages.contains(pkgName) || pkgName == packageName)) {
                val appLabel = try {
                    val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                    packageManager.getApplicationLabel(appInfo).toString()
                } catch (_: Exception) {
                    pkgName
                }

                val iconDrawable = try {
                    val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                    appInfo.loadIcon(packageManager)
                } catch (_: Exception) {
                    null
                }
                val iconBytes = iconDrawable?.let { drawableToPng(it) }

                val appMap = mutableMapOf<String, Any>(
                    "packageName" to pkgName,
                    "appName" to appLabel,
                    "totalTimeInForegroundMs" to durationMs,
                    "totalTimeInForegroundMinutes" to (durationMs / 60000).toInt(),
                    "sessionCount" to (aggregatedAppSessionMap[pkgName] ?: 1),
                    "lastTimeUsed" to (aggregatedAppLastUsedMap[pkgName] ?: 0L)
                )
                if (iconBytes != null) {
                    appMap["icon"] = iconBytes
                }
                appUsageList.add(appMap)
            }
        }

        return mapOf(
            "hasPermission" to true,
            "range" to range,
            "totalScreenTimeMinutes" to aggregatedTotalMinutes,
            "totalSessionsCount" to aggregatedTotalSessions,
            "appsUsage" to appUsageList.sortedByDescending { (it["totalTimeInForegroundMs"] as Long) }
        )
    }

    private fun getDayUsageStats(dayStartMs: Long): Map<String, Any> {
        if (!hasUsagePermission()) {
            return mapOf(
                "hasPermission" to false,
                "dayStartMs" to dayStartMs,
                "totalScreenTimeMinutes" to 0,
                "totalSessionsCount" to 0,
                "appsUsage" to emptyList<Map<String, Any>>()
            )
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val calendar = Calendar.getInstance().apply {
            timeInMillis = dayStartMs
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val startTime = calendar.timeInMillis
        val now = System.currentTimeMillis()

        if (startTime > now) {
            return mapOf(
                "hasPermission" to true,
                "dayStartMs" to dayStartMs,
                "totalScreenTimeMinutes" to 0,
                "totalSessionsCount" to 0,
                "appsUsage" to emptyList<Map<String, Any>>()
            )
        }

        val dayEnd = Math.min(now, startTime + 24 * 3600 * 1000L)
        val maxElapsedMs = Math.max(0L, dayEnd - startTime)

        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = packageManager.queryIntentActivities(launcherIntent, 0)
        val launchablePackages = resolveInfos.mapNotNull { it.activityInfo?.packageName }.toSet()

        val appTimeMap = mutableMapOf<String, Long>()
        val appResumeMap = mutableMapOf<String, Long>()
        val appLastUsedMap = mutableMapOf<String, Long>()
        val appSessionMap = mutableMapOf<String, Int>()

        var lastResumedPkg: String? = null
        var lastResumedTime: Long = 0L

        var currentForegroundPkg: String? = null
        var currentForegroundStartTime: Long = 0L

        try {
            val events = usageStatsManager.queryEvents(startTime, dayEnd)
            val event = UsageEvents.Event()

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val eventType = event.eventType
                val timeStamp = event.timeStamp

                if (eventType == 15 || eventType == 26 || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && eventType == UsageEvents.Event.KEYGUARD_SHOWN)) {
                    if (currentForegroundPkg != null) {
                        val duration = timeStamp - currentForegroundStartTime
                        if (duration > 0 && duration < 24 * 3600 * 1000L) {
                            appTimeMap[currentForegroundPkg!!] = (appTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                        }
                        currentForegroundPkg = null
                    }
                }

                val pkg = event.packageName ?: continue

                if (eventType == UsageEvents.Event.ACTIVITY_RESUMED || eventType == 1) {
                    if (pkg != currentForegroundPkg) {
                        if (currentForegroundPkg != null) {
                            val duration = timeStamp - currentForegroundStartTime
                            if (duration > 0 && duration < 24 * 3600 * 1000L) {
                                appTimeMap[currentForegroundPkg!!] = (appTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                            }
                        }

                        if (pkg != lastResumedPkg || (timeStamp - lastResumedTime > 120000L)) {
                            appSessionMap[pkg] = (appSessionMap[pkg] ?: 0) + 1
                            lastResumedPkg = pkg
                            lastResumedTime = timeStamp
                        }

                        currentForegroundPkg = pkg
                        currentForegroundStartTime = Math.max(startTime, timeStamp)
                    }
                    appLastUsedMap[pkg] = timeStamp
                } else if (eventType == UsageEvents.Event.ACTIVITY_PAUSED || eventType == 2) {
                    if (pkg == currentForegroundPkg) {
                        val duration = timeStamp - currentForegroundStartTime
                        if (duration > 0 && duration < 24 * 3600 * 1000L) {
                            appTimeMap[pkg] = (appTimeMap[pkg] ?: 0L) + duration
                        }
                        currentForegroundPkg = null
                    }
                    appLastUsedMap[pkg] = timeStamp
                }
            }

            if (currentForegroundPkg != null) {
                val duration = dayEnd - currentForegroundStartTime
                if (duration > 0 && duration < 24 * 3600 * 1000L) {
                    appTimeMap[currentForegroundPkg!!] = (appTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                }
            }
        } catch (_: Exception) {}

        var totalForegroundTimeMs = 0L
        var totalSessions = 0
        val appUsageList = mutableListOf<Map<String, Any>>()

        for ((pkgName, rawDuration) in appTimeMap) {
            val durationMs = Math.min(rawDuration, maxElapsedMs)
            if (durationMs > 0) {
                val isLaunchable = launchablePackages.contains(pkgName) || pkgName == packageName

                if (isLaunchable) {
                    totalForegroundTimeMs += durationMs
                    val sessions = appSessionMap[pkgName] ?: 1
                    totalSessions += sessions

                    val appLabel = try {
                        val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                        packageManager.getApplicationLabel(appInfo).toString()
                    } catch (_: Exception) {
                        pkgName
                    }

                    val iconDrawable = try {
                        val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                        appInfo.loadIcon(packageManager)
                    } catch (_: Exception) {
                        null
                    }
                    val iconBytes = iconDrawable?.let { drawableToPng(it) }

                    val appMap = mutableMapOf<String, Any>(
                        "packageName" to pkgName,
                        "appName" to appLabel,
                        "totalTimeInForegroundMs" to durationMs,
                        "totalTimeInForegroundMinutes" to (durationMs / 60000).toInt(),
                        "sessionCount" to sessions,
                        "lastTimeUsed" to (appLastUsedMap[pkgName] ?: 0L)
                    )
                    if (iconBytes != null) {
                        appMap["icon"] = iconBytes
                    }
                    appUsageList.add(appMap)
                }
            }
        }

        val finalTotalMs = Math.min(totalForegroundTimeMs, maxElapsedMs)
        val totalMinutes = (finalTotalMs / 60000).toInt()

        return mapOf(
            "hasPermission" to true,
            "dayStartMs" to dayStartMs,
            "totalScreenTimeMinutes" to totalMinutes,
            "totalSessionsCount" to totalSessions,
            "appsUsage" to appUsageList.sortedByDescending { (it["totalTimeInForegroundMs"] as Long) }
        )
    }

    private fun calculateProductivityScore(
        todayMinutes: Int,
        dailyLimitMinutes: Int,
        currentStreak: Int
    ): Int {
        val limit = Math.max(1, dailyLimitMinutes)

        val goalScore = if (todayMinutes <= limit) {
            val ratio = todayMinutes.toDouble() / limit
            if (ratio <= 0.5) {
                (60 - ratio * 20).toInt().coerceIn(50, 60)
            } else {
                (50 - (ratio - 0.5) * 20).toInt().coerceIn(40, 50)
            }
        } else {
            val overuseRatio = (todayMinutes - limit).toDouble() / limit
            if (overuseRatio <= 0.25) {
                (40 - (overuseRatio / 0.25) * 25).toInt().coerceIn(15, 40)
            } else {
                (15 - ((overuseRatio - 0.25) / 0.75) * 15).toInt().coerceIn(0, 15)
            }
        }

        val streakScore = when {
            currentStreak == 0 -> 0
            currentStreak == 1 -> 8
            currentStreak == 2 -> 14
            currentStreak == 3 -> 18
            else -> 25
        }

        val balanceScore = 12

        val total = goalScore + streakScore + balanceScore
        return total.coerceIn(5, 100)
    }

    private fun calculateRealStreak(
        usageStatsManager: UsageStatsManager,
        launchablePackages: Set<String>,
        dailyLimitMinutes: Int = 180
    ): Map<String, Int> {
        val now = System.currentTimeMillis()

        val calMon = Calendar.getInstance().apply {
            firstDayOfWeek = Calendar.MONDAY
            set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val mondayStart = calMon.timeInMillis
        val daysInCurrentWeek = Math.max(1, ((now - mondayStart) / (24 * 3600 * 1000L)).toInt() + 1)

        val calMonth = Calendar.getInstance().apply {
            set(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val monthStart = calMonth.timeInMillis
        val daysInCurrentMonth = Math.max(1, ((now - monthStart) / (24 * 3600 * 1000L)).toInt() + 1)

        val todayCal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        class DayStat(val minutes: Int, val hasRecordedActivity: Boolean)

        val past30DaysStats = mutableListOf<DayStat>()
        for (i in 0..29) {
            val dayStart = todayCal.timeInMillis - (i * 24 * 3600 * 1000L)
            val dayEnd = Math.min(dayStart + 24 * 3600 * 1000L, now)
            val maxDuration = Math.max(0L, dayEnd - dayStart)

            if (dayStart > now) continue

            val events = usageStatsManager.queryEvents(dayStart, dayEnd)
            val event = UsageEvents.Event()
            val dayAppTimeMap = mutableMapOf<String, Long>()
            val dayAppResumeMap = mutableMapOf<String, Long>()
            var totalEventsCount = 0

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                totalEventsCount++
                val pkg = event.packageName ?: continue
                val eventType = event.eventType
                val timeStamp = event.timeStamp

                if (eventType == UsageEvents.Event.ACTIVITY_RESUMED || eventType == 1) {
                    dayAppResumeMap[pkg] = timeStamp
                } else if (eventType == UsageEvents.Event.ACTIVITY_PAUSED || eventType == 2) {
                    val resumeTime = dayAppResumeMap[pkg]
                    if (resumeTime != null && resumeTime >= dayStart) {
                        val duration = timeStamp - resumeTime
                        if (duration > 0 && duration < 24 * 3600 * 1000L) {
                            dayAppTimeMap[pkg] = (dayAppTimeMap[pkg] ?: 0L) + duration
                        }
                        dayAppResumeMap.remove(pkg)
                    }
                }
            }

            for ((pkg, resumeTime) in dayAppResumeMap) {
                if (resumeTime >= dayStart) {
                    val duration = dayEnd - resumeTime
                    if (duration > 0 && duration < 24 * 3600 * 1000L) {
                        dayAppTimeMap[pkg] = (dayAppTimeMap[pkg] ?: 0L) + duration
                    }
                }
            }

            var dayTotalMs = 0L
            for ((pkg, duration) in dayAppTimeMap) {
                if (launchablePackages.contains(pkg) || pkg == packageName) {
                    dayTotalMs += Math.min(duration, maxDuration)
                }
            }

            val dayMinutes = (Math.min(dayTotalMs, maxDuration) / 60000).toInt()
            val hasRecorded = totalEventsCount > 0 || dayMinutes > 0
            past30DaysStats.add(DayStat(dayMinutes, hasRecorded))
        }

        var currentStreak = 0
        var streakBroken = false
        for (i in past30DaysStats.indices) {
            val stat = past30DaysStats[i]
            val isToday = (i == 0)
            val isValidStreakDay = (isToday || stat.hasRecordedActivity) && stat.minutes <= dailyLimitMinutes

            if (isValidStreakDay && !streakBroken) {
                currentStreak++
            } else {
                streakBroken = true
            }
        }

        var longestStreak = 0
        var tempStreak = 0
        for (i in past30DaysStats.indices.reversed()) {
            val stat = past30DaysStats[i]
            val isToday = (i == 0)
            val isValidStreakDay = (isToday || stat.hasRecordedActivity) && stat.minutes <= dailyLimitMinutes

            if (isValidStreakDay) {
                tempStreak++
                if (tempStreak > longestStreak) {
                    longestStreak = tempStreak
                }
            } else {
                tempStreak = 0
            }
        }

        var weeklyStreakCount = 0
        val weekBound = Math.min(daysInCurrentWeek, past30DaysStats.size)
        for (i in 0 until weekBound) {
            val stat = past30DaysStats[i]
            val isToday = (i == 0)
            val isValidStreakDay = (isToday || stat.hasRecordedActivity) && stat.minutes <= dailyLimitMinutes
            if (isValidStreakDay) {
                weeklyStreakCount++
            }
        }

        var monthlyStreakCount = 0
        val monthBound = Math.min(daysInCurrentMonth, past30DaysStats.size)
        for (i in 0 until monthBound) {
            val stat = past30DaysStats[i]
            val isToday = (i == 0)
            val isValidStreakDay = (isToday || stat.hasRecordedActivity) && stat.minutes <= dailyLimitMinutes
            if (isValidStreakDay) {
                monthlyStreakCount++
            }
        }

        return mapOf(
            "currentStreak" to currentStreak,
            "longestStreak" to Math.max(longestStreak, currentStreak),
            "weeklyStreak" to weeklyStreakCount,
            "monthlyStreak" to monthlyStreakCount
        )
    }

    private fun getRealWeeklyDailyMinutes(
        usageStatsManager: UsageStatsManager,
        launchablePackages: Set<String>
    ): List<Int> {
        val result = mutableListOf<Int>()
        val cal = Calendar.getInstance().apply {
            firstDayOfWeek = Calendar.MONDAY
            set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val now = System.currentTimeMillis()

        for (day in 0..6) {
            val dayStart = cal.timeInMillis
            cal.add(Calendar.DAY_OF_MONTH, 1)
            val dayEnd = cal.timeInMillis

            if (dayStart > now) {
                result.add(0)
                continue
            }

            val actualEnd = Math.min(dayEnd, now)
            val maxDuration = Math.max(0L, actualEnd - dayStart)

            val events = usageStatsManager.queryEvents(dayStart, actualEnd)
            val event = UsageEvents.Event()

            val dayAppTimeMap = mutableMapOf<String, Long>()

            var currentForegroundPkg: String? = null
            var currentForegroundStartTime: Long = 0L

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val eventType = event.eventType
                val timeStamp = event.timeStamp

                if (eventType == 15 || eventType == 26 || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && eventType == UsageEvents.Event.KEYGUARD_SHOWN)) {
                    if (currentForegroundPkg != null) {
                        val duration = timeStamp - currentForegroundStartTime
                        if (duration > 0 && duration < 24 * 3600 * 1000L) {
                            dayAppTimeMap[currentForegroundPkg!!] = (dayAppTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                        }
                        currentForegroundPkg = null
                    }
                }

                val pkg = event.packageName ?: continue

                if (eventType == UsageEvents.Event.ACTIVITY_RESUMED || eventType == 1) {
                    if (pkg != currentForegroundPkg) {
                        if (currentForegroundPkg != null) {
                            val duration = timeStamp - currentForegroundStartTime
                            if (duration > 0 && duration < 24 * 3600 * 1000L) {
                                dayAppTimeMap[currentForegroundPkg!!] = (dayAppTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                            }
                        }
                        currentForegroundPkg = pkg
                        currentForegroundStartTime = Math.max(dayStart, timeStamp)
                    }
                } else if (eventType == UsageEvents.Event.ACTIVITY_PAUSED || eventType == 2) {
                    if (pkg == currentForegroundPkg) {
                        val duration = timeStamp - currentForegroundStartTime
                        if (duration > 0 && duration < 24 * 3600 * 1000L) {
                            dayAppTimeMap[pkg] = (dayAppTimeMap[pkg] ?: 0L) + duration
                        }
                        currentForegroundPkg = null
                    }
                }
            }

            if (currentForegroundPkg != null) {
                val duration = actualEnd - currentForegroundStartTime
                if (duration > 0 && duration < 24 * 3600 * 1000L) {
                    dayAppTimeMap[currentForegroundPkg!!] = (dayAppTimeMap[currentForegroundPkg!!] ?: 0L) + duration
                }
            }

            var dayTotalMs = 0L
            for ((pkg, duration) in dayAppTimeMap) {
                if (launchablePackages.contains(pkg) || pkg == packageName) {
                    dayTotalMs += Math.min(duration, maxDuration)
                }
            }

            val finalDayMs = Math.min(dayTotalMs, maxDuration)
            result.add((finalDayMs / 60000).toInt())
        }

        return result
    }

    private fun getSupportedInstalledApps(): List<Map<String, Any>> {
        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolveInfos = packageManager.queryIntentActivities(launcherIntent, 0)
        val ownPackage = packageName

        val appList = mutableListOf<Map<String, Any>>()

        for (resolveInfo in resolveInfos) {
            val appInfo = resolveInfo.activityInfo?.applicationInfo ?: continue
            val pkgName = appInfo.packageName ?: continue

            if (pkgName == ownPackage) continue

            val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (isSystemApp) continue

            val appLabel = resolveInfo.loadLabel(packageManager)?.toString() ?: pkgName
            val iconDrawable = try {
                resolveInfo.loadIcon(packageManager)
            } catch (_: Exception) {
                null
            }

            val iconBytes = iconDrawable?.let { drawableToPng(it) }

            val appData = mutableMapOf<String, Any>(
                "packageId" to pkgName,
                "name" to appLabel
            )
            if (iconBytes != null) {
                appData["icon"] = iconBytes
            }

            appList.add(appData)
        }

        return appList.sortedBy { (it["name"] as String).lowercase() }
    }

    private fun loadSelectedApps(): List<String> =
        getSharedPreferences(PREFERENCES, MODE_PRIVATE)
            .getStringSet(SELECTED_APPS_KEY, emptySet())
            ?.toList()
            ?: emptyList()

    private fun drawableToPng(drawable: Drawable): ByteArray {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        return ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }

    private fun isAccessibilityGranted(): Boolean {
        val expectedService = "$packageName/${FocusAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.split(":").any { it.equals(expectedService, ignoreCase = true) }
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun getBlockerConfig(): Map<String, Any> {
        val prefs = getSharedPreferences(PREFERENCES, MODE_PRIVATE)
        val blockShorts = prefs.getBoolean("block_youtube_shorts", true)
        val blockReels = prefs.getBoolean("block_instagram_reels", true)
        val action = prefs.getString("blocking_action", "go_back") ?: "go_back"

        val todayStr = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault()).format(java.util.Date())
        val savedDate = prefs.getString("blocked_date", "")
        val count = if (savedDate == todayStr) prefs.getInt("blocked_count_today", 0) else 0

        return mapOf(
            "isAccessibilityGranted" to isAccessibilityGranted(),
            "blockYouTubeShorts" to blockShorts,
            "blockInstagramReels" to blockReels,
            "blockingAction" to action,
            "blockedCountToday" to count
        )
    }

    private fun changeAppIconAndName(aliasName: String): Boolean {
        val pm = packageManager
        val pkg = packageName

        val aliases = listOf(
            "DefaultAlias",
            "CalculatorAlias",
            "NotesAlias",
            "CalendarAlias",
            "ClockAlias"
        )

        val targetAlias = if (aliases.contains(aliasName)) aliasName else "DefaultAlias"

        for (alias in aliases) {
            val componentName = android.content.ComponentName(pkg, "$pkg.$alias")
            val newState = if (alias == targetAlias) {
                android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }

            try {
                pm.setComponentEnabledSetting(
                    componentName,
                    newState,
                    android.content.pm.PackageManager.DONT_KILL_APP
                )
            } catch (_: Exception) {}
        }

        getSharedPreferences(PREFERENCES, MODE_PRIVATE)
            .edit()
            .putString("active_app_disguise", targetAlias)
            .commit()

        return true
    }

    private fun getActiveAppDisguise(): String {
        val prefs = getSharedPreferences(PREFERENCES, MODE_PRIVATE)
        return prefs.getString("active_app_disguise", "DefaultAlias") ?: "DefaultAlias"
    }

    companion object {
        private const val PICK_ICON_REQUEST_CODE = 9912
        private const val APP_SELECTION_CHANNEL = "com.focusguard.app/app_selection"
        private const val USAGE_STATS_CHANNEL = "com.focusguard.app/usage_stats"
        private const val ACCESSIBILITY_CHANNEL = "com.focusguard.app/accessibility"
        private const val SECURITY_CHANNEL = "com.focusguard.app/security"
        private const val PREFERENCES = "focus_guard_preferences"
        private const val SELECTED_APPS_KEY = "selected_controlled_apps"
    }
}
