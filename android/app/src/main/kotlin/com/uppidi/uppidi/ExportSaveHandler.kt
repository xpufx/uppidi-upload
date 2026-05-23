package com.uppidi.uppidi

import android.app.Activity
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

// TODO: Remove this entire file after file_picker 12.x stable ships with a fix.
// file_picker 12.x betas removed "bytes" from the Android method channel arguments
// for saveFile (regression from 11.0.2), causing PathNotFoundException on content URIs.
// Once upstream is fixed, revert export_import.dart to FilePicker.saveFile(bytes: ...).

class ExportSaveHandler(private val activity: Activity) {
    companion object {
        private const val CHANNEL = "com.uppidi.uppidi/export_save"
        private const val SAVE_FILE_CODE = 0xbeef
        private const val TAG = "ExportSaveHandler"
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    fun registerWith(engine: FlutterEngine) {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            if (call.method == "saveFile") {
                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName") ?: "export.json"

                if (pendingResult != null) {
                    result.error("already_active", "Save dialog is already active", null)
                    return@setMethodCallHandler
                }

                pendingResult = result
                pendingBytes = bytes

                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    putExtra(Intent.EXTRA_TITLE, fileName)
                    type = "*/*"
                }

                try {
                    activity.startActivityForResult(intent, SAVE_FILE_CODE)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start save file intent", e)
                    pendingResult?.error("intent_failed", e.message, null)
                    clearPending()
                }
            } else {
                result.notImplemented()
            }
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_FILE_CODE) return false

        if (resultCode == Activity.RESULT_CANCELED) {
            pendingResult?.success(null)
            clearPending()
            return true
        }

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pendingResult?.error("save_failed", "Unknown error", null)
            clearPending()
            return true
        }

        val uri = data.data!!
        try {
            activity.contentResolver.openOutputStream(uri)?.use { output ->
                val bytes = pendingBytes
                if (bytes != null) {
                    output.write(bytes)
                }
            }
            pendingResult?.success(uri.toString())
        } catch (e: IOException) {
            Log.e(TAG, "Failed to write bytes", e)
            pendingResult?.error("write_failed", e.message, null)
        }

        clearPending()
        return true
    }

    private fun clearPending() {
        pendingResult = null
        pendingBytes = null
    }
}
