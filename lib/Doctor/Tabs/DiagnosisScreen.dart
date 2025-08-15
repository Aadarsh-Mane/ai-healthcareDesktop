import 'package:doctordesktop/Doctor/AddDiagnosisScreen.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final doctor = DoctorRepository();

// Enhanced provider without autoDispose for better state management
final diagnosisProvider =
    StateNotifierProvider<DiagnosisNotifier, AsyncValue<List<String>>>((ref) {
  return DiagnosisNotifier();
});

class DiagnosisNotifier extends StateNotifier<AsyncValue<List<String>>> {
  DiagnosisNotifier() : super(const AsyncValue.loading());

  String? _currentPatientId;
  String? _currentAdmissionId;

  Future<void> fetchDiagnosis(String patientId, String admissionId) async {
    _currentPatientId = patientId;
    _currentAdmissionId = admissionId;

    state = const AsyncValue.loading();
    try {
      final diagnosis =
          await doctor.fetchDoctorDiagnosis(admissionId, patientId);
      state = AsyncValue.data(diagnosis);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshDiagnosis() async {
    if (_currentPatientId != null && _currentAdmissionId != null) {
      await fetchDiagnosis(_currentPatientId!, _currentAdmissionId!);
    }
  }

  Future<void> deleteDiagnosis(
      String patientId, String admissionId, String diagnosisToDelete) async {
    try {
      await doctor.deleteDiagnosis(patientId, admissionId, diagnosisToDelete);

      // Update state by removing the deleted diagnosis
      final currentData = state.value;
      if (currentData != null) {
        final updatedList =
            currentData.where((d) => d != diagnosisToDelete).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearState() {
    _currentPatientId = null;
    _currentAdmissionId = null;
    state = const AsyncValue.loading();
  }
}

class DiagnosisScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const DiagnosisScreen({
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  final gradientColors = [HospitalTheme.primary, HospitalTheme.secondary];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiagnosis();
    });
  }

  void _loadDiagnosis() {
    ref
        .read(diagnosisProvider.notifier)
        .fetchDiagnosis(widget.patientId, widget.admissionId);
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      // F5 or Ctrl+R for refresh
      if (event.logicalKey == LogicalKeyboardKey.f5 ||
          (event.logicalKey == LogicalKeyboardKey.keyR &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed))) {
        _refreshDiagnosis();
      }
      // Ctrl+N for new diagnosis
      else if (event.logicalKey == LogicalKeyboardKey.keyN &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _openAddDiagnosisScreen();
      }
    }
  }

  Future<void> _refreshDiagnosis() async {
    await ref.read(diagnosisProvider.notifier).refreshDiagnosis();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Diagnosis data refreshed'),
            ],
          ),
          backgroundColor: HospitalTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: HospitalTheme.radiusSmall,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisAsyncValue = ref.watch(diagnosisProvider);
    final mediaQuery = MediaQuery.of(context).size;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withOpacity(0.05),
                gradientColors[1].withOpacity(0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.only(bottom: 55),
              width: mediaQuery.width * 0.85,
              constraints: const BoxConstraints(maxWidth: 1200),
              child: diagnosisAsyncValue.when(
                data: (diagnosisList) => DiagnosisContent(
                  diagnosisList: diagnosisList,
                  patientId: widget.patientId,
                  admissionId: widget.admissionId,
                  gradientColors: gradientColors,
                  onRefresh: _refreshDiagnosis,
                ),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return HospitalTheme.buildFloatingActionButton(
      icon: Icons.add,
      onPressed: _openAddDiagnosisScreen,
      tooltip: 'Add New Diagnosis (Ctrl+N)',
    );
  }

  void _showKeyboardShortcuts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: HospitalTheme.radiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.keyboard, color: HospitalTheme.primary),
            const SizedBox(width: 12),
            const Text('Keyboard Shortcuts'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutItem('F5 / Ctrl+R', 'Refresh diagnosis data'),
            _buildShortcutItem('Ctrl+N', 'Add new diagnosis'),
            _buildShortcutItem('Escape', 'Close dialogs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: HospitalTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: HospitalTheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading diagnosis data...',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: HospitalTheme.radiusMedium,
          boxShadow: HospitalTheme.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: HospitalTheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Diagnosis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadDiagnosis,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HospitalTheme.textMedium,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAddDiagnosisScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDiagnosisDoctorScreen(
          patientId: widget.patientId,
          admissionId: widget.admissionId,
          addDoctorDiagnosis: doctor.addDoctorDiagnosis,
          fetchDoctorDiagnosis: (patientId, admissionId) {
            // This will be called when returning from add screen
            _loadDiagnosis();
          },
        ),
      ),
    ).then((value) {
      // Always refresh when returning from add screen
      if (value == true || value == null) {
        _loadDiagnosis();
      }
    });
  }
}

class DiagnosisContent extends ConsumerWidget {
  final List<String> diagnosisList;
  final String patientId;
  final String admissionId;
  final List<Color> gradientColors;
  final VoidCallback onRefresh;

