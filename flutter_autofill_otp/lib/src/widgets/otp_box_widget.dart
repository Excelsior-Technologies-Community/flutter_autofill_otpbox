import 'package:flutter/material.dart';

class OtpBoxWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode current;
  final FocusNode? next;
  final FocusNode? previous;
  final double boxHeight;           // NEW
  final double boxWidth;            // NEW
  final Color borderColor;          // NEW
  final Color focusedBorderColor;   // NEW
  final Color fillColor;            // NEW
  final TextStyle? textStyle;       // NEW

  final void Function(String, FocusNode?) moveNext;
  final void Function(String, FocusNode?) moveBack;
  final void Function(String) handlePaste;

  const OtpBoxWidget({
    super.key,
    required this.controller,
    required this.current,
    this.next,
    this.previous,
    required this.moveNext,
    required this.moveBack,
    required this.handlePaste,
    this.boxHeight = 60.0,          // Default
    this.boxWidth = 50.0,           // Default
    this.borderColor = Colors.grey, // Default
    this.focusedBorderColor = Colors.blue, // Default
    this.fillColor = Colors.white,  // Default
    this.textStyle,                 // Optional
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boxWidth,
      height: boxHeight,
      child: TextField(
        controller: controller,
        focusNode: current,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: textStyle ?? TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: fillColor,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: focusedBorderColor, width: 2),
          ),
        ),
        onChanged: (value) {
          // Paste OTP
          if (value.length > 1) {
            handlePaste(value);
            return;
          }
          // next otp box
          moveNext(value, next);
          // previous otp box
          moveBack(value, previous);
        },
      ),
    );
  }
}