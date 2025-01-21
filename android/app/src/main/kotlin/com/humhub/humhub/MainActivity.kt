package com.humhub.app
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK

class MainActivity: FlutterActivity() {

    private lateinit var sharingShortcutsManager: SharingShortcutsManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sharingShortcutsManager = SharingShortcutsManager().also {
            it.pushDirectShareTargets(this)
        }
    }
}


