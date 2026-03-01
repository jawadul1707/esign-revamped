import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'global_variable.dart';
import 'package_selector.dart';
import 'signed_pdf_file_download.dart';

class PdfViewer extends StatefulWidget {
  const PdfViewer({super.key});

  @override
  PdfViewerState createState() => PdfViewerState();
}

class PdfViewerState extends State<PdfViewer> {
  File? selectedPdf;
  bool _isLoading = true;
  PDFViewController? _pdfController;
  int currentPage = 0;
  int totalPages = 0;
  final GlobalKey _pdfViewKey = GlobalKey();
  Offset? _signaturePosition;

  static const double topPadding = 100;
  static const double horizontalPadding = 20;
  static const double bottomPadding = 100;

  @override
  void initState() {
    super.initState();
    _pickPdf();
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        selectedPdf = file;
        _isLoading = true;
        currentPage = 0;
        totalPages = 0;
        _signaturePosition = null;
        _pdfController = null;
        signatureX = null;
        signatureY = null;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isLoading = false);
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 0) {
      _pdfController?.setPage(currentPage - 1);
      setState(() {
        _signaturePosition = null;
        signatureX = null;
        signatureY = null;
      });
    }
  }

  void _goToNextPage() {
    if (currentPage < totalPages - 1) {
      _pdfController?.setPage(currentPage + 1);
      setState(() {
        _signaturePosition = null;
        signatureX = null;
        signatureY = null;
      });
    }
  }

  void _handleTap(TapDownDetails details) {
    final RenderBox? renderBox =
        _pdfViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && _pdfController != null) {
      final Offset localPosition =
          renderBox.globalToLocal(details.globalPosition);
      final Size size = renderBox.size;

      if (localPosition.dx >= 0 &&
          localPosition.dx <= size.width &&
          localPosition.dy >= 0 &&
          localPosition.dy <= size.height) {
        // Use hardcoded page size as specified
        const double pdfWidth = 468.0;
        const double pdfHeight = 720.0;

        final double pdfX = (localPosition.dx / size.width) * pdfWidth;
        final double pdfY = (1 - localPosition.dy / size.height) * pdfHeight;

        // PDF is positioned at left:20, top:200, so adjust signature position
        final double desiredLeft = 20 + localPosition.dx - 30;
        final double desiredTop = 200 + localPosition.dy - 40;

        final double clampedLeft = desiredLeft.clamp(20, 20 + size.width - 80);
        final double clampedTop = desiredTop.clamp(180, 200 + size.height - 60);

        setState(() {
          _signaturePosition = Offset(clampedLeft, clampedTop);
        });

        // Persist tap coordinates globally (convert double to int)
        signatureX = pdfX.round();
        signatureY = pdfY.round();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tapped at: (${pdfX.toStringAsFixed(2)}, ${pdfY.toStringAsFixed(2)})',
            ),
          ),
        );
      }
    }
  }

  // Helper Method for Icon Buttons
  Widget _buildIconButton({
    required IconData icon,
    required double x,
    required double y,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 28),
      tooltip: tooltip,
      onPressed: () {
        setState(() {
          _signaturePosition = _getCornerPosition(x, y);
          signatureX = x.round();
          signatureY = y.round();
        });

        // Feedback for the user
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Placed at $tooltip: ($x, $y)'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  // Function to calculate signature position for a corner
  // moved out of build() so other methods can call it
  Offset _getCornerPosition(double pdfX, double pdfY) {
    final Size screenSize = MediaQuery.of(context).size;
    final double containerWidth = screenSize.width - 40;
    final double containerHeight = screenSize.height - 340; // 200 + 140

    const double pdfWidth = 468.0;
    const double pdfHeight = 720.0;
    final double localDx = (pdfX / pdfWidth) * containerWidth;
    final double localDy =
        containerHeight - (pdfY / pdfHeight) * containerHeight;
    final double desiredLeft = 20 + localDx - 30;
    final double desiredTop = 200 + localDy - 20;
    final double clampedLeft =
        desiredLeft.clamp(20, 20 + containerWidth - 80);
    final double clampedTop =
        desiredTop.clamp(180, 200 + containerHeight - 60);
    return Offset(clampedLeft, clampedTop);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double containerWidth = screenSize.width - 40;
    final double containerHeight = screenSize.height - 340; // 200 + 140

    return Scaffold(
      backgroundColor: const Color(0xFFC2E7FF),
      body: selectedPdf == null
          ? const Center(child: Text('Please select a PDF file'))
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onTapDown: _handleTap,
                  child: Stack(
                    children: [
                      // Position the PDF with minimal padding, fitted to width
                      Positioned(
                        top: 200,
                        left: 20,
                        right: 20,
                        bottom: 140,
                        child: PDFView(
                          key: _pdfViewKey,
                          filePath: selectedPdf!.path,
                          enableSwipe: false,
                          swipeHorizontal: false,
                          fitEachPage: true,
                          fitPolicy: FitPolicy.WIDTH,
                          autoSpacing: true,
                          pageSnap: true,
                          pageFling: false,
                          preventLinkNavigation: true,
                          onViewCreated: (controller) {
                            _pdfController = controller;
                          },
                          onRender: (pages) {
                            setState(() => totalPages = pages ?? 0);
                          },
                          onPageChanged: (page, total) {
                            setState(() {
                              currentPage = page ?? 0;
                              totalPages = total ?? 0;
                              _signaturePosition = null;
                              signatureX = null;
                              signatureY = null;
                            });
                          },
                        ),
                      ),

                      // 4 directional icon buttons for corners
                      Positioned(
                        top: 150,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Top Left
                            _buildIconButton(
                              icon: Icons.north_west,
                              x: 0,
                              y: 720,
                              tooltip: 'Top Left',
                            ),
                            // Top Right
                            _buildIconButton(
                              icon: Icons.north_east,
                              x: 468,
                              y: 720,
                              tooltip: 'Top Right',
                            ),
                            // Bottom Left
                            _buildIconButton(
                              icon: Icons.south_west,
                              x: 0,
                              y: 0,
                              tooltip: 'Bottom Left',
                            ),
                            // Bottom Right
                            _buildIconButton(
                              icon: Icons.south_east,
                              x: 468,
                              y: 0,
                              tooltip: 'Bottom Right',
                            ),
                          ],
                        ),
                      ),

                      if (_signaturePosition != null)
                        Positioned(
                          left: _signaturePosition!.dx,
                          top: _signaturePosition!.dy,
                          child: Image.asset(
                            'assets/signature_placeholder.png',
                            width: 80,
                            height: 80,
                          ),
                        ),

                      /// CONTROLS - Top bar with folder picker on left, page nav in middle
                      Positioned(
                        top: MediaQuery.of(context).padding.top,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.folder_open),
                              onPressed: _pickPdf,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (totalPages > 1)
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left,
                                        size: 28),
                                    onPressed: currentPage > 0
                                        ? _goToPreviousPage
                                        : null,
                                  ),
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: Text(
                                      '${currentPage + 1} / $totalPages',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                if (totalPages > 1)
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right,
                                        size: 28),
                                    onPressed: currentPage < totalPages - 1
                                        ? _goToNextPage
                                        : null,
                                  ),
                              ],
                            ),
                            const SizedBox(
                                width: 48), // Balance for folder icon
                          ],
                        ),
                      ),

                      // Primary action button placed below the PDF viewer
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 80,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            if (signatureX == null || signatureY == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please select signature position first'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            showPackageSelector(context, () async {
                              // Show loading dialog
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              );

                              // Sign the document
                              final signedPdfPath = await signDocument(
                                filePath: selectedPdf!.path,
                                pageNumber: currentPage + 1, // 1-indexed
                              );

                              // Close loading dialog
                              if (!context.mounted) return;
                              Navigator.of(context).pop();

                              if (signedPdfPath != null) {
                                // Navigate to result screen
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignedPdfResultScreen(
                                      signedPdfPath: signedPdfPath,
                                    ),
                                  ),
                                );
                              } else {
                                // Show error
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to sign document'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            });
                          },
                          child: const Text('Sign Document'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
