# Flutter AutoFill OTP Box

A Flutter plugin that automatically reads OTP from SMS and fills it in OTP boxes.

# Features
 Automatic OTP read from SMS
 Works with 4, 6 digit OTP
 Beautiful UI ready
 SMS permission handling 
 Manual paste support

## Installation

Add this to your `pubspec.yaml`:

dependencies:
  flutter_autofill_otpbox:
    path: ../flutter_autofill_otpbox  // your project path

# How to Use
 import this package
import 'package:flutter_autofill_otpbox/flutter_autofill_otpbox.dart';

AutoFillOtpBox(
otpLength: 6,// Works with 4,6 digit OTP
phoneNumber: 'enter your number',
onOtpVerified: (otp) {
print('OTP Received: $otp');
// Add your verification logic here
   },
 )

# Android Setup Required
Required the permission is enabled

In android/app/src/main/AndroidManifest.xml add:
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />

# Troubleshooting
1. OTP not detected? - Check SMS permission
2. Error? - Run flutter clean and flutter pub get
3. Not working? - App should be open when SMS arrives
