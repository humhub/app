package com.humhub.app

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.verify.domain.DomainVerificationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_LINKS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getGoHumhubState" -> result.success(getGoHumhubState())
                    "openOpenByDefaultSettings" -> result.success(openOpenByDefaultSettings())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getGoHumhubState(): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return mapOf(
                "supported" to false,
                "enabled" to true,
                "hostDeclared" to false,
            )
        }

        return try {
            val manager = getSystemService(DomainVerificationManager::class.java)
                ?: return mapOf(
                    "supported" to true,
                    "enabled" to true,
                    "hostDeclared" to false,
                )

            val userState = manager.getDomainVerificationUserState(packageName)
                ?: return mapOf(
                    "supported" to true,
                    "enabled" to true,
                    "hostDeclared" to false,
                )

            val hostState = userState.hostToStateMap[GO_HUMHUB_HOST]

            mapOf(
                "supported" to true,
                "enabled" to userState.isLinkHandlingAllowed,
                "hostDeclared" to (hostState != null),
                "hostState" to hostState,
            )
        } catch (_: PackageManager.NameNotFoundException) {
            mapOf(
                "supported" to true,
                "enabled" to true,
                "hostDeclared" to false,
            )
        }
    }

    private fun openOpenByDefaultSettings(): Boolean {
        return try {
            val packageUri = Uri.parse("package:$packageName")
            val appLinkSettingsIntent = Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS).apply {
                data = packageUri
            }
            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = packageUri
            }
            val intentToLaunch = if (appLinkSettingsIntent.resolveActivity(packageManager) != null) {
                appLinkSettingsIntent
            } else {
                fallbackIntent
            }

            startActivity(intentToLaunch)
            true
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        private const val APP_LINKS_CHANNEL = "humhub/app_links"
        private const val GO_HUMHUB_HOST = "go.humhub.com"
    }
}
