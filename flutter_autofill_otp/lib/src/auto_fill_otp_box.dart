import 'package:flutter/material.dart';
import 'package:flutter_autofill_otp/flutter_autofill_otp.dart';
import 'package:flutter_autofill_otp/src/widgets/otp_box_widget.dart';

class AutoFillOtpBox extends StatefulWidget {
  final int otpLength;
  final String? phoneNumber;
  final VoidCallback? onResendOtp;

  const AutoFillOtpBox({
    super.key,
    this.otpLength = 6,
    this.phoneNumber,
    this.onResendOtp,
  });

  @override
  State<AutoFillOtpBox> createState() => _AutoFillOtpBoxState();
}

class _AutoFillOtpBoxState extends State<AutoFillOtpBox> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;
  bool _permissionGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.otpLength, (_) => TextEditingController());
    focusNodes = List.generate(widget.otpLength, (_) => FocusNode());

    print('🎯 OTP Screen initialized (${widget.otpLength} digits)');
    _initializeSmsListener();
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP auto-filled: $otp'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
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

  void moveNext(int index, String value) {
    if (value.isNotEmpty && index < widget.otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    }
  }

  void moveBack(int index, String value) {
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
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

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            // Title text with dynamic OTP length
            Text(
              'Enter ${widget.otpLength}-digit OTP',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Show phone number if provided
            if (widget.phoneNumber != null) ...[
              Text(
                'Sent to ${widget.phoneNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text(
                'Sent to your mobile number',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ✅ PERMISSION STATUS - BEFORE OTP BOXES
            Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _permissionGranted ? Icons.check_circle : Icons.info,
                    color: _permissionGranted ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _permissionGranted
                        ? 'Auto-fill enabled'
                        : 'Auto-fill requires permission',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _permissionGranted ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Enable Button (if permission not granted)
            if (!_permissionGranted) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 25),
                child: ElevatedButton.icon(
                  onPressed: _initializeSmsListener,
                  icon: const Icon(Icons.sms, size: 18),
                  label: const Text(
                    'Enable Auto-fill',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // OTP Boxes - Dynamic based on length
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.otpLength, (index) {
                return Expanded(
                  child: OtpBoxWidget(
                    controller: controllers[index],
                    current: focusNodes[index],
                    next: index < widget.otpLength - 1 ? focusNodes[index + 1] : null,
                    previous: index > 0 ? focusNodes[index - 1] : null,
                    moveNext: (value, next) => moveNext(index, value),
                    moveBack: (value, previous) => moveBack(index, value),
                    handlePaste: handlePaste,
                  ),
                );
              }),
            ),


          ],
        ),
      ),
    );
  }
}