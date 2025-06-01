import 'dart:convert';

import 'package:doctordesktop/reception/ManualDischargeSummaryScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/patientDischargeModel.dart';
import 'package:doctordesktop/reception/GenerateBillScreen.dart';
import 'package:doctordesktop/reception/GenerateOpdBill.dart';
import 'package:doctordesktop/reception/ExportSummaryScreen.dart';

// PatientFilters class - stays mostly the same but with some optimizations
class PatientFilters {
  String searchQuery = '';
  String doctorType = 'All'; // 'All', 'doctor' (internal), 'external'
  String dateRange =
      'All Time'; // 'All Time', 'Today', 'This Week', 'This Month'

  bool filterPatient(PatientDischarge patient) {
    // Search query filter - optimization to only perform toLowerCase once
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      if (!patient.name.toLowerCase().contains(query) &&
          !patient.patientId.toLowerCase().contains(query) &&
          !patient.contact.toLowerCase().contains(query)) {
        return false;
      }
    }

    // Doctor type filter
    if (doctorType != 'All') {
      final patientDoctorType =
          patient.lastRecord.doctor?.usertype?.toLowerCase() ?? '';
      if (doctorType.toLowerCase() != patientDoctorType) {
        return false;
      }
    }

    // Date range filter
    if (dateRange != 'All Time') {
      final dischargeDate = _parseDateString(patient.lastRecord.dischargeDate);
      if (dischargeDate != null) {
        final now = DateTime.now();

        if (dateRange == 'Today') {
          if (!_isSameDay(dischargeDate, now)) {
            return false;
          }
        } else if (dateRange == 'This Week') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          if (dischargeDate.isBefore(startOfWeek)) {
            return false;
          }
        } else if (dateRange == 'This Month') {
          final startOfMonth = DateTime(now.year, now.month, 1);
          if (dischargeDate.isBefore(startOfMonth)) {
            return false;
          }
        }
      }
    }

    return true;
  }

  DateTime? _parseDateString(String dateStr) {
    try {
      // Example format: "2025-05-01 01:19:23 PM"
      // Parse date part
      final dateParts = dateStr.split(' ')[0].split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time part
      final timeParts = dateStr.split(' ')[1].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      // Handle AM/PM
      final amPm = dateStr.split(' ')[2];
      if (amPm == 'PM' && hour < 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// State notifier for discharged patients
class DischargedPatientsNotifier
    extends StateNotifier<AsyncValue<List<PatientDischarge>>> {
  DischargedPatientsNotifier() : super(const AsyncValue.loading()) {
    fetchDischargedPatients();
  }

  Future<void> fetchDischargedPatients() async {
    try {
      state = const AsyncValue.loading();

      final response = await http
          .get(Uri.parse('${KVM_URL}/reception/getAllDischargedPatient'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final patients =
            data.map((json) => PatientDischarge.fromJson(json)).toList();
        state = AsyncValue.data(patients);
      } else {
        throw Exception(
            'Failed to load discharged patients: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching discharged patients: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> manualRefresh() async {
    await fetchDischargedPatients();
  }
}

// Providers
final dischargedPatientsProvider = StateNotifierProvider<
    DischargedPatientsNotifier, AsyncValue<List<PatientDischarge>>>(
  (ref) => DischargedPatientsNotifier(),
);

final selectedTabProvider = StateProvider<int>((ref) => 0);

final patientFiltersProvider = StateProvider<PatientFilters>((ref) {
  return PatientFilters();
});

class DischargedPatientsScreen1 extends ConsumerStatefulWidget {
  const DischargedPatientsScreen1({Key? key}) : super(key: key);

  @override
  _DischargedPatientsScreenState createState() =>
      _DischargedPatientsScreenState();
}

class _DischargedPatientsScreenState
    extends ConsumerState<DischargedPatientsScreen1>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();

  // We'll use a separate scroll controller for each tab to maintain scroll position
  final ScrollController _allPatientsScrollController = ScrollController();
  final ScrollController _internalPatientsScrollController = ScrollController();
  final ScrollController _externalPatientsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initial data fetch
    ref.read(dischargedPatientsProvider.notifier).fetchDischargedPatients();

    // Setup refresh after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null) {
        route.addScopedWillPopCallback(() async {
          await ref.read(dischargedPatientsProvider.notifier).manualRefresh();
          return true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _mainScrollController.dispose();
    _allPatientsScrollController.dispose();
    _internalPatientsScrollController.dispose();
    _externalPatientsScrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      ref.read(selectedTabProvider.notifier).state = _tabController.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dischargedPatientsAsync = ref.watch(dischargedPatientsProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final filters = ref.watch(patientFiltersProvider);

    // Responsive layout adjustments
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800 && screenSize.width <= 1200;

    // Filtered patient lists by patient type
    List<PatientDischarge> allPatients = [];
    List<PatientDischarge> internalPatients = [];
    List<PatientDischarge> externalPatients = [];

    dischargedPatientsAsync.whenData((patients) {
      // First apply general filters
      final filteredPatients =
          patients.where((p) => filters.filterPatient(p)).toList();

      // Then separate by patient type
      allPatients = filteredPatients;
      internalPatients = filteredPatients
          .where((p) => p.lastRecord.patientType?.toLowerCase() == 'internal')
          .toList();
      externalPatients = filteredPatients
          .where((p) => p.lastRecord.patientType?.toLowerCase() == 'external')
          .toList();
    });

    // Total counts for the status bar
    int totalPatients = allPatients.length;
    int totalInternal = internalPatients.length;
    int totalExternal = externalPatients.length;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filters section
          _buildFilters(isWideScreen),

          // Main content area with tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Patients Tab with its own ScrollController
                _buildPatientList(allPatients, dischargedPatientsAsync,
                    isWideScreen, _allPatientsScrollController),

                // Internal Patients Tab with its own ScrollController
                _buildPatientList(internalPatients, dischargedPatientsAsync,
                    isWideScreen, _internalPatientsScrollController),

                // External Patients Tab with its own ScrollController
                _buildPatientList(externalPatients, dischargedPatientsAsync,
                    isWideScreen, _externalPatientsScrollController),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _buildBottomStatusBar(totalPatients, totalInternal, totalExternal),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Define specific colors for each patient type
    final allPatientsColor = Colors.blue;
    final internalPatientsColor = Colors.green;
    final externalPatientsColor = Colors.orange;

    return AppBar(
      title: Text(
        'Discharged Patients',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
      actions: [
        // Export button with tooltip
        Tooltip(
          message: 'Export Data',
          child: IconButton(
            icon: Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
        ),
        // Refresh button with tooltip
        Tooltip(
          message: 'Refresh Data',
          child: IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(dischargedPatientsProvider.notifier).manualRefresh();
            },
          ),
        ),
        SizedBox(width: 10),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HospitalTheme.primaryDark,
              HospitalTheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      bottom: TabBar(
        controller: _tabController,
        // Make indicator thicker and match tab colors
        indicatorColor: _getCurrentTabColor(),
        indicatorWeight: 4,
        indicatorSize:
            TabBarIndicatorSize.label, // Makes indicator match tab width
        labelStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        // Apply selected colors
        labelColor: _getCurrentTabColor(),
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        tabs: [
          _buildCustomTab(
            icon: Icons.people,
            label: 'All Patients',
            color: allPatientsColor,
            isSelected: _tabController.index == 0,
          ),
          _buildCustomTab(
            icon: Icons.person,
            label: 'Internal',
            color: internalPatientsColor,
            isSelected: _tabController.index == 1,
          ),
          _buildCustomTab(
            icon: Icons.person_outline,
            label: 'External',
            color: externalPatientsColor,
            isSelected: _tabController.index == 2,
          ),
        ],
      ),
    );
  }

// Helper method to get the color for the current tab
  Color _getCurrentTabColor() {
    switch (_tabController.index) {
      case 0:
        return Colors.blue; // All patients
      case 1:
        return Colors.green; // Internal patients
      case 2:
        return Colors.orange; // External patients
      default:
        return Colors.white;
    }
  }

// Custom tab with color indicator
  Widget _buildCustomTab({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
  }) {
    return Tab(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          // Add a subtle background color when selected
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          // Add a border with the specific color
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : null),
            SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isWideScreen) {
    final filters = ref.watch(patientFiltersProvider);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isWideScreen
          ? _buildWideScreenFilters(filters)
          : _buildNarrowScreenFilters(filters),
    );
  }

  // Wide screen layout for filters (horizontal)
  Widget _buildWideScreenFilters(PatientFilters filters) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: HospitalTheme.primary),
              hintText: 'Search patients by name, ID or contact...',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          ref
                              .read(patientFiltersProvider.notifier)
                              .update((state) {
                            state.searchQuery = '';
                            return state;
                          });
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              ref.read(patientFiltersProvider.notifier).update((state) {
                state.searchQuery = value;
                return state;
              });
            },
          ),
        ),

        SizedBox(width: 16),

        // Doctor Type Filter Dropdown
        Expanded(
          child: _buildFilterDropdown(
            labelText: 'Doctor Type',
            value: filters.doctorType,
            items: [
              {'value': 'All', 'label': 'All Doctors', 'icon': Icons.groups},
              {
                'value': 'doctor',
                'label': 'Internal Doctors',
                'icon': Icons.medical_services
              },
              {
                'value': 'external',
                'label': 'External Doctors',
                'icon': Icons.person_pin
              },
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(patientFiltersProvider.notifier).update((state) {
                  state.doctorType = value;
                  return state;
                });
              }
            },
          ),
        ),

        SizedBox(width: 16),

        // Date Range Filter Dropdown
        Expanded(
          child: _buildFilterDropdown(
            labelText: 'Date Range',
            value: filters.dateRange,
            items: [
              {
                'value': 'All Time',
                'label': 'All Time',
                'icon': Icons.date_range
              },
              {'value': 'Today', 'label': 'Today', 'icon': Icons.today},
              {
                'value': 'This Week',
                'label': 'This Week',
                'icon': Icons.view_week
              },
              {
                'value': 'This Month',
                'label': 'This Month',
                'icon': Icons.calendar_month
              },
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(patientFiltersProvider.notifier).update((state) {
                  state.dateRange = value;
                  return state;
                });
              }
            },
          ),
        ),

        SizedBox(width: 16),

        // Reset Button
        ElevatedButton.icon(
          icon: Icon(Icons.filter_list_off),
          label: Text('Reset Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: HospitalTheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            _searchController.clear();
            ref.read(patientFiltersProvider.notifier).state = PatientFilters();
          },
        ),
      ],
    );
  }

  // Narrow screen layout for filters (vertical)
  Widget _buildNarrowScreenFilters(PatientFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: HospitalTheme.primary),
            hintText: 'Search patients by name, ID or contact...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        ref
                            .read(patientFiltersProvider.notifier)
                            .update((state) {
                          state.searchQuery = '';
                          return state;
                        });
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(patientFiltersProvider.notifier).update((state) {
              state.searchQuery = value;
              return state;
            });
          },
        ),

        SizedBox(height: 12),

        // Filter dropdowns in a row
        Row(
          children: [
            // Doctor Type Filter Dropdown
            Expanded(
              child: _buildFilterDropdown(
                labelText: 'Doctor Type',
                value: filters.doctorType,
                items: [
                  {
                    'value': 'All',
                    'label': 'All Doctors',
                    'icon': Icons.groups
                  },
                  {
                    'value': 'doctor',
                    'label': 'Internal Doctors',
                    'icon': Icons.medical_services
                  },
                  {
                    'value': 'external',
                    'label': 'External Doctors',
                    'icon': Icons.person_pin
                  },
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(patientFiltersProvider.notifier).update((state) {
                      state.doctorType = value;
                      return state;
                    });
                  }
                },
              ),
            ),

            SizedBox(width: 8),

            // Date Range Filter Dropdown
            Expanded(
              child: _buildFilterDropdown(
                labelText: 'Date Range',
                value: filters.dateRange,
                items: [
                  {
                    'value': 'All Time',
                    'label': 'All Time',
                    'icon': Icons.date_range
                  },
                  {'value': 'Today', 'label': 'Today', 'icon': Icons.today},
                  {
                    'value': 'This Week',
                    'label': 'This Week',
                    'icon': Icons.view_week
                  },
                  {
                    'value': 'This Month',
                    'label': 'This Month',
                    'icon': Icons.calendar_month
                  },
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(patientFiltersProvider.notifier).update((state) {
                      state.dateRange = value;
                      return state;
                    });
                  }
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Reset Button
        ElevatedButton.icon(
          icon: Icon(Icons.filter_list_off),
          label: Text('Reset Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: HospitalTheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            _searchController.clear();
            ref.read(patientFiltersProvider.notifier).state = PatientFilters();
          },
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String labelText,
    required String value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(labelText),
          icon: Icon(Icons.arrow_drop_down, color: HospitalTheme.primary),
          style: TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          onChanged: onChanged,
          items:
              items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Row(
                children: [
                  Icon(item['icon'] as IconData,
                      size: 18, color: HospitalTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['label'],
                      style: TextStyle(
                        fontWeight: item['value'] == value
                            ? FontWeight.bold
                            : FontWeight.normal,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPatientList(
    List<PatientDischarge> patients,
    AsyncValue<List<PatientDischarge>> patientsAsync,
    bool isWideScreen,
    ScrollController scrollController,
  ) {
    return patientsAsync.when(
      data: (_) {
        if (patients.isEmpty) {
          return _buildEmptyState();
        }

        // Using CustomScrollView with SliverList for better performance with large lists
        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          thickness: 8,
          radius: Radius.circular(4),
          child: CustomScrollView(
            controller: scrollController,
            // Allow physics to handle the scrolling behavior appropriately
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(isWideScreen ? 24 : 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final patient = patients[index];
                      return _buildPatientCard(patient, isWideScreen);
                    },
                    childCount: patients.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(HospitalTheme.secondary),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading patients...',
            style: GoogleFonts.poppins(
              color: HospitalTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch the latest data',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientDischarge patient, bool isWideScreen) {
    final isInternal =
        patient.lastRecord.patientType?.toLowerCase() == 'internal';
    final doctorType = patient.lastRecord.doctor?.usertype ?? 'unknown';
    final doctorName = patient.lastRecord.doctor?.name ?? 'Unknown';

    // Choose tag colors based on patient and doctor types
    final patientTypeColor = isInternal ? Colors.blue : Colors.orange;
    final doctorTypeColor = doctorType.toLowerCase() == 'doctor'
        ? Colors.green
        : doctorType.toLowerCase() == 'external'
            ? Colors.purple
            : Colors.grey;

    // Format discharge date to more readable format
    String formattedDate = '';
    try {
      if (patient.lastRecord.dischargeDate.isNotEmpty) {
        // Assuming format like "2025-05-01 01:19:23 PM"
        final parts = patient.lastRecord.dischargeDate.split(' ');
        if (parts.length >= 3) {
          final datePart = parts[0];
          final timePart = parts[1];
          final amPmPart = parts[2];

          final dateComponents = datePart.split('-');
          if (dateComponents.length == 3) {
            // Format as "May 1, 2025 at 1:19 PM"
            final parsedDate = DateTime(
              int.parse(dateComponents[0]), // year
              int.parse(dateComponents[1]), // month
              int.parse(dateComponents[2]), // day
            );

            formattedDate =
                '${DateFormat.yMMMd().format(parsedDate)} at $timePart $amPmPart';
          } else {
            formattedDate = patient.lastRecord.dischargeDate;
          }
        } else {
          formattedDate = patient.lastRecord.dischargeDate;
        }
      }
    } catch (e) {
      // If any error in parsing, fall back to original format
      formattedDate = patient.lastRecord.dischargeDate;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.black26,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () async {
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(patient: patient),
              ),
            );
            if (shouldRefresh == true) {
              ref.read(dischargedPatientsProvider.notifier).manualRefresh();
            }
          },
          child: Column(
            children: [
              // Card header with patient type and doctor info
              Container(
                color: HospitalTheme.primary.withOpacity(0.05),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Patient ID
                    Row(
                      children: [
                        Icon(Icons.badge,
                            size: 18, color: HospitalTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'ID: ${patient.patientId}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: HospitalTheme.primary,
                          ),
                        ),
                      ],
                    ),

                    // Types
                    Row(
                      children: [
                        // Patient Type Tag
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: patientTypeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: patientTypeColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isInternal
                                    ? Icons.person
                                    : Icons.person_outline,
                                color: patientTypeColor,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                isInternal ? 'Internal' : 'External',
                                style: TextStyle(
                                  color: patientTypeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),

                        // Doctor Type Tag
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: doctorTypeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: doctorTypeColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                doctorType.toLowerCase() == 'doctor'
                                    ? Icons.medical_services
                                    : Icons.person_pin,
                                color: doctorTypeColor,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                doctorType.capitalizeFirst(),
                                style: TextStyle(
                                  color: doctorTypeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main content
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor: HospitalTheme.primary.withOpacity(0.2),
                      backgroundImage: AssetImage('assets/images/p2.png'),
                      radius: 30,
                    ),
                    SizedBox(width: 16),

                    // Patient details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name with discharge badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  patient.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: HospitalTheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Text(
                                  'Discharged',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),

                          // Info grid
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildInfoItem(
                                icon: Icons.person,
                                label: 'Gender',
                                value: patient.gender,
                                color: Colors.blue,
                              ),
                              _buildInfoItem(
                                icon: Icons.phone,
                                label: 'Contact',
                                value: patient.contact,
                                color: Colors.deepPurple,
                              ),
                              _buildInfoItem(
                                icon: Icons.calendar_today,
                                label: 'Discharged',
                                value: formattedDate,
                                color: Colors.teal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Desktop-specific quick actions
                    if (isWideScreen)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.receipt_long,
                                color: HospitalTheme.primary),
                            tooltip: 'Generate Bill',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GenerateIpdBillScreen(
                                  patientId: patient.patientId,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.assignment, color: Colors.orange),
                            tooltip: 'Generate OPD Bill',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OpdBillingScreen(
                                  patientId: patient.patientId,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.medical_services,
                                color: Colors.teal),
                            tooltip: 'View Medical Details',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientDetailsScreen(
                                    patient: patient,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Action buttons for mobile/tablet view
              if (!isWideScreen)
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.receipt_long,
                        label: 'Bill',
                        color: HospitalTheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenerateIpdBillScreen(
                              patientId: patient.patientId,
                            ),
                          ),
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.assignment,
                        label: 'OPD',
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OpdBillingScreen(
                              patientId: patient.patientId,
                            ),
                          ),
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.medical_services,
                        label: 'Details',
                        color: Colors.teal,
                        onTap: () {
                          // Already navigating to details on card tap, but
                          // this gives an explicit button for clarity
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold),
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
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open,
              size: 80,
              color: HospitalTheme.secondary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Discharged Patients',
            style: GoogleFonts.poppins(
              color: HospitalTheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: 400,
            child: Text(
              'All patients are currently checked in or your filters have no matching results',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.black26,
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              ref.read(dischargedPatientsProvider.notifier).manualRefresh();

              // Also clear any filters
              _searchController.clear();
              ref.read(patientFiltersProvider.notifier).state =
                  PatientFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Unable to Load Patients',
            style: GoogleFonts.poppins(
              color: Colors.red.shade700,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: 400,
            child: Text(
              'There was a problem connecting to the server. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: Icon(Icons.support_agent),
                label: Text('Get Help'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HospitalTheme.primary,
                  side: BorderSide(color: HospitalTheme.primary),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  // Show help or support dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Contact system administrator for assistance')),
                  );
                },
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black26,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  ref.read(dischargedPatientsProvider.notifier).manualRefresh();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatusBar(
      int totalPatients, int totalInternal, int totalExternal) {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      height: 94,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HospitalTheme.primaryDark,
              HospitalTheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusCounter(
              label: 'All Patients',
              count: totalPatients,
              icon: Icons.people,
            ),
            Container(
                height: 30, width: 1, color: Colors.white.withOpacity(0.3)),
            _buildStatusCounter(
              label: 'Internal',
              count: totalInternal,
              icon: Icons.person,
            ),
            Container(
                height: 30, width: 1, color: Colors.white.withOpacity(0.3)),
            _buildStatusCounter(
              label: 'External',
              count: totalExternal,
              icon: Icons.person_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCounter({
    required String label,
    required int count,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Patient Details Screen for viewing individual patient information
class PatientDetailsScreen extends StatefulWidget {
  final PatientDischarge patient;

  const PatientDetailsScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final TextEditingController _billingAmountController =
      TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  bool _isDischargedByReception = false;

  @override
  void initState() {
    super.initState();
    _isDischargedByReception = widget.patient.lastRecord.dischargedByReception;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _toggleDischargeByReception(bool value) async {
    if (value) {
      bool confirm = await _showConfirmationDialog(context);
      if (confirm) {
        setState(() {
          _isDischargedByReception = true;
        });
        // Call the backend to update the discharge status
        await _updateDischargeStatus();
      }
    } else {
      setState(() {
        _isDischargedByReception = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Confirm Discharge',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.primary,
              ),
            ),
            content: Text(
              'Are you sure you want to discharge this patient?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.secondary,
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ) ??
        false;
  }

  Future<void> _updateDischargeStatus() async {
    try {
      final response = await http.put(
        Uri.parse(
            '${KVM_URL}/reception/dischargeByReceptionCondition/${widget.patient.patientId}/${widget.patient.lastRecord.admissionId}'),
      );

      if (response.statusCode == 200) {
        // Update the UI to reflect the discharge status
        _showSnackBar(context, "Patient discharged successfully.");
      } else {
        setState(() {
          // Reset the switch if the API call fails
          _isDischargedByReception = false;
        });
        _showSnackBar(
            context, "Failed to discharge patient: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        // Reset the switch if there's an exception
        _isDischargedByReception = false;
      });
      _showSnackBar(context, "Error: $e");
    }
  }

  Future<void> _generateDischargeSummary() async {
    BuildContext? dialogContext;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx; // Store the dialog context
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Generating discharge summary...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your document',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/reception/generateDischargeSummary/${widget.patient.patientId}'),
      );

      // Close loading dialog using the stored context
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop();
        dialogContext = null;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final String driveLink = responseData['data']['driveLink'];
          final String fileName =
              responseData['data']['fileName'] ?? 'Discharge Summary';

          // Show success dialog with PDF link and action buttons
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext successDialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Summary Generated',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discharge summary has been generated successfully!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HospitalTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: HospitalTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: HospitalTheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: HospitalTheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Would you like to open the PDF document now?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Close Button
                  TextButton(
                    onPressed: () {
                      Navigator.of(successDialogContext).pop();
                      _showSnackBar(
                          context, 'Discharge summary saved successfully');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Open PDF Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(successDialogContext).pop();
                      Methods().openPdf(driveLink);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HospitalTheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      'Open PDF',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          _showSnackBar(context,
              'Failed to generate discharge summary: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        _showSnackBar(context,
            'Failed to generate discharge summary. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog if still showing using stored context
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop();
      }

      print('Error generating discharge summary: $e');
      _showSnackBar(
          context, 'Error generating discharge summary: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.patient.lastRecord;
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800 && screenSize.width <= 1200;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildPatientHeader(),
                const SizedBox(height: 20),
                // Responsive layout based on screen width
                if (isWideScreen) ...[
                  // Wide screen layout - two columns side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column - Patient & Admission details
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildInfoCard(
                              'Patient Information',
                              Icons.person_outline,
                              _buildPatientInfoContent(),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              'Admission Details',
                              Icons.medical_services,
                              _buildAdmissionDetailsContent(record),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right column - Medical overview, discharge & actions
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildMedicalInfoCard(record),
                            const SizedBox(height: 16),
                            _buildDischargeSection(),
                            const SizedBox(height: 16),
                            _buildActionButtons(record),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (isMediumScreen) ...[
                  // Medium screen layout - staggered columns
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column - Patient info & Medical overview
                      Expanded(
                        child: Column(
                          children: [
                            _buildInfoCard(
                              'Patient Information',
                              Icons.person_outline,
                              _buildPatientInfoContent(),
                            ),
                            const SizedBox(height: 16),
                            _buildMedicalInfoCard(record),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right column - Admission details, discharge & actions
                      Expanded(
                        child: Column(
                          children: [
                            _buildInfoCard(
                              'Admission Details',
                              Icons.medical_services,
                              _buildAdmissionDetailsContent(record),
                            ),
                            const SizedBox(height: 16),
                            _buildDischargeSection(),
                            const SizedBox(height: 16),
                            _buildActionButtons(record),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Mobile/small screen layout - single column
                  _buildInfoCard(
                    'Patient Information',
                    Icons.person_outline,
                    _buildPatientInfoContent(),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'Admission Details',
                    Icons.medical_services,
                    _buildAdmissionDetailsContent(record),
                  ),
                  const SizedBox(height: 16),
                  _buildMedicalInfoCard(record),
                  const SizedBox(height: 16),
                  _buildDischargeSection(),
                  const SizedBox(height: 16),
                  _buildActionButtons(record),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the patient info content separately to avoid code duplication
  Widget _buildPatientInfoContent() {
    return Column(
      children: [
        _buildInfoRow('Patient ID', widget.patient.patientId),
        _buildInfoRow('Gender', widget.patient.gender),
        _buildInfoRow('Contact', widget.patient.contact),
        _buildInfoRow(
            'Patient Type',
            widget.patient.lastRecord.patientType?.capitalizeFirst() ??
                'Unknown'),
        _buildInfoRow(
            'Doctor Type',
            widget.patient.lastRecord.doctor?.usertype?.capitalizeFirst() ??
                'Unknown'),
        _buildInfoRow(
            'Doctor Name', widget.patient.lastRecord.doctor?.name ?? 'Unknown'),
      ],
    );
  }

  // Build the admission details content separately
  Widget _buildAdmissionDetailsContent(record) {
    return Column(
      children: [
        _buildInfoRow('Admission ID', record.admissionId),
        _buildInfoRow('Admission Date', record.admissionDate),
        _buildInfoRow('Discharge Date', record.dischargeDate),
        _buildInfoRow('Reason', record.reasonForAdmission),
        _buildInfoRow('Condition', record.conditionAtDischarge),
        _buildInfoRow('Symptoms', record.symptoms),
        _buildInfoRow('Diagnosis', record.initialDiagnosis),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: HospitalTheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context, true),
      ),
      title: Text(
        widget.patient.name,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Tooltip(
          message: 'Print Details',
          child: IconButton(
            icon: Icon(Icons.print, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Print functionality coming soon')),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientHeader() {
    // Determine patient and doctor type for the header display
    final isInternalPatient =
        widget.patient.lastRecord.patientType?.toLowerCase() == 'internal';
    final doctorType =
        widget.patient.lastRecord.doctor?.usertype?.capitalizeFirst() ??
            'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [HospitalTheme.primary, HospitalTheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${widget.patient.patientId}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Type badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Patient type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInternalPatient ? Icons.person : Icons.person_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      isInternalPatient
                          ? 'Internal Patient'
                          : 'External Patient',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 6),

              // Doctor type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      doctorType.toLowerCase() == 'doctor'
                          ? Icons.medical_services
                          : Icons.person_pin,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '$doctorType Doctor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Widget content) {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: HospitalTheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard(record) {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: HospitalTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Medical Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMedicalStat(
                      'Weight', '${record.weight} kg', Icons.line_weight),
                ),
                Expanded(
                  child: _buildMedicalStat(
                      'Previous Balance',
                      '\$${record.previousRemainingAmount}',
                      Icons.attach_money),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildMedicalStat(
                'Amount Due', '\$${record.amountToBePayed}', Icons.payment),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalStat(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: HospitalTheme.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeSection() {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.exit_to_app, color: HospitalTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Discharge Control',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Mark as Discharged',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              subtitle: Text(
                'Confirm patient discharge status',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              activeColor: HospitalTheme.secondary,
              activeTrackColor: HospitalTheme.secondary.withOpacity(0.2),
              value: _isDischargedByReception,
              onChanged: _toggleDischargeByReception,
            ),
            if (_isDischargedByReception)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Patient has been marked as discharged',
                        style: GoogleFonts.poppins(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(record) {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_customize, color: HospitalTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            Container(
              width: double.infinity,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  _buildActionButton(
                    'Generate Bill',
                    Icons.receipt_long,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenerateIpdBillScreen(
                            patientId: widget.patient.patientId),
                      ),
                    ),
                  ),
                  _buildActionButton(
                    'Generate OPD Bill',
                    Icons.assignment,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OpdBillingScreen(
                                patientId: widget.patient.patientId,
                              )),
                    ),
                  ),
                  // _buildActionButton(
                  //   'Generate IPD Receipt',
                  //   Icons.summarize,
                  //   Colors.teal,
                  //   () => Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => GenerateIpdBillScreen(
                  //               patientId: widget.patient.patientId,
                  //               remainingAmount:
                  //                   record.previousRemainingAmount.toString(),
                  //               amountTobePaid:
                  //                   record.amountToBePayed.toString(),
                  //             )),
                  //   ),
                  // ),
                  _buildActionButton(
                    'View History',
                    Icons.history,
                    Colors.indigo,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenerateIpdBillScreen(
                            patientId: widget.patient.patientId),
                      ),
                    ),
                  ),
                  _buildActionButton(
                    'Export Data',
                    Icons.file_download,
                    Colors.deepPurple,
                    () {
                      // Export functionality here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export feature coming soon')),
                      );
                    },
                  ),
                  _buildActionButton(
                    'Print Summary',
                    Icons.print,
                    Colors.blueGrey,
                    () {
                      _generateDischargeSummary(); // Updated to call the new method

                      // Print functionality here
                    },
                  ),
                  _buildActionButton(
                    'Generate Manual Summary',
                    Icons.print,
                    Colors.blueGrey,

                    // Updated to call the new method
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManualDischargeSummaryScreen(
                            patientId: widget.patient.patientId),
                      ),
                    ),

                    // Print functionality here
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return ElevatedButton.icon(
      icon: Icon(icon, size: isSmallScreen ? 16 : 20),
      label: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: isSmallScreen ? 12 : 14,
        ),
      ),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: isSmallScreen ? 12 : 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        shadowColor: Colors.black12,
      ),
    );
  }
}

// String extension to capitalize first letter
extension StringExtension on String {
  String capitalizeFirst() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}
