import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doctordesktop/constants/HospitalTheme.dart';

class ReceptionBedManagementScreen extends StatefulWidget {
  const ReceptionBedManagementScreen({Key? key}) : super(key: key);

  @override
  _ReceptionBedManagementScreenState createState() =>
      _ReceptionBedManagementScreenState();
}

class _ReceptionBedManagementScreenState
    extends State<ReceptionBedManagementScreen> {
  List<Section> sections = [];
  List<TypeStat> typeStats = [];
  List<Patient> admittedPatients = [];
  bool isLoadingSections = false;
  bool isLoadingPatients = false;
  int expandedSectionIndex = -1;

  // For bed assignment
  String? selectedPatientId;
  String? selectedAdmissionId;
  String? selectedSectionId;
  int? selectedBedNumber;
  Patient? selectedPatient;

  // For patient filtering and searching
  String searchQuery = '';
  String selectedFilter = 'All';
  List<Patient> filteredPatients = [];
  String sortOrder = 'Newest';

  // For patient details panel
  bool isPatientsExpanded = true;

  // For pagination
  int patientsPerPage = 5;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    fetchSections();
    fetchAdmittedPatients();
  }

  Future<void> fetchSections() async {
    setState(() {
      isLoadingSections = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/admin/getAllSections'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Clear existing data first
        setState(() {
          sections = (data['data'] as List)
              .map((json) => Section.fromJson(json))
              .toList();
          typeStats = (data['typeStats'] as List)
              .map((json) => TypeStat.fromJson(json))
              .toList();

          // Force reset of bed data flags
          for (var section in sections) {
            section.isBedsDataLoaded = false;
          }

          isLoadingSections = false;
        });

        // If a section is expanded, refresh its bed details
        if (expandedSectionIndex >= 0 &&
            expandedSectionIndex < sections.length) {
          fetchSectionBedDetails(
              sections[expandedSectionIndex], expandedSectionIndex);
        }
      } else {
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      setState(() {
        isLoadingSections = false;
      });
      showErrorSnackBar('Error loading sections: $e');
    }
  }

  Future<void> fetchAdmittedPatients() async {
    setState(() {
      isLoadingPatients = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/getAdmittedPatients'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          admittedPatients = (data['data'] as List)
              .map((json) => Patient.fromJson(json))
              .toList();
          applyFiltersAndSearch(); // Apply filters and search after loading
          isLoadingPatients = false;
        });
      } else {
        throw Exception('Failed to load admitted patients');
      }
    } catch (e) {
      setState(() {
        isLoadingPatients = false;
      });
      showErrorSnackBar('Error loading admitted patients: $e');
    }
  }

  // Add this new method for filtering and searching
  void applyFiltersAndSearch() {
    setState(() {
      filteredPatients = admittedPatients.where((patient) {
        // Apply search filter
        final nameMatches =
            patient.name.toLowerCase().contains(searchQuery.toLowerCase());
        final idMatches =
            patient.patientId.toLowerCase().contains(searchQuery.toLowerCase());
        final searchMatches = nameMatches || idMatches;

        // Apply status filter
        bool statusMatches = true;
        if (selectedFilter != 'All') {
          if (selectedFilter == 'No Bed') {
            // Check if patient has no bed assigned
            statusMatches = patient.admissionRecords.isNotEmpty &&
                (patient.admissionRecords.first.bedNumber == null);
          } else if (selectedFilter == 'Has Bed') {
            // Check if patient has a bed assigned
            statusMatches = patient.admissionRecords.isNotEmpty &&
                (patient.admissionRecords.first.bedNumber != null);
          }
        }

        return searchMatches && statusMatches;
      }).toList();

      // Apply sorting
      if (sortOrder == 'Name') {
        filteredPatients.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortOrder == 'ID') {
        filteredPatients.sort((a, b) => a.patientId.compareTo(b.patientId));
      } else {
        // Sort by newest (default) - assuming admission date is the indicator
        filteredPatients.sort((a, b) {
          if (a.admissionRecords.isEmpty) return 1;
          if (b.admissionRecords.isEmpty) return -1;
          return b.admissionRecords.first.admissionDate
              .compareTo(a.admissionRecords.first.admissionDate);
        });
      }

      // Reset to first page when filtering changes
      currentPage = 0;
    });
  }

  // Add pagination helpers
  int get totalPages => (filteredPatients.length / patientsPerPage).ceil();
  List<Patient> get paginatedPatients {
    final startIndex = currentPage * patientsPerPage;
    final endIndex = (startIndex + patientsPerPage < filteredPatients.length)
        ? startIndex + patientsPerPage
        : filteredPatients.length;

    if (startIndex >= filteredPatients.length) {
      return [];
    }

    return filteredPatients.sublist(startIndex, endIndex);
  }

  Future<void> fetchSectionBedDetails(Section section, int sectionIndex) async {
    if (section.isBedsDataLoaded) return; // Skip if already loaded

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

          // Ensure we're still in the widget tree before updating state
          if (mounted) {
            setState(() {
              // Create a new section object with updated data from the API
              sections[sectionIndex] = Section(
                id: section.id,
                name: section.name,
                type: section.type,
                totalBeds: section.totalBeds,
                availableBeds: updatedAvailableBeds, // Use the value from API
                isActive: section.isActive,
                createdAt: section.createdAt,
              );

              // Then update its bed details
              sections[sectionIndex].availableBedNumbers = availableBedsList;
              sections[sectionIndex].occupiedBeds = occupiedBedsList;
              sections[sectionIndex].isBedsDataLoaded = true;
            });
          }
        }
      }
    } catch (e) {
      showErrorSnackBar('Error loading bed details: $e');
    }
  }

  Future<void> assignBedToPatient() async {
    if (selectedPatientId == null ||
        selectedSectionId == null ||
        selectedBedNumber == null ||
        selectedAdmissionId == null) {
      showErrorSnackBar('Please select patient, section, and bed');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/assignBedToPatient'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': selectedPatientId,
          'sectionId': selectedSectionId,
          'bedNumber': selectedBedNumber,
          'admissionRecordId': selectedAdmissionId,
        }),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar('Bed assigned successfully');

        // Reset selection first
        setState(() {
          selectedPatientId = null;
          selectedSectionId = null;
          selectedBedNumber = null;
          selectedAdmissionId = null;
          selectedPatient = null;
        });

        // Force a complete refresh of all data
        await fetchSections();
        await fetchAdmittedPatients();

        // Also reset the bed data loaded flag for the section that was modified
        setState(() {
          final sectionIndex =
              sections.indexWhere((s) => s.id == selectedSectionId);
          if (sectionIndex != -1) {
            sections[sectionIndex].isBedsDataLoaded = false;
            // If the section is expanded, refresh its bed details
            if (expandedSectionIndex == sectionIndex) {
              fetchSectionBedDetails(sections[sectionIndex], sectionIndex);
            }
          }
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to assign bed');
      }
    } catch (e) {
      showErrorSnackBar('Error assigning bed: $e');
    }
  }

  void toggleSectionExpansion(int index) {
    setState(() {
      if (expandedSectionIndex == index) {
        expandedSectionIndex = -1; // Collapse if already expanded
      } else {
        expandedSectionIndex = index; // Expand this section
        // Load bed details if not already loaded
        if (!sections[index].isBedsDataLoaded) {
          fetchSectionBedDetails(sections[index], index);
        }
      }
    });
  }

  void selectBed(Section section, int bedNumber) {
    setState(() {
      selectedSectionId = section.id;
      selectedBedNumber = bedNumber;
    });
  }

  void selectPatient(Patient patient) {
    setState(() {
      selectedPatient = patient;
      selectedPatientId = patient.patientId;
      if (patient.admissionRecords.isNotEmpty) {
        selectedAdmissionId = patient.admissionRecords.first.id;
      }
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Hospital Bed Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              // Show a loading indicator
              setState(() {
                isLoadingSections = true;
                isLoadingPatients = true;
              });

              // Reset all section data flags
              for (var section in sections) {
                section.isBedsDataLoaded = false;
              }

              // Await both fetch operations
              await fetchSections();
              await fetchAdmittedPatients();

              showSuccessSnackBar('Data refreshed successfully');
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left sidebar - Enhanced Patient List
          Container(
            width: 340, // Made slightly wider for better content display
            color: HospitalTheme.background,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HospitalTheme.primary,
                        HospitalTheme.primaryLight
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bed, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
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
                          isPatientsExpanded
                              ? Icons.unfold_less
                              : Icons.unfold_more,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            isPatientsExpanded = !isPatientsExpanded;
                          });
                        },
                        tooltip: isPatientsExpanded ? 'Collapse' : 'Expand',
                      ),
                    ],
                  ),
                ),

                // Bed stats - Collapsible if needed
                if (!isPatientsExpanded)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: HospitalTheme.cardBackground,
                      border: Border(
                        top: BorderSide(color: HospitalTheme.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hospital Stats',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (isLoadingSections)
                          Center(child: CircularProgressIndicator())
                        else
                          ...typeStats.map((stat) => _buildStatItem(stat)),
                      ],
                    ),
                  ),

                Divider(height: 1),

                // Patient selection section - Enhanced with search and filters
                Expanded(
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search and filter bar
                        _buildSearchAndFilterBar(),

                        // Patient list header
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
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
                                      border: Border.all(
                                          color: HospitalTheme.border),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    child: DropdownButton<String>(
                                      value: sortOrder,
                                      isDense: true,
                                      underline: SizedBox(),
                                      icon:
                                          Icon(Icons.arrow_drop_down, size: 16),
                                      items: [
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
                                          setState(() {
                                            sortOrder = value;
                                            applyFiltersAndSearch();
                                          });
                                        }
                                      },
                                    ),
                                  ),

                                  SizedBox(width: 8),

                                  // Refresh button
                                  IconButton(
                                    icon: Icon(Icons.refresh, size: 18),
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
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
                ),

                // Assignment section
                if (selectedPatient != null)
                  Container(
                    padding: EdgeInsets.all(16),
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
                            Text(
                              'Bed Assignment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  selectedPatientId = null;
                                  selectedSectionId = null;
                                  selectedBedNumber = null;
                                  selectedAdmissionId = null;
                                  selectedPatient = null;
                                });
                              },
                              tooltip: 'Clear selection',
                              color: HospitalTheme.textMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Patient: ${selectedPatient!.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          selectedSectionId != null && selectedBedNumber != null
                              ? 'Selected: ${sections.firstWhere((s) => s.id == selectedSectionId).name} - Bed $selectedBedNumber'
                              : 'Select a section and bed from the right panel',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: selectedSectionId != null &&
                                  selectedBedNumber != null
                              ? assignBedToPatient
                              : null,
                          child: Text('Assign Bed'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 44),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with action buttons
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hospital Sections',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      if (selectedPatient != null)
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: HospitalTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Assigning: ${selectedPatient!.name} (${selectedPatient!.patientId})',
                            style: TextStyle(
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
                  child: isLoadingSections
                      ? Center(child: CircularProgressIndicator())
                      : sections.isEmpty
                          ? Center(
                              child: Text(
                                'No sections found.',
                                style:
                                    TextStyle(color: HospitalTheme.textMedium),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: sections.length,
                              itemBuilder: (context, index) {
                                return _buildSectionCard(
                                    sections[index], index);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search input
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or ID',
              prefixIcon: Icon(Icons.search, color: HospitalTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: HospitalTheme.border),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                applyFiltersAndSearch();
              });
            },
          ),

          SizedBox(height: 12),

          // Filter buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                SizedBox(width: 8),
                _buildFilterChip('No Bed'),
                SizedBox(width: 8),
                _buildFilterChip('Has Bed'),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Stats bar showing count
          Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing: ${filteredPatients.length} patient${filteredPatients.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: 13,
                  ),
                ),
                if (searchQuery.isNotEmpty || selectedFilter != 'All')
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        searchQuery = '';
                        selectedFilter = 'All';
                        applyFiltersAndSearch();
                      });
                    },
                    child: Text(
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
    final isSelected = selectedFilter == label;

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
        setState(() {
          selectedFilter = selected ? label : 'All';
          applyFiltersAndSearch();
        });
      },
    );
  }

  Widget _buildPatientsList() {
    if (isLoadingPatients) {
      return Center(child: CircularProgressIndicator());
    }

    if (admittedPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Icon(Icons.search_off, size: 48, color: HospitalTheme.textMedium),
            SizedBox(height: 16),
            Text(
              'No patients match your filters',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.clear),
              label: Text('Clear Filters'),
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  selectedFilter = 'All';
                  applyFiltersAndSearch();
                });
              },
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
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: paginatedPatients.length,
            itemBuilder: (context, index) {
              final patient = paginatedPatients[index];
              final isSelected = selectedPatientId == patient.patientId;
              return _buildPatientCard(patient, isSelected);
            },
          ),
        ),

        // Pagination controls
        if (totalPages > 1)
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
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
                  icon: Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: currentPage > 0
                      ? () => setState(() => currentPage--)
                      : null,
                  tooltip: 'Previous page',
                  color: HospitalTheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Page ${currentPage + 1} of $totalPages',
                  style: TextStyle(
                    color: HospitalTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: currentPage < totalPages - 1
                      ? () => setState(() => currentPage++)
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
      margin: EdgeInsets.only(bottom: 8),
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
        onTap: () => selectPatient(patient),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
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
                  SizedBox(width: 8),

                  // Patient avatar
                  CircleAvatar(
                    backgroundColor: hasBed
                        ? HospitalTheme.success.withOpacity(0.2)
                        : HospitalTheme.warning.withOpacity(0.2),
                    child: Text(
                      patient.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: hasBed
                            ? HospitalTheme.success
                            : HospitalTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),

                  // Patient info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'ID: ${patient.patientId}',
                              style: TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '• ${patient.gender}, ${patient.age}',
                              style: TextStyle(
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        SizedBox(width: 4),
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
                SizedBox(height: 8),
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
                          SizedBox(width: 4),
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
                    SizedBox(width: 12),
                    if (sectionInfo.isNotEmpty)
                      Expanded(
                        child: Text(
                          sectionInfo,
                          style: TextStyle(
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
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HospitalTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: HospitalTheme.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_alt,
                        size: 16,
                        color: HospitalTheme.warning,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          admitNotes,
                          style: TextStyle(
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
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statIcon, color: statColor, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${stat.availableBeds}/${stat.totalBeds} beds available',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                SizedBox(height: 6),
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

  Widget _buildSectionCard(Section section, int index) {
    bool isExpanded = index == expandedSectionIndex;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with expand button
          InkWell(
            onTap: () => toggleSectionExpansion(index),
            child: Container(
              padding: EdgeInsets.all(16),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.name,
                      style: TextStyle(
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
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: HospitalTheme.primary,
                    ),
                    onPressed: () => toggleSectionExpansion(index),
                    tooltip: isExpanded ? 'Collapse' : 'Expand',
                  ),
                ],
              ),
            ),
          ),

          // Overview stats
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSectionInfoCard(
                  icon: Icons.bed,
                  title: 'Total Beds',
                  value: section.totalBeds.toString(),
                  color: HospitalTheme.primary,
                ),
                SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.check_circle,
                  title: 'Available',
                  value: section.availableBeds.toString(),
                  color: HospitalTheme.success,
                ),
                SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.person,
                  title: 'Occupied',
                  value: (section.totalBeds - section.availableBeds).toString(),
                  color: HospitalTheme.warning,
                ),
                SizedBox(width: 16),
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bed Layout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Show loading indicator while fetching bed details
                  section.isBedsDataLoaded
                      ? _buildBedLayout(section)
                      : Center(
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

  Widget _buildSectionInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
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
      padding: EdgeInsets.all(16),
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
          SizedBox(height: 16),

          // Theater-style layout for beds
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Entrance indicator
                Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ENTRANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),

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
                                  : row * bedsPerRow + col <
                                      section.availableBeds,
                              isSelected: selectedSectionId == section.id &&
                                  selectedBedNumber ==
                                      row * bedsPerRow + col + 1,
                              type: section.type,
                              patientInfo: section.isBedsDataLoaded
                                  ? _getPatientInfoForBed(
                                      section, row * bedsPerRow + col + 1)
                                  : null,
                            ),
                            if (col < bedsPerRow - 1) SizedBox(width: 8),
                          ],
                      ],
                    ),
                  ),

                // Nurse station
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HospitalTheme.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

