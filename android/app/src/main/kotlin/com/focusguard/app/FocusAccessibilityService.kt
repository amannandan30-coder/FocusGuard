package com.focusguard.app

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FocusAccessibilityService : AccessibilityService() {

    private var lastActionTime = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == ownPackageName) return

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val now = SystemClock.elapsedRealtime()

        val isFocusSessionActive = prefs.getBoolean(KEY_FOCUS_SESSION_ACTIVE, false)
        val selectedApps = prefs.getStringSet(KEY_SELECTED_APPS, emptySet()) ?: emptySet()

        // 1. Priority Enforcement: Active Focus Session App Blocking
        if (isFocusSessionActive && selectedApps.contains(packageName)) {
            if (now - lastActionTime < 400L) return

            lastActionTime = now
            incrementBlockedCountToday()

            // Perform Global Action Home to exit app
            performGlobalAction(GLOBAL_ACTION_HOME)

            // Force launcher activity to bring user to home screen immediately
            try {
                val homeIntent = android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
                    addCategory(android.content.Intent.CATEGORY_HOME)
                    flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                startActivity(homeIntent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to launch home intent: ${e.message}")
            }

            Log.d(TAG, "Focus Session Active: Booted user out of managed app $packageName")
            return
        }

        // 2. Standard Shorts / Reels Content Blocker
        if (now - lastActionTime < DEBOUNCE_MS) {
            return
        }

        val blockShorts = prefs.getBoolean(KEY_BLOCK_YOUTUBE_SHORTS, true)
        val blockReels = prefs.getBoolean(KEY_BLOCK_INSTAGRAM_REELS, true)

        var shouldBlockContent = false

        if (blockShorts && packageName == YOUTUBE_PACKAGE) {
            shouldBlockContent = isYouTubeShortsOpened(event)
        } else if (blockReels && packageName == INSTAGRAM_PACKAGE) {
            shouldBlockContent = isInstagramReelsOpened(event)
        }

        if (shouldBlockContent) {
            lastActionTime = now
            incrementBlockedCountToday()

            val actionType = prefs.getString(KEY_BLOCKING_ACTION, ACTION_GO_BACK) ?: ACTION_GO_BACK
            if (actionType == ACTION_GO_HOME) {
                performGlobalAction(GLOBAL_ACTION_HOME)
            } else {
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
            Log.d(TAG, "Blocked Short/Reel in $packageName with action: $actionType")
        }
    }

    override fun onInterrupt() {
        // Required by AccessibilityService lifecycle
    }

    private fun isYouTubeShortsOpened(event: AccessibilityEvent): Boolean {
        val rootNode = rootInActiveWindow ?: return false

        // Check 1: Known YouTube Shorts view IDs
        val shortsViewIds = listOf(
            "com.google.android.youtube:id/reel_recycler",
            "com.google.android.youtube:id/reel_player_page_container",
            "com.google.android.youtube:id/shorts_player_view",
            "com.google.android.youtube:id/reel_view_holder",
            "com.google.android.youtube:id/shorts_container"
        )

        for (viewId in shortsViewIds) {
            val nodes = rootNode.findAccessibilityNodeInfosByViewId(viewId)
            if (!nodes.isNullOrEmpty()) {
                nodes.forEach { it.recycle() }
                return true
            }
        }

        // Check 2: Class name or content description check
        val sourceNode = event.source
        if (sourceNode != null) {
            val contentDesc = sourceNode.contentDescription?.toString()?.lowercase() ?: ""
            val text = sourceNode.text?.toString()?.lowercase() ?: ""
            if (contentDesc.contains("shorts player") || text.contains("shorts player")) {
                sourceNode.recycle()
                return true
            }
            sourceNode.recycle()
        }

        return false
    }

    private fun isInstagramReelsOpened(event: AccessibilityEvent): Boolean {
        val rootNode = rootInActiveWindow ?: return false

        // Check 1: Known Instagram Reels view IDs
        val reelsViewIds = listOf(
            "com.instagram.android:id/reels_viewer_view_pager",
            "com.instagram.android:id/reels_video_view",
            "com.instagram.android:id/clips_video_container",
            "com.instagram.android:id/reel_viewer_view"
        )

        for (viewId in reelsViewIds) {
            val nodes = rootNode.findAccessibilityNodeInfosByViewId(viewId)
            if (!nodes.isNullOrEmpty()) {
                nodes.forEach { it.recycle() }
                return true
            }
        }

        return false
    }

    private fun incrementBlockedCountToday() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val savedDate = prefs.getString(KEY_BLOCKED_DATE, "")

        var count = if (savedDate == todayStr) {
            prefs.getInt(KEY_BLOCKED_COUNT_TODAY, 0)
        } else {
            0
        }

        count++
        prefs.edit()
            .putString(KEY_BLOCKED_DATE, todayStr)
            .putInt(KEY_BLOCKED_COUNT_TODAY, count)
            .apply()
    }

    private val ownPackageName: String
        get() = packageName

    companion object {
        private const val TAG = "FocusAccessibility"
        private const val DEBOUNCE_MS = 1500L

        private const val YOUTUBE_PACKAGE = "com.google.android.youtube"
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"

        const val PREFS_NAME = "focus_guard_preferences"
        const val KEY_BLOCK_YOUTUBE_SHORTS = "block_youtube_shorts"
        const val KEY_BLOCK_INSTAGRAM_REELS = "block_instagram_reels"
        const val KEY_BLOCKING_ACTION = "blocking_action"
        const val KEY_BLOCKED_COUNT_TODAY = "blocked_count_today"
        const val KEY_BLOCKED_DATE = "blocked_date"
        const val KEY_FOCUS_SESSION_ACTIVE = "focus_session_active"
        const val KEY_SELECTED_APPS = "selected_controlled_apps"

        const val ACTION_GO_BACK = "go_back"
        const val ACTION_GO_HOME = "go_home"
    }
}
