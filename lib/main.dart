import 'package:flutter/material.dart';
import 'package:flutter_autofill_otpbox/src/auto_fill_otp_box_screen/auto_fill_otp_box.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoFill_OtpBox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AutoFillOtpBox()
    );
  }
}

