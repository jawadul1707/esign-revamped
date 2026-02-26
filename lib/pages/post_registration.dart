import 'package:crypt/pages/home.dart';
import 'package:flutter/material.dart';

class EndPage extends StatelessWidget {
  const EndPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Do not create a new MaterialApp – use the existing app's theme and
    // navigation stack.  This prevents theme overrides that changed button
    // colors when returning from the thank-you screen.
    return const ThankYouPage();
  }
}

class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('e-Sign Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4, // Slight shadow for the card
              margin: const EdgeInsets.all(16.0), // Margin around the card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              color: const Color(0xFFC2E7FF),
              child: const Padding(
                padding: EdgeInsets.all(16.0), // Padding inside the card
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Thank you for registering with e-Sign.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005D99),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10), // Space between text
                    Text(
                      'Return to the homepage and log in to access your account.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF005D99)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Space between the card and button
            SizedBox(
              width: 324,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  // Pop all previous routes and go to the root (home) route
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005D99), // Button background color
                  foregroundColor: const Color(0xFFC2E7FF), // Button text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded button
                  ),
                ),
                child: const Text('Return to Homepage'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}