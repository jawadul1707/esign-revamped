import 'package:crypt/pages/global_variable.dart';
import 'package:crypt/pages/pin_input.dart';

import 'package:flutter/material.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Define TextEditingControllers for each field
  final phoneNoController = TextEditingController(text: mobileNumber);
  final emailController = TextEditingController(text: email);
  final fathersNameController = TextEditingController(text: father);
  final mothersNameController = TextEditingController(text: mother);
  final dateOfBirthController = TextEditingController(text: dOB);
  final commonNameController = TextEditingController(text: name);
  final serialNumberTypeController = TextEditingController(text: "NID");
  final serialNumberValueController = TextEditingController(text: nidAsString);
  final houseIdentifierController = TextEditingController(text: "");
  final streetAddressController = TextEditingController(text: "");
  final localityController = TextEditingController(text: "");
  final stateController = TextEditingController(text: "");
  final postalCodeController = TextEditingController(text: "");
  final countryController = TextEditingController(text: "Bangladesh");

  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to the controllers to validate the form in real-time
    houseIdentifierController.addListener(_validateForm);
    streetAddressController.addListener(_validateForm);
    localityController.addListener(_validateForm);
    stateController.addListener(_validateForm);
    postalCodeController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    houseIdentifierController.dispose();
    streetAddressController.dispose();
    localityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    super.dispose();
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
          title: const Text('User Details'),
          automaticallyImplyLeading: false, // Removes the back button
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    readOnly: true,
                    controller: phoneNoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: fathersNameController,
                    decoration: const InputDecoration(labelText: 'Father\'s Name'),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: mothersNameController,
                    decoration: const InputDecoration(labelText: 'Mother\'s Name'),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: dateOfBirthController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                        labelText: 'Date of Birth: (YYYY-MM-DD)'),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: commonNameController,
                    decoration: const InputDecoration(labelText: 'Common Name'),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: serialNumberTypeController,
                    decoration: const InputDecoration(
                        labelText: 'Serial Number Type'),
                  ),
                  TextFormField(
                    readOnly: true,
                    controller: serialNumberValueController,
                    decoration: const InputDecoration(
                        labelText: 'Serial Number Value'),
                  ),
                  TextFormField(
                    controller: houseIdentifierController,
                    decoration: const InputDecoration(labelText: 'House Identifier (Required)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: streetAddressController,
                    decoration: const InputDecoration(labelText: 'Street Address (Required)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: localityController,
                    decoration: const InputDecoration(labelText: 'Locality (Required)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: stateController,
                    decoration: const InputDecoration(labelText: 'State (Required)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: postalCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Postal Code (Required)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: countryController,
                    decoration: const InputDecoration(labelText: 'Country (Required)'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 360,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled
                          ? () {
                              if (_formKey.currentState?.validate() ?? false) {
                                houseIdentifier = houseIdentifierController.text;
                                streetAddress = streetAddressController.text;
                                locality = localityController.text;
                                state = stateController.text;
                                postalCode = postalCodeController.text;
                                country = countryController.text;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PinInputPage(),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFFC2E7FF),
                        backgroundColor: const Color(0xFF005D99), // Text color
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
