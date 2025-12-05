import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_autofill_otp/src/widgets/otp_box_widget.dart';
import 'sms_autofill_service.dart';

class AutoFillOtpBox extends StatefulWidget {
  final int otpLength;
  final double boxHeight;           // NEW: Box height parameter
  final double boxWidth;            // NEW: Box width parameter
  final double boxSpacing;          // NEW: Space between boxes
  final Color borderColor;          // NEW: Border color
  final Color focusedBorderColor;   // NEW: Focused border color
  final Color fillColor;            // NEW: Box fill color
  final TextStyle? textStyle;       // NEW: Custom text style
  final String? phoneNumber;
  final VoidCallback? onResendOtp;
  final ValueChanged<String>? onOtpVerified;
  final bool showResendButton;
  final Duration resendTimeout;
  final bool showPermissionStatus;  // NEW: Show/hide permission status
  final bool autoFocusFirstBox;     // NEW: Auto focus first box

  const AutoFillOtpBox({
    super.key,
    this.otpLength = 6,
    this.phoneNumber,
    this.onResendOtp,
    this.onOtpVerified,
    this.boxHeight = 60.0,          // Default height
    this.boxWidth = 50.0,           // Default width
    this.boxSpacing = 8.0,          // Default spacing
    this.borderColor = Colors.grey, // Default border color
    this.focusedBorderColor = Colors.blue, // Default focused color
    this.fillColor = Colors.white,  // Default fill color
    this.textStyle,                 // Optional custom text style
    this.showResendButton = true,
    this.resendTimeout = const Duration(seconds: 30),
    this.showPermissionStatus = true, // Default show permission
    this.autoFocusFirstBox = true,  // Default auto focus
  });

  @override
  State<AutoFillOtpBox> createState() => _AutoFillOtpBoxState();
}

class _AutoFillOtpBoxState extends State<AutoFillOtpBox> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;
  bool _permissionGranted = false;
  bool _isLoading = true;
  String _currentOtp = '';
  int _resendTimer = 0;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.otpLength, (_) => TextEditingController());
    focusNodes = List.generate(widget.otpLength, (_) => FocusNode());

    // Initialize SMS service
    SmsAutoFillService.initialize();

    print('🎯 OTP Screen initialized (${widget.otpLength} digits)');
    _initializeSmsListener();

    // Auto focus first box if enabled
    if (widget.autoFocusFirstBox) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && focusNodes.isNotEmpty) {
          focusNodes[0].requestFocus();
        }
      });
    }

    // Start resend timer
    if (widget.showResendButton) {
      _startResendTimer();
    }
  }

  Future<void> _initializeSmsListener() async {
    setState(() => _isLoading = true);

    final hasPermission = await SmsAutoFillService.checkPermission();
    print('🔐 Initial permission check: $hasPermission');

    if (hasPermission) {
      await _startListening();
    } else {
      final granted = await SmsAutoFillService.requestPermission();
      print('📋 Permission request result: $granted');
      if (granted) {
        await _startListening();
      } else {
        _showPermissionDialog();
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _startListening() async {
    setState(() => _permissionGranted = true);
    print('👂 Starting SMS listener...');

    await SmsAutoFillService.startListening((otp) {
      print('🎯 OTP callback triggered: $otp');
      if (otp.length == widget.otpLength) _fillOtpBoxes(otp);
    });

    print('✅ SMS listener started');
  }

  void _fillOtpBoxes(String otp) {
    print('🔠 Filling OTP boxes with: $otp');
    for (int i = 0; i < widget.otpLength && i < otp.length; i++) {
      controllers[i].text = otp[i];
    }
    focusNodes.last.requestFocus();
    _currentOtp = otp;

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP auto-filled: $otp'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // Callback for OTP verified
    if (widget.onOtpVerified != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onOtpVerified!(otp);
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'This app needs SMS permission to automatically read OTP codes. '
              'Please grant the permission in app settings to use auto-fill feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final granted = await SmsAutoFillService.requestPermission();
              if (granted) await _startListening();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _startResendTimer() {
    _resendTimer = widget.resendTimeout.inSeconds;
    _canResend = false;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _resendTimer--;
      });

      if (_resendTimer <= 0) {
        _canResend = true;
        timer.cancel();
      }
    });
  }

  void moveNext(int index, String value) {
    if (value.isNotEmpty && index < widget.otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    }

    // Update current OTP
    _updateCurrentOtp();
  }

  void moveBack(int index, String value) {
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // Update current OTP
    _updateCurrentOtp();
  }

  void _updateCurrentOtp() {
    String otp = '';
    for (var controller in controllers) {
      otp += controller.text;
    }
    _currentOtp = otp;

    // Check if OTP is complete
    if (otp.length == widget.otpLength && widget.onOtpVerified != null) {
      widget.onOtpVerified!(otp);
    }
  }

  void handlePaste(String value) {
    print('📋 Paste detected: $value');
    if (value.length == widget.otpLength) _fillOtpBoxes(value);
  }

  @override
  void dispose() {
    SmsAutoFillService.stopListening();
    for (var c in controllers) c.dispose();
    for (var f in focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                widget.phoneNumber != null
                    ? 'Enter the ${widget.otpLength}-digit code sent to\n${widget.phoneNumber}'
                    : 'Enter the ${widget.otpLength}-digit code sent to your phone',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Permission Status (optional)
              if (widget.showPermissionStatus) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _permissionGranted
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: _permissionGranted
                          ? Colors.green
                          : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _permissionGranted
                          ? 'Auto-fill enabled'
                          : 'Enable auto-fill for faster verification',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _permissionGranted
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // OTP Boxes
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.otpLength, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: widget.boxSpacing / 2),
                      child: OtpBoxWidget(
                        controller: controllers[index],
                        current: focusNodes[index],
                        next: index < widget.otpLength - 1
                            ? focusNodes[index + 1]
                            : null,
                        previous: index > 0
                            ? focusNodes[index - 1]
                            : null,
                        moveNext: (value, next) => moveNext(index, value),
                        moveBack: (value, previous) => moveBack(index, value),
                        handlePaste: handlePaste,
                        boxHeight: widget.boxHeight,
                        boxWidth: widget.boxWidth,
                        borderColor: widget.borderColor,
                        focusedBorderColor: widget.focusedBorderColor,
                        fillColor: widget.fillColor,
                        textStyle: widget.textStyle,
                      ),
                    );
                  }),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}