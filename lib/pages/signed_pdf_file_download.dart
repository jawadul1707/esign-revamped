import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'global_variable.dart';

Future<String?> signDocument({
  required String filePath,
  required int pageNumber,
}) async {
  final url = Uri.parse('$uri/sign-service/api/v1/digital-signature/sign');

  // Validate required fields
  if (accessToken == null ||
      userid == null ||
      packageId == null ||
      certificateSerialNumber == null ||
      signatureX == null ||
      signatureY == null) {
    if (kDebugMode) {
      print('❌ Missing required fields for signing document');
      print('  - accessToken: ${accessToken != null ? "✓" : "✗"}');
      print('  - userid: ${userid ?? "null"}');
      print('  - packageId: ${packageId ?? "null"}');
      print(
          '  - certificateSerialNumber: ${certificateSerialNumber ?? "null"}');
      print('  - signatureX: ${signatureX ?? "null"}');
      print('  - signatureY: ${signatureY ?? "null"}');
    }
    return null;
  }

  if (kDebugMode) {
    print('🔐 SIGN DOCUMENT REQUEST DEBUG INFO:');
    print('═══════════════════════════════════════');
    print('📍 URL: $url');
    print('👤 User ID: $userid');
    print('📦 Package ID: $packageId');
    print('🔢 Certificate Serial Number: $certificateSerialNumber');
    print('🔒 Password: 12345678');
    print('📄 Page Number: $pageNumber');
    print('📍 Signature Position X: ${signatureX!.toStringAsFixed(2)}');
    print('📍 Signature Position Y: ${signatureY!.toStringAsFixed(2)}');
    print('📌 Reason: eSign test');
    print('📍 Location: Bangladesh');
    print('📁 File Path: $filePath');
    print('🔑 FULL Access Token:');
    print(accessToken);
    print('═══════════════════════════════════════');
    print('⚠️ COMPARE ALL VALUES ABOVE WITH BRUNO!');
    print('═══════════════════════════════════════');
  }

  // 1. Create the Multipart Request
  var request = http.MultipartRequest('POST', url);

  // 2. Add Text Fields (Bruno order: fields before files)
  request.fields.addAll({
    'userId': userid!,
    'packageId': packageId!,
    'certificateSerialNumber': certificateSerialNumber.toString(),
    'password': '123456',
    'reason': 'eSign test',
    'location': 'Bangladesh',
    'pageNumber': pageNumber.toString(),
    'signaturePositionX': signatureX!.toStringAsFixed(2),
    'signaturePositionY': signatureY!.toStringAsFixed(2),
  });

  if (kDebugMode) {
    print('📝 Request Fields:');
    request.fields.forEach((key, value) {
      print('  - $key: $value');
    });
  }

  // 3. Add the File (using fromPath like Bruno)
  if (await File(filePath).exists()) {
    final file = File(filePath);
    final fileSize = await file.length();

    if (kDebugMode) {
      print('📄 File Info:');
      print('  - Path: $filePath');
      print('  - Name: ${path.basename(filePath)}');
      print('  - Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
    }

    // Use fromPath exactly like Bruno
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    if (kDebugMode) {
      print('✅ File successfully added using fromPath (Bruno method)');
    }
  } else {
    if (kDebugMode) {
      print('❌ File not found at specified path: $filePath');
    }
    return null;
  }

  // 4. Add Headers LAST (Bruno order: headers after files)
  var headers = {
    'Authorization': 'Bearer $accessToken',
  };
  request.headers.addAll(headers);

  // 5. Send the Request
  try {
    if (kDebugMode) {
      print('🚀 Sending request...');
      print('📦 Total request fields: ${request.fields.length}');
      print('📦 Total files attached: ${request.files.length}');
      print('📋 Request headers:');
      request.headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          print('  - $key: Bearer [TOKEN_PRESENT]');
        } else {
          print('  - $key: $value');
        }
      });
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode) {
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print(
          '📥 Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
    }

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('✅ Document signed successfully!');
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final String? base64Data = jsonResponse['data'];

      if (base64Data != null) {
        // Decode base64 to bytes
        final bytes = base64Decode(base64Data);

        // Generate new filename with -signed suffix
        final originalFileName = path.basenameWithoutExtension(filePath);
        final newFileName = '${originalFileName}-signed.pdf';

        // Get directory to save the file
        final directory = await getApplicationDocumentsDirectory();
        final newFilePath = path.join(directory.path, newFileName);

        // Write the file
        final newFile = File(newFilePath);
        await newFile.writeAsBytes(bytes);

        if (kDebugMode) {
          print('💾 Signed PDF saved to: $newFilePath');
        }

        return newFilePath;
      }
    } else if (response.statusCode == 403) {
      if (kDebugMode) {
        print('❌ 403 FORBIDDEN ERROR - Authorization Issue');
        print('═══════════════════════════════════════');
        print('Possible causes:');
        print('1. Access token is invalid or expired');
        print('2. User does not have permission to sign documents');
        print('3. Certificate serial number does not belong to this user');
        print('4. Package ID is invalid or not purchased');
        print('5. User ID mismatch');
        print('═══════════════════════════════════════');
        print('Response Body: ${response.body}');
      }
    } else {
      if (kDebugMode) {
        print('❌ Failed to sign. Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Exception occurred while signing: $e');
      print('Stack trace:');
      print(StackTrace.current);
    }
  }

  return null;
}

class SignedPdfResultScreen extends StatelessWidget {
  final String signedPdfPath;

  const SignedPdfResultScreen({super.key, required this.signedPdfPath});

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      // Get Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to external storage
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadDir = Directory('${externalDir.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
        }
      }

      final fileName = path.basename(signedPdfPath);
      final destinationPath = path.join(directory.path, fileName);

      // Copy file to downloads
      final sourceFile = File(signedPdfPath);
      await sourceFile.copy(destinationPath);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded to: $destinationPath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading file: $e');
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(signedPdfPath);

    return Scaffold(
      backgroundColor: const Color(0xFFC2E7FF),
      appBar: AppBar(
        title: const Text('Signed Document'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Document Signed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _downloadPdf(context),
                  icon: const Icon(Icons.download, size: 24),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back, size: 24),
                  label: const Text('Back to Viewer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
