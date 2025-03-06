import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/constants/button.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController morningDosageController = TextEditingController();
  final TextEditingController afternoonDosageController =
      TextEditingController();
  final TextEditingController nightDosageController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  List<String> medicineSuggestions = [];
  List<DoctorPrescription> _prescriptions = [];

  String selectedMedicines = ''; // Store as a single string
  bool isLoadingSuggestions = false;
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

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
        Uri.parse('${KVM_URL}/search?q=$query'),
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

  Future<void> _fetchPrescriptions() async {
    try {
      final prescriptions = await doctor.fetchPrescriptions(
        widget.patientId,
        widget.admissionId,
      );
      setState(() {
        _prescriptions = prescriptions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching prescriptions: $e')),
      );
    }
  }

  Future<void> _addPrescription() async {
    final morningDosage = morningDosageController.text.isEmpty
        ? '0'
        : morningDosageController.text;
    final afternoonDosage = afternoonDosageController.text.isEmpty
        ? '0'
        : afternoonDosageController.text;
    final nightDosage =
        nightDosageController.text.isEmpty ? '0' : nightDosageController.text;
    final medicine = Medicine(
      name: selectedMedicines,
      morning: morningDosage,
      afternoon: afternoonDosage,
      night: nightDosage,
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
      _fetchPrescriptions();
    } catch (e) {
      print('Error adding prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deletePrescription(String id) async {
    try {
      await doctor.deletePrescription(widget.patientId, widget.admissionId, id);
      await _fetchPrescriptions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting prescription: $e')),
      );
    }
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(true); // Navigate back on Escape
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _addPrescription(); // Add prescription on Enter
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add Precription'),
          backgroundColor: Colors.teal,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
        body: Container(
          height: MediaQuery.of(context)
              .size
              .height, // Ensures full screen coverage

          decoration: BoxDecoration(
            image: DecorationImage(
              colorFilter: ColorFilter.mode(
                Colors.white70, // Adjust overlay color opacity
                BlendMode.lighten,
              ),
              image: AssetImage("assets/images/bb1.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: _handleKeyPress,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
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
                                    style:
                                        const TextStyle(color: Colors.white)),
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
                    if (isLoadingSuggestions) const LinearProgressIndicator(),
                    if (medicineSuggestions.isNotEmpty) _buildSuggestionsList(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                        ),
                        Image.asset(
                          'assets/images/prescrip.png',
                          width: 50,
                          height: 50,
                        ),
                        _buildTextField(
                          controller: medicineNameController,
                          label: 'Medicine Name',
                          onChanged: _fetchMedicineSuggestions,
                        ),
                        const SizedBox(width: 40),
                        _buildDosageField(
                            controller: morningDosageController,
                            label: 'Morning'),
                        const SizedBox(width: 23),
                        _buildDosageField(
                            controller: afternoonDosageController,
                            label: 'Afternoon'),
                        const SizedBox(width: 23),
                        _buildDosageField(
                            controller: nightDosageController, label: 'Night'),
                        const SizedBox(width: 23),
                        const SizedBox(width: 10),
                        Container(
                          width:
                              170, // Adjust this width based on your text length
                          child: NeumorphicButton1(
                            onTap: () {
                              _addPrescription();
                            },
                            padding: const EdgeInsets.all(12),
                            child: const Center(
                              // Ensure text is centered
                              child: Text(
                                'Add Prescription',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow
                                    .ellipsis, // Handle long text gracefully
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Current Prescriptions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _prescriptions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No prescriptions added yet'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _prescriptions.length,
                            itemBuilder: (context, index) {
                              final prescription = _prescriptions[index];
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 20,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            child: Image.asset(
                                              'assets/images/prescrip.png',
                                              width: 40,
                                              height: 40,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              prescription.medicine.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          _buildDosageDisplay('M',
                                              prescription.medicine.morning),
                                          const SizedBox(width: 10),
                                          _buildDosageDisplay('A',
                                              prescription.medicine.afternoon),
                                          const SizedBox(width: 10),
                                          _buildDosageDisplay(
                                              'N', prescription.medicine.night),
                                          const SizedBox(width: 16),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deletePrescription(
                                                    prescription.medicine.id!),
                                          ),
                                        ],
                                      ),
                                      if (prescription
                                          .medicine.comment.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8, left: 56),
                                          child: Text(
                                            'Note: ${prescription.medicine.comment}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );

                              // return Card(
                              //   margin: const EdgeInsets.only(bottom: 12),
                              //   elevation: 2,
                              //   shape: RoundedRectangleBorder(
                              //     borderRadius: BorderRadius.circular(10),
                              //   ),
                              //   child: ListTile(
                              //     contentPadding: const EdgeInsets.symmetric(
                              //       horizontal: 16,
                              //       vertical: 8,
                              //     ),
                              //     title: Text(
                              //       prescription.medicine.name,
                              //       style: const TextStyle(
                              //         fontWeight: FontWeight.w500,
                              //         fontSize: 16,
                              //       ),
                              //     ),
                              //     subtitle: Column(
                              //       crossAxisAlignment: CrossAxisAlignment.start,
                              //       children: [
                              //         const SizedBox(height: 6),
                              //         _buildDosageRow(
                              //             'Morning', prescription.medicine.morning),
                              //         _buildDosageRow('Afternoon',
                              //             prescription.medicine.afternoon),
                              //         _buildDosageRow(
                              //             'Night', prescription.medicine.night),
                              //         if (prescription.medicine.comment.isNotEmpty)
                              //           Padding(
                              //             padding: const EdgeInsets.only(top: 6),
                              //             child: Text(
                              //               'Note: ${prescription.medicine.comment}',
                              //               style: TextStyle(
                              //                 color: Colors.grey[600],
                              //                 fontStyle: FontStyle.italic,
                              //               ),
                              //             ),
                              //           ),
                              //       ],
                              //     ),
                              //     trailing: IconButton(
                              //       icon: const Icon(Icons.delete_outline,
                              //           color: Colors.red),
                              //       onPressed: () => _deletePrescription(
                              //           prescription.medicine.id!),
                              //     ),
                              //   ),
                              // );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildDosageDisplay(String time, String dosage) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            dosage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageRow(String time, String dosage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$time: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8), // Space between the time and the dosage field
          Container(
            width: 60, // Compact size for small numbers
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // Circular touch
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Colors.grey.shade500,
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              dosage, // Display the dosage as text here
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: 16, // Adjust the font size as needed
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageField({
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      width: 60, // Compact size for small numbers
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Circular touch
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center, // Center align for single digits
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: label.substring(0, 1), // "M", "A", "N"
          border: InputBorder.none,
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
    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Circular touch
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          7.0,
        ),
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
          ),
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
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