// Update the bed item to be more compact for better fit
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
        width: 60, // Reduced from 70
        height: 60, // Reduced from 70
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
              if (isAvailable && selectedPatient != null) {
                // Select this bed for assignment
                selectBed(section, bedNumber);
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
                SizedBox(height: 2), // Reduced spacing
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

  Widget _buildOccupiedBedsTable(Section section) {
    if (section.occupiedBeds.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Occupied Beds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          SizedBox(height: 12),
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
                columns: [
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: HospitalTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: HospitalTheme.error),
                          ),
                          child: Text(
                            'Bed ${bed.bedNumber}',
                            style: TextStyle(
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
                              icon: Icon(Icons.visibility,
                                  color: HospitalTheme.primary),
                              onPressed: () {
                                // View patient details
                              },
                              tooltip: 'View Patient',
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: Icon(Icons.swap_horiz,
                                  color: HospitalTheme.warning),
                              onPressed: () {
                                // Transfer patient to another bed
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
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: HospitalTheme.textDark,
          ),
        ),
      ],
    );
  }

  // Widget _buildBedItem({
  //   required Section section,
  //   required int bedNumber,
  //   required bool isAvailable,
  //   required bool isSelected,
  //   required String type,
  //   OccupiedBed? patientInfo,
  // }) {
  //   IconData icon = type == 'Icu' ? Icons.local_hospital : Icons.bed;

  //   Color color;
  //   if (isSelected) {
  //     color = HospitalTheme.primary;
  //   } else if (isAvailable) {
  //     color = HospitalTheme.success;
  //   } else {
  //     color = HospitalTheme.error;
  //   }

  //   return Tooltip(
  //     message: isAvailable
  //         ? 'Bed $bedNumber (Available)'
  //         : patientInfo != null
  //             ? 'Bed $bedNumber - ${patientInfo.patientName} (${patientInfo.patientId})'
  //             : 'Bed $bedNumber (Occupied)',
  //     child: Container(
  //       width: 70,
  //       height: 70,
  //       decoration: BoxDecoration(
  //         color: color.withOpacity(0.2),
  //         borderRadius: BorderRadius.circular(8),
  //         border: Border.all(color: color, width: isSelected ? 2 : 1),
  //       ),
  //       child: Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           borderRadius: BorderRadius.circular(8),
  //           onTap: () {
  //             if (isAvailable && selectedPatient != null) {
  //               // Select this bed for assignment
  //               selectBed(section, bedNumber);
  //             } else if (!isAvailable && patientInfo != null) {
  //               // Show patient details or options to change
  //               showDialog(
  //                 context: context,
  //                 builder: (context) =>
  //                     _buildPatientDetailsDialog(section, patientInfo),
  //               );
  //             }
  //           },
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(icon, color: color),
  //               SizedBox(height: 4),
  //               Text(
  //                 'Bed $bedNumber',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.bold,
  //                   color: color,
  //                 ),
  //               ),
  //               if (!isAvailable && patientInfo != null)
  //                 Text(
  //                   patientInfo.patientId,
  //                   style: TextStyle(
  //                     fontSize: 10,
  //                     color: color,
  //                   ),
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPatientDetailsDialog(Section section, OccupiedBed patientInfo) {
    return AlertDialog(
      title: Text('Patient Details'),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientDetailRow('Section', section.name),
            _buildPatientDetailRow(
                'Bed Number', patientInfo.bedNumber.toString()),
            _buildPatientDetailRow('Patient ID', patientInfo.patientId),
            _buildPatientDetailRow('Patient Name', patientInfo.patientName),
            _buildPatientDetailRow('Admission Date',
                '${patientInfo.admissionDate.day}/${patientInfo.admissionDate.month}/${patientInfo.admissionDate.year}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Option to change bed
            Navigator.pop(context);

            // Find the patient in the admitted list
            try {
              final patient = admittedPatients
                  .firstWhere((p) => p.patientId == patientInfo.patientId);

              // Select this patient for bed transfer
              selectPatient(patient);

              // Show a snackbar with instructions
              showSuccessSnackBar(
                  'Select a new bed for ${patientInfo.patientName}');
            } catch (e) {
              showErrorSnackBar('Patient data not found in admitted list');
            }
          },
          child: Text('Change Bed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: HospitalTheme.warning,
          ),
        ),
      ],
    );
  }

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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: HospitalTheme.textDark,
              ),
            ),
          ),
        ],
      ),
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

