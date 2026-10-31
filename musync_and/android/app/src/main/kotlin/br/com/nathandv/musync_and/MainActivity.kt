package br.com.nathandv.musync_and

import com.ryanheise.audioservice.AudioServiceActivity

import android.media.MediaScannerConnection
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "br.com.nathandv.musync_and/scanfile"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (!path.isNullOrBlank()) {
                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(path),
                        null
                    ) { scannedPath, uri ->
                        runOnUiThread {
                            if (uri != null) {
                                result.success(uri.toString())
                            } else {
                                result.error(
                                    "SCAN_FAILED",
                                    "O Android não conseguiu indexar o arquivo.",
                                    scannedPath
                                )
                            }
                        }
                    }
                } else {
                    result.error("INVALID_PATH", "Path é nulo ou inválido", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
