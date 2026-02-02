import 'package:crypt/pages/fv_instruction.dart';
import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/nidv_instruction.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DobDisplayPage extends StatelessWidget {
  const DobDisplayPage({super.key});

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
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
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
                    children: <Widget>[
                      const SizedBox(height: 0),
                      const Spacer(),
                      SizedBox(
                        width: 320,
                        height: 160,
                        child: Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: const Color(0xFF005D99),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Date of Birth: $dOB',
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'NID: $nidNumber',
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 360,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FaceVerificationPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFFC2E7FF),
                            backgroundColor:
                                const Color(0xFF005D99), // Text color
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // Rounded corners
                            ),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          text: 'Not your NID? ',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 16),
                          children: [
                            TextSpan(
                              text: 'Try again.',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            NidVerificationPage()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
