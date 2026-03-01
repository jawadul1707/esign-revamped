import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_variable.dart';
import 'end_user_certificate.dart';

class Package {
  final String packageId;
  final String packageName;
  final int costInCredit;
  final String algorithm;
  final int keySize;
  final int validityDaysInFuture;
  final bool defaultPackage;

  Package({
    required this.packageId,
    required this.packageName,
    required this.costInCredit,
    required this.algorithm,
    required this.keySize,
    required this.validityDaysInFuture,
    required this.defaultPackage,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      packageId: json['packageId'],
      packageName: json['packageName'],
      costInCredit: json['costInCredit'],
      algorithm: json['algorithm'],
      keySize: json['keySize'],
      validityDaysInFuture: json['validityDaysInFuture'],
      defaultPackage: json['defaultPackage'],
    );
  }
}

Future<List<Package>> fetchPackageData() async {
  final url = Uri.parse('$uri/billing-service/api/v1/package');

  final Map<String, String> headers = {
    'Authorization': 'Bearer ${accessToken ?? ""}',
  };

  try {
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> packagesJson = jsonResponse['data'];
      return packagesJson.map((json) => Package.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load packages: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('An error occurred: $e');
  }
}

void showPackageSelector(BuildContext context, VoidCallback onPackageSelected) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PackageSelectorDialog(onPackageSelected: onPackageSelected);
    },
  );
}

class PackageSelectorDialog extends StatefulWidget {
  final VoidCallback onPackageSelected;

  const PackageSelectorDialog({super.key, required this.onPackageSelected});

  @override
  State<PackageSelectorDialog> createState() => _PackageSelectorDialogState();
}

class _PackageSelectorDialogState extends State<PackageSelectorDialog> {
  List<Package>? packages;
  String? selectedPackageId;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final fetchedPackages = await fetchPackageData();
      setState(() {
        packages = fetchedPackages;
        isLoading = false;
        // Auto-select default package if available
        for (var pkg in fetchedPackages) {
          if (pkg.defaultPackage) {
            selectedPackageId = pkg.packageId;
            break;
          }
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Package',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading packages',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : packages == null || packages!.isEmpty
                          ? const Center(child: Text('No packages available'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: packages!.length,
                              itemBuilder: (context, index) {
                                final package = packages![index];
                                final isSelected =
                                    selectedPackageId == package.packageId;

                                return Card(
                                  elevation: isSelected ? 4 : 1,
                                  color: isSelected
                                      ? Colors.blue[50]
                                      : Colors.white,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedPackageId = package.packageId;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Radio<String>(
                                            value: package.packageId,
                                            groupValue: selectedPackageId,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedPackageId = value;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      package.packageName,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.blue[800]
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    if (package.defaultPackage)
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .only(left: 8),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.green[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          'DEFAULT',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .green[800],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Cost: ${package.costInCredit} Credits',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Algorithm: ${package.algorithm}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                Text(
                                                  'Key Size: ${package.keySize} | Validity: ${package.validityDaysInFuture} day(s)',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                  ),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                onPressed: selectedPackageId != null && !isLoading
                    ? () async {
                        // Find the selected package and store its details
                        final selectedPackage = packages!.firstWhere(
                          (pkg) => pkg.packageId == selectedPackageId,
                        );
                        packageId = selectedPackageId;
                        algorithm = selectedPackage.algorithm;
                        keySize = selectedPackage.keySize;
                        validityDaysInFuture =
                            selectedPackage.validityDaysInFuture;

                        // Print package ID
                        if (kDebugMode) {
                          print('Selected Package ID: $packageId');
                        }

                        // Generate certificate
                        final certResult = await generateCertificate();

                        // Print certificate serial number
                        if (kDebugMode) {
                          print(
                              'Generated Certificate Serial Number: $certificateSerialNumber');
                        }

                        if (!context.mounted) return;

                        // Validate certificate generation succeeded
                        if (certResult == null ||
                            certificateSerialNumber == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Failed to generate certificate. Please try again.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).pop();
                        widget.onPackageSelected();
                      }
                    : null,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
