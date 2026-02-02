import 'package:crypt/pages/nid_capture.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class NidVerificationPage extends StatelessWidget {
  const NidVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Show message when trying to navigate back
        final snackBar = SnackBar(
          content: const Text('Please complete the registration process first'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Removes the back button
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_card,
                      size: 100,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Position your NID Card in the camera frame. Follow the instructions on your screen.\n\n'
                      '1. Find a well-lit area to focus your NID Card.\n\n'
                      '2. Remove any obstacles between NID Card and Camera.\n\n'
                      '3. Hold your device parallelly to the NID Card.\n\n'
                      '4. Do not move your NID Card away from the outlined area.\n\n'
                      'The verification process will take less than a minute to complete.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 360,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    final cameras = await availableCameras();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraPage(cameras: cameras),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFFC2E7FF),
                    backgroundColor: const Color(0xFF005D99), // Text color
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}