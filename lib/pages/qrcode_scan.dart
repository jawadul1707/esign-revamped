import 'dart:convert';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/qrcode_result.dart';

import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:http/http.dart' as http;


class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String scannedString = ''; // Variable to store the scanned QR code string
  String signerName = ''; // Variable to store the signer name
  String signerEmailAddress = ''; // Variable to store the signer email address
  String signDate = ''; // Variable to store the sign date
  String signReason = ''; // Variable to store the sign reason
  String signLocation = ''; // Variable to store the sign location

  // Function to handle what happens when a QR code is scanned
  void _onQRViewCreated(Code result) async {
    if (result.isValid) {
      setState(() {
        scannedString = result.text!; // Store the scanned string
      });
      //print('Scanned String: $scannedString'); // Print the string

      // Call the API with the appended string
      await _callVerifyAPI(scannedString);
    }
  }

  // Function to call the API with the scanned string
  Future<void> _callVerifyAPI(String scannedString) async {
    try {
      var request = http.Request(
        'GET',
        Uri.parse(
          '$uri/sign-service/api/v1/digital-signature/verify/$scannedString',
        ),
      );

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        //print('API Response: $responseBody');

        Map<String, dynamic> responseJson = jsonDecode(responseBody);
        var data = responseJson['data'];

        // Extract the data
        String signerName = data['signerName'];
        String signerEmailAddress = data['signerEmailAddress'];
        String signDate = data['signDate'];
        String signReason = data['signReason'];
        String signLocation = data['signLocation'];

        // Navigate to the SignDetailsPage with the extracted data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignDetailsPage(
              signerName: signerName,
              signerEmailAddress: signerEmailAddress,
              signDate: signDate,
              signReason: signReason,
              signLocation: signLocation,
            ),
          ),
        );
      } else {
        //print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      //print('Exception occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
      ),
      body: ReaderWidget(
        onScan: (Code result) {
          _onQRViewCreated(result); // Capture the scanned string
        },
      ),
    );
  }
}
