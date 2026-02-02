import 'dart:convert';
import 'dart:io';

import 'package:crypt/pages/fv_success.dart';
import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/fv_failure.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class SelfiePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SelfiePage({required this.cameras, super.key}); 

  @override
  _SelfiePageState createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> {

  late CameraController _selfiecontroller;
  late Future<void> _initializeControllerFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Reset the imageLocation when navigating to this page
    selfieLocation = null;

    if (widget.cameras.isEmpty) {
      // Handle the case when there are no cameras available
      //print('No cameras available');
      return;
    }

    // Find the front camera
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    _selfiecontroller = CameraController(
      frontCamera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _selfiecontroller.initialize();
  }

  @override
  void dispose() {
    _selfiecontroller.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _initializeControllerFuture;
      final image = await _selfiecontroller.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, '${DateTime.now()}.png');
      await image.saveTo(imagePath);

      setState(() {
        selfieLocation = imagePath;
        //print(imageLocation);
        //print(selfieLocation);
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '$uri/user-management-service/api/v1/face/recognition'),
      );

      request.files.add(
          await http.MultipartFile.fromPath('sourceImage', clearImageLocation!));
      request.files.add(
          await http.MultipartFile.fromPath('targetImage', selfieLocation!));

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        //String responseString = await response.stream.bytesToString();
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['statusCode'] == "OK") {
          // Navigate to the second page if face matched
          Navigator.push(this.context, MaterialPageRoute(builder: (context) => const NIDInfoFetcher()));
        } else {
          // Navigate to the third page if face didn't match
          Navigator.push(this.context, MaterialPageRoute(builder: (context) => const InvalidPage()));
        }
        
        //print(responseBody);
        //Navigator.push(
          //this.context,
          //MaterialPageRoute(builder: (context) => const NIDInfoFetcher()),
        //);
      } else {
        //print(response.reasonPhrase);
      }
    } catch (e) {
      //print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Take a Picture')),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return selfieLocation == null
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(1.0, 1.0, 1.0), // Flip the preview
                        child: CameraPreview(_selfiecontroller),
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0), // Flip the captured image
                        child: Image.file(File(selfieLocation!)),
                      );
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
              padding: EdgeInsets.only(bottom: 45.0), // Space between text and button
              child: Text(
                "Take a photo of your face",
                style: TextStyle(
                  fontSize: 15, // Adjust the font size as needed
                  color: Color(0xFF005D99), // Text color
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Align text to the center
              ),
            ),
            GestureDetector(
              onTap: _takeSelfie,
              child: Container(
                width: 100.0,  // Increased size of the button
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Keep the button centered
    );
  }
}

// CustomPainter for drawing the transparent cutout
class CutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Outer rectangle that covers the entire screen
    final outerRect = Offset.zero & size;

    // Define the position and size of the oval
    const double ovalWidth = 250; // Width of the oval
    const double ovalHeight = 300; // Height of the oval
    final double left = (size.width - ovalWidth) / 2; // Center the oval horizontally
    const double top = 50; // Set the top position of the oval

    // Define the oval area
    final Rect ovalRect = Rect.fromLTWH(left, top, ovalWidth, ovalHeight);

    // Paint the outer area with a semi-transparent color
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw the outer area excluding the oval
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(outerRect), // Outer area
        Path()..addOval(ovalRect), // Oval area
      ),
      paint,
    );

    // Draw border around the oval
    final borderPaint = Paint()
      ..color = const Color(0xFF005D99)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}