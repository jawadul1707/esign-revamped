import 'dart:async';
import 'dart:convert';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/email_input.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

class OtpNumberInputPage extends StatefulWidget {
  const OtpNumberInputPage({super.key});

  @override
  _OtpNumberInputPageState createState() => _OtpNumberInputPageState();
}

class _OtpNumberInputPageState extends State<OtpNumberInputPage> {
  late final SmsRetriever smsRetriever;
  late final TextEditingController pinController;
  late final FocusNode focusNode;
  late final GlobalKey<FormState> formKey;
  bool _isButtonEnabled = false;

  late Timer _timer;
  int _start = 60; // 1 minute countdown
  bool _isResendEnabled = false; // Controls whether resend button is enabled

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    pinController = TextEditingController();
    focusNode = FocusNode();
    startTimer(); // Start the timer when the page loads

    // Initialize the SmsRetriever with SmartAuth
    smsRetriever = SmsRetrieverImpl(SmartAuth());

    // Start listening for SMS autofill
    _listenForSmsCode();
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
  void _resendCode() async {
    // Call your OTP resend function here
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('$uri/user-management-service/api/v1/mobile/otp/send'));
    request.body = json.encode({"mobileNumber": mobileNumber});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
    startTimer(); // Restart the countdown after resending the code
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    smsRetriever.dispose(); // Dispose of SmsRetriever
    _timer.cancel(); // Cancel the timer
    super.dispose();
  }

  Future<void> _listenForSmsCode() async {
    try {
      final otpCode = await smsRetriever.getSmsCode();
      if (otpCode != null) {
        setState(() {
          pinController.text = otpCode; // Autofill the Pinput field
          _isButtonEnabled = otpCode.length == 6;
        });
      }
    } catch (e) {
      print('Failed to get OTP: $e');
    }
  }

  Future<bool> _verifyOTP(String otp) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('$uri/user-management-service/api/v1/mobile/otp/verify'));
    request.body = json.encode({
      "mobileNumber": mobileNumber,
      "otp": otp,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    return response.statusCode == 200;
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = Color(0xFF00BFA5);
    const borderColor = Color(0xFFC2E7FF);
    const submitColor = Color(0xFF005D99);

    final defaultPinTheme = PinTheme(
      width: 40,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Color(0xFF005D99),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Verify OTP'),
        ),
        automaticallyImplyLeading: false,
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
                      'Enter the code sent to +88$mobileNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Form(
                    key: formKey,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Pinput(
                        length: 6,
                        smsRetriever: smsRetriever, // Use smsRetriever here
                        controller: pinController,
                        focusNode: focusNode,
                        defaultPinTheme: defaultPinTheme,
                        separatorBuilder: (index) => const SizedBox(width: 8),
                        onCompleted: (pin) async {
                          if (_isButtonEnabled) {
                            bool isVerificationSuccessful =
                                await _verifyOTP(pin);
                            if (isVerificationSuccessful) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmailInputPage(),
                                ),
                              );
                            } else {
                              final snackBar = SnackBar(
                                content: const Text('OTP Verification Failed'),
                                action: SnackBarAction(
                                  label: 'OK',
                                  onPressed: () {},
                                ),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          }
                        },
                        onChanged: (value) {
                          setState(() {
                            _isButtonEnabled = value.length == 6;
                          });
                        },
                        cursor: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 9),
                              width: 22,
                              height: 1,
                              color: focusedBorderColor,
                            ),
                          ],
                        ),
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: focusedBorderColor),
                          ),
                        ),
                        submittedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: submitColor),
                          ),
                        ),
                        errorPinTheme: defaultPinTheme.copyBorderWith(
                          border: Border.all(color: Colors.redAccent),
                        ),
                      ),
                    ),
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
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled
                          ? () async {
                              bool isVerificationSuccessful =
                                  await _verifyOTP(pinController.text);
                              if (isVerificationSuccessful) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EmailInputPage(),
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

/// Implement SmsRetriever using SmartAuth
class SmsRetrieverImpl implements SmsRetriever {
  const SmsRetrieverImpl(this.smartAuth);

  final SmartAuth smartAuth;

  @override
  Future<void> dispose() {
    return smartAuth.removeSmsListener();
  }

  @override
  Future<String?> getSmsCode() async {
    final signature = await smartAuth.getAppSignature();
    debugPrint('App Signature: $signature');
    final res = await smartAuth.getSmsCode(
      useUserConsentApi: true,
    );
    if (res.succeed && res.codeFound) {
      return res.code!;
    }
    return null;
  }

  @override
  bool get listenForMultipleSms => false;
}
