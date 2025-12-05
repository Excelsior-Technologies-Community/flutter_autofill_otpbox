// android/app/src/main/kotlin/com/example/flutter_autofill_otpbox/FileLogger.kt
package com.example.flutter_autofill_otpbox

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

class FileLogger(private val context: Context) {

    companion object {
        private const val TAG = "SMS_DEBUG"
        private const val LOG_FILE = "debug_log.txt"
        private val dateFormat = SimpleDateFormat("HH:mm:ss.SSS", Locale.getDefault())
    }

    fun log(message: String) {
        try {
            val timestamp = dateFormat.format(Date())
            val logMessage = "[$timestamp] $message\n"

            // Console mein bhi print karo
            Log.d(TAG, message)

            // File mein save karo
            val logFile = File(context.filesDir, LOG_FILE)
            FileOutputStream(logFile, true).use { fos ->
                fos.write(logMessage.toByteArray())
            }
        } catch (e: Exception) {
            Log.e(TAG, "Log write error: ${e.message}")
        }
    }

    fun getLogs(): String {
        return try {
            val logFile = File(context.filesDir, LOG_FILE)
            if (logFile.exists()) {
                logFile.readText()
            } else {
                "No logs found"
            }
        } catch (e: Exception) {
            "Error reading logs: ${e.message}"
        }
    }

    fun clearLogs() {
        try {
            val logFile = File(context.filesDir, LOG_FILE)
            if (logFile.exists()) {
                logFile.delete()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Clear logs error: ${e.message}")
        }
    }
}