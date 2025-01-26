import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddDiagnosisDoctorScreen extends StatefulWidget {
  final String admissionId;
  final String patientId;
  final Future<void> Function(
          String admissionId, String symptomWithDateTime, String patientId)
      addDoctorDiagnosis;
  final void Function(String patientId, String admissionId)
      fetchDoctorDiagnosis;

  const AddDiagnosisDoctorScreen({
    Key? key,
    required this.admissionId,
    required this.patientId,
    required this.addDoctorDiagnosis,
    required this.fetchDoctorDiagnosis,
  }) : super(key: key);

  @override
  _AddDiagnosisDoctorScreenState createState() =>
      _AddDiagnosisDoctorScreenState();
}

class _AddDiagnosisDoctorScreenState extends State<AddDiagnosisDoctorScreen> {
  final TextEditingController _symptomsController = TextEditingController();

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _addDiagnosis();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _addDiagnosis() async {
    final newSymptom = _symptomsController.text.trim();
    if (newSymptom.isNotEmpty) {
      // Get current date and time
      final String currentDateTime =
          DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

      // Append date and time to the symptom
      final String symptomWithDateTime = '$newSymptom Date: $currentDateTime';

      // Call the API with the appended symptom
      await widget.addDoctorDiagnosis(
        widget.admissionId,
        symptomWithDateTime,
        widget.patientId,
      );

      // Fetch updated diagnosis
      widget.fetchDoctorDiagnosis(widget.patientId, widget.admissionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosis added successfully!')),
      );

      // Clear the input field
      _symptomsController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosis cannot be empty!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Diagnosis by Doctor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _symptomsController,
                decoration: const InputDecoration(
                  labelText: 'Enter diagnosis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _addDiagnosis,
                  child: const Text('Add Diagnosis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
