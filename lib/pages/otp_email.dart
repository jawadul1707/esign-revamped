import 'dart:async';
import 'dart:convert';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/nidv_instruction.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

class OtpEmailInputPage extends StatefulWidget {
  const OtpEmailInputPage({super.key});

  @override
  _OtpEmailInputPageState createState() => _OtpEmailInputPageState();
}

class _OtpEmailInputPageState extends State<OtpEmailInputPage> {
  String _otpCode = '';
  bool _isButtonEnabled = false;
  bool _isResendEnabled = false;
  late Timer _timer;
  int _start = 60;

  final defaultPinTheme = PinTheme(
    width: 40,
    height: 56,
    textStyle: const TextStyle(
      fontSize: 20,
      color: Color(0xFF005D99),
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFC2E7FF)),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  @override
  void initState() {
    super.initState();
    startTimer(); // Start the countdown timer when the page loads
  }

  // Timer function that counts down from 60 seconds
  void startTimer() {
    setState(() {
      _start = 60;
      _isResendEnabled = false; // Disable resend button during countdown
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isResendEnabled = true; // Enable resend button after countdown
        });
        _timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // Function to handle resend OTP
  Future<void> _resendCode() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('$uri/user-management-service/api/v1/email/otp/send'));
    request.body = json.encode({"email": email});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print('OTP resent successfully');
    } else {
      print('Failed to resend OTP');
    }

    startTimer(); // Restart the countdown after resending the code
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  void _onOtpChanged(String code) {
    setState(() {
      _otpCode = code;
      _isButtonEnabled = code.length == 6;
    });
  }

  Future<bool> _verifyOTP() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST',
        Uri.parse('$uri/user-management-service/api/v1/email/otp/verify'));
    request.body = json.encode({
      "email": email,
      "otp": _otpCode,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else {
      return false; // OTP verification failed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Email OTP'),
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 40,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Enter the code sent to \n$email',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Pinput(
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration?.copyWith(
                        border: Border.all(color: const Color(0xFF00BFA5)),
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration?.copyWith(
                        border: Border.all(color: const Color(0xFF005D99)),
                      ),
                    ),
                    onChanged: _onOtpChanged,
                    onCompleted: (pin) {
                      _onOtpChanged(pin);
                    },
                  ),
                  const Spacer(),
                  // Resend Code and Timer Text
                  Text.rich(
                    TextSpan(
                      text: "Didn't receive code? ",
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: _isResendEnabled
                              ? "Resend Code" // Blue clickable text when countdown is finished
                              : "Resend Code in ${_start ~/ 60}:${(_start % 60).toString().padLeft(2, '0')}", // Countdown display
                          style: TextStyle(
                            color: _isResendEnabled
                                ? const Color(0xFF005D99)
                                : Colors
                                    .black, // Blue when active, grey when disabled
                            fontWeight: FontWeight.bold,
                            decoration: _isResendEnabled
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                          recognizer: _isResendEnabled
                              ? (TapGestureRecognizer()
                                ..onTap = _resendCode) // Enable tap if allowed
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled
                          ? () async {
                              bool isVerificationSuccessful =
                                  await _verifyOTP();
                              if (isVerificationSuccessful) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NidVerificationPage(),
                                  ),
                                );
                              } else {
                                final snackBar = SnackBar(
                                  content:
                                      const Text('OTP Verification Failed'),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    onPressed: () {},
                                  ),
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFFC2E7FF),
                        backgroundColor: const Color(0xFF005D99),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
