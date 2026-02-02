import 'dart:convert';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/user_details.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NIDInfoFetcher extends StatefulWidget {
  const NIDInfoFetcher({super.key});

  @override
  _NIDInfoFetcherState createState() => _NIDInfoFetcherState();
}

class _NIDInfoFetcherState extends State<NIDInfoFetcher> {
  bool _isLoading = false; // State to manage loading

  Future<void> getNIDInfo() async {
    setState(() {
      _isLoading = true; // Start loading after pressing the button
    });

    var headers = {'Content-Type': 'application/json'};

    var request = http.Request(
      'POST',
      Uri.parse('$uri/user-management-service/api/v1/nid/fetch'),
    );
    request.body = json.encode({
      "dob": dOB,
      "nid": nidNumber,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();
      Map<String, dynamic> responseBody = jsonDecode(responseString);

      name = responseBody['name'];
      father = responseBody['father'];
      mother = responseBody['mother'];
      presentAddress = responseBody['presentAddress'];
      permanentAddress = responseBody['permanentAddress'];

      // Redirect to UserDetailsPage after fetching data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserDetailsPage(),
        ),
      );
    } else {
      print(response.reasonPhrase);
    }

    setState(() {
      _isLoading = false; // Stop loading after fetching data
    });
  }

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
          elevation: 0,
          automaticallyImplyLeading: false, // Remove the back button
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
                      Icons.check_circle_outline,
                      size: 100,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    // Text(
                    //   'Instructions',
                    //   style: TextStyle(
                    //     fontSize: 24,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // SizedBox(height: 16),
                    Text(
                      'The Verification Is Complete.',
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
                  onPressed: _isLoading
                      ? null
                      : () async {
                          await getNIDInfo();
                        },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFFC2E7FF),
                    backgroundColor: const Color(0xFF005D99), // Text color
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF005D99)), // Set the color to match button text
                        )
                      : const Text(
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
