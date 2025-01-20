import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddPrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String admissionId;

  const AddPrescriptionScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final doctor = DoctorRepository();
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController morningDosageController =
      TextEditingController(text: "0");
  final TextEditingController afternoonDosageController =
      TextEditingController(text: "0");
  final TextEditingController nightDosageController =
      TextEditingController(text: "0");
  final TextEditingController commentController = TextEditingController();

  List<String> medicineSuggestions = [];
  String selectedMedicines = ''; // Store as a single string
  bool isLoadingSuggestions = false;

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

    if (medicineSuggestions.isEmpty && query.isNotEmpty) {
      setState(() {
        if (!medicineSuggestions.contains(query)) {
          medicineSuggestions = [query];
        }
      });
    }
  }

  Future<void> _addPrescription() async {
    final medicine = Medicine(
      name: selectedMedicines,
      morning: morningDosageController.text,
      afternoon: afternoonDosageController.text,
      night: nightDosageController.text,
      comment: commentController.text,
    );

    final doctorPrescription = DoctorPrescription(medicine: medicine);

    try {
      await doctor.addPrescription(
        widget.patientId,
        widget.admissionId,
        doctorPrescription,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription added successfully')),
      );

      setState(() {
        selectedMedicines = '';
        morningDosageController.clear();
        afternoonDosageController.clear();
        nightDosageController.clear();
        commentController.clear();
      });
    } catch (e) {
      print('Error adding prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Prescription'),
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
              Text(
                'Prescription Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.teal,
                    ),
              ),
              const SizedBox(height: 20),
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
              _buildTextField(
                controller: medicineNameController,
                label: 'Medicine Name',
                onChanged: _fetchMedicineSuggestions,
              ),
              if (isLoadingSuggestions) const LinearProgressIndicator(),
              if (medicineSuggestions.isNotEmpty) _buildSuggestionsList(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: morningDosageController..text = '0',
                label: 'Morning Dosage',
              ),
              _buildTextField(
                controller: afternoonDosageController..text = '0',
                label: 'Afternoon Dosage',
              ),
              _buildTextField(
                controller: nightDosageController..text = '0',
                label: 'Night Dosage',
              ),
              _buildTextField(
                controller: commentController,
                label: 'Comment',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addPrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Add Prescription',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
