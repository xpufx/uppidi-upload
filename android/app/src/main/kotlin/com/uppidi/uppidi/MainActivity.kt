package com.uppidi.uppidi

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var exportSaveHandler: ExportSaveHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = ExportSaveHandler(this)
        handler.registerWith(flutterEngine)
        exportSaveHandler = handler
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val handled = exportSaveHandler?.onActivityResult(requestCode, resultCode, data) ?: false
        if (!handled) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
