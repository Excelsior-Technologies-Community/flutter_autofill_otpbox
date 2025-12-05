import 'dart:async';
import 'package:flutter/material.dart'; // Add this

class SmsAutoFillService {
  // Always return true for permission in test mode
  static Future<bool> checkPermission() async {
    print('🔐 TEST MODE: Skipping permission check');
    await Future.delayed(Duration(milliseconds: 500)); // Simulate delay
    return true; // Always return true for testing
  }

  // Always succeed in test mode
  static Future<bool> requestPermission() async {
    print('📋 TEST MODE: Simulating permission grant');
    await Future.delayed(Duration(milliseconds: 500));
    return true;
  }

  // Simulate SMS listener
  static Future<String> startListening(void Function(String) onOtpReceived) async {
    print('👂 TEST MODE: Simulating SMS listener');

    // Auto-send test OTP after delay
    Timer(Duration(seconds: 3), () {
      // Send specific format OTP
      final testOtp = '9998'; // Your test OTP
      print('📨 TEST MODE: Sending OTP: $testOtp');
      onOtpReceived(testOtp);
    });

    return "Test listener started";
  }

  // Get app signature (return dummy)
  static Future<String?> getAppSignature() async {
    await Future.delayed(Duration(milliseconds: 300));
    return "test_signature_123";
  }

  // Stop listening
  static Future<String> stopListening() async {
    return "Test listener stopped";
  }

  // Initialize (empty for test mode)
  static void initialize() {
    print('🎯 TEST MODE: Initialized without native plugin');
  }
}