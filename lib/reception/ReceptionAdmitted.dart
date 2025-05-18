import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';

// State Providers for better state management using Riverpod
final sectionsProvider = StateNotifierProvider<SectionsNotifier, List<Section>>(
    (ref) => SectionsNotifier());
final typeStatsProvider =
    StateNotifierProvider<TypeStatsNotifier, List<TypeStat>>(
        (ref) => TypeStatsNotifier());
final admittedPatientsProvider =
    StateNotifierProvider<PatientsNotifier, List<Patient>>(
        (ref) => PatientsNotifier());

// State notifiers for Riverpod
class SectionsNotifier extends StateNotifier<List<Section>> {
  SectionsNotifier() : super([]);

  void setSections(List<Section> sections) {
    state = sections;
  }

  void updateSectionBedDetails(
      int index, List<int> availableBeds, List<OccupiedBed> occupiedBeds) {
    final updatedSections = [...state];
    final section = updatedSections[index];

    updatedSections[index] = Section(
      id: section.id,
      name: section.name,
      type: section.type,
      totalBeds: section.totalBeds,
      availableBeds: section.availableBeds,
      isActive: section.isActive,
      createdAt: section.createdAt,
      availableBedNumbers: availableBeds,
      occupiedBeds: occupiedBeds,
      isBedsDataLoaded: true,
    );

    state = updatedSections;
  }

  void updateSectionAvailableBeds(String sectionId, int updatedAvailableBeds) {
    state = [
      for (final section in state)
        if (section.id == sectionId)
          section.copyWith(availableBeds: updatedAvailableBeds)
        else
          section,
    ];
  }
}

class TypeStatsNotifier extends StateNotifier<List<TypeStat>> {
  TypeStatsNotifier() : super([]);

  void setTypeStats(List<TypeStat> stats) {
    state = stats;
  }
}

class PatientsNotifier extends StateNotifier<List<Patient>> {
  PatientsNotifier() : super([]);

  void setPatients(List<Patient> patients) {
    state = patients;
  }
}

// Selection state provider
final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>(
        (ref) => SelectionNotifier());

class SelectionState {
  final String? patientId;
  final String? admissionId;
  final String? sectionId;
  final int? bedNumber;
  final Patient? patient;

  SelectionState({
    this.patientId,
    this.admissionId,
    this.sectionId,
    this.bedNumber,
    this.patient,
  });

  SelectionState copyWith({
    String? patientId,
    String? admissionId,
    String? sectionId,
    int? bedNumber,
    Patient? patient,
    bool clearPatient = false,
    bool clearAll = false,
  }) {
    if (clearAll) {
      return SelectionState();
    }

    return SelectionState(
      patientId: patientId ?? this.patientId,
      admissionId: admissionId ?? this.admissionId,
      sectionId: sectionId ?? this.sectionId,
      bedNumber: bedNumber ?? this.bedNumber,
      patient: clearPatient ? null : patient ?? this.patient,
    );
  }
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(SelectionState());

  void selectPatient(Patient patient) {
    state = state.copyWith(
      patientId: patient.patientId,
      patient: patient,
      admissionId: patient.admissionRecords.isNotEmpty
          ? patient.admissionRecords.first.id
          : null,
    );
  }

  void selectBed(String sectionId, int bedNumber) {
    state = state.copyWith(
      sectionId: sectionId,
      bedNumber: bedNumber,
    );
  }

  void clear() {
    state = state.copyWith(clearAll: true);
  }
}

// Filter state provider
final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>(
    (ref) => FilterNotifier());

class FilterState {
  final String searchQuery;
  final String selectedFilter;
  final String sortOrder;
  final int currentPage;
  final int patientsPerPage;

  FilterState({
    this.searchQuery = '',
    this.selectedFilter = 'All',
    this.sortOrder = 'Newest',
    this.currentPage = 0,
    this.patientsPerPage = 5,
  });

  FilterState copyWith({
    String? searchQuery,
    String? selectedFilter,
    String? sortOrder,
    int? currentPage,
    int? patientsPerPage,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      currentPage: currentPage ?? this.currentPage,
      patientsPerPage: patientsPerPage ?? this.patientsPerPage,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(FilterState());

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 0);
  }

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter, currentPage: 0);
  }

  void updateSortOrder(String order) {
    state = state.copyWith(sortOrder: order);
  }

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void resetPage() {
    state = state.copyWith(currentPage: 0);
  }

  void resetFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedFilter: 'All',
      currentPage: 0,
    );
  }
}

// UI state provider
final uiStateProvider =
    StateNotifierProvider<UIStateNotifier, UIState>((ref) => UIStateNotifier());

class UIState {
  final bool isLoadingSections;
  final bool isLoadingPatients;
  final int expandedSectionIndex;
  final bool isPatientsExpanded;

  UIState({
    this.isLoadingSections = false,
    this.isLoadingPatients = false,
    this.expandedSectionIndex = -1,
    this.isPatientsExpanded = true,
  });

