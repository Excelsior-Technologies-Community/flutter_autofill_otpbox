import 'package:flutter/services.dart';

class SmsAutoFillService {
  static const MethodChannel _channel = MethodChannel('sms_retriever');
  static Function(String)? _otpCallback;

  // Test connection
  static Future<bool> testConnection() async {
    try {
      print('🔗 Testing native connection...');
      final result = await _channel.invokeMethod('test');
      print('✅ Native connection: $result');
      return true;
    } catch (e) {
      print('❌ Native connection failed: $e');
      return false;
    }
  }

  // Get debug logs from native
  static Future<String> getLogs() async {
    try {
      final String logs = await _channel.invokeMethod('getLogs');
      print('📋 Native Logs:\n$logs');
      return logs;
    } on PlatformException catch (e) {
      return 'Error getting logs: ${e.message}';
    }
  }

  // Request SMS permission
  static Future<bool> requestPermission() async {
    try {
      print('📱 Requesting SMS permission...');
      final bool granted = await _channel.invokeMethod('requestPermission');
      print('✅ Permission result: $granted');
      return granted;
    } on PlatformException catch (e) {
      print('❌ Permission error: ${e.message}');
      return false;
    }
  }

  // Check if permission is granted
  static Future<bool> checkPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('checkPermission');
      print('🔐 Current permission: $granted');
      return granted;
    } on PlatformException catch (e) {
      print('❌ Check permission error: ${e.message}');
      return false;
    }
  }

  // Start listening for SMS
  static Future<void> startListening(Function(String) onOtpReceived) async {
    _otpCallback = onOtpReceived;

    // Set up method call handler first
    _channel.setMethodCallHandler((call) async {
      print('📞 Native Method: ${call.method}');

      if (call.method == 'onOtpReceived') {
        final String otp = call.arguments.toString();
        print('🎯 OTP received: $otp');
        _otpCallback?.call(otp);
      } else if (call.method == 'onTimeout') {
        print('⏱️ SMS retriever timeout');
      } else if (call.method == 'onPermissionGranted') {
        print('✅ Permission granted by user');
      } else if (call.method == 'onPermissionDenied') {
        print('❌ Permission denied by user');
      } else if (call.method == 'onError') {
        print('❌ Native error: ${call.arguments}');
      }
    });

    try {
      print('🔵 Starting SMS listener...');
      final result = await _channel.invokeMethod('startListening');
      print('✅ SMS listener: $result');
    } on PlatformException catch (e) {
      print('❌ Failed to start: ${e.message}');
    }
  }

  // Get app signature
  static Future<String?> getAppSignature() async {
    try {
      print('📝 Getting app signature...');
      final signature = await _channel.invokeMethod('getAppSignature');
      print('✅ App Signature: $signature');
      return signature;
    } catch (e) {
      print('❌ Get signature error: $e');
      return null;
    }
  }

  // Stop listening
  static Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopListening');
      _otpCallback = null;
      print('🛑 SMS listener stopped');
    } catch (e) {
      print('❌ Stop error: $e');
    }
  }
}