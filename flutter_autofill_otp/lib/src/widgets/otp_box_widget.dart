import 'package:flutter/material.dart';

class OtpBoxWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode current;
  final FocusNode? next;
  final FocusNode? previous;

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
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 45,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: TextField(
          controller: controller,
          focusNode: current,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          decoration: InputDecoration(
            counterText: "",
            contentPadding: EdgeInsets.all(4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)
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
      ),
    );
  }
}
