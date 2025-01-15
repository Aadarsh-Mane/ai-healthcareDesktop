import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDoctorConsultingScreen extends StatefulWidget {
  final String patientId;
  final String admissionId;

  AddDoctorConsultingScreen(
      {required this.patientId, required this.admissionId});

  @override
  _AddDoctorConsultingScreenState createState() =>
      _AddDoctorConsultingScreenState();
}

class _AddDoctorConsultingScreenState extends State<AddDoctorConsultingScreen> {
  final doctor = DoctorRepository();
  final _formKey = GlobalKey<FormState>();

  final allergiesController = TextEditingController();
  final cheifComplaintController = TextEditingController();
  final describeAllergiesController = TextEditingController();
  final historyOfPresentIllnessController = TextEditingController();
  final personalHabitsController = TextEditingController();
  final familyHistoryController = TextEditingController();
  final menstrualHistoryController = TextEditingController();
  final wongBakerController = TextEditingController();
  final visualAnalogueController = TextEditingController();
  final relevantPreviousInvestigationsController = TextEditingController();
  final immunizationHistoryController = TextEditingController();
  final pastMedicalHistoryController = TextEditingController();

  String? selectedAllergy; // Store the selected allergy type
  String? selectedPersonalHabit; // Store the selected personal habit

  double _wongBakerValue = 5; // Default value for Wong Baker (Scale 1-10)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Doctor Consulting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown for Known Allergies
              DropdownButtonFormField<String>(
                value: selectedAllergy,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedAllergy = newValue;
                  });
                },
                items: ['Drugs', 'Food', 'Latex', 'Dye', 'Contrast', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Known Allergies',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Please select an allergy type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Dropdown for Personal Habits
              DropdownButtonFormField<String>(
                value: selectedPersonalHabit,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPersonalHabit = newValue;
                  });
                },
                items: ['Smoking', 'Alcohol', 'Chewing Tobacco', 'None']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Personal Habits',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a personal habit';
                  }
                  return null;
                },
              ),

              _buildTextField(
                  cheifComplaintController, 'Chief Complaint', true),
              _buildTextField(
                  describeAllergiesController, 'Describe Allergies', true),
              _buildTextField(historyOfPresentIllnessController,
                  'History of Present Illness', true),
              _buildTextField(
                  pastMedicalHistoryController, 'Past Medical History', true),
              _buildTextField(familyHistoryController, 'Family History', true),
              _buildTextField(relevantPreviousInvestigationsController,
                  'Relevant Previous Investigations', true),
              _buildTextField(
                  menstrualHistoryController, 'Menstrual History', true),
              _buildTextField(wongBakerController, 'Wong Baker', false),
              _buildTextField(
                  visualAnalogueController, 'Visual Analogue', false),
              _buildTextField(
                  immunizationHistoryController, 'Immunization History', false),

              // Add Slider for Wong Baker scale
              const SizedBox(height: 20),
              Text(
                'Wong Baker Faces Scale (1 - 10)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _wongBakerValue,
                min: 1,
                max: 10,
                divisions: 9,
                label: _wongBakerValue.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _wongBakerValue = value;
                  });
                },
              ),
              Center(
                child: Text(
                  _getEmojiForWongBaker(_wongBakerValue),
                  style: TextStyle(fontSize: 40),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    String currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(DateTime.now());

                    final consulting = DoctorConsulting(
                      date:
                          currentDateTime, // Set the formatted current date and time

                      allergies: selectedAllergy ?? '', // Save selected allergy
                      personalHabits:
                          selectedPersonalHabit ?? '', // Save personal habit
                      cheifComplaint: cheifComplaintController.text,
                      describeAllergies: describeAllergiesController.text,
                      historyOfPresentIllness:
                          historyOfPresentIllnessController.text,
                      familyHistory: familyHistoryController.text,
                      menstrualHistory: menstrualHistoryController.text,
                      wongBaker: _getEmojiForWongBaker(_wongBakerValue),
                      visualAnalogue: visualAnalogueController.text,
                      relevantPreviousInvestigations:
                          relevantPreviousInvestigationsController.text,
                      immunizationHistory: immunizationHistoryController.text,
                      pastMedicalHistory: pastMedicalHistoryController.text,
                    );

                    try {
                      await doctor.addDoctorConsultant(
                          widget.patientId, widget.admissionId, consulting);
                      setState(() {
                        doctor.fetchDoctorConsultant(
                            widget.patientId, widget.admissionId);
                      });
                      Navigator.pop(context, true);
                    } catch (e) {
                      print('Error adding consulting: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Add Doctor Consultant'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmojiForWongBaker(double value) {
    if (value <= 1) return '😖 1'; // Very painful
    if (value <= 2) return '😞 2'; // Painful
    if (value <= 3) return '😕 3'; // Uncomfortable
    if (value <= 4) return '😐 4'; // Neutral
    if (value <= 5) return '🙂 5'; // Slight discomfort
    if (value <= 6) return '😊 6'; // Mild discomfort
    if (value <= 7) return '😁 7'; // Happy
    if (value <= 8) return '😃 8'; // Very happy
    if (value <= 9) return '😄 9'; // Extremely happy
    return '😆'; // Maximum happiness
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isTextArea) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        maxLines: isTextArea ? 5 : 1, // Make multi-line fields larger
        minLines: isTextArea
            ? 3
            : 1, // Ensure initial height is larger for text areas
        style: TextStyle(fontSize: 16),
        validator: (value) {
          return null;
        },
      ),
    );
  }
}
