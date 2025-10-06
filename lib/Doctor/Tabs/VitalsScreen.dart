import 'package:doctordesktop/Doctor/Tabs/VitalsChartScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ScrollController _verticalController = ScrollController();
  Set<String> selectedRows = <String>{};
  String? sortColumn;
  bool sortAscending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(vitalsProvider.notifier)
          .fetchVitals(widget.patientId, widget.admissionId);
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vitalsState = ref.watch(vitalsProvider);
    final screenSize = MediaQuery.of(context).size;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: HospitalTheme.background,
          image: DecorationImage(
            image: const AssetImage('assets/images/bb1.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
            colorFilter: ColorFilter.mode(
              HospitalTheme.primary.withOpacity(0.05),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.02), // Dynamic padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              SizedBox(height: screenSize.height * 0.02),
              Expanded(
                child: vitalsState.when(
                  loading: () => _buildLoadingShimmer(),
                  error: (error, stack) => _buildErrorView(error),
                  data: (vitalsList) => vitalsList.isEmpty
                      ? _buildEmptyState()
                      : _buildResponsiveTable(vitalsList),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Ctrl/Cmd + A to select all
      if ((event.logicalKey == LogicalKeyboardKey.keyA) &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        setState(() {
          final vitalsState = ref.read(vitalsProvider);
          vitalsState.whenData((vitals) {
            selectedRows = vitals.map((v) => v.id ?? '').toSet();
          });
        });
      }
      // Delete key to delete selected items
      else if (event.logicalKey == LogicalKeyboardKey.delete &&
          selectedRows.isNotEmpty) {
        _showBulkDeleteConfirmation();
      }
      // Escape to clear selection
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          selectedRows.clear();
        });
      }
    }
  }

  Widget _buildResponsiveTable(List<Vitals> vitalsList) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 1200;

    // Sort data if needed
    List<Vitals> sortedList = List.from(vitalsList);
    if (sortColumn != null) {
      sortedList
          .sort((a, b) => _compareValues(a, b, sortColumn!, sortAscending));
    }

    return HospitalTheme.buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Table Header with actions
          _buildTableHeader(sortedList),

          // Responsive Table Content
          Expanded(
            child: isCompact
                ? _buildCompactCardView(sortedList)
                : _buildOptimizedDataTable(sortedList),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedDataTable(List<Vitals> vitalsList) {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Container(
          width: double.infinity,
          child: DataTable(
            showCheckboxColumn: true,
            columnSpacing: 16, // Reduced spacing
            horizontalMargin: 12,
            headingRowHeight: 48,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 68,
            decoration: const BoxDecoration(color: Colors.white),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: HospitalTheme.textDark,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 12,
              color: HospitalTheme.textDark,
            ),
            headingRowColor:
                MaterialStateProperty.all(HospitalTheme.surfaceLight),
            columns: _buildOptimizedColumns(),
            rows: vitalsList
                .map((vital) => _buildOptimizedDataRow(vital))
                .toList(),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildOptimizedColumns() {
    return [
      _buildSortableColumn('Date/Time', 'recordedAt'),
      _buildSortableColumn('Temp', 'temperature'),
      _buildSortableColumn('Pulse', 'pulse'),
      _buildSortableColumn('BP', 'bloodPressure'),
      _buildSortableColumn('Sugar', 'bloodSugarLevel'),
      const DataColumn(label: Text('Notes')),
      const DataColumn(label: Text('Actions'), numeric: false),
    ];
  }

  DataRow _buildOptimizedDataRow(Vitals vital) {
    final isSelected = selectedRows.contains(vital.id);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        setState(() {
          if (selected == true) {
            selectedRows.add(vital.id ?? '');
          } else {
            selectedRows.remove(vital.id);
          }
        });
      },
      color: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.selected)) {
          return HospitalTheme.primary.withOpacity(0.08);
        }
        return null;
      }),
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDateShort(vital.recordedAt ?? ''),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatTime(vital.recordedAt ?? ''),
                  style: const TextStyle(
                    fontSize: 10,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(_buildCompactVitalCell(
          vital.temperature,
          '°C',
          _getTemperatureColor(vital.temperature),
          FontAwesomeIcons.thermometerHalf,
        )),
        DataCell(_buildCompactVitalCell(
          vital.pulse,
          'bpm',
          _getPulseColor(vital.pulse),
          FontAwesomeIcons.heartbeat,
        )),
        DataCell(_buildCompactVitalCell(
          vital.bloodPressure,
          '',
          _getBPColor(vital.bloodPressure),
          FontAwesomeIcons.weight,
        )),
        DataCell(_buildCompactVitalCell(
          vital.bloodSugarLevel,
          'mg/dL',
          _getBSLColor(vital.bloodSugarLevel),
          FontAwesomeIcons.flask,
        )),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              _getCleanNotes(vital.other),
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showVitalDetails(vital),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                tooltip: 'View',
                color: HospitalTheme.primary,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(vital.id ?? ''),
                icon: const Icon(Icons.delete_outline, size: 16),
                tooltip: 'Delete',
                color: HospitalTheme.error,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactVitalCell(
      String value, String unit, Color statusColor, IconData icon) {
    final isEmpty = value.isEmpty;
    final displayValue = isEmpty ? '-' : value;

    return Container(
      constraints: const BoxConstraints(maxWidth: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: statusColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontWeight: isEmpty ? FontWeight.normal : FontWeight.w600,
                    fontSize: 11,
                    color: isEmpty
                        ? HospitalTheme.textMedium
                        : HospitalTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!isEmpty && unit.isNotEmpty)
            Text(
              unit,
              style: const TextStyle(
                fontSize: 9,
                color: HospitalTheme.textLight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactCardView(List<Vitals> vitalsList) {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _verticalController,
        padding: const EdgeInsets.all(16),
        itemCount: vitalsList.length,
        itemBuilder: (context, index) {
          final vital = vitalsList[index];
          final isSelected = selectedRows.contains(vital.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedRows.remove(vital.id);
                  } else {
                    selectedRows.add(vital.id ?? '');
                  }
                });
              },
              borderRadius: HospitalTheme.radiusMedium,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? HospitalTheme.primary.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: HospitalTheme.radiusMedium,
                  border: Border.all(
                    color: isSelected
                        ? HospitalTheme.primary
                        : HospitalTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: HospitalTheme.shadowSmall,
                ),
                child: Column(
                  children: [
                    // Header row with date and actions
                    Row(
                      children: [
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: const Icon(
                              Icons.check_circle,
                              color: HospitalTheme.primary,
                              size: 20,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _formatDateTime(vital.recordedAt ?? ''),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: HospitalTheme.textDark,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _showVitalDetails(vital),
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 18),
                              tooltip: 'View',
                              color: HospitalTheme.primary,
                            ),
                            IconButton(
                              onPressed: () =>
                                  _showDeleteConfirmation(vital.id ?? ''),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              tooltip: 'Delete',
                              color: HospitalTheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vitals grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactVitalDisplay(
                            'Temp',
                            vital.temperature,
                            '°C',
                            FontAwesomeIcons.thermometerHalf,
                            _getTemperatureColor(vital.temperature),
                          ),
                        ),
                        Expanded(
                          child: _buildCompactVitalDisplay(
                            'Pulse',
                            vital.pulse,
                            'bpm',
                            FontAwesomeIcons.heartbeat,
                            _getPulseColor(vital.pulse),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactVitalDisplay(
                            'BP',
                            vital.bloodPressure,
                            '',
                            FontAwesomeIcons.weight,
                            _getBPColor(vital.bloodPressure),
                          ),
                        ),
                        Expanded(
                          child: _buildCompactVitalDisplay(
                            'Sugar',
                            vital.bloodSugarLevel,
                            'mg/dL',
                            FontAwesomeIcons.flask,
                            _getBSLColor(vital.bloodSugarLevel),
                          ),
                        ),
                      ],
                    ),

                    // Notes if available
                    if (vital.other.isNotEmpty && vital.other != 'N/A') ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: HospitalTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Notes: ${_getCleanNotes(vital.other)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactVitalDisplay(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    final isEmpty = value.isEmpty;
    final displayValue =
        isEmpty ? 'Not recorded' : '$value${unit.isNotEmpty ? ' $unit' : ''}';

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
              color:
                  isEmpty ? HospitalTheme.textMedium : HospitalTheme.textDark,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<Vitals> vitalsList) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Selection info
          if (selectedRows.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HospitalTheme.primary),
              ),
              child: Text(
                '${selectedRows.length} selected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _showBulkDeleteConfirmation,
              icon:
                  const Icon(Icons.delete_outline, color: HospitalTheme.error),
              tooltip: 'Delete Selected',
            ),
            IconButton(
              onPressed: () => setState(() => selectedRows.clear()),
              icon: const Icon(Icons.clear, color: HospitalTheme.textMedium),
              tooltip: 'Clear Selection',
            ),
            const Spacer(),
          ] else ...[
            Text(
              '${vitalsList.length} records',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
              ),
            ),
            const Spacer(),
          ],

          // Action buttons
          _buildActionButton(
            icon: Icons.add_chart,
            label: 'Chart',
            color: HospitalTheme.accent,
            onPressed: () => _navigateToChartView(),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.add,
            label: 'Add',
            color: HospitalTheme.primary,
            onPressed: _openAddVitalsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return HospitalTheme.buildCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [HospitalTheme.primary, HospitalTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FontAwesomeIcons.heartPulse,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Vitals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track and monitor patient vital sign',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Use Ctrl+A to select all, Delete key to remove selected items',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
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
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return HospitalTheme.buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header shimmer
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          // Table shimmer
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Container(
                    height: 60,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: HospitalTheme.error),
          const SizedBox(height: 16),
          const Text(
            'Failed to load vitals data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(color: HospitalTheme.textMedium),
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
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FontAwesomeIcons.heartPulse,
              size: 64,
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Vitals Records',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start monitoring patient vitals by adding the first record',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openAddVitalsDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Vitals Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  void _navigateToChartView() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VitalsChartScreen(
          patientId: widget.patientId,
          admissionId: widget.admissionId,
          vitals: ref.read(vitalsProvider).value ?? [],
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      ref.read(vitalsProvider.notifier).fetchVitals(
            widget.patientId,
            widget.admissionId,
          );
    }
  }

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
            width: 500,
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
                          colors: [HospitalTheme.primary, HospitalTheme.accent],
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
                    const Text(
                      'Add Vitals Record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form fields
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: HospitalTheme.textMedium),
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
                        backgroundColor: HospitalTheme.primary,
                        foregroundColor: Colors.white,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.error,
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
            prefixIcon: Icon(prefix, size: 18, color: HospitalTheme.primary),
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.bold,
            ),
            hintText: isRequired ? 'Required' : 'Optional',
            hintStyle: TextStyle(
              color: HospitalTheme.textMedium.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HospitalTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HospitalTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: HospitalTheme.primary, width: 2),
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

  void _showVitalDetails(Vitals vital) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.heartPulse,
                    color: HospitalTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Vital Signs Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                  'Recorded At', _formatDateTime(vital.recordedAt ?? '')),
              _buildDetailRow('Temperature', '${vital.temperature}°C'),
              _buildDetailRow('Pulse',
                  vital.pulse.isEmpty ? 'Not recorded' : '${vital.pulse} bpm'),
              _buildDetailRow(
                  'Blood Pressure',
                  vital.bloodPressure.isEmpty
                      ? 'Not recorded'
                      : vital.bloodPressure),
              _buildDetailRow(
                  'Blood Sugar',
                  vital.bloodSugarLevel.isEmpty
                      ? 'Not recorded'
                      : '${vital.bloodSugarLevel} mg/dL'),
              _buildDetailRow('Notes', _getCleanNotes(vital.other)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not recorded' : value,
              style: TextStyle(
                color: value.isEmpty
                    ? HospitalTheme.textLight
                    : HospitalTheme.textDark,
                fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String vitalsId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Vitals Record'),
          content: const Text(
            'Are you sure you want to delete this vitals record? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: HospitalTheme.textMedium)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(vitalsProvider.notifier).deleteVital(
                      widget.patientId,
                      widget.admissionId,
                      vitalsId,
                    );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vitals record deleted successfully'),
                    backgroundColor: HospitalTheme.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Selected Records'),
          content: Text(
            'Are you sure you want to delete ${selectedRows.length} selected vitals records? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: HospitalTheme.textMedium)),
            ),
            ElevatedButton(
              onPressed: () async {
                for (String vitalsId in selectedRows) {
                  await ref.read(vitalsProvider.notifier).deleteVital(
                        widget.patientId,
                        widget.admissionId,
                        vitalsId,
                      );
                }
                setState(() => selectedRows.clear());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Selected vitals records deleted successfully'),
                    backgroundColor: HospitalTheme.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  bool _validateInputs(
    TextEditingController temperature,
    TextEditingController pulse,
    TextEditingController bloodPressure,
    TextEditingController bloodSugarLevel,
  ) {
    if (temperature.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least Temperature'),
          backgroundColor: HospitalTheme.error,
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
    final vitals = Vitals(
      temperature: temperature,
      pulse: pulse.isEmpty ? "" : pulse,
      bloodPressure: bloodPressure.isEmpty ? "" : bloodPressure,
      bloodSugarLevel: bloodSugarLevel.isEmpty ? "" : bloodSugarLevel,
      other: other,
    );

    try {
      await doctor.addVitals(widget.patientId, widget.admissionId, vitals);
      ref
          .read(vitalsProvider.notifier)
          .fetchVitals(widget.patientId, widget.admissionId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitals record added successfully'),
          backgroundColor: HospitalTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add vitals record. Please try again.'),
          backgroundColor: HospitalTheme.error,
        ),
      );
    }
  }

  // Utility methods
  DataColumn _buildSortableColumn(String label, String columnKey) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (sortColumn == columnKey) ...[
            const SizedBox(width: 4),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: HospitalTheme.primary,
            ),
          ],
        ],
      ),
      onSort: (columnIndex, ascending) {
        setState(() {
          sortColumn = columnKey;
          sortAscending = ascending;
        });
      },
    );
  }

  int _compareValues(Vitals a, Vitals b, String column, bool ascending) {
    dynamic aValue, bValue;

    switch (column) {
      case 'recordedAt':
        aValue = DateTime.tryParse(a.recordedAt ?? '') ?? DateTime(1900);
        bValue = DateTime.tryParse(b.recordedAt ?? '') ?? DateTime(1900);
        break;
      case 'temperature':
        aValue = double.tryParse(a.temperature) ?? 0;
        bValue = double.tryParse(b.temperature) ?? 0;
        break;
      case 'pulse':
        aValue = double.tryParse(a.pulse) ?? 0;
        bValue = double.tryParse(b.pulse) ?? 0;
        break;
      case 'bloodPressure':
        aValue = a.bloodPressure;
        bValue = b.bloodPressure;
        break;
      case 'bloodSugarLevel':
        aValue = double.tryParse(a.bloodSugarLevel) ?? 0;
        bValue = double.tryParse(b.bloodSugarLevel) ?? 0;
        break;
      default:
        return 0;
    }

    final result = aValue.compareTo(bValue);
    return ascending ? result : -result;
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateShort(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('hh:mm a').format(date.toLocal());
    } catch (e) {
      return '';
    }
  }

  String _formatDateTime(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  String _getCleanNotes(String notes) {
    if (notes.isEmpty || notes == 'N/A') return 'No notes';
    return notes.split('\nDate:').first.trim();
  }

  // Color indicators based on vital values
  Color _getTemperatureColor(String temp) {
    if (temp.isEmpty) return HospitalTheme.textMedium;
    try {
      final double value = double.parse(temp);
      if (value < 36.0) return Colors.blue;
      if (value > 38.0) return HospitalTheme.error;
      return HospitalTheme.success;
    } catch (e) {
      return HospitalTheme.textMedium;
    }
  }

  Color _getPulseColor(String pulse) {
    if (pulse.isEmpty) return HospitalTheme.textMedium;
    try {
      final double value = double.parse(pulse);
      if (value < 60) return Colors.blue;
      if (value > 100) return HospitalTheme.error;
      return HospitalTheme.success;
    } catch (e) {
      return HospitalTheme.textMedium;
    }
  }

  Color _getBPColor(String bp) {
    if (bp.isEmpty) return HospitalTheme.textMedium;
    if (bp.contains('/')) {
      final parts = bp.split('/');
      try {
        final systolic = int.parse(parts[0].trim());
        final diastolic = int.parse(parts[1].trim());

        if (systolic > 140 || diastolic > 90) return HospitalTheme.error;
        if (systolic < 90 || diastolic < 60) return Colors.blue;
        return HospitalTheme.success;
      } catch (e) {}
    }
    return HospitalTheme.textMedium;
  }

  Color _getBSLColor(String bsl) {
    if (bsl.isEmpty) return HospitalTheme.textMedium;
    try {
      final double value = double.parse(bsl);
      if (value < 70) return Colors.blue;
      if (value > 180) return HospitalTheme.error;
      return HospitalTheme.success;
    } catch (e) {
      return HospitalTheme.textMedium;
    }
  }
}
