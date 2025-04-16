import 'package:doctordesktop/Doctor/AddPrescriptionDialod.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Provider to manage prescriptions data state
final prescriptionsProvider = StateNotifierProvider<PrescriptionsNotifier,
    AsyncValue<List<DoctorPrescription>>>((ref) {
  return PrescriptionsNotifier();
});

class PrescriptionsNotifier
    extends StateNotifier<AsyncValue<List<DoctorPrescription>>> {
  PrescriptionsNotifier() : super(const AsyncValue.loading());
  final doctor = DoctorRepository();

  Future<void> fetchPrescriptions(String patientId, String admissionId) async {
    try {
      state = const AsyncValue.loading();
      final prescriptions =
          await doctor.fetchPrescriptions(patientId, admissionId);
      state = AsyncValue.data(prescriptions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePrescription(
      String patientId, String admissionId, String prescriptionId) async {
    try {
      await doctor.deletePrescription(patientId, admissionId, prescriptionId);

      // Optimistic update - remove the deleted item from the list
      state.whenData((prescriptions) {
        final updatedList = prescriptions
            .where((prescription) => prescription.medicine.id != prescriptionId)
            .toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e) {
      // Revert on error by refetching the data
      fetchPrescriptions(patientId, admissionId);
    }
  }
}

class DoctorPrescriptionsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const DoctorPrescriptionsScreen({
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  _DoctorPrescriptionsScreenState createState() =>
      _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState
    extends ConsumerState<DoctorPrescriptionsScreen> {
  final doctor = DoctorRepository();
  // Key colors from HospitalTheme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF8FBFD);
  final Color cardBackground = Colors.white;
  final Color textDark = const Color(0xFF2D3748);
  final Color textMedium = const Color(0xFF5A6B7F);
  final Color success = const Color(0xFF43A047);
  final Color error = const Color(0xFFE53935);
  final Color warning = const Color(0xFFFFA000);

  // Form controllers
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController morningDoseController = TextEditingController();
  final TextEditingController afternoonDoseController = TextEditingController();
  final TextEditingController nightDoseController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(prescriptionsProvider.notifier)
          .fetchPrescriptions(widget.patientId, widget.admissionId);
    });
  }

  @override
  void dispose() {
    medicineNameController.dispose();
    morningDoseController.dispose();
    afternoonDoseController.dispose();
    nightDoseController.dispose();
    commentController.dispose();
    super.dispose();
  }

  bool _isPrescriptionLoading = false;

  @override
  Widget build(BuildContext context) {
    final prescriptionsState = ref.watch(prescriptionsProvider);
    final screenSize = MediaQuery.of(context).size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count
        final int columnCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
                ? 2
                : 1;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            image: DecorationImage(
              image: const AssetImage('assets/images/bb1.png'),
              fit: BoxFit.cover,
              opacity: 0.1,
              colorFilter: ColorFilter.mode(
                primaryColor.withOpacity(0.05),
                BlendMode.lighten,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Stats and Add Button
                _buildHeaderSection(),
                const SizedBox(height: 16),

                // Main Content - Prescriptions List
                Expanded(
                  child: prescriptionsState.when(
                    loading: () => _buildLoadingShimmer(columnCount),
                    error: (error, stack) => _buildErrorView(error),
                    data: (prescriptionsList) => prescriptionsList.isEmpty
                        ? _buildEmptyState()
                        : _buildPrescriptionsGrid(
                            prescriptionsList, columnCount),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchDoctorAdvice(
      BuildContext context, patientId, admissionId) async {
    setState(() => _isPrescriptionLoading = true);

    try {
      final url =
          '${KVM_URL}/reception/getDoctorAdvice/${patientId}/${admissionId}';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      final fileLink = data['fileLink'];

      if (fileLink != null) {
        Methods().openPdf(fileLink);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file link found in the response')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      // Always reset the loading state, regardless of success or failure
      setState(() => _isPrescriptionLoading = false);
    }
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
            child: const Icon(FontAwesomeIcons.pills,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Prescriptions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  'Manage medications and dosage instructions',
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
                icon: Icons.medication,
                label: 'Prescription',
                color: Colors.purple,
                isLoading: _isPrescriptionLoading,
                onPressed: () async {
                  // The loading state is now managed inside _fetchDoctorAdvice
                  await _fetchDoctorAdvice(
                      context, widget.patientId, widget.admissionId);
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                  icon: Icons.add,
                  label: 'Add Prescription',
                  color: primaryColor,
                  onPressed: () async {
                    // Navigate and wait for result
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddPrescriptionScreen(
                          patientId: widget.patientId,
                          admissionId: widget.admissionId,
                        ),
                      ),
                    );

                    // If returning from the AddPrescriptionScreen, refresh the data
                    if (result == true || result == null) {
                      ref
                          .read(prescriptionsProvider.notifier)
                          .fetchPrescriptions(
                              widget.patientId, widget.admissionId);
                    }
                  }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 170,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    height: 28,
                    width: 28,
                    child: CustomLoadingAnimation(),
                  )
                : Icon(icon, size: 28, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsGrid(
      List<DoctorPrescription> prescriptionsList, int columnCount) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // Use mainAxisExtent instead of childAspectRatio to set a fixed height
        mainAxisExtent: 280, // Fixed height for each card
      ),
      itemCount: prescriptionsList.length,
      itemBuilder: (context, index) {
        final prescription = prescriptionsList[index];
        return _buildPrescriptionCard(prescription);
      },
    );
  }

// Update this method in your code:
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Today';

    try {
      // Handle ISO date string format
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date.toLocal());
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }

  Widget _buildPrescriptionCard(DoctorPrescription prescription) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and delete option
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.9),
                  accentColor.withOpacity(0.9)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Prescribed: ${prescription.medicine.date ?? _formatDate(DateTime.now().toString())}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 30,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 16),
                    onPressed: () =>
                        _showDeleteConfirmation(prescription.medicine.id ?? ""),
                    tooltip: 'Delete Prescription',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),

          // Prescription content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Important to prevent expansion
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrescriptionRow(
                      icon: FontAwesomeIcons.pills,
                      label: 'Medicine',
                      value: prescription.medicine.name ?? '',
                      color: primaryColor,
                    ),
                    const SizedBox(height: 8),
                    _buildPrescriptionRow(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Morning',
                      value: prescription.medicine.morning ?? '',
                      color: Colors.orange,
                      suffix: 'tablet(s)',
                    ),
                    const SizedBox(height: 8),
                    _buildPrescriptionRow(
                      icon: Icons.wb_twighlight,
                      label: 'Afternoon',
                      value: prescription.medicine.afternoon ?? '',
                      color: accentColor,
                      suffix: 'tablet(s)',
                    ),
                    const SizedBox(height: 8),
                    _buildPrescriptionRow(
                      icon: Icons.nightlight_outlined,
                      label: 'Night',
                      value: prescription.medicine.night ?? '',
                      color: primaryColor.withOpacity(0.7),
                      suffix: 'tablet(s)',
                    ),
                    if (prescription.medicine.comment != null &&
                        prescription.medicine.comment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildPrescriptionRow(
                        icon: FontAwesomeIcons.notesMedical,
                        label: 'Notes',
                        value: prescription.medicine.comment ?? '',
                        color: textMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? suffix,
  }) {
    // Handle empty values
    final displayValue = value.isEmpty
        ? 'Not specified'
        : (suffix != null && value.isNotEmpty ? '$value $suffix' : value);
    final displayColor = value.isEmpty ? textMedium : color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: displayColor, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: value.isEmpty ? textMedium.withOpacity(0.7) : textDark,
                  fontStyle:
                      value.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(int columnCount) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading prescriptions data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(prescriptionsProvider.notifier).fetchPrescriptions(
                      widget.patientId,
                      widget.admissionId,
                    ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddPrescriptionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Prescription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _openAddPrescriptionDialog() {
    // Clear all controllers first
    medicineNameController.clear();
    morningDoseController.clear();
    afternoonDoseController.clear();
    nightDoseController.clear();
    commentController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500, // Fixed width for desktop
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
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
                      child: const Icon(
                        FontAwesomeIcons.pills,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Add New Prescription',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Required fields info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: textMedium,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only Medicine Name is required. Other fields are optional.',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form fields with improved styling
                _buildFormField(
                  controller: medicineNameController,
                  label: 'Medicine Name',
                  prefix: FontAwesomeIcons.pills,
                  isRequired: true,
                ),
                const SizedBox(height: 16),

                // Dosage fields in a row
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: morningDoseController,
                        label: 'Morning',
                        prefix: Icons.wb_sunny_outlined,
                        suffix: 'tablets',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        controller: afternoonDoseController,
                        label: 'Afternoon',
                        prefix: Icons.wb_twighlight,
                        suffix: 'tablets',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        controller: nightDoseController,
                        label: 'Night',
                        prefix: Icons.nightlight_outlined,
                        suffix: 'tablets',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildFormField(
                  controller: commentController,
                  label: 'Additional Notes',
                  prefix: FontAwesomeIcons.notesMedical,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: textMedium),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_validateInputs()) {
                          await _savePrescription();
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Prescription'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData prefix,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(prefix, size: 18, color: primaryColor),
            suffixText: suffix,
            suffixStyle:
                TextStyle(color: textMedium, fontWeight: FontWeight.bold),
            hintText: isRequired ? 'Required' : 'Optional',
            hintStyle: TextStyle(
              color: textMedium.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFDFEAF4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFDFEAF4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  bool _validateInputs() {
    // Only medicine name is required
    if (medicineNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter Medicine Name'),
          backgroundColor: error,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _savePrescription() async {
    try {
      final medicine = Medicine(
        name: medicineNameController.text.trim(),
        morning: morningDoseController.text.isEmpty
            ? "0"
            : morningDoseController.text,
        afternoon: afternoonDoseController.text.isEmpty
            ? "0"
            : afternoonDoseController.text,
        night:
            nightDoseController.text.isEmpty ? "0" : nightDoseController.text,
        comment: commentController.text.trim(),
        date: DateTime.now(),
      );

      final prescription = DoctorPrescription(medicine: medicine);

      await doctor.addPrescription(
        widget.patientId,
        widget.admissionId,
        prescription,
      );

      // Refresh data
      ref.read(prescriptionsProvider.notifier).fetchPrescriptions(
            widget.patientId,
            widget.admissionId,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prescription added successfully'),
          backgroundColor: success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding prescription: $e'),
          backgroundColor: error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String prescriptionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Delete Prescription'),
          content: Text(
              'Are you sure you want to delete this prescription? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: textMedium)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(prescriptionsProvider.notifier).deletePrescription(
                      widget.patientId,
                      widget.admissionId,
                      prescriptionId,
                    );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: error,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
