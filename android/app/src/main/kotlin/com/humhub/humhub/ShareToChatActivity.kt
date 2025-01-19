package com.humhub.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity

class ShareToChatActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Get the intent
        val intent = intent
        if (Intent.ACTION_SEND == intent.action && intent.type != null) {
            // Handle the shared image
            val imageUri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)
            if (imageUri != null) {
                handleSharedImage(imageUri)
            } else {
                Toast.makeText(this, "No image received", Toast.LENGTH_SHORT).show()
            }
        }

        // Finish the activity after handling the share
        finish()
    }

    private fun handleSharedImage(imageUri: Uri) {
        // Handle the image received via the share intent
        // Example: Pass the image URI to Flutter through a MethodChannel
        Toast.makeText(this, "Shared to Chat: $imageUri", Toast.LENGTH_SHORT).show()

        // TODO: Pass this image URI to Flutter if required using MethodChannel
    }
}
