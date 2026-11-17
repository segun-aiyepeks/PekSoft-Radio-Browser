package com.peksoft.peksoft_radio

import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.peksoft.radio/links")
            .setMethodCallHandler { call, result ->
                if (call.method == "openUrl") {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        startActivity(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID_URL", "URL is required", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
