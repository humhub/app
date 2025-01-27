package com.humhub.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.annotation.NonNull
import android.content.pm.verify.domain.DomainVerificationManager
import android.content.pm.verify.domain.DomainVerificationUserState
import android.os.Build
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.S)
class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_links_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkOpenByDefault") {
                val packageName = call.argument<String>("packageName")
                packageName?.let {
                    val domainVerificationManager = getSystemService(DomainVerificationManager::class.java)
                    val userState = domainVerificationManager?.getDomainVerificationUserState(it)

                    // Cast the Map to correct type before processing
                    val hostToStateMap = userState?.hostToStateMap?.mapKeys { it.key.toString() }
                        ?.mapValues { it.value }

                    val unsupportedUrls = hostToStateMap?.filter { entry ->
                        entry.value == DomainVerificationUserState.DOMAIN_STATE_NONE
                    }?.keys?.toList() ?: emptyList()

                    result.success(mapOf("unsupportedUrls" to unsupportedUrls))
                } ?: result.error("INVALID_PACKAGE", "Package name is null", null)
            } else {
                result.notImplemented()
            }
        }
    }
}


