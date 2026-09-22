package id.hidocs.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var securityBridge: SecurityBridge? = null
    private val deepLinkChannel = "hidocs/deep_link"
    private var pendingLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        securityBridge = SecurityBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        securityBridge?.register()
        io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, deepLinkChannel
        ).setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                result.success(pendingLink ?: intent?.dataString)
                pendingLink = null
            } else {
                result.notImplemented()
            }
        }
        pendingLink = intent?.dataString
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingLink = intent.dataString
    }

    override fun onDestroy() {
        securityBridge?.dispose()
        securityBridge = null
        super.onDestroy()
    }
}
