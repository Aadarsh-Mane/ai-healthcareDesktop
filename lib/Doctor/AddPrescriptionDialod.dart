import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/constants/button.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

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

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen>
    with SingleTickerProviderStateMixin {
  final doctor = DoctorRepository();
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController morningDosageController = TextEditingController();
  final TextEditingController afternoonDosageController =
      TextEditingController();
  final TextEditingController nightDosageController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  final FocusNode medicineFocusNode = FocusNode();

  // Colors from HospitalTheme - same as VitalsScreen
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF8FBFD);
  final Color cardBackground = Colors.white;
  final Color textDark = const Color(0xFF2D3748);
  final Color textMedium = const Color(0xFF5A6B7F);
  final Color success = const Color(0xFF43A047);
  final Color error = const Color(0xFFE53935);
  final Color warning = const Color(0xFFFFA000);

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> medicineSuggestions = [];
  List<DoctorPrescription> _prescriptions = [];

  String selectedMedicines = ''; // Store as a single string
  bool isLoadingSuggestions = false;
  bool showComment = false;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Add listener to medicine name controller for Enter key
    medicineNameController.addListener(_handleMedicineNameChange);
  }

  @override
  void dispose() {
    medicineNameController.removeListener(_handleMedicineNameChange);
    medicineNameController.dispose();
    morningDosageController.dispose();
    afternoonDosageController.dispose();
    nightDosageController.dispose();
    commentController.dispose();
    medicineFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleMedicineNameChange() {
    if (medicineNameController.text.contains('\n')) {
      // Handle Enter key
      final medicineName =
          medicineNameController.text.replaceAll('\n', '').trim();
      if (medicineName.isNotEmpty) {
        setState(() {
          if (selectedMedicines.isEmpty) {
            selectedMedicines = medicineName;
          } else {
            selectedMedicines += ', ' + medicineName;
          }
          medicineNameController.clear();
          medicineSuggestions = [];
        });
      }
    }
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
      _showSnackBar('Error fetching prescriptions: $e', isError: true);
    }
  }

  Future<void> _addPrescription() async {
    if (selectedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    final morningDosage = morningDosageController.text.isEmpty
        ? '0'
        : morningDosageController.text;
    final afternoonDosage = afternoonDosageController.text.isEmpty
        ? '0'
        : afternoonDosageController.text;
    final nightDosage =
        nightDosageController.text.isEmpty ? '0' : nightDosageController.text;
    final comment = commentController.text;

    // Split the medicines into a list
    List<String> medicinesList =
        selectedMedicines.split(', ').where((med) => med.isNotEmpty).toList();

    try {
      // Create a counter for successful additions
      int successCount = 0;

      // Add each medicine individually
      for (String medicineName in medicinesList) {
        final medicine = Medicine(
          name: medicineName.trim(), // Ensure no extra spaces
          morning: morningDosage,
          afternoon: afternoonDosage,
          night: nightDosage,
          comment: comment,
        );

        final doctorPrescription = DoctorPrescription(medicine: medicine);

        await doctor.addPrescription(
          widget.patientId,
          widget.admissionId,
          doctorPrescription,
        );

        successCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$successCount prescriptions added successfully')),
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

  void _showSuccessAnimation() {
    _animationController.forward().then((_) {
      _showSnackBar('Prescription added successfully');
      _animationController.reverse();
    });
  }

  Future<void> _deletePrescription(String id) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    try {
      await doctor.deletePrescription(widget.patientId, widget.admissionId, id);
      await _fetchPrescriptions();
      _showSnackBar('Prescription deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting prescription: $e', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Confirm Deletion'),
              content: const Text(
                  'Are you sure you want to delete this prescription?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: textMedium)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(true); // Navigate back on Escape
      } else if (event.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _addPrescription(); // Add prescription on Ctrl+S
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? error : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _addMedicine() {
    final medicineName = medicineNameController.text.trim();
    if (medicineName.isNotEmpty) {
      setState(() {
        if (selectedMedicines.isEmpty) {
          selectedMedicines = medicineName;
        } else {
          selectedMedicines += ', ' + medicineName;
        }
        medicineNameController.clear();
        medicineSuggestions = [];
      });
      FocusScope.of(context).requestFocus(medicineFocusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Prescription',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Save Prescription (Ctrl+S)',
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: _addPrescription,
            ),
          ),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context)
                .pop(true); // Return true to refresh parent screen
          },
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: const AssetImage("assets/images/bb1.png"),
            fit: BoxFit.cover,
            opacity: 0.1,
            colorFilter: ColorFilter.mode(
              primaryColor.withOpacity(0.05),
              BlendMode.lighten,
            ),
          ),
        ),
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: _handleKeyPress,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeaderSection(),
                const SizedBox(height: 16),

                // Main content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Add prescription form
                      Expanded(
                        flex: 3,
                        child: _buildPrescriptionForm(),
                      ),

                      const SizedBox(width: 24),

                      // Right side - Current prescriptions
                      Expanded(
                        flex: 4,
                        child: _buildPrescriptionsList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Title with Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(FontAwesomeIcons.heartPulse,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Vitals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  'Track and monitor patient vital signs',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Quick Actions
          Row(
            children: [
              _buildActionButton(
                icon: Icons.print,
                label: 'Print All',
                color: accentColor,
                onPressed: () {
                  // Implementation for printing
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.add,
                label: 'Add Vitals',
                color: primaryColor,
                onPressed: () => _addPrescription(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Widget _buildHeaderSection() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: cardBackground,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.04),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     padding: const EdgeInsets.all(20),
  //     child: Row(
  //       children: [
  //         // Title with Icon
  //         Container(
  //           padding: const EdgeInsets.all(10),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [primaryColor, accentColor],
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //             ),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: const Icon(FontAwesomeIcons.pills,
  //               color: Colors.white, size: 24),
  //         ),
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Patient Prescriptions',
  //                 style: TextStyle(
  //                   fontSize: 24,
  //                   fontWeight: FontWeight.bold,
  //                   color: textDark,
  //                 ),
  //               ),
  //               Text(
  //                 'Manage medications and dosage instructions',
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: textMedium,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         // Quick Actions
  //         Row(
  //           children: [
  //             _buildActionButton(
  //               icon: Icons.print,
  //               label: 'Print All',
  //               color: accentColor,
  //               onPressed: () {
  //                 // Implementation for printing
  //               },
  //             ),
  //             const SizedBox(width: 12),
  //             _buildActionButton(
  //               icon: Icons.save,
  //               label: 'Save Prescription',
  //               color: primaryColor,
  //               onPressed: _addPrescription,
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPrescriptionForm() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFDFEAF4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Row(
              children: [
                Icon(FontAwesomeIcons.penToSquare,
                    size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Add New Prescription',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Medicine selection header
            Text(
              'Medicine Selection',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),

            // Selected medicines chips
            if (selectedMedicines.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDFEAF4),
                    width: 1,
                  ),
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: selectedMedicines
                      .split(', ')
                      .map((medicine) => Chip(
                            label: Text(medicine),
                            backgroundColor: accentColor,
                            labelStyle: const TextStyle(color: Colors.white),
                            deleteIconColor: Colors.white,
                            elevation: 1,
                            shadowColor: Colors.black12,
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
              ),
              const SizedBox(height: 16),
            ],

            // Medicine search
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: medicineNameController,
                    label: 'Search or add medicine',
                    hintText: 'Type medicine name and press Enter',
                    prefixIcon: FontAwesomeIcons.magnifyingGlass,
                    onChanged: _fetchMedicineSuggestions,
                    focusNode: medicineFocusNode,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addMedicine,
                    tooltip: 'Add Medicine',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Loading indicator for suggestions
            if (isLoadingSuggestions)
              LinearProgressIndicator(
                backgroundColor: accentColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),

            // Suggestions list
            if (medicineSuggestions.isNotEmpty)
              Expanded(
                flex: 2,
                child: _buildSuggestionsList(),
              ),

            const SizedBox(height: 16),

            // Dosage section
            Text(
              'Dosage Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDosageInput(
                  controller: morningDosageController,
                  label: 'Morning',
                  icon: Icons.wb_sunny_outlined,
                ),
                _buildDosageInput(
                  controller: afternoonDosageController,
                  label: 'Afternoon',
                  icon: Icons.wb_twighlight,
                ),
                _buildDosageInput(
                  controller: nightDosageController,
                  label: 'Night',
                  icon: Icons.nightlight_outlined,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Comment toggle and field
            InkWell(
              onTap: () {
                setState(() {
                  showComment = !showComment;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      showComment ? Icons.expand_less : Icons.expand_more,
                      color: primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Additional Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Comment field with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: showComment ? 120 : 0,
              margin: EdgeInsets.only(top: showComment ? 12 : 0),
              child: showComment
                  ? _buildTextField(
                      controller: commentController,
                      label: 'Notes',
                      prefixIcon: FontAwesomeIcons.notesMedical,
                      maxLines: 4,
                    )
                  : null,
            ),

            const Spacer(),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addPrescription,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Prescription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsList() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFDFEAF4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Row(
              children: [
                Icon(FontAwesomeIcons.listCheck, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Current Prescriptions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),

            // Prescriptions list
            Expanded(
              child: _prescriptions.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: _prescriptions.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final prescription = _prescriptions[index];
                        return _buildPrescriptionItem(prescription);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.pills,
              size: 48,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Prescriptions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start managing patient medications by adding the first prescription',
            style: TextStyle(
              fontSize: 16,
              color: textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildPrescriptionItem(DoctorPrescription prescription) {
    final dateText = prescription.medicine.date != null
        ? _formatDate(prescription.medicine.date.toString())
        : 'Today';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and delete option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: textMedium),
                  const SizedBox(width: 6),
                  Text(
                    'Prescribed: $dateText',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMedium,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: error, size: 18),
                onPressed: () => _deletePrescription(prescription.medicine.id!),
                tooltip: 'Delete Prescription',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          // Prescription content
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFDFEAF4),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine name
                Text(
                  prescription.medicine.name ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Dosage information
                Row(
                  children: [
                    _buildDosageDisplay(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Morning',
                      value: prescription.medicine.morning ?? '',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildDosageDisplay(
                      icon: Icons.wb_twighlight,
                      label: 'Afternoon',
                      value: prescription.medicine.afternoon ?? '',
                      color: accentColor,
                    ),
                    const SizedBox(width: 12),
                    _buildDosageDisplay(
                      icon: Icons.nightlight_outlined,
                      label: 'Night',
                      value: prescription.medicine.night ?? '',
                      color: primaryColor.withOpacity(0.7),
                    ),
                  ],
                ),

                // Notes if available
                if (prescription.medicine.comment != null &&
                    prescription.medicine.comment!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FontAwesomeIcons.notesMedical,
                          size: 14, color: textMedium),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prescription.medicine.comment ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageDisplay({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Handle empty values
    final displayValue = value.isEmpty || value == '0' ? '0' : value;
    final isZero = displayValue == '0';
    final displayColor = isZero ? textMedium : color;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textMedium,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: displayColor),
                const SizedBox(width: 6),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isZero ? textMedium.withOpacity(0.5) : textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    FocusNode? focusNode,
    String? hintText,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: label,
          prefixIcon:
              prefixIcon != null ? Icon(prefixIcon, color: accentColor) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildDosageInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textMedium,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(height: 8),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: textMedium.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: medicineSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = medicineSuggestions[index];
          return ListTile(
            title: Text(suggestion),
            leading: const Icon(FontAwesomeIcons.pills,
                color: Colors.teal, size: 16),
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
              FocusScope.of(context).requestFocus(medicineFocusNode);
            },
          );
        },
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (color ?? primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? primaryColor),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }
}