  UIState copyWith({
    bool? isLoadingSections,
    bool? isLoadingPatients,
    int? expandedSectionIndex,
    bool? isPatientsExpanded,
  }) {
    return UIState(
      isLoadingSections: isLoadingSections ?? this.isLoadingSections,
      isLoadingPatients: isLoadingPatients ?? this.isLoadingPatients,
      expandedSectionIndex: expandedSectionIndex ?? this.expandedSectionIndex,
      isPatientsExpanded: isPatientsExpanded ?? this.isPatientsExpanded,
    );
  }
}

class UIStateNotifier extends StateNotifier<UIState> {
  UIStateNotifier() : super(UIState());

  void setLoadingSections(bool isLoading) {
    state = state.copyWith(isLoadingSections: isLoading);
  }

  void setLoadingPatients(bool isLoading) {
    state = state.copyWith(isLoadingPatients: isLoading);
  }

  void toggleSectionExpansion(int index) {
    state = state.copyWith(
      expandedSectionIndex: state.expandedSectionIndex == index ? -1 : index,
    );
  }

  void togglePatientsExpanded() {
    state = state.copyWith(isPatientsExpanded: !state.isPatientsExpanded);
  }
}

// Filtered patients provider
final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patients = ref.watch(admittedPatientsProvider);
  final filterState = ref.watch(filterProvider);

  return patients.where((patient) {
    // Apply search filter
    final nameMatches = patient.name
        .toLowerCase()
        .contains(filterState.searchQuery.toLowerCase());
    final idMatches = patient.patientId
        .toLowerCase()
        .contains(filterState.searchQuery.toLowerCase());
    final searchMatches = nameMatches || idMatches;

    // Apply status filter
    bool statusMatches = true;
    if (filterState.selectedFilter != 'All') {
      if (filterState.selectedFilter == 'No Bed') {
        // Check if patient has no bed assigned
        statusMatches = patient.admissionRecords.isNotEmpty &&
            (patient.admissionRecords.first.bedNumber == null);
      } else if (filterState.selectedFilter == 'Has Bed') {
        // Check if patient has a bed assigned
        statusMatches = patient.admissionRecords.isNotEmpty &&
            (patient.admissionRecords.first.bedNumber != null);
      }
    }

    return searchMatches && statusMatches;
  }).toList()
    ..sort((a, b) {
      // Apply sorting
      if (filterState.sortOrder == 'Name') {
        return a.name.compareTo(b.name);
      } else if (filterState.sortOrder == 'ID') {
        return a.patientId.compareTo(b.patientId);
      } else {
        // Sort by newest (default) - assuming admission date is the indicator
        if (a.admissionRecords.isEmpty) return 1;
        if (b.admissionRecords.isEmpty) return -1;
        return b.admissionRecords.first.admissionDate
            .compareTo(a.admissionRecords.first.admissionDate);
      }
    });
});

// Paginated patients provider
final paginatedPatientsProvider = Provider<List<Patient>>((ref) {
  final filteredPatients = ref.watch(filteredPatientsProvider);
  final filterState = ref.watch(filterProvider);

  final startIndex = filterState.currentPage * filterState.patientsPerPage;
  final endIndex =
      (startIndex + filterState.patientsPerPage < filteredPatients.length)
          ? startIndex + filterState.patientsPerPage
          : filteredPatients.length;

  if (startIndex >= filteredPatients.length) {
    return [];
  }

  return filteredPatients.sublist(startIndex, endIndex);
});

// Total pages provider
final totalPagesProvider = Provider<int>((ref) {
  final filteredPatients = ref.watch(filteredPatientsProvider);
  final patientsPerPage = ref.watch(filterProvider).patientsPerPage;

  return (filteredPatients.length / patientsPerPage).ceil();
});

class ReceptionBedManagementScreen extends ConsumerStatefulWidget {
  const ReceptionBedManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReceptionBedManagementScreen> createState() =>
      _ReceptionBedManagementScreenState();
}

