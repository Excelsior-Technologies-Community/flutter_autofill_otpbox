package com.example.flutter_autofill_otpbox

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "sms_retriever"
    private val SMS_PERMISSION_CODE = 101
    private val TAG = "SMS_DEBUG"

    private var receiver: MySMSBroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    // Lazy initialization of FileLogger
    private val fileLogger by lazy {
        FileLogger(this).also {
            it.clearLogs()
            it.log("🎯 FileLogger initialized")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        fileLogger.log("🚀 configureFlutterEngine called")

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // IMPORTANT: Set method call handler here
        methodChannel?.setMethodCallHandler { call, result ->
            fileLogger.log("📞 Method Called: ${call.method}")

            when (call.method) {
                "test" -> {
                    fileLogger.log("✅ Test method called from Flutter")
                    result.success("Connection OK")
                }

                "requestPermission" -> {
                    fileLogger.log("🔄 Requesting permission...")
                    pendingResult = result
                    requestSmsPermission()
                }

                "checkPermission" -> {
                    val hasPermission = checkSmsPermission()
                    fileLogger.log("🔍 Permission check: $hasPermission")
                    result.success(hasPermission)
                }

                "startListening" -> {
                    fileLogger.log("👂 Starting SMS listener...")
                    if (checkSmsPermission()) {
                        startSmsListener()
                        result.success("Listener started")
                    } else {
                        fileLogger.log("❌ Permission not granted for listener")
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                    }
                }

                "getAppSignature" -> {
                    val signature = AppSignatureHelper(this).appSignatures.firstOrNull()
                    fileLogger.log("📝 App Signature: $signature")
                    result.success(signature)
                }

                "getLogs" -> {
                    val logs = fileLogger.getLogs()
                    result.success(logs)
                }

                "stopListening" -> {
                    fileLogger.log("🛑 Stopping listener...")
                    stopSmsListener()
                    result.success("Listener stopped")
                }

                else -> {
                    fileLogger.log("❌ Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        fileLogger.log("✅ MethodChannel configured")
    }

    private fun checkSmsPermission(): Boolean {
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECEIVE_SMS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        fileLogger.log("🔐 Permission check result: $hasPermission")
        return hasPermission
    }

    private fun requestSmsPermission() {
        fileLogger.log("📢 Requesting SMS permission...")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!checkSmsPermission()) {
                fileLogger.log("🔄 Showing permission dialog...")
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.RECEIVE_SMS, Manifest.permission.READ_SMS),
                    SMS_PERMISSION_CODE
                )
            } else {
                fileLogger.log("✅ Permission already granted")
                pendingResult?.success(true)
                pendingResult = null
            }
        } else {
            fileLogger.log("📱 Old Android version, permission auto granted")
            pendingResult?.success(true)
            pendingResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        fileLogger.log("🎯 onRequestPermissionsResult called: $requestCode")

        if (requestCode == SMS_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED

            fileLogger.log("📋 Permission result: $granted")

            pendingResult?.success(granted)
            pendingResult = null

            if (granted) {
                fileLogger.log("✅ Permission granted!")
                methodChannel?.invokeMethod("onPermissionGranted", null)
            } else {
                fileLogger.log("❌ Permission denied!")
                methodChannel?.invokeMethod("onPermissionDenied", null)
            }
        }
    }

    private fun startSmsListener() {
        fileLogger.log("🚀 Starting SMS Retriever...")

        val client = SmsRetriever.getClient(this)
        val task = client.startSmsRetriever()

        task.addOnSuccessListener {
            fileLogger.log("✅ SmsRetriever started successfully")

            // Register broadcast receiver
            if (receiver == null) {
                receiver = MySMSBroadcastReceiver()
                receiver?.setMethodChannel(methodChannel)
                receiver?.setFileLogger(fileLogger)
                fileLogger.log("📡 Created new receiver")
            }

            val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
            registerReceiver(receiver, intentFilter)

            fileLogger.log("📡 BroadcastReceiver registered")
        }

        task.addOnFailureListener { exception ->
            fileLogger.log("❌ Failed to start SmsRetriever: ${exception.message}")
            methodChannel?.invokeMethod("onError", "Failed to start: ${exception.message}")
        }
    }

    private fun stopSmsListener() {
        try {
            if (receiver != null) {
                unregisterReceiver(receiver)
                receiver = null
                fileLogger.log("📡 Receiver unregistered")
            }
        } catch (e: Exception) {
            fileLogger.log("❌ Error unregistering receiver: ${e.message}")
        }
    }

    override fun onDestroy() {
        fileLogger.log("👋 App Destroyed")
        stopSmsListener()
        super.onDestroy()
    }

    class MySMSBroadcastReceiver : BroadcastReceiver() {

        private var methodChannel: MethodChannel? = null
        private var fileLogger: FileLogger? = null

        fun setMethodChannel(channel: MethodChannel?) {
            this.methodChannel = channel
        }

        fun setFileLogger(logger: FileLogger?) {
            this.fileLogger = logger
        }

        override fun onReceive(context: Context?, intent: Intent?) {
            fileLogger?.log("📩 BroadcastReceiver triggered!")

            if (SmsRetriever.SMS_RETRIEVED_ACTION == intent?.action) {
                val extras = intent.extras
                val status = extras?.get(SmsRetriever.EXTRA_STATUS) as? Status

                fileLogger?.log("📊 Status Code: ${status?.statusCode}")

                when (status?.statusCode) {
                    CommonStatusCodes.SUCCESS -> {
                        val message = extras.get(SmsRetriever.EXTRA_SMS_MESSAGE) as? String
                        fileLogger?.log("📨 SMS Received: $message")

                        if (message != null) {
                            val otpPattern = "\\d{4,6}".toRegex()
                            val otp = otpPattern.find(message)?.value

                            if (otp != null) {
                                fileLogger?.log("✅ OTP Extracted: $otp")
                                methodChannel?.invokeMethod("onOtpReceived", otp)
                            } else {
                                fileLogger?.log("❌ No OTP found in message")
                            }
                        }
                    }

                    CommonStatusCodes.TIMEOUT -> {
                        fileLogger?.log("⏱️ SMS Retriever Timeout")
                        methodChannel?.invokeMethod("onTimeout", null)
                    }

                    else -> {
                        fileLogger?.log("❌ Unknown status: ${status?.statusCode}")
                    }
                }
            } else {
                fileLogger?.log("❌ Not our intent: ${intent?.action}")
            }
        }
    }
}