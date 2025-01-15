import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  List<String> medicineSuggestions = [];
  String selectedMedicines = ''; // Store as a single string
  bool isLoadingSuggestions = false;

  // Dropdown values for dosage (1 to 5)

  Future<void> _fetchMedicineSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        medicineSuggestions = [];
      });
      return;
    }

    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${VERCEL_URL}/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          medicineSuggestions = List<String>.from(data['suggestions'] ?? []);
        });
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() {
        medicineSuggestions = [];
      });
    } finally {
      setState(() {
        isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _addSymptom() async {
    // Get current date and time
    final String currentDateTime =
        DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

    // Append the current date and time to the symptom string
    final String newSymptom =
        '$selectedMedicines - $currentDateTime'; // Append date to symptoms

    try {
      await doctor.addSymptomsByDoctor(
        widget.admissionId,
        newSymptom, // Pass the newSymptom with the date appended
        widget.patientId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription added successfully')),
      );

      // Clear fields for new prescription without popping the screen
      setState(() {
        selectedMedicines = '';
      });
    } catch (e) {
      print('Error adding prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  // Future<void> _addSymptom() async {
  //   final String newSymptom = selectedMedicines; // Define the variable

  //   try {
  //     await doctor.addSymptomsByDoctor(
  //       widget.admissionId,
  //       newSymptom, // Pass the variable
  //       widget.patientId,
  //     );

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Prescription added successfully')),
  //     );

  //     // Clear fields for new prescription without popping the screen
  //     setState(() {
  //       selectedMedicines = '';
  //     });
  //   } catch (e) {
  //     print('Error adding prescription: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   }
  // }

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
      body: Padding(
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

              // Display selected medicines as chips above the medicine name field
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: selectedMedicines
                    .split(', ')
                    .map((medicine) => Chip(
                          label: Text(medicine,
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.teal,
                          onDeleted: () {
                            setState(() {
                              selectedMedicines = selectedMedicines
                                  .split(', ')
                                  .where((e) => e != medicine)
                                  .join(', ');
                            });
                          },
                        ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              // Medicine name field with suggestions
              _buildTextField(
                controller: medicineNameController,
                label: 'Medicine Name',
                onChanged: _fetchMedicineSuggestions,
              ),

              if (isLoadingSuggestions) const LinearProgressIndicator(),
              if (medicineSuggestions.isNotEmpty) _buildSuggestionsList(),

              const SizedBox(height: 20),

              // Dosage dropdowns for Morning, Afternoon, and Night

              const SizedBox(height: 20),

              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: _addSymptom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Button color
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 30), // Added horizontal padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17), // Rounded corners
                  ),
                  minimumSize: const Size(
                      double.infinity, 50), // Ensures the button is wide enough
                ),
                child: const Text(
                  'Add Symptoms',
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

  // Helper function to build the medicine suggestions list
  Widget _buildSuggestionsList() {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      height: 200,
      child: ListView.builder(
        itemCount: medicineSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = medicineSuggestions[index];
          return ListTile(
            title: Text(suggestion),
            onTap: () {
              setState(() {
                if (selectedMedicines.isEmpty) {
                  selectedMedicines = suggestion;
                } else {
                  selectedMedicines += ', ' + suggestion;
                }
                medicineNameController.clear();
                medicineSuggestions = [];
              });
            },
          );
        },
      ),
    );
  }
}
