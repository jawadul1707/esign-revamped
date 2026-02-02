import 'dart:convert';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/post_registration.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

class PinInputPage extends StatefulWidget {
  const PinInputPage({super.key});

  @override
  _PinInputPageState createState() => _PinInputPageState();
}

class _PinInputPageState extends State<PinInputPage> {
  final _phoneController1 = TextEditingController();
  final _phoneController2 = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  void _storePinNumber1(String input) {
    pin1 = input;
    //print(pin1);
  }

  void _storePinNumber2(String input) {
    pin2 = input;
    //print(pin2);
    if (pin1 == pin2) {
      setState(() {
        _isButtonEnabled = true;
      });
    }
  }

  // Function to send an OTP
  Future<void> _createUser() async {
    //print("shaka laka boom boom");
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('$uri/user-management-service/api/v1/create/user'));
    request.body = json.encode({
      "phoneNo": mobileNumber,
      "email": email,
      "password": pin1,
      "fathersName": father,
      "mothersName": mother,
      "dateOfBirth": dOB,
      "commonName": name,
      "serialNumberType": "NID",
      "serialNumberValue": nidAsString,
      "houseIdentifier": houseIdentifier,
      "streetAddress": streetAddress,
      "locality": locality,
      "state": state,
      "postalCode": postalCode,
      "country": country,
      "organizationUnit": "individual",
      "organization": "individual",
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 201) {
      //print(await response.stream.bytesToString());
      String responseString = await response.stream.bytesToString();
      Map<String, dynamic> responseBody = jsonDecode(responseString);

      userid = responseBody['data']['userId'];
      // print("userid $userid");
      // print("userid retrieved succeesfully");
    } else {
      // print(response.reasonPhrase);
    }
  }

  // Future<void> _getPackageId() async {
  //   var headers = {'Content-Type': 'application/json'};
  //   var request = http.Request(
  //       'GET',
  //       Uri.parse(
  //           '$uri/subscription-management-service/api/v1/package/default'));

  //   request.headers.addAll(headers);

  //   http.StreamedResponse response = await request.send();

  //   if (response.statusCode == 200) {
  //     //print(await response.stream.bytesToString());
  //     String responseString = await response.stream.bytesToString();
  //     Map<String, dynamic> responseBody = jsonDecode(responseString);

  //     packageid = responseBody['data']['packageId'];
  //     // print("package id: $packageid");
  //     // print("package id retrieved in variable");
  //   } else {
  //     // print(response.reasonPhrase);
  //   }
  // }

  // Future<void> _subscriberCreation() async {
  //   var headers = {'Content-Type': 'application/json'};
  //   var request = http.Request(
  //       'POST',
  //       Uri.parse(
  //           '$uri/subscription-management-service/api/v1/subscription/subscribe'));
  //   request.body = json.encode({
  //     "userId": userid,
  //     "packageId": packageid,
  //   });

  //   request.headers.addAll(headers);

  //   http.StreamedResponse response = await request.send();

  //   if (response.statusCode == 200) {
  //     //print(await response.stream.bytesToString());
  //     print("package id and user id sent successfully");
  //   } else {
  //     // print(response.statusCode);
  //     // print(response.reasonPhrase);
  //     // print(await response.stream.bytesToString());
  //   }
  // }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Set Pin Number'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter a 6-digit PIN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Pinput(
                    length: 6,
                    controller: _phoneController1, // use controller here
                    obscureText: true,
                    defaultPinTheme: defaultPinTheme,
                    onChanged: _storePinNumber1,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Re-enter the PIN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Pinput(
                    length: 6,
                    controller: _phoneController2, // use controller here
                    obscureText: true,
                    defaultPinTheme: defaultPinTheme,
                    onChanged: _storePinNumber2,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 360,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled && !_isLoading
                          ? () async {
                              setState(() {
                                _isLoading = true; // Start loading
                              });

                              try {
                                //await _getPackageId();
                                await _createUser();
                                //await _subscriberCreation();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EndPage(),
                                  ),
                                );
                              } catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('An error occurred: $error'),
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false; // Stop loading
                                });
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
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF005D99)),
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
    _phoneController1.dispose();
    _phoneController2.dispose();
    super.dispose();
  }
}