  const DiagnosisContent({
    required this.diagnosisList,
    required this.patientId,
    required this.admissionId,
    required this.gradientColors,
    required this.onRefresh,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final padding = isDesktop ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: HospitalTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 32),

            // Main Content
            diagnosisList.isEmpty
                ? _buildEmptyState()
                : _buildDiagnosisTable(context),

            const SizedBox(height: 32),

            // Add Button
            _buildAddButton(ref, context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: HospitalTheme.radiusSmall,
            ),
            child: const Icon(
              FontAwesomeIcons.clipboardCheck,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diagnosis by Doctor',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: $patientId • Admission ID: $admissionId',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Tooltip(
                message: 'Refresh Data',
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${diagnosisList.length} Diagnoses',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadow,
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.clipboardCheck,
              size: 48,
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Diagnosis Records Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'There are currently no diagnosis records for this patient.\nClick "Add Diagnosis" to create the first diagnosis entry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight.withOpacity(0.5),
              borderRadius: HospitalTheme.radiusSmall,
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: HospitalTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Use AI suggestions or manual entry to add diagnosis',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTable(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadow,
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.list,
                    color: HospitalTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Diagnosis Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ],
              ),
              Tooltip(
                message: 'Pull down to refresh',
                child: Icon(
                  Icons.swipe_down_alt,
                  color: HospitalTheme.textLight,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isDesktop ? screenWidth * 0.7 : screenWidth * 0.8,
                ),
                child: DataTable(
                  columnSpacing: isDesktop ? 40 : 20,
                  horizontalMargin: 0,
                  headingRowColor: MaterialStateColor.resolveWith(
                    (states) => HospitalTheme.surfaceLight.withOpacity(0.5),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  columns: [
                    _buildDataColumn(
                      'No.',
                      FontAwesomeIcons.hashtag,
                      gradientColors[0],
                    ),
                    _buildDataColumn(
                      'Diagnosis',
                      FontAwesomeIcons.clipboardCheck,
                      gradientColors[1],
                    ),
                    _buildDataColumn(
                      'Date & Time',
                      FontAwesomeIcons.calendarAlt,
                      gradientColors[0],
                    ),
                    _buildDataColumn(
                      'Actions',
                      FontAwesomeIcons.cogs,
                      gradientColors[1],
                    ),
                  ],
                  rows: diagnosisList
                      .asMap()
                      .map((index, diagnosis) {
                        final dateSplit = diagnosis.split(RegExp(r' - Date: '));
                        final diagnosisText = dateSplit[0];
                        final dateText =
                            dateSplit.length > 1 ? dateSplit[1] : 'No date';

                        return MapEntry(
                          index,
                          DataRow(
                            color: MaterialStateColor.resolveWith(
                              (states) => index.isEven
                                  ? Colors.transparent
                                  : HospitalTheme.surfaceLight.withOpacity(0.3),
                            ),
                            cells: [
                              DataCell(_buildIndexCell(index + 1)),
                              DataCell(_buildDiagnosisCell(diagnosisText)),
                              DataCell(_buildDateCell(dateText)),
                              DataCell(_buildActionCell(diagnosis)),
                            ],
                          ),
                        );
                      })
                      .values
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(WidgetRef ref, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadow,
      ),
      child: ElevatedButton.icon(
        onPressed: () => _openAddDiagnosisScreen(ref, context),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          'Add New Diagnosis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: HospitalTheme.radiusMedium,
          ),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, IconData icon, Color color) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexCell(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HospitalTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: HospitalTheme.primary,
        ),
      ),
    );
  }

  Widget _buildDiagnosisCell(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.stethoscope,
            color: gradientColors[0],
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: text,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCell(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          FontAwesomeIcons.clock,
          color: gradientColors[1],
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: HospitalTheme.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCell(String diagnosis) {
    return Consumer(
      builder: (context, ref, child) {
        return IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: HospitalTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.delete_outline,
              color: HospitalTheme.error,
              size: 16,
            ),
          ),
          onPressed: () => _showDeleteConfirmation(context, ref, diagnosis),
          tooltip: 'Delete Diagnosis',
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, String diagnosis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: HospitalTheme.radiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: HospitalTheme.warning),
            const SizedBox(width: 12),
            const Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this diagnosis?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusSmall,
              ),
              child: Text(
                diagnosis.split(' - Date: ')[0],
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: HospitalTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                color: HospitalTheme.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(diagnosisProvider.notifier)
                  .deleteDiagnosis(patientId, admissionId, diagnosis);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openAddDiagnosisScreen(WidgetRef ref, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDiagnosisDoctorScreen(
          patientId: patientId,
          admissionId: admissionId,
          addDoctorDiagnosis: doctor.addDoctorDiagnosis,
          fetchDoctorDiagnosis: (patientId, admissionId) {
            // Refresh data when called from AddDiagnosisScreen
            ref
                .read(diagnosisProvider.notifier)
                .fetchDiagnosis(patientId, admissionId);
          },
        ),
      ),
    ).then((value) {
      // Always refresh when returning from add screen
      if (value == true || value == null) {
        ref
            .read(diagnosisProvider.notifier)
            .fetchDiagnosis(patientId, admissionId);
      }
    });
  }
}
