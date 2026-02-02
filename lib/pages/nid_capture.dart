import 'dart:convert';
import 'dart:io';

import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/dob_nid_display.dart';
import 'package:crypt/pages/nid_failure.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraPage({required this.cameras, super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  //VARIABLES
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Reset the imageLocation when navigating to this page
    imageLocation = null;

    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndUpload() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, '${DateTime.now()}.png');
      await image.saveTo(imagePath);

      setState(() {
        imageLocation = imagePath;
        print(imagePath);
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$uri/user-management-service/api/v1/detect-text'),
      );

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();

        // Parse the JSON response
        Map<String, dynamic> responseBody = jsonDecode(responseString);

        // Extract values and store them in separate variables
        String? dob = responseBody['dob'];
        int? nid = responseBody['nid'] as int?; // Cast to int for type safety

        if (dob == null || nid == null) {
          // Redirect to nid_failure page if either value is null
          Navigator.push(
            this.context,
            MaterialPageRoute(builder: (context) => const NIDInvalidPage()),
          );
        } else {
          dOB = dob;
          nidNumber = nid;

          // Fetch additional NID details
          await fetchNidDetails();

          Navigator.push(
            this.context,
            MaterialPageRoute(builder: (context) => const DobDisplayPage()),
          );
        }
      } else {
        print(response.reasonPhrase);
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchNidDetails() async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
        'POST',
        Uri.parse(
            'https://staging-gw.e-sign.com.bd:9100/user-management-service/api/v1/nid/fetch'),
      );
      request.body = json.encode({"dob": dOB, "nid": nidNumber});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        Map<String, dynamic> responseBody = jsonDecode(responseString);

        // Extract the photo in base64 format
        String? base64Photo = responseBody['photo'];

        if (base64Photo != null) {
          // Decode the base64 string to binary data
          List<int> photoBytes = base64Decode(base64Photo);

          // Get the directory to save the file
          final directory = await getApplicationDocumentsDirectory();
          final photoPath = join(directory.path, 'nid_photo.png');

          // Write the binary data to the file
          File photoFile = File(photoPath);
          await photoFile.writeAsBytes(photoBytes);

          print("Photo saved at: $photoPath");
          clearImageLocation = photoPath;
        } else {
          print("Photo not found in response.");
        }
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Exception caught: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return imageLocation == null
                    ? CameraPreview(_controller)
                    : Image.file(File(imageLocation!));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),

          // Custom painter for transparent rectangle
          Opacity(
            opacity: 1, // Opacity for the outer area
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: CutoutPainter(),
            ),
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Bottom blue bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 140, // Height of the bottom bar
              width: double.infinity,
              color: const Color(0xFFC2E7FF), // Change the color to blue
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0), // Adjust height as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(
                  bottom: 45.0), // Space between text and button
              child: Text(
                "Take a photo of the front of your NID card",
                style: TextStyle(
                  fontSize: 15, // Adjust the font size as needed
                  color: Color(0xFF005D99), // Text color
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Align text to the center
              ),
            ),
            GestureDetector(
              onTap: _takePictureAndUpload,
              child: Container(
                width: 100.0, // Increased size of the button
                height: 100.0, // Ensuring a circular shape
                decoration: const BoxDecoration(
                  shape: BoxShape.circle, // Makes the button circular
                  color: Color(0xFF005D99), // Background color
                ),
                child: const Icon(
                  Icons.camera,
                  size: 50, // Increased icon size
                  color: Color(0xFFC2E7FF), // Icon color
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // Keep the button centered
    );
  }
}

// CustomPainter for drawing the transparent cutout
class CutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Outer rectangle that covers the entire screen
    final outerRect = Offset.zero & size;

    // Define the size and position of the cut-out rectangle
    const double cutoutWidth = 300;
    const double cutoutHeight = 200;
    final double left = (size.width - cutoutWidth) / 2;
    final double top = (size.height - cutoutHeight) / 2;

    // Define the cut-out area as a rounded rectangle (RRect)
    final RRect cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight),
      const Radius.circular(24), // Adjust the corner radius here
    );

    // Paint the outer area with a semi-transparent color
    final paint = Paint()
      ..color = Colors.white //.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw the outer area excluding the cutout rounded rectangle
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(outerRect), // Outer area
        Path()..addRRect(cutoutRect), // Cut-out rounded rectangle
      ),
      paint,
    );

    // Draw border around the cut-out rounded rectangle
    final borderPaint = Paint()
      ..color = const Color(0xFF005D99)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    canvas.drawRRect(cutoutRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
