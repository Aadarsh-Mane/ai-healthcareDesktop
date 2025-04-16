import 'package:doctordesktop/Doctor/Tabs/VitalsChartScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';

// Provider to manage vitals data state
final vitalsProvider =
    StateNotifierProvider<VitalsNotifier, AsyncValue<List<Vitals>>>((ref) {
  return VitalsNotifier();
});

class VitalsNotifier extends StateNotifier<AsyncValue<List<Vitals>>> {
  VitalsNotifier() : super(const AsyncValue.loading());
  final doctor = DoctorRepository();

  Future<void> fetchVitals(String patientId, String admissionId) async {
    try {
      state = const AsyncValue.loading();
      final vitals = await doctor.fetchVitals(patientId, admissionId);
      state = AsyncValue.data(vitals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteVital(
      String patientId, String admissionId, String vitalsId) async {
    try {
      await doctor.deleteVitals(patientId, admissionId, vitalsId);

      // Optimistic update - remove the deleted item from the list
      state.whenData((vitals) {
        final updatedList =
            vitals.where((vital) => vital.id != vitalsId).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e) {
      // Revert on error by refetching the data
      fetchVitals(patientId, admissionId);
    }
  }
}

class VitalsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const VitalsScreen({
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  _VitalsScreenState createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
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

  @override
  void initState() {
    super.initState();
    // Fetch data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(vitalsProvider.notifier)
          .fetchVitals(widget.patientId, widget.admissionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vitalsState = ref.watch(vitalsProvider);
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

                // Main Content - Vitals List
                Expanded(
                  child: vitalsState.when(
                    loading: () => _buildLoadingShimmer(columnCount),
                    error: (error, stack) => _buildErrorView(error),
                    data: (vitalsList) => vitalsList.isEmpty
                        ? _buildEmptyState()
                        : _buildVitalsGrid(vitalsList, columnCount),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PageRouteBuilder _createFallingPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -1), // Starts from the top
            end: Offset(0, 0), // Ends at the normal position
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut, // Smooth falling effect
          )),
          child: child,
        );
      },
    );
  }

  // Update the _buildHeaderSection method in the _VitalsScreenState class
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
                icon: Icons.add_chart,
                label: 'Chart View',
                color: accentColor,
                onPressed: () async {
                  // Launch chart view and wait for result
                  final result = await Navigator.of(context).push(
                    _createFallingPageRoute(
                      VitalsChartScreen(
                        patientId: widget.patientId,
                        admissionId: widget.admissionId,
                        vitals: ref.read(vitalsProvider).value ?? [],
                      ),
                    ),
                  );

                  // Refresh vitals data if requested
                  if (result == true) {
                    ref.read(vitalsProvider.notifier).fetchVitals(
                          widget.patientId,
                          widget.admissionId,
                        );
                  }
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.add,
                label: 'Add Vitals',
                color: primaryColor,
                onPressed: () => _openAddVitalsDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Add these imports at the top of the file
// import 'package:doctordesktop/screens/VitalsChartScreen.dart'; // Or wherever your VitalsChartScreen is located

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

  Widget _buildVitalsGrid(List<Vitals> vitalsList, int columnCount) {
    // Increase childAspectRatio to make cards taller
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 9.2, // Reduced ratio makes cards taller
        mainAxisExtent: 240, // Fixed height for each card
      ),
      itemCount: vitalsList.length,
      itemBuilder: (context, index) {
        final vitals = vitalsList[index];
        return _buildVitalCard(vitals);
      },
    );
  }

  Widget _buildVitalCard(Vitals vitals) {
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
                    'Recorded: ${_formatDate(vitals.recordedAt ?? "")}',
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
                    onPressed: () => _showDeleteConfirmation(vitals.id ?? ""),
                    tooltip: 'Delete Record',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),

          // Vitals content - Using SingleChildScrollView to handle overflow
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVitalRowWithIndicator(
                      icon: FontAwesomeIcons.thermometerHalf,
                      label: 'Temperature',
                      value: '${vitals.temperature}°C',
                      color: _getTemperatureColor(vitals.temperature),
                    ),
                    const SizedBox(height: 8),
                    _buildVitalRowWithIndicator(
                      icon: FontAwesomeIcons.heartbeat,
                      label: 'Pulse',
                      value: vitals.pulse.isEmpty ? '' : '${vitals.pulse} bpm',
                      color: _getPulseColor(vitals.pulse),
                    ),
                    const SizedBox(height: 8),
                    _buildVitalRowWithIndicator(
                      icon: FontAwesomeIcons.weight,
                      label: 'Blood Pressure',
                      value: vitals.bloodPressure,
                      color: _getBPColor(vitals.bloodPressure),
                    ),
                    const SizedBox(height: 8),
                    _buildVitalRowWithIndicator(
                      icon: FontAwesomeIcons.flask,
                      label: 'Blood Sugar',
                      value: vitals.bloodSugarLevel.isEmpty
                          ? ''
                          : '${vitals.bloodSugarLevel}',
                      color: _getBSLColor(vitals.bloodSugarLevel),
                    ),
                    if (vitals.other.isNotEmpty &&
                        vitals.other != 'N/A' &&
                        !vitals.other.startsWith('Date:')) ...[
                      const SizedBox(height: 8),
                      _buildVitalRowWithIndicator(
                        icon: FontAwesomeIcons.notesMedical,
                        label: 'Notes',
                        value: vitals.other.split('\nDate:').first,
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

  Widget _buildVitalRowWithIndicator({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Handle empty values
    final displayValue = value.isEmpty ? 'Not recorded' : value;
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

        // Status indicator - only show for non-empty values
        if (value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
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
        childAspectRatio: 1.6,
        mainAxisExtent: 240, // Fixed height for each card
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
            'Error loading vitals data',
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
            onPressed: () => ref.read(vitalsProvider.notifier).fetchVitals(
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
              FontAwesomeIcons.heartPulse,
              size: 48,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Vitals Records',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start monitoring patient vitals by adding the first record',
            style: TextStyle(
              fontSize: 16,
              color: textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddVitalsDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Vitals Record'),
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
  void _openAddVitalsDialog() {
    final temperature = TextEditingController();
    final pulse = TextEditingController();
    final bloodPressure = TextEditingController();
    final bloodSugarLevel = TextEditingController();
    final other = TextEditingController();

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
                        FontAwesomeIcons.plusCircle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Add Vitals Record',
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
                          'Only Temperature is required. Other fields are optional.',
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
                  controller: temperature,
                  label: 'Temperature',
                  prefix: FontAwesomeIcons.thermometerHalf,
                  suffix: '°C',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: pulse,
                  label: 'Pulse',
                  prefix: FontAwesomeIcons.heartbeat,
                  suffix: 'bpm',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: bloodPressure,
                  label: 'Blood Pressure',
                  prefix: FontAwesomeIcons.weight,
                  suffix: 'mmHg',
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: bloodSugarLevel,
                  label: 'Blood Sugar Level',
                  prefix: FontAwesomeIcons.flask,
                  suffix: 'mg/dL',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: other,
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
                        if (_validateInputs(temperature, pulse, bloodPressure,
                            bloodSugarLevel)) {
                          await _saveVitals(
                            temperature.text,
                            pulse.text,
                            bloodPressure.text,
                            bloodSugarLevel.text,
                            other.text,
                          );
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
                      child: const Text('Save Record'),
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

  bool _validateInputs(
    TextEditingController temperature,
    TextEditingController pulse,
    TextEditingController bloodPressure,
    TextEditingController bloodSugarLevel,
  ) {
    // Make only temperature required as the minimum field
    if (temperature.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least Temperature'),
          backgroundColor: error,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveVitals(
    String temperature,
    String pulse,
    String bloodPressure,
    String bloodSugarLevel,
    String other,
  ) async {
    final String currentDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final String otherWithDateTime = other.isEmpty
        ? 'Date: $currentDateTime'
        : '$other\nDate: $currentDateTime';

    final vitals = Vitals(
      temperature: temperature,
      pulse: pulse.isEmpty ? "" : pulse,
      bloodPressure: bloodPressure.isEmpty ? "" : bloodPressure,
      bloodSugarLevel: bloodSugarLevel.isEmpty ? "" : bloodSugarLevel,
      other: other,
    );

    try {
      await doctor.addVitals(widget.patientId, widget.admissionId, vitals);
      // Refresh data
      ref
          .read(vitalsProvider.notifier)
          .fetchVitals(widget.patientId, widget.admissionId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vitals record added successfully'),
          backgroundColor: success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding vitals: $e'),
          backgroundColor: error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String vitalsId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Delete Vitals Record'),
          content: Text(
              'Are you sure you want to delete this vitals record? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: textMedium)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(vitalsProvider.notifier).deleteVital(
                      widget.patientId,
                      widget.admissionId,
                      vitalsId,
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

  // Format date to a more readable format
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  // Color indicators based on vital values
  Color _getTemperatureColor(String temp) {
    try {
      final double value = double.parse(temp);
      if (value < 36.0) return Colors.blue;
      if (value > 38.0) return error;
      return success;
    } catch (e) {
      return textMedium;
    }
  }

  Color _getPulseColor(String pulse) {
    try {
      final double value = double.parse(pulse);
      if (value < 60) return Colors.blue;
      if (value > 100) return error;
      return success;
    } catch (e) {
      return textMedium;
    }
  }

  Color _getBPColor(String bp) {
    // Simple check for high blood pressure
    if (bp.contains('/')) {
      final parts = bp.split('/');
      try {
        final systolic = int.parse(parts[0].trim());
        final diastolic = int.parse(parts[1].trim());

        if (systolic > 140 || diastolic > 90) return error;
        if (systolic < 90 || diastolic < 60) return Colors.blue;
        return success;
      } catch (e) {}
    }
    return textMedium;
  }

  Color _getBSLColor(String bsl) {
    try {
      final double value = double.parse(bsl);
      if (value < 70) return Colors.blue;
      if (value > 180) return error;
      return success;
    } catch (e) {
      return textMedium;
    }
  }
}
