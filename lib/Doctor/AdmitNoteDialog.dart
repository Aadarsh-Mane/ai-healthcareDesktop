import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdmitPatientDialog extends StatefulWidget {
  final String patientName;
  final Function(String) onAdmit;

  const AdmitPatientDialog(
      {Key? key, required this.patientName, required this.onAdmit})
      : super(key: key);

  @override
  _AdmitPatientDialogState createState() => _AdmitPatientDialogState();
}

class _AdmitPatientDialogState extends State<AdmitPatientDialog> {
  String _selectedLocation = 'General Ward';
  final TextEditingController _otherLocationController =
      TextEditingController();
  bool _showOtherField = false;

  @override
  void dispose() {
    _otherLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Admit Patient',
        style: TextStyle(color: Color(0xFF005F9E), fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify where patient ${widget.patientName} should be admitted:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Radio options for admission locations
            RadioListTile<String>(
              title: const Text('General Ward'),
              value: 'General Ward',
              groupValue: _selectedLocation,
              activeColor: Color(0xFF005F9E),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value!;
                  _showOtherField = false;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('ICU'),
              value: 'ICU',
              groupValue: _selectedLocation,
              activeColor: Color(0xFF005F9E),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value!;
                  _showOtherField = false;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Other'),
              value: 'Other',
              groupValue: _selectedLocation,
              activeColor: Color(0xFF005F9E),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value!;
                  _showOtherField = true;
                });
              },
            ),

            // Show text field if "Other" is selected
            if (_showOtherField)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _otherLocationController,
                  decoration: InputDecoration(
                    labelText: 'Specify location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xFF005F9E), width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF005F9E),
          ),
          onPressed: () {
            final String admitNote = _showOtherField
                ? 'Other: ${_otherLocationController.text.trim()}'
                : _selectedLocation;

            widget.onAdmit(admitNote);
          },
          child: const Text('Admit Patient'),
        ),
      ],
    );
  }
}
