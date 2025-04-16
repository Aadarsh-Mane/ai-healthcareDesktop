import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TreatmentDashboard extends StatefulWidget {
  final String patientId;
  final String admissionId;

  const TreatmentDashboard({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  State<TreatmentDashboard> createState() => _TreatmentDashboardState();
}

class _TreatmentDashboardState extends State<TreatmentDashboard> {
  // More vibrant gradient colors with deeper contrast
  final gradientColors = [const Color(0xFF3949AB), const Color(0xFF00BCD4)];
  // Secondary accent color for highlights
  final accentColor = const Color(0xFF7C4DFF);
  bool isLoading = true;
  Map<String, dynamic> treatmentData = {};
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTreatmentData();
  }

  Future<void> fetchTreatmentData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/doctors/getDoctorTreatment/${widget.patientId}/${widget.admissionId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          treatmentData = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> addTreatmentData({
    List<Map<String, dynamic>>? medications,
    List<Map<String, dynamic>>? ivFluids,
    List<Map<String, dynamic>>? procedures,
    List<Map<String, dynamic>>? specialInstructions,
  }) async {
    try {
      // Create request body
      Map<String, dynamic> requestBody = {
        "patientId": widget.patientId,
        "admissionId": widget.admissionId,
      };

      if (medications != null && medications.isNotEmpty) {
        requestBody["medications"] = medications;
      }
      if (ivFluids != null && ivFluids.isNotEmpty) {
        requestBody["ivFluids"] = ivFluids;
      }
      if (procedures != null && procedures.isNotEmpty) {
        requestBody["procedures"] = procedures;
      }
      if (specialInstructions != null && specialInstructions.isNotEmpty) {
        requestBody["specialInstructions"] = specialInstructions;
      }

      // Send POST request
      final response = await http.post(
        Uri.parse('${KVM_URL}/doctors/addDoctorTreatment'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success, refresh data
        await fetchTreatmentData();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treatment added successfully'),
              backgroundColor: Color(0xFF43A047),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add treatment: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteTreatmentData({
    required String treatmentType,
    required String treatmentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${KVM_URL}/doctors/deleteDoctorTreatment'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "patientId": widget.patientId,
          "admissionId": widget.admissionId,
          "treatmentType": treatmentType,
          "treatmentId": treatmentId,
        }),
      );
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success, refresh data
        await fetchTreatmentData();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treatment deleted successfully'),
              backgroundColor: Color(0xFF43A047),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to delete treatment: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddTreatmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: AddTreatmentForm(
            gradientColors: gradientColors,
            accentColor: accentColor,
            onSubmit: addTreatmentData,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(
      //       bottom: 100.0, right: 10), // adjust value as needed
      //   child: FloatingActionButton(
      //     onPressed: () => _showAddTreatmentDialog(context),
      //     backgroundColor: accentColor,
      //     child: const Icon(Icons.add, color: Colors.white),
      //     elevation: 4,
      //   ),
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade50, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: gradientColors[0],
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Text(errorMessage,
                        style: const TextStyle(color: Colors.red)))
                : TreatmentDashboardView(
                    onAddTreatment: () => _showAddTreatmentDialog(context),
                    treatmentData: treatmentData,
                    gradientColors: gradientColors,
                    accentColor: accentColor,
                    onRefresh: fetchTreatmentData,
                    patientId: widget.patientId,
                    onDelete: deleteTreatmentData,
                  ),
      ),
    );
  }
}

class TreatmentDashboardView extends StatelessWidget {
  final Map<String, dynamic> treatmentData;
  final List<Color> gradientColors;
  final Color accentColor;
  final VoidCallback onRefresh;
  final String patientId;
  final Function({
    required String treatmentType,
    required String treatmentId,
  }) onDelete;
  final VoidCallback onAddTreatment; // Added this parameter

  const TreatmentDashboardView({
    Key? key,
    required this.treatmentData,
    required this.gradientColors,
    required this.accentColor,
    required this.onRefresh,
    required this.patientId,
    required this.onDelete,
    required this.onAddTreatment, // Added this parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Expanded(
            child: _buildDashboardGrid(),
          ),
        ],
      ),
    );
  }

  // Updated _buildHeader method in TreatmentDashboardView
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services_rounded,
                  color: gradientColors[0],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Patient Treatment Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: gradientColors[0],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors[0].withOpacity(0.1),
                    gradientColors[1].withOpacity(0.1)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gradientColors[0].withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: gradientColors[0].withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Patient ID: $patientId',
                    style: TextStyle(
                      fontSize: 14,
                      color: gradientColors[0].withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: gradientColors[0].withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last Updated: ${DateTime.now().toString().substring(0, 16)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: gradientColors[0].withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Add Treatment Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onAddTreatment,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text(
                  'Add Treatment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Refresh Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Export Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accentColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.download_rounded, color: accentColor),
                label: Text(
                  'Export',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardGrid() {
    // Category icons with more attractive and meaningful icons
    final categoryIcons = {
      'Medications': Icons.medication_rounded,
      'IV Fluids': Icons.water_drop_rounded,
      'procedures': Icons.healing_rounded,
      'special Instructions': Icons.priority_high_rounded,
    };

    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.3,
      ),
      children: [
        _buildCategorySection(
          'medications',
          categoryIcons['Medications']!,
          treatmentData['medications'] ?? [],
          (item) => [
            'Dosage: ${item['dosage']}',
            'Type: ${item['type']}',
            'Date: ${item['date'] ?? DateTime.now().toString().substring(0, 10)}',
            'Time: ${item['time'] ?? DateTime.now().toString().substring(11, 19)}',
          ],
        ),
        _buildCategorySection(
          'ivFluids',
          categoryIcons['IV Fluids']!,
          treatmentData['ivFluids'] ?? [],
          (item) => [
            'Quantity: ${item['quantity']}',
            'Duration: ${item['duration']}',
            'Date: ${item['date'] ?? DateTime.now().toString().substring(0, 10)}',
            'Time: ${item['time'] ?? DateTime.now().toString().substring(11, 19)}',
          ],
        ),
        _buildCategorySection(
          'procedures',
          categoryIcons['procedures']!,
          treatmentData['procedures'] ?? [],
          (item) => [
            'Frequency: ${item['frequency']}',
            'Date: ${item['date'] ?? DateTime.now().toString().substring(0, 10)}',
            'Time: ${item['time'] ?? DateTime.now().toString().substring(11, 19)}',
          ],
        ),
        _buildCategorySection(
          'special Instructions',
          categoryIcons['special Instructions']!,
          treatmentData['specialInstructions'] ?? [],
          (item) => [
            item['instruction'],
            'Date: ${item['date'] ?? DateTime.now().toString().substring(0, 10)}',
            'Time: ${item['time'] ?? DateTime.now().toString().substring(11, 19)}',
          ],
        ),
      ],
    );
  }

  String _extractTreatmentId(dynamic item) {
    // Helper method to extract a unique identifier for the treatment
    return item['id'] ??
        item['_id'] ??
        DateTime.now().millisecondsSinceEpoch.toString();
  }

  Widget _buildCategorySection(
    String title,
    IconData icon,
    List<dynamic> items,
    List<String> Function(dynamic) getDetails,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState('No ${title.toLowerCase()} found')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final details = getDetails(item);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: gradientColors[0].withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: gradientColors[0].withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: gradientColors[0].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getItemIcon(title),
                                    size: 16,
                                    color: gradientColors[0],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title == 'special Instructions'
                                        ? 'Special Instruction'
                                        : item['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red.shade300,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    // Determine the treatmentId based on the item and title
                                    String treatmentId =
                                        _extractTreatmentId(item);

                                    // Convert title to lowercase for API
                                    String treatmentType =
                                        title.replaceAll(' ', '');
                                    print(treatmentType);
                                    onDelete(
                                      treatmentType: treatmentType,
                                      treatmentId: treatmentId,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...details.map((detail) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 6, left: 32),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(
                                            top: 6, right: 8),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          detail,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(String category) {
    switch (category) {
      case 'Medications':
        return Icons.medication_liquid_rounded;
      case 'IV Fluids':
        return Icons.water_rounded;
      case 'Procedures':
        return Icons.medical_information_rounded;
      case 'Special Instructions':
        return Icons.note_alt_rounded;
      default:
        return Icons.circle;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gradientColors[0].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: gradientColors[0].withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: gradientColors[0].withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// The AddTreatmentForm class remains exactly the same as in the previous implementation,
// so I'm not repeating it here to save space.

class AddTreatmentForm extends StatefulWidget {
  final List<Color> gradientColors;
  final Color accentColor;
  final Function({
    List<Map<String, dynamic>>? medications,
    List<Map<String, dynamic>>? ivFluids,
    List<Map<String, dynamic>>? procedures,
    List<Map<String, dynamic>>? specialInstructions,
  }) onSubmit;

  const AddTreatmentForm({
    Key? key,
    required this.gradientColors,
    required this.accentColor,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddTreatmentForm> createState() => _AddTreatmentFormState();
}

class _AddTreatmentFormState extends State<AddTreatmentForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  String? _selectedMedicationType;

  // Medication fields
  final TextEditingController _medicationNameController =
      TextEditingController();
  final TextEditingController _medicationDosageController =
      TextEditingController();
  final TextEditingController _medicationTypeController =
      TextEditingController();

  // IV Fluid fields
  final TextEditingController _fluidNameController = TextEditingController();
  final TextEditingController _fluidQuantityController =
      TextEditingController();
  final TextEditingController _fluidDurationController =
      TextEditingController();

  // Procedure fields
  final TextEditingController _procedureNameController =
      TextEditingController();
  final TextEditingController _procedureFrequencyController =
      TextEditingController();

  // Special Instruction fields
  final TextEditingController _instructionController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedMedicationType = 'Oral'; // Set default value
  }

  @override
  void dispose() {
    _tabController.dispose();
    _medicationNameController.dispose();
    _medicationDosageController.dispose();
    _medicationTypeController.dispose();
    _fluidNameController.dispose();
    _fluidQuantityController.dispose();
    _fluidDurationController.dispose();
    _procedureNameController.dispose();
    _procedureFrequencyController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Based on the current tab, submit the appropriate data
      switch (_tabController.index) {
        case 0: // Medications
          String medicationType = _selectedMedicationType == 'Other'
              ? _medicationTypeController.text
              : _selectedMedicationType!;

          widget.onSubmit(
            medications: [
              {
                "name": _medicationNameController.text,
                "dosage": _medicationDosageController.text,
                "type": medicationType,
              }
            ],
          );
          ;
          break;
        case 1: // IV Fluids
          widget.onSubmit(
            ivFluids: [
              {
                "name": _fluidNameController.text,
                "quantity": _fluidQuantityController.text,
                "duration": _fluidDurationController.text,
              }
            ],
          );
          break;
        case 2: // Procedures
          widget.onSubmit(
            procedures: [
              {
                "name": _procedureNameController.text,
                "frequency": _procedureFrequencyController.text,
              }
            ],
          );
          break;
        case 3: // Special Instructions
          widget.onSubmit(
            specialInstructions: [
              {
                "instruction": _instructionController.text,
              }
            ],
          );
          break;
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),
      width: 600,
      height: 500,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle_rounded,
                  color: widget.accentColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add New Treatment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: widget.gradientColors[0],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.gradientColors[0].withOpacity(0.2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: widget.gradientColors[0],
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: widget.gradientColors[0],
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Medication'),
                  Tab(text: 'IV Fluid'),
                  Tab(text: 'Procedure'),
                  Tab(text: 'Instruction'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Medication form
                  _buildMedicationForm(),

                  // IV Fluid form
                  _buildIVFluidForm(),

                  // Procedure form
                  _buildProcedureForm(),

                  // Special Instruction form
                  _buildSpecialInstructionForm(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.gradientColors[0],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.gradientColors[0],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientColors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white),
                    label: const Text(
                      'Add Treatment',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField1(
            label: 'Medication Name',
            controller: _medicationNameController,
            icon: Icons.medication_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter medication name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField1(
            label: 'Dosage',
            controller: _medicationDosageController,
            icon: Icons.scale_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter dosage';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Medication Type Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.category_rounded, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMedicationType,
                          isExpanded: true,
                          hint: Text('Select Type'),
                          items: ['Oral', 'Injection', 'IV', 'Other']
                              .map((String type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMedicationType = newValue;
                              // Clear the custom type field if not "Other"
                              if (newValue != 'Other') {
                                _medicationTypeController.text = newValue!;
                              } else {
                                _medicationTypeController.clear();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Custom Type field shown only when "Other" is selected
          if (_selectedMedicationType == 'Other')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildFormField1(
                label: 'Custom Type',
                controller: _medicationTypeController,
                icon: Icons.edit_outlined,
                validator: (value) {
                  if (_selectedMedicationType == 'Other' &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter custom medication type';
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField1({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon, // Added this parameter
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: Colors.grey.shade600), // Using the icon here
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.gradientColors[0], width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildIVFluidForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label: 'Fluid Name',
            controller: _fluidNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter fluid name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Quantity',
            controller: _fluidQuantityController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter quantity';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Duration',
            controller: _fluidDurationController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter duration';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProcedureForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label: 'Procedure Name',
            controller: _procedureNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter procedure name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Frequency',
            controller: _procedureFrequencyController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter frequency';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructionForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label: 'Instruction',
            controller: _instructionController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter instruction';
              }
              return null;
            },
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.gradientColors[0], width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}
