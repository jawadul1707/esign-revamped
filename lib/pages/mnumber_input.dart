import 'dart:convert';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// The mobile number input page for the Dohatec e-Sign application.
class MobileNumberInputPage extends StatefulWidget {
  const MobileNumberInputPage({super.key});

  @override
  MobileNumberInputPageState createState() => MobileNumberInputPageState();
}

class MobileNumberInputPageState extends State<MobileNumberInputPage> {
  final _phoneController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  /// Validates the phone number input and updates button state.
  void _validatePhoneNumber(String input) {
    final isValid = RegExp(r'^\d{11}$').hasMatch(input);
    setState(() {
      _isButtonEnabled = isValid;
    });
    mobileNumber = input; // Update global variable
  }

  /// Sends a POST request to the specified endpoint with the given body.
  Future<http.StreamedResponse> _sendPostRequest(String endpoint, Map<String, String> body) async {
    final headers = {'Content-Type': 'application/json'};
    final request = http.Request('POST', Uri.parse('$uri/user-management-service$endpoint'));
    request.body = json.encode(body);
    request.headers.addAll(headers);
    return await request.send();
  }

  /// Checks if the phone number is available.
  Future<bool> _checkPhoneNumber(String phoneNumber) async {
    try {
      final response = await _sendPostRequest('/api/v1/check/phoneNo', {'phoneNo': phoneNumber});
      return response.statusCode == 200;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check phone number: $e')),
        );
      }
      return false;
    }
  }

  /// Sends an OTP to the phone number.
  Future<bool> _sendOTP(String phoneNumber) async {
    try {
      final response = await _sendPostRequest('/api/v1/mobile/otp/send', {'mobileNumber': phoneNumber});
      if (response.statusCode == 200) {
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: ${response.reasonPhrase}')),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
      return false;
    }
  }

  /// Handles the Continue button press, checking the phone number and sending OTP.
  Future<void> _handleContinueButtonPress(String phoneNumber) async {
    setState(() => _isLoading = true);

    final isValid = await _checkPhoneNumber(phoneNumber);
    if (isValid && context.mounted) {
      final otpSent = await _sendOTP(phoneNumber);
      if (otpSent) {
        try {
          Navigator.pushNamed(
            context,
            '/otp-number',
            arguments: phoneNumber,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Navigation failed: $e')),
            );
          }
        }
      }
    } else if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => _buildErrorDialog(context),
      );
    }

    if (context.mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Sign up with e-Sign',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildUI(context),
    );
  }

  /// Builds the main UI with a scrollable, top-aligned layout.
  Widget _buildUI(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrink-wrap content
              mainAxisAlignment: MainAxisAlignment.start, // Align at top
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch to full width
              children: [
                _buildTextFieldLabel(context),
                const SizedBox(height: 4),
                _buildTextField(context),
                const SizedBox(height: 16),
                _buildContinueButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the label for the text field.
  Widget _buildTextFieldLabel(BuildContext context) {
    return Text(
      'Enter your mobile number',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// Builds the phone number text field.
  Widget _buildTextField(BuildContext context) {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: '01XXXXXXXXX',
        border: OutlineInputBorder(),
      ),
      onChanged: _validatePhoneNumber,
    );
  }

  /// Builds the Continue button.
  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 40,
      child: ElevatedButton(
        onPressed: _isButtonEnabled && !_isLoading
            ? () => _handleContinueButtonPress(_phoneController.text)
            : null,
        style: customButtonStyle(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Color(0xFFC2E7FF),
              )
            : const Text('Continue', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  /// Builds the error dialog for invalid phone numbers.
  Widget _buildErrorDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      title: Text(
        'Error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      content: Text(
        'Mobile number already exists. Please try again.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'OK',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}