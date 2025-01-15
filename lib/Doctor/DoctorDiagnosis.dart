import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorDiagnosisSection extends StatefulWidget {
  final String admissionId;
  final String patientId;

  const DoctorDiagnosisSection({
    Key? key,
    required this.admissionId,
    required this.patientId,
  }) : super(key: key);

  @override
  DoctorDiagnosisSectionState createState() => DoctorDiagnosisSectionState();
}

class DoctorDiagnosisSectionState extends State<DoctorDiagnosisSection> {
  final doctor = DoctorRepository();
  late final Patient1 patient;

  bool _isExpanded = false; // Controls expansion state

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: doctor.fetchDoctorDiagnosis(widget.admissionId, widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData) {
          final symptoms = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Symptoms by Doctor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Date: ${DateTime.now().toLocal()}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (symptoms.isEmpty)
                      const Text(
                        'No symptoms added by the doctor.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade400,
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: DataTable(
                          columnSpacing: 24,
                          horizontalMargin: 16,
                          columns: const [
                            DataColumn(
                                label: Text(
                              'No.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                fontSize: 16,
                              ),
                            )),
                            DataColumn(
                                label: Text(
                              'Symptom',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                fontSize: 16,
                              ),
                            )),
                          ],
                          rows: symptoms
                              .asMap()
                              .map((index, symptom) {
                                return MapEntry(
                                  index,
                                  DataRow(cells: [
                                    DataCell(
                                      Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        symptom,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ]),
                                );
                              })
                              .values
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _openAddDiagnosisDialog(widget.admissionId),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Symptom',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ],
                ),
            ],
          );
        } else {
          return const Text('No data available');
        }
      },
    );
  }

  void _openAddDiagnosisDialog(String admissionId) {
    final TextEditingController _symptomsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Diagnosis by Doctor'),
          content: TextField(
            controller: _symptomsController,
            decoration: const InputDecoration(
              labelText: 'Enter diagnosis',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSymptom = _symptomsController.text.trim();
                if (newSymptom.isNotEmpty) {
                  // Get current date
                  final String currentDateTime =
                      DateFormat('yyyy-MM-dd hh:mm:ss a')
                          .format(DateTime.now());

                  // Append date and time to the symptom
                  final String symptomWithDateTime =
                      '$newSymptom Date: $currentDateTime';

                  // Call the API with the appended symptom
                  await doctor.addDoctorDiagnosis(
                    admissionId,
                    symptomWithDateTime,
                    widget.patientId,
                  );

                  setState(() {
                    doctor.fetchDoctorDiagnosis(
                      widget.patientId,
                      admissionId,
                    );
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
