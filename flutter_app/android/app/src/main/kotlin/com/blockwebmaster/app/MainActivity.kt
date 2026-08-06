package com.blockwebmaster.app

import com.blockwebmaster.app.blocker.BlockerBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val blockerChannelName = "com.blockwebmaster.app/blocker"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, blockerChannelName)
      .setMethodCallHandler(BlockerBridge(applicationContext))
  }
}
