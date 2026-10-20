package apps.waleed.sunnah.wgoot

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import apps.waleed.sunnah.wgoot.compass.CompassStreamHandler

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val compass = CompassStreamHandler(this)
        MethodChannel(messenger, "apps.waleed.sunnah.wgoot/compass")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(compass.isAvailable)
                    else -> result.notImplemented()
                }
            }
        EventChannel(messenger, "apps.waleed.sunnah.wgoot/compass/heading")
            .setStreamHandler(compass)
    }
}
