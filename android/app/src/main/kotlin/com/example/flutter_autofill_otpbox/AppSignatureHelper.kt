package com.example.flutter_autofill_otpbox

import android.content.Context
import android.content.pm.PackageManager
import android.util.Base64
import android.util.Log
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class AppSignatureHelper(private val context: Context) {

    val appSignatures: List<String>
        get() = try {
            val packageName = context.packageName
            val packageManager = context.packageManager
            val packageInfo = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES
            )

            val signatures = packageInfo.signatures   // <-- This is nullable

            if (signatures == null || signatures.isEmpty()) {
                Log.e("AppSignatureHelper", "No signatures found")
                emptyList()
            } else {
                signatures.mapNotNull { sig ->
                    hash(packageName, sig.toCharsString())
                }
            }
        } catch (e: Exception) {
            Log.e("AppSignatureHelper", "Error: ${e.message}")
            emptyList()
        }

    private fun hash(packageName: String, signature: String): String? {
        val appInfo = "$packageName $signature"

        return try {
            val messageDigest = MessageDigest.getInstance("SHA-256")
            messageDigest.update(appInfo.toByteArray(StandardCharsets.UTF_8))

            var hashSignature = messageDigest.digest()
            hashSignature = hashSignature.copyOfRange(0, 9)

            val base64Hash = Base64.encodeToString(
                hashSignature,
                Base64.NO_PADDING or Base64.NO_WRAP
            ).substring(0, 11)

            Log.d("AppSignatureHelper", "Hash: $base64Hash")
            base64Hash
        } catch (e: NoSuchAlgorithmException) {
            Log.e("AppSignatureHelper", "NoSuchAlgorithm: ${e.message}")
            null
        }
    }
}
