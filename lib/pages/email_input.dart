import 'dart:convert';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/otp_email.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailInputPage extends StatefulWidget {
  const EmailInputPage({super.key});

  @override
  _EmailInputPageState createState() => _EmailInputPageState();
}

class _EmailInputPageState extends State<EmailInputPage> {
  // VARIABLES
  final _emailController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false; // Variable to track loading state

  void _validateEmail(String input) {
    // Assuming a basic validation for an email address
    final isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
    setState(() {
      _isButtonEnabled = isValid;
    });
    email = input;
  }

  // Function to check the email
  Future<bool> _checkEmail() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
      'POST',
      Uri.parse('$uri/user-management-service/api/v1/check/email'),
    );
    request.body = json.encode({"email": email});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        return true; // Email is valid
      } else {
        print(response.reasonPhrase);
        return false; // Email is invalid or other errors
      }
    } catch (e) {
      print('Error: $e'); // Handle network errors
      return false;
    }
  }

  // Function to send an OTP
  Future<void> _sendOTP() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
      'POST',
      Uri.parse('$uri/user-management-service/api/v1/email/otp/send'),
    );
    request.body = json.encode({"email": email});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        //print(await response.stream.bytesToString());
      } else {
        //print(response.reasonPhrase);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Handle Continue button press
  Future<void> _handleContinueButtonPress() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    bool isValid = await _checkEmail();
    if (isValid) {
      await _sendOTP();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OtpEmailInputPage(),
          settings: RouteSettings(arguments: email),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFCCCC), // Set the dialog background color to red
          title: const Text(
            'Error',
            style: TextStyle(color: Color(0xFFFF3333)), // Set the title text color to red
          ),
          content: const Text(
            'Email address already exists. Please try again.',
            style: TextStyle(color: Color(0xFFFF3333)), // Set the content text color to red
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFFF3333)), // Set button text color to red
              ),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Enter Email Address'),
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
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _validateEmail,
                  ),
                  const Spacer(),
                  // Updated onPressed for the Continue button
                  SizedBox(
                    width: 360,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled && !_isLoading
                          ? _handleContinueButtonPress
                          : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFFC2E7FF),
                        backgroundColor: const Color(0xFF005D99),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFFC2E7FF),
                            )
                          : const Text('Continue'),
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
