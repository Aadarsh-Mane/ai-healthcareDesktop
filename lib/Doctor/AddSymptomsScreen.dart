import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddSymptomScreen extends StatefulWidget {
  final String patientId;
  final String admissionId;

  const AddSymptomScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen> {
  final doctor = DoctorRepository();
  final TextEditingController symptomController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  List<String> symptomSuggestions = [];
  String selectedSymptoms = ''; // Store as a single string
  bool isLoadingSuggestions = false;

  Future<void> _fetchSymptomSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        symptomSuggestions = [];
      });
      return;
    }

    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          symptomSuggestions = List<String>.from(data['suggestions'] ?? []);
        });
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() {
        symptomSuggestions = [];
      });
    } finally {
      setState(() {
        isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _addSymptom() async {
    // If the symptom entered by the user is not in the suggestions, add it
    final newSymptom = symptomSuggestions.contains(symptomController.text)
        ? symptomController.text
        : symptomController.text;

    // Get current date and time
    final String currentDateTime =
        DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

    // Append the current date and time to the symptom string
    final String fullSymptom =
        '$newSymptom - $currentDateTime'; // Append date to symptoms

    try {
      await doctor.addSymptomsByDoctor(
        widget.admissionId,
        fullSymptom, // Pass the fullSymptom with the date appended
        widget.patientId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom added successfully')),
      );

      // Clear fields for new symptom without popping the screen
      setState(() {
        selectedSymptoms = '';
      });
    } catch (e) {
      print('Error adding symptom: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(true); // Navigate back on Escape
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _addSymptom(); // Add prescription on Enter
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Symptoms'),
        backgroundColor: Colors.teal,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Symptoms Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.teal,
                      ),
                ),
                const SizedBox(height: 20),

                // Display selected symptoms as chips
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: selectedSymptoms
                      .split(', ')
                      .map((symptom) => Chip(
                            label: Text(symptom,
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.teal,
                            onDeleted: () {
                              setState(() {
                                selectedSymptoms = selectedSymptoms
                                    .split(', ')
                                    .where((e) => e != symptom)
                                    .join(', ');
                              });
                            },
                          ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // Symptom name field with suggestions
                _buildTextField(
                  controller: symptomController,
                  label: 'Symptom Name',
                  // onChanged: _fetchSymptomSuggestions,
                ),

                if (isLoadingSuggestions) const LinearProgressIndicator(),
                if (symptomSuggestions.isNotEmpty) _buildSuggestionsList(),

                const SizedBox(height: 20),

                // Submit button
                ElevatedButton(
                  onPressed: _addSymptom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // Button color
                    padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 30), // Added horizontal padding
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17), // Rounded corners
                    ),
                    minimumSize: const Size(double.infinity,
                        50), // Ensures the button is wide enough
                  ),
                  child: const Text(
                    'Add Symptom',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight
                          .w600, // Slightly bolder text for better visibility
                      color:
                          Colors.white, // Ensure text is readable on the button
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to create styled text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // Helper function to build the symptom suggestions list
  Widget _buildSuggestionsList() {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      height: 200,
      child: ListView.builder(
        itemCount: symptomSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = symptomSuggestions[index];
          return ListTile(
            title: Text(suggestion),
            onTap: () {
              setState(() {
                if (selectedSymptoms.isEmpty) {
                  selectedSymptoms = suggestion;
                } else {
                  selectedSymptoms += ', ' + suggestion;
                }
                symptomController.clear();
                symptomSuggestions = [];
              });
            },
          );
        },
      ),
    );
  }
}
