package com.electriccookie.tiny_pkce_launcher

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TinyPkceLauncherPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tiny_pkce_launcher")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "launchUrl" -> {
                val url = call.argument<String>("url")
                val scheme = call.argument<String>("scheme")
                val useEphemeralSession = call.argument<Boolean>("useEphemeralSession") ?: false

                if (url == null || scheme == null) {
                    result.error("INVALID_ARGUMENT", "url and scheme must be provided", null)
                    return
                }

                if (activity == null) {
                    result.error("NO_ACTIVITY", "No activity available", null)
                    return
                }

                if (useEphemeralSession) {
                    launchWithCustomTabs(url)
                } else {
                    // Fallback to standard intent
                    launchWithIntent(url)
                }

                // Return null immediately - callback will be handled via deep links (app_links)
                // The CustomTabs session is isolated and won't share cookies/data
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun launchWithCustomTabs(url: String) {
        val activity = this.activity ?: return
        val uri = Uri.parse(url)

        val builder = CustomTabsIntent.Builder()
        // CustomTabs with default settings creates an isolated session
        // that doesn't share cookies/data with the main browser
        val customTabsIntent = builder.build()

        // Launch CustomTabs - the session is ephemeral by default
        customTabsIntent.launchUrl(activity, uri)
    }

    private fun launchWithIntent(url: String) {
        val activity = this.activity ?: return
        val uri = Uri.parse(url)
        val intent = Intent(Intent.ACTION_VIEW, uri)
        activity.startActivity(intent)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
