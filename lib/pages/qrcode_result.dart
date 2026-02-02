import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class SignDetailsPage extends StatelessWidget {
  final String signerName;
  final String signerEmailAddress;
  final String signDate;
  final String signReason;
  final String signLocation;

  const SignDetailsPage({
    required this.signerName,
    required this.signerEmailAddress,
    required this.signDate,
    required this.signReason,
    required this.signLocation,
    super.key,
  });

  // Function to format the signDate with month as a name
  String _formatSignDate(String dateStr) {
    try {
      // Parse the date string into a DateTime object
      DateTime dateTime = DateTime.parse(dateStr);

      // Format it to the desired format: yyyy MMMM dd HH:mm (e.g., 2024 October 03 12:38)
      String formattedDate =
          DateFormat("dd MMMM yyyy HH:mm:ss").format(dateTime);

      return formattedDate; // Return the date and time with space between them
    } catch (e) {
      return dateStr; // If parsing fails, return the original string
    }
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF005D99), // Matches the label color
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(12.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2), // Light gray background
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        const SizedBox(height: 15), // Space between fields
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailField('Signed by', signerName),
            _buildDetailField('Signer email address', signerEmailAddress),
            _buildDetailField(
                'Date', _formatSignDate(signDate)), // Apply the formatted date
            _buildDetailField('Reason', signReason),
            _buildDetailField('Location', signLocation),
            const Spacer(),
            const Text(
              'This page only shows information about the digital signature. '
              'To check file integrity, please go to e-sign.com.bd.',
              style: TextStyle(
                fontSize: 14, // Smaller font size
                color: Colors.black54, // Light gray text color for subtlety
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 360,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context,
                      ModalRoute.withName('/')); // Go back to the homepage
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFFFFF),
                  backgroundColor: const Color(0xFF005D99), // Text color
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                ),
                child: const Text(
                  'Go to Homepage',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