class _ReceptionBedManagementScreenState
    extends ConsumerState<ReceptionBedManagementScreen> {
  // Setup keyboard shortcuts
  final FocusNode _shortcutFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Initialize data fetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    await fetchSections();
    await fetchAdmittedPatients();
  }

  Future<void> fetchSections() async {
    ref.read(uiStateProvider.notifier).setLoadingSections(true);

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/admin/getAllSections'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Update state with Riverpod
        ref.read(sectionsProvider.notifier).setSections((data['data'] as List)
            .map((json) => Section.fromJson(json))
            .toList());

        ref.read(typeStatsProvider.notifier).setTypeStats(
            (data['typeStats'] as List)
                .map((json) => TypeStat.fromJson(json))
                .toList());

        ref.read(uiStateProvider.notifier).setLoadingSections(false);

        // If a section is expanded, refresh its bed details
        final expandedIndex = ref.read(uiStateProvider).expandedSectionIndex;
        if (expandedIndex >= 0 &&
            expandedIndex < ref.read(sectionsProvider).length) {
          fetchSectionBedDetails(
              ref.read(sectionsProvider)[expandedIndex], expandedIndex);
        }
      } else {
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      ref.read(uiStateProvider.notifier).setLoadingSections(false);
      showErrorSnackBar('Error loading sections: $e');
    }
  }

  Future<void> fetchAdmittedPatients() async {
    ref.read(uiStateProvider.notifier).setLoadingPatients(true);

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/getAdmittedPatients'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Update state with Riverpod
        ref.read(admittedPatientsProvider.notifier).setPatients(
            (data['data'] as List)
                .map((json) => Patient.fromJson(json))
                .toList());

        ref.read(uiStateProvider.notifier).setLoadingPatients(false);
      } else {
        throw Exception('Failed to load admitted patients');
      }
    } catch (e) {
      ref.read(uiStateProvider.notifier).setLoadingPatients(false);
      showErrorSnackBar('Error loading admitted patients: $e');
    }
  }

  Future<void> fetchSectionBedDetails(Section section, int sectionIndex) async {
    // Skip if already loaded
    if (section.isBedsDataLoaded) return;

    try {
      // Fetch available beds
      final availableResponse = await http.get(
        Uri.parse('${KVM_URL}/reception/availableBeds/${section.id}'),
      );

      if (availableResponse.statusCode == 200) {
        final availableData = json.decode(availableResponse.body);
        final availableBedsList =
            List<int>.from(availableData['data']['availableBedNumbers']);

        // Get the updated available beds count from API
        final updatedAvailableBeds =
            availableData['data']['section']['availableBeds'];

        // Fetch occupied beds
        final occupiedResponse = await http.get(
          Uri.parse('${KVM_URL}/reception/occupiedBeds/${section.id}'),
        );

        if (occupiedResponse.statusCode == 200) {
          final occupiedData = json.decode(occupiedResponse.body);
          final occupiedBedsList =
              (occupiedData['data']['occupiedBeds'] as List)
                  .map((bed) => OccupiedBed.fromJson(bed))
                  .toList();

          // Update section data
          ref.read(sectionsProvider.notifier).updateSectionBedDetails(
              sectionIndex, availableBedsList, occupiedBedsList);

          // Update available beds count
          ref
              .read(sectionsProvider.notifier)
              .updateSectionAvailableBeds(section.id, updatedAvailableBeds);
        }
      }
    } catch (e) {
      showErrorSnackBar('Error loading bed details: $e');
    }
  }

  Future<void> assignBedToPatient() async {
    final selection = ref.read(selectionProvider);

    if (selection.patientId == null ||
        selection.sectionId == null ||
        selection.bedNumber == null ||
        selection.admissionId == null) {
      showErrorSnackBar('Please select patient, section, and bed');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/assignBedToPatient'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': selection.patientId,
          'sectionId': selection.sectionId,
          'bedNumber': selection.bedNumber,
          'admissionRecordId': selection.admissionId,
        }),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar('Bed assigned successfully');

        // Reset selection
        ref.read(selectionProvider.notifier).clear();

        // Force a complete refresh of all data
        await fetchSections();
        await fetchAdmittedPatients();

        // Reset the bed data loaded flag for the modified section
        final sectionIndex = ref
            .read(sectionsProvider)
            .indexWhere((s) => s.id == selection.sectionId);

        if (sectionIndex != -1) {
          // If the section is expanded, refresh its bed details
          if (ref.read(uiStateProvider).expandedSectionIndex == sectionIndex) {
            fetchSectionBedDetails(
                ref.read(sectionsProvider)[sectionIndex], sectionIndex);
          }
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to assign bed');
      }
    } catch (e) {
      showErrorSnackBar('Error assigning bed: $e');
    }
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: HospitalTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HospitalTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Using consumer to watch the state
    final uiState = ref.watch(uiStateProvider);
    final selection = ref.watch(selectionProvider);
    final sections = ref.watch(sectionsProvider);
    final typeStats = ref.watch(typeStatsProvider);

    // Focus node to capture keyboard shortcuts
    return KeyboardListener(
      focusNode: _shortcutFocusNode,
      autofocus: true,
      onKeyEvent: (keyEvent) {
        if (keyEvent is KeyDownEvent) {
          // Refresh data with F5
          if (keyEvent.logicalKey == LogicalKeyboardKey.f5) {
            _fetchInitialData();
          }

          // Ctrl+F for search focus
          if (keyEvent.logicalKey == LogicalKeyboardKey.keyF &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            // Focus on search field - would need a FocusNode
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hospital Be Management'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _fetchInitialData();
                showSuccessSnackBar('Data refreshed successfully');
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Row(
          children: [
            // Left sidebar - Enhanced Patient List
            _buildPatientsSidebar(size),

            // Main content area
            Expanded(
              child: _buildMainContent(size),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(Size size) {
    final uiState = ref.watch(uiStateProvider);
    final sections = ref.watch(sectionsProvider);
    final selection = ref.watch(selectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hospital Sections',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              if (selection.patient != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HospitalTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Assigning: ${selection.patient!.name} (${selection.patient!.patientId})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Main content - Sections and bed layout
        Expanded(
          child: uiState.isLoadingSections
              ? const Center(child: CircularProgressIndicator())
              : sections.isEmpty
                  ? const Center(
                      child: Text(
                        'No sections found.',
                        style: TextStyle(color: HospitalTheme.textMedium),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        return _buildSectionCard(sections[index], index);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(Section section, int index) {
    final uiState = ref.watch(uiStateProvider);
    final selection = ref.watch(selectionProvider);
    bool isExpanded = index == uiState.expandedSectionIndex;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with expand button
          InkWell(
            onTap: () {
              ref.read(uiStateProvider.notifier).toggleSectionExpansion(index);
              if (!section.isBedsDataLoaded &&
                  index == ref.read(uiStateProvider).expandedSectionIndex) {
                fetchSectionBedDetails(section, index);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getSectionColor(section.type).withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: HospitalTheme.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSectionIcon(section.type),
                    color: _getSectionColor(section.type),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ),
                  HospitalTheme.buildStatusBadge(
                    section.type,
                    color: _getSectionColor(section.type),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: HospitalTheme.primary,
                    ),
                    onPressed: () {
                      ref
                          .read(uiStateProvider.notifier)
                          .toggleSectionExpansion(index);
                      if (!section.isBedsDataLoaded &&
                          index ==
                              ref.read(uiStateProvider).expandedSectionIndex) {
                        fetchSectionBedDetails(section, index);
                      }
                    },
                    tooltip: isExpanded ? 'Collapse' : 'Expand',
                  ),
                ],
              ),
            ),
          ),

          // Overview stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSectionInfoCard(
                  icon: Icons.bed,
                  title: 'Total Beds',
                  value: section.totalBeds.toString(),
                  color: HospitalTheme.primary,
                ),
                const SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.check_circle,
                  title: 'Available',
                  value: section.availableBeds.toString(),
                  color: HospitalTheme.success,
                ),
                const SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.person,
                  title: 'Occupied',
                  value: (section.totalBeds - section.availableBeds).toString(),
                  color: HospitalTheme.warning,
                ),
                const SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.timeline,
                  title: 'Occupancy Rate',
                  value: section.availableBeds == 0
                      ? '100%'
                      : '${(((section.totalBeds - section.availableBeds) / section.totalBeds) * 100).toStringAsFixed(1)}%',
                  color: HospitalTheme.laboratory,
                ),
              ],
            ),
          ),

          // Expanded section with bed layout
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bed Layout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Show loading indicator while fetching bed details
                  section.isBedsDataLoaded
                      ? _buildBedLayout(section)
                      : const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Loading bed details...'),
                            ],
                          ),
                        ),

                  // Show occupied beds details if any
                  if (section.isBedsDataLoaded &&
                      section.occupiedBeds.isNotEmpty)
                    _buildOccupiedBedsTable(section),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOccupiedBedsTable(Section section) {
    if (section.occupiedBeds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Occupied Beds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: HospitalTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  HospitalTheme.surfaceLight,
                ),
                columns: const [
                  DataColumn(label: Text('Bed Number')),
                  DataColumn(label: Text('Patient ID')),
                  DataColumn(label: Text('Patient Name')),
                  DataColumn(label: Text('Admission Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: section.occupiedBeds.map((bed) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: HospitalTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: HospitalTheme.error),
                          ),
                          child: Text(
                            'Bed ${bed.bedNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.error,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(bed.patientId)),
                      DataCell(Text(bed.patientName)),
                      DataCell(Text(
                        '${bed.admissionDate.day}/${bed.admissionDate.month}/${bed.admissionDate.year}',
                      )),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility,
                                  color: HospitalTheme.primary),
                              onPressed: () {
                                // Find patient details
                                final patients =
                                    ref.read(admittedPatientsProvider);
                                try {
                                  final patient = patients.firstWhere(
                                    (p) => p.patientId == bed.patientId,
                                  );
                                  // Show detailed patient info dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        _buildPatientDetailsDialog(
                                            section, bed),
                                  );
                                } catch (e) {
                                  showErrorSnackBar(
                                      'Patient details not found');
                                }
                              },
                              tooltip: 'View Patient',
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.swap_horiz,
                                  color: HospitalTheme.warning),
                              onPressed: () {
                                // Find the patient in the admitted list
                                final patients =
                                    ref.read(admittedPatientsProvider);
                                try {
                                  final patient = patients.firstWhere(
                                    (p) => p.patientId == bed.patientId,
                                  );

                                  // Select this patient for bed transfer
                                  ref
                                      .read(selectionProvider.notifier)
                                      .selectPatient(patient);

                                  // Show a snackbar with instructions
                                  showSuccessSnackBar(
                                      'Select a new bed for ${bed.patientName}');
                                } catch (e) {
                                  showErrorSnackBar('Patient data not found');
                                }
                              },
                              tooltip: 'Transfer',
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedLayout(Section section) {
    // Calculate dynamic values based on available width
    final screenWidth = MediaQuery.of(context).size.width;
    final selection = ref.watch(selectionProvider);

    // Adjust beds per row based on available width
    // This ensures the layout is responsive on different screen sizes
    int bedsPerRow = (screenWidth < 1200)
        ? 5
        : (screenWidth < 1600)
            ? 8
            : 10;
    int rows = (section.totalBeds / bedsPerRow).ceil();

    return Container(
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Legend for the bed layout
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Available', HospitalTheme.success),
              _buildLegendItem('Occupied', HospitalTheme.error),
              _buildLegendItem('Selected', HospitalTheme.primary),
            ],
          ),
          const SizedBox(height: 16),

          // Theater-style layout for beds
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Entrance indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ENTRANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Beds layout - wrapped in SingleChildScrollView for horizontal scrolling if needed
                for (int row = 0; row < rows; row++)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int col = 0; col < bedsPerRow; col++)
                          if (row * bedsPerRow + col < section.totalBeds) ...[
                            _buildBedItem(
                              section: section,
                              bedNumber: row * bedsPerRow + col + 1,
                              isAvailable: section.isBedsDataLoaded
                                  ? section.availableBedNumbers
                                      .contains(row * bedsPerRow + col + 1)
                                  : (row * bedsPerRow + col + 1) <=
                                      section.availableBeds,
                              isSelected: selection.sectionId == section.id &&
                                  selection.bedNumber ==
                                      row * bedsPerRow + col + 1,
                              type: section.type,
                              patientInfo: section.isBedsDataLoaded
                                  ? _getPatientInfoForBed(
                                      section, row * bedsPerRow + col + 1)
                                  : null,
                            ),
                            if (col < bedsPerRow - 1) const SizedBox(width: 8),
                          ],
                      ],
                    ),
                  ),

                // Nurse station
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HospitalTheme.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.medical_services,
                          color: HospitalTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'NURSING STATION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(TypeStat stat) {
    Color statColor;
    IconData statIcon;

    switch (stat.id) {
      case 'Icu':
        statColor = HospitalTheme.medical;
        statIcon = Icons.medical_services;
        break;
      case 'Ward':
        statColor = HospitalTheme.laboratory;
        statIcon = Icons.local_hospital;
        break;
      default:
        statColor = HospitalTheme.pharmacy;
        statIcon = Icons.bed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statIcon, color: statColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stat.availableBeds}/${stat.totalBeds} beds available',
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: stat.occupancyRate,
                  backgroundColor: HospitalTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    stat.occupancyRate > 0.8
                        ? HospitalTheme.error
                        : stat.occupancyRate > 0.6
                            ? HospitalTheme.warning
                            : HospitalTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    final uiState = ref.watch(uiStateProvider);
    final paginatedPatients = ref.watch(paginatedPatientsProvider);
    final filteredPatients = ref.watch(filteredPatientsProvider);
    final totalPages = ref.watch(totalPagesProvider);
    final filterState = ref.watch(filterProvider);
    final patients = ref.watch(admittedPatientsProvider);
    final selection = ref.watch(selectionProvider);

    if (uiState.isLoadingPatients) {
      return const Center(child: CircularProgressIndicator());
    }

    if (patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_off, size: 48, color: HospitalTheme.textMedium),
            SizedBox(height: 16),
            Text(
              'No admitted patients found',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
          ],
        ),
      );
    }

    if (filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                size: 48, color: HospitalTheme.textMedium),
            const SizedBox(height: 16),
            const Text(
              'No patients match your filters',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              onPressed: () => ref.read(filterProvider.notifier).resetFilters(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Patient cards with pagination
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: paginatedPatients.length,
            itemBuilder: (context, index) {
              final patient = paginatedPatients[index];
              final isSelected = selection.patientId == patient.patientId;
              return _buildPatientCard(patient, isSelected);
            },
          ),
        ),

        // Pagination controls
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: HospitalTheme.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: filterState.currentPage > 0
                      ? () => ref.read(filterProvider.notifier).previousPage()
                      : null,
                  tooltip: 'Previous page',
                  color: HospitalTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Page ${filterState.currentPage + 1} of $totalPages',
                  style: const TextStyle(
                    color: HospitalTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: filterState.currentPage < totalPages - 1
                      ? () => ref.read(filterProvider.notifier).nextPage()
                      : null,
                  tooltip: 'Next page',
                  color: HospitalTheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPatientCard(Patient patient, bool isSelected) {
    // Extract notes from the first admission record
    String admitNotes = '';
    String sectionInfo = '';
    String bedInfo = '';
    bool hasBed = false;

    if (patient.admissionRecords.isNotEmpty) {
      AdmissionRecord record = patient.admissionRecords.first;
      admitNotes = record.admitNotes ?? '';

      if (record.section != null) {
        sectionInfo = '${record.section!.name} (${record.section!.type})';
      }

      if (record.bedNumber != null) {
        bedInfo = 'Bed ${record.bedNumber}';
        hasBed = true;
      } else {
        bedInfo = 'No bed assigned';
        hasBed = false;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () =>
            ref.read(selectionProvider.notifier).selectPatient(patient),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasBed
                          ? HospitalTheme.success
                          : HospitalTheme.warning,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Patient avatar
                  CircleAvatar(
                    backgroundColor: hasBed
                        ? HospitalTheme.success.withOpacity(0.2)
                        : HospitalTheme.warning.withOpacity(0.2),
                    child: Text(
                      patient.name.isNotEmpty
                          ? patient.name.substring(0, 1).toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: hasBed
                            ? HospitalTheme.success
                            : HospitalTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Patient info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'ID: ${patient.patientId}',
                              style: const TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${patient.gender}, ${patient.age}',
                              style: const TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bed status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasBed
                          ? HospitalTheme.success.withOpacity(0.1)
                          : HospitalTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasBed
                            ? HospitalTheme.success
                            : HospitalTheme.warning,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasBed ? Icons.bed : Icons.bed_outlined,
                          size: 16,
                          color: hasBed
                              ? HospitalTheme.success
                              : HospitalTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasBed ? 'Assigned' : 'Needs Bed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasBed
                                ? HospitalTheme.success
                                : HospitalTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bed and section information (if assigned)
              if (sectionInfo.isNotEmpty || bedInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (bedInfo.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.bed,
                              size: 16,
                              color: hasBed
                                  ? HospitalTheme.primary
                                  : HospitalTheme.textMedium),
                          const SizedBox(width: 4),
                          Text(
                            bedInfo,
                            style: TextStyle(
                              color: hasBed
                                  ? HospitalTheme.primary
                                  : HospitalTheme.textMedium,
                              fontWeight:
                                  hasBed ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 12),
                    if (sectionInfo.isNotEmpty)
                      Expanded(
                        child: Text(
                          sectionInfo,
                          style: const TextStyle(
                            color: HospitalTheme.textMedium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],

              // Admit notes (highlighted) - show only if selected or contains important keywords
              if (admitNotes.isNotEmpty &&
                  (isSelected ||
                      admitNotes.toLowerCase().contains('urgent') ||
                      admitNotes.toLowerCase().contains('emergency'))) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HospitalTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: HospitalTheme.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.note_alt,
                        size: 16,
                        color: HospitalTheme.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          admitNotes,
                          style: const TextStyle(
                            color: HospitalTheme.textDark,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                          maxLines: isSelected ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientsSidebar(Size size) {
    final uiState = ref.watch(uiStateProvider);
    final selection = ref.watch(selectionProvider);
    final typeStats = ref.watch(typeStatsProvider);
    final paginatedPatients = ref.watch(paginatedPatientsProvider);
    final totalPages = ref.watch(totalPagesProvider);
    final filterState = ref.watch(filterProvider);
    final sections = ref.watch(sectionsProvider);

    return Container(
      width: 340, // Made slightly wider for better content display
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [HospitalTheme.primary, HospitalTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bed, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Bed Assignment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Add an expand/collapse button for the patient list
                IconButton(
                  icon: Icon(
                    uiState.isPatientsExpanded
                        ? Icons.unfold_less
                        : Icons.unfold_more,
                    color: Colors.white,
                  ),
                  onPressed: () => ref
                      .read(uiStateProvider.notifier)
                      .togglePatientsExpanded(),
                  tooltip: uiState.isPatientsExpanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),
          ),

          // Bed stats - Collapsible if needed
          if (!uiState.isPatientsExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.cardBackground,
                border: Border(
                  top: BorderSide(color: HospitalTheme.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hospital Stats',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (uiState.isLoadingSections)
                    const Center(child: CircularProgressIndicator())
                  else
                    ...typeStats.map((stat) => _buildStatItem(stat)),
                ],
              ),
            ),

          const Divider(height: 1),

          // Patient selection section - Enhanced with search and filters
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search and filter bar
                _buildSearchAndFilterBar(),

                // Patient list header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Admitted Patients',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      Row(
                        children: [
                          // Sort options dropdown
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: HospitalTheme.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            child: DropdownButton<String>(
                              value: filterState.sortOrder,
                              isDense: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Newest',
                                  child: Text('Newest',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                DropdownMenuItem(
                                  value: 'Name',
                                  child: Text('Name',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                DropdownMenuItem(
                                  value: 'ID',
                                  child: Text('ID',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  ref
                                      .read(filterProvider.notifier)
                                      .updateSortOrder(value);
                                }
                              },
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Refresh button
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: fetchAdmittedPatients,
                            tooltip: 'Refresh',
                            color: HospitalTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // The patient list itself
                Expanded(
                  child: _buildPatientsList(),
                ),
              ],
            ),
          ),

          // Assignment section
          if (selection.patient != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                border: Border(
                  top: BorderSide(color: HospitalTheme.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bed Assignment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            ref.read(selectionProvider.notifier).clear(),
                        tooltip: 'Clear selection',
                        color: HospitalTheme.textMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Patient: ${selection.patient!.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selection.sectionId != null && selection.bedNumber != null
                        ? 'Selected: ${sections.firstWhere((s) => s.id == selection.sectionId).name} - Bed ${selection.bedNumber}'
                        : 'Select a section and bed from the right panel',
                    style: const TextStyle(
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: selection.sectionId != null &&
                            selection.bedNumber != null
                        ? assignBedToPatient
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Assign Bed'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final filterState = ref.watch(filterProvider);
    final filteredPatients = ref.watch(filteredPatientsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search input
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or ID',
              prefixIcon:
                  const Icon(Icons.search, color: HospitalTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: HospitalTheme.border),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              isDense: true,
            ),
            onChanged: (value) =>
                ref.read(filterProvider.notifier).updateSearchQuery(value),
          ),

          const SizedBox(height: 12),

          // Filter buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('No Bed'),
                const SizedBox(width: 8),
                _buildFilterChip('Has Bed'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Stats bar showing count
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing: ${filteredPatients.length} patient${filteredPatients.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: 13,
                  ),
                ),
                if (filterState.searchQuery.isNotEmpty ||
                    filterState.selectedFilter != 'All')
                  GestureDetector(
                    onTap: () =>
                        ref.read(filterProvider.notifier).resetFilters(),
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(
                        color: HospitalTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final filterState = ref.watch(filterProvider);
    final isSelected = filterState.selectedFilter == label;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: HospitalTheme.primary.withOpacity(0.2),
      checkmarkColor: HospitalTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? HospitalTheme.primary : HospitalTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
        ),
      ),
      onSelected: (bool selected) {
        ref
            .read(filterProvider.notifier)
            .updateFilter(selected ? label : 'All');
      },
    );
  }

  // Rest of the widget methods and model classes...

  Widget _buildBedItem({
    required Section section,
    required int bedNumber,
    required bool isAvailable,
    required bool isSelected,
    required String type,
    OccupiedBed? patientInfo,
  }) {
    IconData icon = type == 'Icu' ? Icons.local_hospital : Icons.bed;

    Color color;
    if (isSelected) {
      color = HospitalTheme.primary;
    } else if (isAvailable) {
      color = HospitalTheme.success;
    } else {
      color = HospitalTheme.error;
    }

    return Tooltip(
      message: isAvailable
          ? 'Bed $bedNumber (Available)'
          : patientInfo != null
              ? 'Bed $bedNumber - ${patientInfo.patientName} (${patientInfo.patientId})'
              : 'Bed $bedNumber (Occupied)',
      child: Container(
        width: 60, // Reduced for compactness
        height: 60, // Reduced for compactness
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (isAvailable && ref.read(selectionProvider).patient != null) {
                // Select this bed for assignment
                ref
                    .read(selectionProvider.notifier)
                    .selectBed(section.id, bedNumber);
              } else if (!isAvailable && patientInfo != null) {
                // Show patient details or options to change
                showDialog(
                  context: context,
                  builder: (context) =>
                      _buildPatientDetailsDialog(section, patientInfo),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20), // Smaller icon
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  'Bed $bedNumber',
                  style: TextStyle(
                    fontSize: 10, // Smaller text
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isAvailable && patientInfo != null)
                  Text(
                    patientInfo.patientId,
                    style: TextStyle(
                      fontSize: 8, // Smaller text
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OccupiedBed? _getPatientInfoForBed(Section section, int bedNumber) {
    if (!section.isBedsDataLoaded) return null;

    try {
      return section.occupiedBeds
          .firstWhere((bed) => bed.bedNumber == bedNumber);
    } catch (e) {
      return null; // No patient in this bed
    }
  }

  // Improved Patient Details Dialog function
  Widget _buildPatientDetailsDialog(Section section, OccupiedBed patientInfo) {
    // Use Builder to get the correct context for navigation
    return Builder(builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Patient Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            // Added for responsiveness
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientDetailRow('Section', section.name),
                _buildPatientDetailRow(
                    'Bed Number', patientInfo.bedNumber.toString()),
                _buildPatientDetailRow('Patient ID', patientInfo.patientId),
                _buildPatientDetailRow('Patient Name', patientInfo.patientName),
                _buildPatientDetailRow(
                  'Admission Date',
                  '${patientInfo.admissionDate.day}/${patientInfo.admissionDate.month}/${patientInfo.admissionDate.year}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Use the correct context to pop the dialog
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Pop the dialog first to remove it from the navigation stack
              Navigator.of(dialogContext).pop();

              // Find the patient in the admitted list and select for bed transfer
              final patients = ref.read(admittedPatientsProvider);
              try {
                final patient = patients.firstWhere(
                  (p) => p.patientId == patientInfo.patientId,
                );

                // Select this patient for bed transfer
                ref.read(selectionProvider.notifier).selectPatient(patient);

                // Show a snackbar with instructions
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Select a new bed for ${patientInfo.patientName}'),
                    backgroundColor: HospitalTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('Patient data not found in admitted list'),
                    backgroundColor: HospitalTheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.warning,
            ),
            child: const Text('Change Bed'),
          ),
        ],
      );
    });
  }

  // Model classes with null safety

  // Note: Add these at the end of the file

  Widget _buildPatientDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: HospitalTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: HospitalTheme.textDark,
          ),
        ),
      ],
    );
  }

  Color _getSectionColor(String type) {
    switch (type) {
      case 'Icu':
        return HospitalTheme.medical;
      case 'Ward':
        return HospitalTheme.laboratory;
      default:
        return HospitalTheme.pharmacy;
    }
  }

  IconData _getSectionIcon(String type) {
    switch (type) {
      case 'Icu':
        return Icons.medical_services;
      case 'Ward':
        return Icons.local_hospital;
      default:
        return Icons.bed;
    }
  }
}

// Model classes with null safety

class Section {
  final String id;
  final String name;
  final String type;
  final int totalBeds;
  final int availableBeds;
  final bool isActive;
  final DateTime createdAt;
  final List<int> availableBedNumbers;
  final List<OccupiedBed> occupiedBeds;
  final bool isBedsDataLoaded;

  Section({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBeds,
    required this.availableBeds,
    required this.isActive,
    required this.createdAt,
    this.availableBedNumbers = const [],
    this.occupiedBeds = const [],
    this.isBedsDataLoaded = false,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      totalBeds: json['totalBeds'] ?? 0,
      availableBeds: json['availableBeds'] ?? 0,
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Section copyWith({
    String? id,
    String? name,
    String? type,
    int? totalBeds,
    int? availableBeds,
    bool? isActive,
    DateTime? createdAt,
    List<int>? availableBedNumbers,
    List<OccupiedBed>? occupiedBeds,
    bool? isBedsDataLoaded,
  }) {
    return Section(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      totalBeds: totalBeds ?? this.totalBeds,
      availableBeds: availableBeds ?? this.availableBeds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      availableBedNumbers: availableBedNumbers ?? this.availableBedNumbers,
      occupiedBeds: occupiedBeds ?? this.occupiedBeds,
      isBedsDataLoaded: isBedsDataLoaded ?? this.isBedsDataLoaded,
    );
  }
}

class OccupiedBed {
  final int bedNumber;
  final String patientId;
  final String patientName;
  final DateTime admissionDate;

  OccupiedBed({
    required this.bedNumber,
    required this.patientId,
    required this.patientName,
    required this.admissionDate,
  });

  factory OccupiedBed.fromJson(Map<String, dynamic> json) {
    return OccupiedBed(
      bedNumber: json['bedNumber'] ?? 0,
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      admissionDate:
          DateTime.tryParse(json['admissionDate'] ?? '') ?? DateTime.now(),
    );
  }
}

class TypeStat {
  final String id;
  final int count;
  final int totalBeds;
  final int availableBeds;

  TypeStat({
    required this.id,
    required this.count,
    required this.totalBeds,
    required this.availableBeds,
  });

  factory TypeStat.fromJson(Map<String, dynamic> json) {
    return TypeStat(
      id: json['_id'] ?? '',
      count: json['count'] ?? 0,
      totalBeds: json['totalBeds'] ?? 0,
      availableBeds: json['availableBeds'] ?? 0,
    );
  }

  double get occupancyRate {
    if (totalBeds == 0) return 0.0;
    return (totalBeds - availableBeds) / totalBeds;
  }
}

class Patient {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String? contact;
  final String? address;
  final String? imageUrl;
  final bool discharged;
  final int pendingAmount;
  final List<AdmissionRecord> admissionRecords;

  Patient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    this.contact,
    this.address,
    this.imageUrl,
    required this.discharged,
    required this.pendingAmount,
    required this.admissionRecords,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'],
      address: json['address'],
      imageUrl: json['imageUrl'],
      discharged: json['discharged'] ?? false,
      pendingAmount: json['pendingAmount'] ?? 0,
      admissionRecords: json['admissionRecords'] != null
          ? (json['admissionRecords'] as List)
              .map((record) => AdmissionRecord.fromJson(record))
              .toList()
          : [],
    );
  }
}

class SectionInfo {
  final String id;
  final String name;
  final String type;

  SectionInfo({
    required this.id,
    required this.name,
    required this.type,
  });

  factory SectionInfo.fromJson(Map<String, dynamic> json) {
    return SectionInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class DoctorInfo {
  final String id;
  final String name;

  DoctorInfo({
    required this.id,
    required this.name,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class AdmissionRecord {
  final String id;
  final DateTime admissionDate;
  final String status;
  final String? reasonForAdmission;
  final String? symptoms;
  final String? initialDiagnosis;
  final String? admitNotes;
  final int? bedNumber;
  final DoctorInfo? doctor;
  final SectionInfo? section;

  AdmissionRecord({
    required this.id,
    required this.admissionDate,
    required this.status,
    this.reasonForAdmission,
    this.symptoms,
    this.initialDiagnosis,
    this.admitNotes,
    this.bedNumber,
    this.doctor,
    this.section,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      id: json['_id'] ?? '',
      admissionDate:
          DateTime.tryParse(json['admissionDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      reasonForAdmission: json['reasonForAdmission'],
      symptoms: json['symptoms'],
      initialDiagnosis: json['initialDiagnosis'],
      admitNotes: json['admitNotes'],
      bedNumber: json['bedNumber'],
      doctor:
          json['doctor'] != null ? DoctorInfo.fromJson(json['doctor']) : null,
      section: json['section'] != null
          ? SectionInfo.fromJson(json['section'])
          : null,
    );
  }
}
