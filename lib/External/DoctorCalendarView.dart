import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';

class DoctorAppointmentsListView extends StatefulWidget {
  const DoctorAppointmentsListView({Key? key}) : super(key: key);

  @override
  _DoctorAppointmentsListViewState createState() =>
      _DoctorAppointmentsListViewState();
}

class _DoctorAppointmentsListViewState
    extends State<DoctorAppointmentsListView> {
  bool _isLoading = true;
  List<Doctor> _doctors = [];
  List<Appointment> _appointments = [];
  Map<String, List<Appointment>> _appointmentsByDoctor = {};
  Doctor? _selectedDoctor;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filterOptions = [
    'All',
    'Today',
    'This Week',
    'This Month',
    'Upcoming',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch doctors
      final doctorsResponse = await http.get(
        Uri.parse('${KVM_URL}/reception/listExternalDoctors'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch appointments
      final appointmentsResponse = await http.get(
        Uri.parse('${KVM_URL}/reception/getAllAppointments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (doctorsResponse.statusCode == 200 &&
          appointmentsResponse.statusCode == 200) {
        final doctorsData = json.decode(doctorsResponse.body);
        final appointmentsData = json.decode(appointmentsResponse.body);

        setState(() {
          _doctors = (doctorsData['doctors'] as List)
              .map((json) => Doctor.fromJson(json))
              .toList();

          _appointments = (appointmentsData['appointments'] as List)
              .map((json) => Appointment.fromJson(json))
              .toList();

          // Group appointments by doctor
          _appointmentsByDoctor = {};
          for (var appointment in _appointments) {
            String doctorId = appointment.doctorId;
            if (_appointmentsByDoctor.containsKey(doctorId)) {
              _appointmentsByDoctor[doctorId]!.add(appointment);
            } else {
              _appointmentsByDoctor[doctorId] = [appointment];
            }
          }

          if (_doctors.isNotEmpty) {
            _selectedDoctor = _doctors.first;
          }

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  List<Appointment> _getFilteredAppointments() {
    if (_selectedDoctor == null) return [];

    // Get appointments for selected doctor
    final doctorAppointments = _appointmentsByDoctor[_selectedDoctor!.id] ?? [];

    // Apply search filter if available
    List<Appointment> filteredAppointments = doctorAppointments;
    if (_searchQuery.isNotEmpty) {
      filteredAppointments = doctorAppointments.where((appointment) {
        return appointment.patientName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            appointment.patientId
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            appointment.patientContact
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            appointment.symptoms
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply date/status filter
    switch (_selectedFilter) {
      case 'Today':
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        return filteredAppointments.where((a) => a.date == todayStr).toList();

      case 'This Week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));

        return filteredAppointments.where((a) {
          final appointmentDate = DateTime.parse(a.date);
          return appointmentDate
                  .isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              appointmentDate.isBefore(endOfWeek.add(Duration(days: 1)));
        }).toList();

      case 'This Month':
        final now = DateTime.now();
        return filteredAppointments.where((a) {
          final appointmentDate = DateTime.parse(a.date);
          return appointmentDate.year == now.year &&
              appointmentDate.month == now.month;
        }).toList();

      case 'Upcoming':
        final now = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);

        return filteredAppointments.where((a) {
          if (DateTime.parse(a.date).isAfter(DateTime.parse(todayStr)))
            return true;
          if (a.date == todayStr) {
            // Compare time if it's today
            try {
              final appointmentTime = DateFormat('hh:mm a').parse(a.time);
              final currentTime = DateTime.now();
              final appointmentDateTime = DateTime(now.year, now.month, now.day,
                  appointmentTime.hour, appointmentTime.minute);
              return appointmentDateTime.isAfter(currentTime);
            } catch (e) {
              return false;
            }
          }
          return false;
        }).toList();

      case 'Completed':
        return filteredAppointments
            .where((a) => a.status.toLowerCase() == 'completed')
            .toList();

      case 'Cancelled':
        return filteredAppointments
            .where((a) => a.status.toLowerCase() == 'cancelled')
            .toList();

      case 'All':
      default:
        return filteredAppointments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HospitalTheme.background,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading appointments...',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout based on constraints
                final isSmallScreen = constraints.maxWidth < 1100;
                final doctorSidebarWidth =
                    isSmallScreen ? constraints.maxWidth * 0.3 : 280.0;

                return Row(
                  children: [
                    // Doctor sidebar with adaptive width
                    SizedBox(
                      width: doctorSidebarWidth,
                      child: _buildDoctorSidebar(isSmallScreen),
                    ),

                    // Main content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top header with filters
                          _buildHeader(isSmallScreen),

                          // Appointments list
                          Expanded(
                            child: _buildAppointmentsList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDoctorSidebar(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar header with larger text
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E2843), Color(0xFF1E2843).withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: Colors.white,
                  size: isSmallScreen ? 22 : 28,
                ),
                SizedBox(width: isSmallScreen ? 10 : 16),
                Expanded(
                  child: Text(
                    'Select Doctor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 22,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search box with larger text
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search doctors',
                prefixIcon: Icon(
                  Icons.search,
                  color: HospitalTheme.textMedium,
                  size: isSmallScreen ? 22 : 24,
                ),
                filled: true,
                fillColor: HospitalTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 14,
                    horizontal: isSmallScreen ? 16 : 20),
                hintStyle: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                ),
              ),
              style: TextStyle(fontSize: isSmallScreen ? 15 : 16),
              onChanged: (value) {
                // Filter doctors based on search - could be implemented
              },
            ),
          ),

          // Doctor list with larger text
          Expanded(
            child: ListView.builder(
              itemCount: _doctors.length,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                final isSelected = _selectedDoctor?.id == doctor.id;
                final appointmentCount =
                    _appointmentsByDoctor[doctor.id]?.length ?? 0;

                return Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? HospitalTheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? HospitalTheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedDoctor = doctor;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Row(
                        children: [
                          // Doctor avatar - slightly larger
                          Container(
                            width: isSmallScreen ? 42 : 54,
                            height: isSmallScreen ? 42 : 54,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? HospitalTheme.primary.withOpacity(0.2)
                                  : HospitalTheme.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? HospitalTheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: doctor.imageUrl != null &&
                                    doctor.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      doctor.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            doctor.doctorName
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 18 : 22,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? HospitalTheme.primary
                                                  : HospitalTheme.textMedium,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      doctor.doctorName
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 18 : 22,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? HospitalTheme.primary
                                            : HospitalTheme.textMedium,
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 16),

                          // Doctor info with larger text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. ${doctor.doctorName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 15 : 17,
                                    color: isSelected
                                        ? HospitalTheme.primary
                                        : HospitalTheme.textDark,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  doctor.speciality ??
                                      doctor.department ??
                                      'Specialist',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: HospitalTheme.textMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Appointment count badge - larger text
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 4 : 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? HospitalTheme.primary
                                  : HospitalTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$appointmentCount',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : HospitalTheme.textMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Add doctor button with larger text
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: SizedBox(
              width: double.infinity,
              child: HospitalTheme.buildGradientButton(
                label: isSmallScreen ? 'Add Doctor' : 'Add New Doctor',
                icon: Icons.add,
                onPressed: () {
                  // Navigate to add doctor screen
                },
                height: isSmallScreen ? 42 : 48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    if (_selectedDoctor == null) {
      return SizedBox.shrink();
    }

    final filteredAppointments = _getFilteredAppointments();
    final totalAppointments =
        _appointmentsByDoctor[_selectedDoctor!.id]?.length ?? 0;

    // Count by status
    final completedCount = _appointmentsByDoctor[_selectedDoctor!.id]
            ?.where((a) => a.status.toLowerCase() == 'completed')
            .length ??
        0;
    final pendingCount = _appointmentsByDoctor[_selectedDoctor!.id]
            ?.where((a) =>
                a.status.toLowerCase() == 'pending' ||
                a.status.toLowerCase() == 'accepted')
            .length ??
        0;
    final cancelledCount = _appointmentsByDoctor[_selectedDoctor!.id]
            ?.where((a) => a.status.toLowerCase() == 'cancelled')
            .length ??
        0;

    // Count today's appointments
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayCount = _appointmentsByDoctor[_selectedDoctor!.id]
            ?.where((a) => a.date == todayStr)
            .length ??
        0;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 20,
          vertical: isSmallScreen ? 14 : 18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor info with responsive layout - more compact
          Row(
            children: [
              // Doctor avatar - slightly larger
              Container(
                width: isSmallScreen ? 42 : 52,
                height: isSmallScreen ? 42 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HospitalTheme.surfaceLight,
                  border: Border.all(
                    color: HospitalTheme.primary,
                    width: 1.5,
                  ),
                ),
                child: _selectedDoctor!.imageUrl != null &&
                        _selectedDoctor!.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 21 : 26),
                        child: Image.network(
                          _selectedDoctor!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _selectedDoctor!.doctorName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: HospitalTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 18 : 22,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          _selectedDoctor!.doctorName
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: HospitalTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 18 : 22,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 16),

              // Doctor name and specialty - larger text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${_selectedDoctor!.doctorName}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _selectedDoctor!.speciality ??
                          _selectedDoctor!.department ??
                          'Specialist',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: HospitalTheme.primary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Add appointment button - restored and larger
              HospitalTheme.buildGradientButton(
                label: isSmallScreen ? 'Add' : 'Add Appointment',
                icon: Icons.add,
                onPressed: () {
                  // Navigate to add appointment screen
                },
                width: isSmallScreen ? 100 : 160,
                height: isSmallScreen ? 36 : 42,
              ),
            ],
          ),

          SizedBox(height: 16),

          // Stats row in a horizontally scrollable container
          SizedBox(
            height: isSmallScreen ? 80 : 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatCard(
                  'Total',
                  '$totalAppointments',
                  Icons.calendar_month,
                  HospitalTheme.primary,
                  isSmallScreen,
                ),
                _buildStatCard(
                  'Today',
                  '$todayCount',
                  Icons.today,
                  HospitalTheme.medical,
                  isSmallScreen,
                ),
                _buildStatCard(
                  'Completed',
                  '$completedCount',
                  Icons.check_circle_outline,
                  HospitalTheme.success,
                  isSmallScreen,
                ),
                _buildStatCard(
                  'Pending',
                  '$pendingCount',
                  Icons.pending_actions,
                  HospitalTheme.warning,
                  isSmallScreen,
                ),
                _buildStatCard(
                  'Cancelled',
                  '$cancelledCount',
                  Icons.cancel_outlined,
                  HospitalTheme.error,
                  isSmallScreen,
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Filters and search row - increased text size
          Row(
            children: [
              // Filter dropdown - larger text
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 6 : 10),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HospitalTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: Icon(Icons.arrow_drop_down,
                        color: HospitalTheme.textMedium,
                        size: isSmallScreen ? 20 : 24),
                    style: TextStyle(
                      color: HospitalTheme.textDark,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    isDense: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFilter = newValue;
                        });
                      }
                    },
                    items: _filterOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForFilter(value),
                              size: isSmallScreen ? 16 : 18,
                              color: HospitalTheme.primary,
                            ),
                            SizedBox(width: 6),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Search box - larger text
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search appointments',
                    prefixIcon: Icon(
                      Icons.search,
                      color: HospitalTheme.textMedium,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    filled: true,
                    fillColor: HospitalTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: HospitalTheme.border),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    hintStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              SizedBox(width: 12),

              // Display info - larger text
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 14,
                    vertical: isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filteredAppointments.length}/$totalAppointments',
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Stat card with larger text
  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 130 : 150,
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 10 : 12,
          horizontal: isSmallScreen ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: HospitalTheme.textMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFilter(String filter) {
    switch (filter) {
      case 'Today':
        return Icons.today;
      case 'This Week':
        return Icons.date_range;
      case 'This Month':
        return Icons.calendar_month;
      case 'Upcoming':
        return Icons.upcoming;
      case 'Completed':
        return Icons.check_circle_outline;
      case 'Cancelled':
        return Icons.cancel_outlined;
      case 'All':
      default:
        return Icons.list_alt;
    }
  }

  Widget _buildAppointmentsList() {
    if (_selectedDoctor == null) {
      return Center(
        child: Text(
          'Select a doctor to view appointments',
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 16,
          ),
        ),
      );
    }

    final filteredAppointments = _getFilteredAppointments();

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing the filter or select another doctor',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            HospitalTheme.buildGradientButton(
              label: 'Add New Appointment',
              icon: Icons.add,
              onPressed: () {
                // Navigate to add appointment screen
              },
            ),
          ],
        ),
      );
    }

    // Group by date
    Map<String, List<Appointment>> appointmentsByDate = {};
    for (var appointment in filteredAppointments) {
      if (!appointmentsByDate.containsKey(appointment.date)) {
        appointmentsByDate[appointment.date] = [];
      }
      appointmentsByDate[appointment.date]!.add(appointment);
    }

    // Sort dates
    List<String> sortedDates = appointmentsByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Container(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 900;
        return ListView.builder(
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final appointments = appointmentsByDate[date]!;

            // Sort appointments by time
            appointments.sort((a, b) {
              try {
                final timeA = DateFormat('hh:mm a').parse(a.time);
                final timeB = DateFormat('hh:mm a').parse(b.time);
                return timeA.compareTo(timeB);
              } catch (e) {
                return 0;
              }
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                _buildDateHeader(date),

                // Appointments for this date
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(
                        appointments[index], isSmallScreen);
                  },
                ),

                const SizedBox(height: 24),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildDateHeader(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    String dateLabel;
    if (date.isAtSameMomentAs(today)) {
      dateLabel = 'Today';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: HospitalTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateLabel,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: HospitalTheme.border,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, bool isSmallScreen) {
    Color statusColor;
    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = HospitalTheme.success;
        break;
      case 'cancelled':
        statusColor = HospitalTheme.error;
        break;
      case 'pending':
        statusColor = HospitalTheme.warning;
        break;
      case 'accepted':
        statusColor = HospitalTheme.medical;
        break;
      default:
        statusColor = HospitalTheme.info;
    }

    // For very small screens, use a more compact vertical layout
    if (isSmallScreen) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: HospitalTheme.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time and status row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: HospitalTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.time,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: HospitalTheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  HospitalTheme.buildStatusBadge(
                    appointment.status.toUpperCase(),
                    color: statusColor,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Patient info
              Text(
                appointment.patientName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: HospitalTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // ID and Contact info
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ID: ${appointment.patientId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 14, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.patientContact,
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (appointment.symptoms.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.medical_information_outlined,
                        size: 14, color: HospitalTheme.textMedium),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Symptoms: ${appointment.symptoms}',
                        style: TextStyle(
                          fontSize: 12,
                          color: HospitalTheme.textMedium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Bottom action area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Appointment type
                  Row(
                    children: [
                      Icon(
                        appointment.appointmentType.toLowerCase() == 'online'
                            ? Icons.videocam_outlined
                            : Icons.person_outlined,
                        size: 14,
                        color: appointment.appointmentType.toLowerCase() ==
                                'online'
                            ? HospitalTheme.secondary
                            : HospitalTheme.medical,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.appointmentType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: appointment.appointmentType.toLowerCase() ==
                                  'online'
                              ? HospitalTheme.secondary
                              : HospitalTheme.medical,
                        ),
                      ),
                    ],
                  ),

                  // Action buttons
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        color: HospitalTheme.primary,
                        onTap: () {
                          // Edit appointment
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        color: HospitalTheme.error,
                        onTap: () {
                          // Delete appointment
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // For larger screens, use the original horizontal layout
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: HospitalTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            Container(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: HospitalTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.time,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: HospitalTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: HospitalTheme.textMedium),
                      const SizedBox(width: 4),
                      Text(
                        'ID: ${appointment.patientId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.phone_outlined,
                          size: 14, color: HospitalTheme.textMedium),
                      const SizedBox(width: 4),
                      Text(
                        appointment.patientContact,
                        style: TextStyle(
                          fontSize: 14,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                  if (appointment.symptoms.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.medical_information_outlined,
                            size: 14, color: HospitalTheme.textMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Symptoms: ${appointment.symptoms}',
                            style: TextStyle(
                              fontSize: 14,
                              color: HospitalTheme.textMedium,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status and type
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                HospitalTheme.buildStatusBadge(
                  appointment.status.toUpperCase(),
                  color: statusColor,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      appointment.appointmentType.toLowerCase() == 'online'
                          ? Icons.videocam_outlined
                          : Icons.person_outlined,
                      size: 16,
                      color:
                          appointment.appointmentType.toLowerCase() == 'online'
                              ? HospitalTheme.secondary
                              : HospitalTheme.medical,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appointment.appointmentType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: appointment.appointmentType.toLowerCase() ==
                                'online'
                            ? HospitalTheme.secondary
                            : HospitalTheme.medical,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: HospitalTheme.primary,
                      onTap: () {
                        // Edit appointment
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: HospitalTheme.error,
                      onTap: () {
                        // Delete appointment
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}

// Model classes

class Doctor {
  final String id;
  final String email;
  final String usertype;
  final String doctorName;
  final String? speciality;
  final String? experience;
  final String? department;
  final String? phoneNumber;
  final String? imageUrl;

  Doctor({
    required this.id,
    required this.email,
    required this.usertype,
    required this.doctorName,
    this.speciality,
    this.experience,
    this.department,
    this.phoneNumber,
    this.imageUrl,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'],
      email: json['email'],
      usertype: json['usertype'],
      doctorName: json['doctorName'],
      speciality: json['speciality'],
      experience: json['experience'],
      department: json['department'],
      phoneNumber: json['phoneNumber'],
      imageUrl: json['imageUrl'],
    );
  }
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String patientContact;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final String symptoms;
  final String appointmentType;
  final String date;
  final String time;
  final String status;
  final String paymentStatus;
  final String? rescheduledTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientContact,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.symptoms,
    required this.appointmentType,
    required this.date,
    required this.time,
    required this.status,
    required this.paymentStatus,
    this.rescheduledTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      patientContact: json['patientContact'],
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      doctorSpecialization: json['doctorSpecialization'] ?? '',
      symptoms: json['symptoms'] ?? '',
      appointmentType: json['appointmentType'],
      date: json['date'],
      time: json['time'],
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      rescheduledTo: json['rescheduledTo'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
