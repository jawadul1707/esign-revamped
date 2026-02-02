import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'global_variable.dart';

Future<Map<String, dynamic>?> generateCertificate() async {
  final url = Uri.parse(
      '$uri/certificate-generation-service/api/v1/certificate/end-user');

  // Validate required fields
  if (accessToken == null ||
      name == null ||
      nidNumber == null ||
      houseIdentifier == null ||
      streetAddress == null ||
      locality == null ||
      state == null ||
      postalCode == null ||
      country == null ||
      email == null ||
      algorithm == null ||
      keySize == null ||
      validityDaysInFuture == null) {
    if (kDebugMode) {
      print('Missing required fields for certificate generation');
    }
    return null;
  }

  // 1. Define the Headers
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  // 2. Define the Request Body
  final Map<String, dynamic> body = {
    "password": "123456",
    "subjectCommonName": name,
    "subjectSerialNumberType": "NID",
    "subjectSerialNumberValue": nidNumber.toString(),
    "subjectHouseIdentifier": houseIdentifier,
    "subjectStreetAddress": streetAddress,
    "subjectLocality": locality,
    "subjectState": state,
    "subjectPostalCode": postalCode,
    "subjectOrganizationUnit": "individual",
    "subjectOrganization": "individual",
    "subjectCountry": country,
    "validityDaysInFuture": validityDaysInFuture,
    "algorithm": algorithm,
    "keySize": keySize,
    "digitalSignature": true,
    "nonRepudiation": true,
    "keyEncipherment": false,
    "dataEncipherment": false,
    "keyAgreement": false,
    "keyCertSign": false,
    "crlSign": false,
    "encipherOnly": false,
    "decipherOnly": false,
    "subjectAltName": email
  };

  try {
    // 3. Send POST request with JSON encoded body
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (kDebugMode) {
        print('Certificate generated successfully!');
        print('Response: ${response.body}');
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Store certificate serial number in global variable
      if (jsonResponse['data'] != null) {
        certificateSerialNumber = jsonResponse['data'] as int;
        if (kDebugMode) {
          print('Certificate Serial Number: $certificateSerialNumber');
        }
      }

      return jsonResponse;
    } else {
      if (kDebugMode) {
        print('Certificate generation error: ${response.statusCode}');
        print('Details: ${response.body}');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Certificate generation connection error: $e');
    }
    return null;
  }
}