// Model classes

class Section {
  final String id;
  final String name;
  final String type;
  final int totalBeds;
  final int availableBeds;
  final bool isActive;
  final DateTime createdAt;
  List<int> availableBedNumbers = [];
  List<OccupiedBed> occupiedBeds = [];
  bool isBedsDataLoaded = false;

  Section({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBeds,
    required this.availableBeds,
    required this.isActive,
    required this.createdAt,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      totalBeds: json['totalBeds'],
      availableBeds: json['availableBeds'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
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
      bedNumber: json['bedNumber'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      admissionDate: DateTime.parse(json['admissionDate']),
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
      id: json['_id'],
      count: json['count'],
      totalBeds: json['totalBeds'],
      availableBeds: json['availableBeds'],
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
  final String contact;
  final String address;
  final String imageUrl;
  final bool discharged;
  final int pendingAmount;
  final List<AdmissionRecord> admissionRecords;

  Patient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    required this.imageUrl,
    required this.discharged,
    required this.pendingAmount,
    required this.admissionRecords,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'],
      patientId: json['patientId'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      contact: json['contact'],
      address: json['address'],
      imageUrl: json['imageUrl'],
      discharged: json['discharged'],
      pendingAmount: json['pendingAmount'],
      admissionRecords: (json['admissionRecords'] as List)
          .map((record) => AdmissionRecord.fromJson(record))
          .toList(),
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
      id: json['id'],
      name: json['name'],
      type: json['type'],
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
      id: json['id'],
      name: json['name'],
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
      id: json['_id'],
      admissionDate: DateTime.parse(json['admissionDate']),
      status: json['status'],
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
