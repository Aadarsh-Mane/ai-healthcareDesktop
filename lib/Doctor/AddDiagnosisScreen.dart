import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  List<String> diagnosisSuggestions = [];
  List<String> selectedDiagnoses = [];
  bool isLoadingSuggestions = false;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _fetchDiagnosisSuggestions() async {
    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
          Uri.parse('${KVM_URL}/doctors/getDiagnosis/${widget.patientId}'));
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          diagnosisSuggestions = List<String>.from(data['diagnosis'] ?? []);
        });
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() {
        diagnosisSuggestions = [];
      });
    } finally {
      setState(() {
        isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _addDiagnosis() async {
    // Add manually typed diagnosis if it's not empty
    if (_symptomsController.text.isNotEmpty) {
      selectedDiagnoses.add(_symptomsController.text.trim());
    }

    if (selectedDiagnoses.isNotEmpty) {
      final String currentDateTime =
          DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());
      final String symptomWithDateTime =
          '${selectedDiagnoses.join(', ')} - Date: $currentDateTime';

      await widget.addDoctorDiagnosis(
        widget.admissionId,
        symptomWithDateTime,
        widget.patientId,
      );

      widget.fetchDoctorDiagnosis(widget.patientId, widget.admissionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosis added successfully!')),
      );

      setState(() {
        selectedDiagnoses.clear();
        _symptomsController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a diagnosis!')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDiagnosisSuggestions();
  }

  @override
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display selected diagnoses (including manual entries)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: selectedDiagnoses
                    .map((diagnosis) => Chip(
                          label: Text(diagnosis),
                          backgroundColor: Colors.teal,
                          onDeleted: () {
                            setState(() {
                              selectedDiagnoses.remove(diagnosis);
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _fetchDiagnosisSuggestions,
                  child: const Text('AI Suggestions'),
                ),
              ),
              // Show loading indicator if suggestions are being fetched
              if (isLoadingSuggestions)
                const Center(child: CircularProgressIndicator()),

              // Show diagnosis suggestions
              if (!isLoadingSuggestions)
                Column(
                  children: diagnosisSuggestions.map((diagnosis) {
                    return CheckboxListTile(
                      title: Text(diagnosis),
                      value: selectedDiagnoses.contains(diagnosis),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value != null && value) {
                            selectedDiagnoses.add(diagnosis);
                          } else {
                            selectedDiagnoses.remove(diagnosis);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // Input field for manual diagnosis entry (always visible)
              const SizedBox(height: 10),
              TextField(
                controller: _symptomsController,
                decoration: const InputDecoration(
                  labelText: 'Enter diagnosis manually',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Add Diagnosis button
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

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _addDiagnosis();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
