import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SymptomsLayout extends StatefulWidget {
  final String patientId;
  final String admissionId;
  final Function(String, String, String) addSymptomsByDoctor;

  const SymptomsLayout({
    Key? key,
    required this.patientId,
    required this.admissionId,
    required this.addSymptomsByDoctor,
  }) : super(key: key);

  @override
  _SymptomsLayoutState createState() => _SymptomsLayoutState();
}

class _SymptomsLayoutState extends State<SymptomsLayout> {
  final TextEditingController symptomController = TextEditingController();
  List<String> symptomSuggestions = [];
  bool isLoadingSuggestions = false;
  String selectedSymptoms = '';
  bool isLoadingTrendingSymptoms = true;
  List<Map<String, dynamic>> trendingSymptoms = [];

  @override
  void initState() {
    super.initState();
    _fetchTrendingSymptoms();
  }

  Future<void> _fetchTrendingSymptoms() async {
    setState(() {
      isLoadingTrendingSymptoms = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getSymptomAnalytics'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          setState(() {
            trendingSymptoms = List<Map<String, dynamic>>.from(
                data['data']['mostUsedSymptoms'] ?? []);
            isLoadingTrendingSymptoms = false;
          });
        } else {
          setState(() {
            trendingSymptoms = [];
            isLoadingTrendingSymptoms = false;
          });
        }
      } else {
        setState(() {
          trendingSymptoms = [];
          isLoadingTrendingSymptoms = false;
        });
      }
    } catch (e) {
      print('Error fetching trending symptoms: $e');
      setState(() {
        trendingSymptoms = [];
        isLoadingTrendingSymptoms = false;
      });
    }
  }

  // Search functionality removed as requested

  void _addSymptomToSelection(String symptom) {
    List<String> current =
        selectedSymptoms.isEmpty ? [] : selectedSymptoms.split(', ');

    if (!current.contains(symptom)) {
      current.add(symptom);
      setState(() {
        selectedSymptoms = current.join(', ');
      });
    }
  }

  Future<void> _addSymptom() async {
    if (symptomController.text.isEmpty && selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a symptom')),
      );
      return;
    }

    // If there's text in the input field, add it to the selection
    if (symptomController.text.isNotEmpty) {
      _addSymptomToSelection(symptomController.text);
      symptomController.clear();
    }

    // Now process all selected symptoms
    List<String> symptoms = selectedSymptoms.split(', ');
    final String currentDateTime =
        DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

    for (String symptom in symptoms) {
      final String fullSymptom = '$symptom - $currentDateTime';

      try {
        await widget.addSymptomsByDoctor(
          widget.admissionId,
          fullSymptom,
          widget.patientId,
        );
      } catch (e) {
        print('Error adding symptom: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding "$symptom": $e')),
        );
        return; // Exit on first error
      }
    }

    // Clear selections after successful addition
    setState(() {
      selectedSymptoms = '';
      symptomSuggestions = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${symptoms.length} symptom(s) added successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Symptom Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005F9E),
            ),
          ),
          SizedBox(height: 8),

          // Description subtitle
          Text(
            'Add symptoms observed in this patient',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),

          SizedBox(height: 24),

          // Trending Symptoms Section
          Text(
            'Trending Symptoms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF005F9E),
            ),
          ),
          SizedBox(height: 8),

          // Trending Symptoms Chips
          if (isLoadingTrendingSymptoms)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F9E)),
              ),
            )
          else if (trendingSymptoms.isEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No trending symptoms data available',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: trendingSymptoms.map((symptom) {
                final name = symptom['name'] as String;
                final count = symptom['count'] as int;
                final isSelected = selectedSymptoms.split(', ').contains(name);

                return HospitalTheme.buildSpecialtyChip(
                  label: '$name ($count)',
                  icon: Icons.trending_up,
                  isSelected: isSelected,
                  onTap: () {
                    _addSymptomToSelection(name);
                  },
                );
              }).toList(),
            ),

          SizedBox(height: 24),

          // Selected symptoms section
          if (selectedSymptoms.isNotEmpty) ...[
            Text(
              'Selected Symptoms',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF005F9E),
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: selectedSymptoms
                    .split(', ')
                    .where((s) => s.isNotEmpty)
                    .map((symptom) => Chip(
                          label: Text(
                            symptom,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: Color(0xFF00B8D4),
                          deleteIconColor: Colors.white,
                          onDeleted: () {
                            setState(() {
                              selectedSymptoms = selectedSymptoms
                                  .split(', ')
                                  .where((s) => s != symptom)
                                  .join(', ');
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          ],

          SizedBox(height: 24),

          // Text field for manually entering symptoms
          TextField(
            controller: symptomController,
            decoration: InputDecoration(
              hintText: 'Enter symptom name',
              prefixIcon:
                  Icon(Icons.medical_information, color: Color(0xFF005F9E)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF005F9E), width: 2),
              ),
              suffixIcon: symptomController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          symptomController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _addSymptomToSelection(value);
                symptomController.clear();
                setState(() {
                  symptomSuggestions = [];
                });
              }
            },
          ),

          // Search functionality removed as requested

          SizedBox(height: 24),

          // Add Button (Gradient)
          Center(
            child: HospitalTheme.buildGradientButton(
              label: 'Add Symptoms',
              icon: Icons.add_circle,
              onPressed: _addSymptom,
              startColor: Color(0xFF005F9E),
              endColor: Color(0xFF00B8D4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    symptomController.dispose();
    super.dispose();
  }
}

// Usage example:
//
// SymptomsLayout(
//   patientId: widget.patient.patientId,
//   admissionId: widget.patient.admissionRecords.first.id,
//   addSymptomsByDoctor: doctor.addSymptomsByDoctor,
// )
