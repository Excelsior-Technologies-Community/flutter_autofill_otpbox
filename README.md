# Otp Auto Fill

A Flutter package for automatically reading and filling OTP from SMS.

## Features
* Automatic OTP detection from SMS
* Beautiful OTP screen UI
* SMS permission handling
* Works with 4, 6 digit OTP
* Manual paste support
* Auto-fill notification

## ✨ Preview
![screen-20251211-1611222](https://github.com/user-attachments/assets/22ff05a8-7e32-4be2-8c7d-4d64472af67b)


## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_autofill_otpbox: ^1.0.0
```
## Android Setup
1. Add permissions to AndroidManifest.xml
Add these permissions to your android/app/src/main/AndroidManifest.xml:
```
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />

```
2. SMS Retriever API
No extra configuration required – handled automatically by the package.

## Usage
```
dart
import 'package:flutter_autofill_otpbox/flutter_autofill_otpbox.dart';
class OtpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AutoFillOtpBox(
  otpLength: 6,
  phoneNumber: '+91 9586710103',
  onResendOtp: () {
    print('Resend OTP clicked');
    // Add your resend OTP logic
  },
  onOtpVerified: (otp) {
    print('OTP Verified: $otp');
    // Verify OTP with your backend
  },
)
  }
}
```
## Full Example
```
import 'package:flutter/material.dart';
import 'package:flutter_autofill_otpbox/flutter_autofill_otpbox.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("OTP Autofill Example")),
        body: const Center(
          child: AutoFillOtpBox(
            otpLength: 6,
            boxWidth: 45,
            boxHeight: 50,
            borderColor: Colors.purple,
            focusedBorderColor: Colors.deepOrange,
            fillColor: Colors.purple[50],
            textStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
            showPermissionStatus: false, // Hide permission status
            autoFocusFirstBox: false, // Don't auto focus
            ),
          ),
        ),
      ),
    );
  }
}


