import 'dart:convert';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];
  String _errorMessage = '';
  String _doctorName = '';
  String _speciality = '';
  Map<String, List<Map<String, dynamic>>> _groupedAppointments = {};
  DateTime _selectedDate = DateTime.now();
  String _activeFilter = 'All'; // Default filter
  bool _isCalendarVisible = false;

  // Map to track appointment counts by date for the calendar
  Map<DateTime, int> _appointmentCountsByDate = {};

  // Tab controller for different view types (List/Calendar/Timeline)
  late TabController _tabController;

  // Desktop layout properties
  final double _sidebarWidth = 280.0;
  bool _isSidebarExpanded = true;
  final List<String> _filterOptions = [
    'All',
    'Today',
    'Upcoming',
    'Completed',
    'Cancelled',
    'Accepted' // Added "Accepted" option
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
    _fetchAppointments();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _doctorName = prefs.getString('user_name') ?? 'Doctor';
      _speciality = prefs.getString('doctor_speciality') ?? 'Specialist';
    });
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('doctor_token') ?? '';

      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getDoctorAppointments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> appointmentsList = data['doctorAppointments'] ?? [];

        setState(() {
          _appointments = appointmentsList
              .map((item) => item as Map<String, dynamic>)
              .toList();
          _groupAppointmentsByDate();
          _updateAppointmentCounts();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load appointments. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  void _updateAppointmentCounts() {
    _appointmentCountsByDate = {};

    for (var appointment in _appointments) {
      final dateStr = appointment['date'] as String? ?? '';
      if (dateStr.isNotEmpty) {
        try {
          final date = DateTime.parse(dateStr);
          // Normalize date to remove time component
          final normalizedDate = DateTime(date.year, date.month, date.day);

          if (_appointmentCountsByDate.containsKey(normalizedDate)) {
            _appointmentCountsByDate[normalizedDate] =
                _appointmentCountsByDate[normalizedDate]! + 1;
          } else {
            _appointmentCountsByDate[normalizedDate] = 1;
          }
        } catch (e) {
          // Handle invalid date format
        }
      }
    }
  }

  void _groupAppointmentsByDate() {
    _groupedAppointments = {};

    // Apply filter before grouping
    List<Map<String, dynamic>> filteredAppointments = _appointments;

    if (_activeFilter != 'All') {
      filteredAppointments = _appointments.where((appointment) {
        final status = (appointment['status'] as String? ?? '').toLowerCase();
        final date = appointment['date'] as String? ?? '';

        switch (_activeFilter.toLowerCase()) {
          case 'today':
            final now = DateTime.now();
            final today =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            return date == today;
          case 'waiting':
            return status == 'waiting';
          case 'pending':
            return status == 'pending';
          case 'completed':
            return status == 'completed';
          case 'cancelled':
            return status == 'cancelled';
          case 'rescheduled':
            return status == 'rescheduled';
          case 'accepted': // Added case for 'accepted' status
            return status == 'accepted';
          default:
            return true;
        }
      }).toList();
    }

    for (var appointment in filteredAppointments) {
      final date = appointment['date'] as String? ?? '';
      if (date.isNotEmpty) {
        if (!_groupedAppointments.containsKey(date)) {
          _groupedAppointments[date] = [];
        }

        _groupedAppointments[date]!.add(appointment);
      }
    }

    // Sort appointments by time within each date
    _groupedAppointments.forEach((date, appointments) {
      appointments.sort((a, b) {
        final aTime = a['time'] as String? ?? '';
        final bTime = b['time'] as String? ?? '';
        return aTime.compareTo(bTime);
      });
    });
  }

  // Format date from yyyy-MM-dd to a more readable format
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today, ${DateFormat('MMM d, yyyy').format(date)}';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow, ${DateFormat('MMM d, yyyy').format(date)}';
    } else {
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    }
  }

  Future<void> _rescheduleAppointment(
      {required String patientId,
      required String appointmentId,
      required String newDate,
      required String newTime}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('doctor_token') ?? '';

      final response = await http.patch(
        Uri.parse('${KVM_URL}/doctors/rescheduleAppointment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'patientId': patientId,
          'appointmentId': appointmentId,
          'newDate': newDate,
          'newTime': newTime,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully rescheduled
        _showSnackBar(
            'Appointment rescheduled successfully', HospitalTheme.success);

        // Refresh appointments list
        _fetchAppointments();
      } else {
        // Handle error
        final errorBody = json.decode(response.body);
        setState(() {
          _errorMessage =
              errorBody['message'] ?? 'Failed to reschedule appointment';
        });

        _showSnackBar(_errorMessage, HospitalTheme.error);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });

      _showSnackBar(_errorMessage, HospitalTheme.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to show SnackBar with desktop-appropriate styling
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(
      {required String patientId,
      required String appointmentId,
      required String status}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('doctor_token') ?? '';

      final response = await http.post(
        Uri.parse('${KVM_URL}/doctors/updateAppointmentStatus'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'patientId': patientId,
          'appointmentId': appointmentId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully updated status
        _showSnackBar(
            'Appointment status updated to $status', HospitalTheme.success);

        // Refresh appointments list
        _fetchAppointments();
      } else {
        // Handle error
        final errorBody = json.decode(response.body);
        setState(() {
          _errorMessage =
              errorBody['message'] ?? 'Failed to update appointment status';
        });

        _showSnackBar(_errorMessage, HospitalTheme.error);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });

      _showSnackBar(_errorMessage, HospitalTheme.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get status color based on appointment status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return HospitalTheme.success;
      case 'cancelled':
        return HospitalTheme.error;
      case 'rescheduled':
        return HospitalTheme.warning;
      case 'completed':
        return HospitalTheme.info;
      default:
        return HospitalTheme.secondary;
    }
  }

  // Get appointment type icon
  IconData _getAppointmentTypeIcon(String type) {
    return type.toLowerCase() == 'online'
        ? Icons.videocam_outlined
        : Icons.person_outlined;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HospitalTheme.primary,
              onPrimary: HospitalTheme.textOnPrimary,
              surface: HospitalTheme.cardBackground,
              onSurface: HospitalTheme.textDark,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              contentTextStyle: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Set active filter to 'Custom Date'
        _activeFilter = 'Custom Date';
        // Filter appointments for the selected date
        _filterAppointmentsByDate(picked);
      });
    }
  }

  void _filterAppointmentsByDate(DateTime selectedDate) {
    // Format the selected date to match the format in the appointments data
    final formattedDate =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    // Filter appointments for just this date
    _groupedAppointments = {};

    final filteredAppointments = _appointments.where((appointment) {
      return appointment['date'] == formattedDate;
    }).toList();

    if (filteredAppointments.isNotEmpty) {
      _groupedAppointments[formattedDate] = filteredAppointments;

      // Sort appointments by time
      _groupedAppointments[formattedDate]!.sort((a, b) {
        final aTime = a['time'] as String? ?? '';
        final bTime = b['time'] as String? ?? '';
        return aTime.compareTo(bTime);
      });
    }
  }

  List<String> get _sortedDates {
    final dates = _groupedAppointments.keys.toList();
    dates.sort();
    return dates;
  }

  int _countAppointmentsByType(String type) {
    return _appointments.where((appointment) {
      return (appointment['appointmentType'] as String? ?? '').toLowerCase() ==
          type.toLowerCase();
    }).length;
  }

  int _countAppointmentsByStatus(String status) {
    return _appointments.where((appointment) {
      return (appointment['status'] as String? ?? '').toLowerCase() ==
          status.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    // Modern desktop scaffold with responsive layout
    return Scaffold(
      appBar: _buildDesktopAppBar(),
      body: Row(
        children: [
          // Left sidebar for desktop
          // if (_isSidebarExpanded) _buildSidebar(),

          // Main content area
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: HospitalTheme.primary))
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _appointments.isEmpty
                        ? _buildEmptyState()
                        : _buildAppointmentsContent(),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Navigate to a screen for creating new appointments
      //   },
      //   backgroundColor: HospitalTheme.primary,
      //   foregroundColor: HospitalTheme.textOnPrimary,
      //   icon: const Icon(Icons.add),
      //   label: const Text('New Appointment'),
      //   elevation: 4,
      // ),
    );
  }

  Widget _buildAppointmentsContent() {
    return Column(
      children: [
        // Tab bar for switching between view types
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // Enhanced tab bar with icons
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: HospitalTheme.border),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: HospitalTheme.primary,
                  unselectedLabelColor: HospitalTheme.textMedium,
                  indicatorColor: HospitalTheme.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.view_list),
                      text: 'List View',
                    ),
                    Tab(
                      icon: Icon(Icons.calendar_month),
                      text: 'Calendar',
                    ),
                    Tab(
                      icon: Icon(Icons.timeline),
                      text: 'Timeline',
                    ),
                  ],
                  onTap: (index) {
                    // Reset filters when switching to calendar view
                    if (index == 1 && _activeFilter != 'All') {
                      setState(() {
                        _activeFilter = 'All';
                        _groupAppointmentsByDate();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Tab view content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // LIST VIEW
              _buildAppointmentsList(),

              // CALENDAR VIEW
              _buildCalendarView(),

              // TIMELINE VIEW
              _buildTimelineView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Calendar widget with reduced size
          Container(
            height: 320, // Reduced height
            margin: const EdgeInsets.fromLTRB(
                16, 16, 16, 8), // Reduced bottom margin
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _selectedDate,
              calendarFormat: CalendarFormat.month,
              rowHeight: 36, // Reduced row height
              daysOfWeekHeight: 20, // Reduced days of week height
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                formatButtonDecoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(
                  color: HospitalTheme.primary,
                  fontSize: 12, // Smaller format button text
                ),
                titleTextStyle: TextStyle(
                  fontSize: 15, // Smaller title text
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
                headerPadding: const EdgeInsets.symmetric(
                    vertical: 8), // Less padding in header
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  size: 20, // Smaller icons
                  color: HospitalTheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  size: 20, // Smaller icons
                  color: HospitalTheme.primary,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: HospitalTheme.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markersAnchor: 0.7,
                cellMargin: const EdgeInsets.all(2), // Reduced cell margin
                defaultTextStyle:
                    const TextStyle(fontSize: 12), // Smaller day text
                weekendTextStyle:
                    const TextStyle(fontSize: 12), // Smaller weekend text
                outsideTextStyle: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textLight,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final appointmentCount = _appointmentCountsByDate[
                          DateTime(date.year, date.month, date.day)] ??
                      0;

                  if (appointmentCount > 0) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 14, // Smaller marker size
                        height: 14, // Smaller marker size
                        decoration: BoxDecoration(
                          color: appointmentCount > 2
                              ? HospitalTheme.warning
                              : HospitalTheme.success,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            appointmentCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8, // Smaller text in marker
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _filterAppointmentsByDate(selectedDay);
                });
              },
            ),
          ),

          // Calendar Legend with reduced size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCalendarLegendItem(
                    HospitalTheme.success, '1-2 appointments'),
                const SizedBox(width: 12),
                _buildCalendarLegendItem(
                    HospitalTheme.warning, '3+ appointments'),
                const SizedBox(width: 12),
                _buildCalendarLegendItem(
                    HospitalTheme.primary.withOpacity(0.7), 'Today'),
                const SizedBox(width: 12),
                _buildCalendarLegendItem(HospitalTheme.primary, 'Selected'),
              ],
            ),
          ),

          const SizedBox(height: 12), // Reduced spacing

          // Selected date header with reduced size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HospitalTheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: HospitalTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Appointments for ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                      style: TextStyle(
                        fontSize: 14, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8), // Reduced spacing

          // List of appointments for selected date - expanded to use more space
          Expanded(
            child: _sortedDates.isEmpty
                ? Center(
                    child: Text(
                      'No appointments for this date',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sortedDates.isNotEmpty
                        ? _groupedAppointments[_sortedDates[0]]?.length ?? 0
                        : 0,
                    itemBuilder: (context, index) {
                      if (_sortedDates.isEmpty ||
                          _groupedAppointments[_sortedDates[0]] == null ||
                          index >=
                              _groupedAppointments[_sortedDates[0]]!.length) {
                        return const SizedBox.shrink();
                      }

                      final appointment =
                          _groupedAppointments[_sortedDates[0]]![index];
                      return _buildCalendarAppointmentCard(appointment);
                    },
                  ),
          ),
        ],
      ),
    );
  }

// Updated legend item for smaller size
  Widget _buildCalendarLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12, // Smaller size
          height: 12, // Smaller size
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11, // Smaller text
            color: HospitalTheme.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarAppointmentCard(Map<String, dynamic> appointment) {
    final String patientName = appointment['patientName'] ?? 'Patient';
    final String patientId = appointment['patientId'] ?? 'Unknown ID';
    final String time = appointment['time'] ?? '00:00';
    final String status = appointment['status'] ?? 'pending';
    final String appointmentType = appointment['appointmentType'] ?? 'offline';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: HospitalTheme.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: HospitalTheme.surfaceLight,
              child: Text(
                patientName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: HospitalTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              patientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  _getAppointmentTypeIcon(appointmentType),
                  size: 14,
                  color: HospitalTheme.textMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status.substring(0, 1).toUpperCase() + status.substring(1),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Add action buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(appointment, status, patientId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView() {
    return Container(
      color: HospitalTheme.background,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: _sortedDates.length,
        itemBuilder: (context, index) {
          final date = _sortedDates[index];
          final appointments = _groupedAppointments[date]!;

          return _buildTimelineDateSection(date, appointments);
        },
      ),
    );
  }

  Widget _buildTimelineDateSection(
      String date, List<Map<String, dynamic>> appointments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: HospitalTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 1,
                color: HospitalTheme.border,
                width: 40,
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${appointments.length} appointments',
                  style: TextStyle(
                    color: HospitalTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Timeline appointments
        Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: HospitalTheme.border,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: appointments.map((appointment) {
              return _buildTimelineAppointment(appointment);
            }).toList(),
          ),
        ),

        // Space between dates
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTimelineAppointment(Map<String, dynamic> appointment) {
    final String patientName = appointment['patientName'] ?? 'Patient';
    final String patientId = appointment['patientId'] ?? 'Unknown ID';
    final String time = appointment['time'] ?? '00:00';
    final String status = appointment['status'] ?? 'pending';
    final String appointmentType = appointment['appointmentType'] ?? 'offline';
    final String symptoms = appointment['symptoms'] ?? 'No symptoms recorded';

    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time indicator
          Container(
            margin: const EdgeInsets.only(right: 16, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: HospitalTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.primary,
              ),
            ),
          ),

          // Timeline connecting line
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),

          // Appointment card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HospitalTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: HospitalTheme.surfaceLight,
                        child: Text(
                          patientName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: HospitalTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  _getAppointmentTypeIcon(appointmentType),
                                  size: 14,
                                  color: HospitalTheme.textMedium,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointmentType
                                          .substring(0, 1)
                                          .toUpperCase() +
                                      appointmentType.substring(1),
                                  style: TextStyle(
                                    color: HospitalTheme.textMedium,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.substring(0, 1).toUpperCase() +
                              status.substring(1),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (symptoms.isNotEmpty &&
                      symptoms != 'No symptoms recorded') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Symptoms:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      symptoms,
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Enhanced action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children:
                        _buildActionButtons(appointment, status, patientId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? Icons.menu_open : Icons.menu,
              color: HospitalTheme.primary,
            ),
            onPressed: () {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            },
          ),
          const SizedBox(width: 16),
          Text(
            'Doctor Dashboard',
            style: TextStyle(
              color: HospitalTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        // Search field
        Container(
          width: 300,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: HospitalTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search patients...',
              hintStyle: TextStyle(color: HospitalTheme.textLight),
              prefixIcon: Icon(Icons.search, color: HospitalTheme.textMedium),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              // Implement search functionality here
            },
          ),
        ),
        const SizedBox(width: 16),

        // Calendar button
        IconButton(
          icon: Icon(Icons.calendar_today, color: HospitalTheme.primary),
          onPressed: () => _selectDate(context),
          tooltip: 'Open Calendar',
        ),

        // Notifications button
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                  color: HospitalTheme.textDark),
              onPressed: () {
                // Open notifications panel
              },
              tooltip: 'Notifications',
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: HospitalTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Profile menu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PopupMenuButton(
            offset: const Offset(0, 40),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: HospitalTheme.primary,
                  child: Text(
                    _doctorName.isNotEmpty ? _doctorName[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Dr. $_doctorName',
                  style: TextStyle(
                    color: HospitalTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: HospitalTheme.textMedium),
              ],
            ),
            itemBuilder: (context) => <PopupMenuEntry>[
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading:
                      Icon(Icons.person_outline, color: HospitalTheme.primary),
                  title: const Text('My Profile'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined,
                      color: HospitalTheme.textMedium),
                  title: const Text('Settings'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: HospitalTheme.error),
                  title: const Text('Logout'),
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildSidebar() {
  //   return Container(
  //     width: _sidebarWidth,
  //     color: Colors.white,
  //     child: Column(
  //       children: [
  //         // Doctor Profile header
  //         Container(
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             border: Border(
  //               bottom: BorderSide(color: HospitalTheme.border),
  //             ),
  //           ),
  //           child: Column(
  //             children: [
  //               CircleAvatar(
  //                 radius: 40,
  //                 backgroundColor: HospitalTheme.surfaceLight,
  //                 child: Icon(
  //                   Icons.person,
  //                   size: 40,
  //                   color: HospitalTheme.primary,
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               Text(
  //                 'Dr. $_doctorName',
  //                 style: const TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 _speciality,
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: HospitalTheme.textMedium,
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   _buildStatusIndicator('Online', HospitalTheme.success),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Available',
  //                     style: TextStyle(
  //                       color: HospitalTheme.success,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),

  //         // Navigation menu
  //         Expanded(
  //           child: ListView(
  //             padding: EdgeInsets.zero,
  //             children: [
  //               _buildNavItem('Dashboard', Icons.dashboard_outlined, false),
  //               _buildNavItem('Appointments', Icons.calendar_month, true),
  //               _buildNavItem('Patients', Icons.people_outline, false),
  //               _buildNavItem('Medical Records', Icons.folder_outlined, false),
  //               _buildNavItem(
  //                   'Prescriptions', Icons.medication_outlined, false),
  //               _buildNavItem('Lab Results', Icons.science_outlined, false),
  //               _buildNavItem('Messages', Icons.message_outlined, false,
  //                   badgeCount: 5),
  //               _buildNavItem('Video Calls', Icons.videocam_outlined, false),
  //               _buildNavItem('Schedule', Icons.schedule, false),
  //               _buildNavItem('Finance', Icons.attach_money, false),
  //               const Divider(height: 32),
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                   vertical: 8,
  //                 ),
  //                 child: Text(
  //                   'FILTERS',
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.bold,
  //                     color: HospitalTheme.textMedium,
  //                   ),
  //                 ),
  //               ),
  //               ..._filterOptions.map((filter) => _buildFilterOption(filter)),
  //             ],
  //           ),
  //         ),

  //         // Footer actions
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             border: Border(
  //               top: BorderSide(color: HospitalTheme.border),
  //             ),
  //             color: Colors.white,
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               IconButton(
  //                 icon: Icon(Icons.settings_outlined,
  //                     color: HospitalTheme.textMedium),
  //                 onPressed: () {},
  //                 tooltip: 'Settings',
  //               ),
  //               IconButton(
  //                 icon:
  //                     Icon(Icons.help_outline, color: HospitalTheme.textMedium),
  //                 onPressed: () {},
  //                 tooltip: 'Help',
  //               ),
  //               IconButton(
  //                 icon: Icon(Icons.logout, color: HospitalTheme.textMedium),
  //                 onPressed: () {},
  //                 tooltip: 'Logout',
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatusIndicator(String status, Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, bool isActive,
      {int? badgeCount}) {
    return InkWell(
      onTap: () {
        // Navigate to the selected section
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? HospitalTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? HospitalTheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isActive ? HospitalTheme.primary : HospitalTheme.textMedium,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color:
                    isActive ? HospitalTheme.primary : HospitalTheme.textDark,
              ),
            ),
            const Spacer(),
            if (badgeCount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: HospitalTheme.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filter) {
    final bool isActive = _activeFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = filter;
          _groupAppointmentsByDate();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive
                      ? HospitalTheme.primary
                      : HospitalTheme.textLight,
                  width: 2,
                ),
                color: isActive ? HospitalTheme.primary : Colors.transparent,
              ),
              child: isActive
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              filter,
              style: TextStyle(
                fontSize: 14,
                color:
                    isActive ? HospitalTheme.primary : HospitalTheme.textDark,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: HospitalTheme.buildCard(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: HospitalTheme.error),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _fetchAppointments,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: HospitalTheme.buildCard(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 100,
              color: HospitalTheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            Text(
              'No Appointments Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 400,
              child: Text(
                'You don\'t have any scheduled appointments for the selected period. Try changing the filter or create a new appointment.',
                style: TextStyle(
                  fontSize: 16,
                  color: HospitalTheme.textMedium,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchAppointments,
                  icon: Icon(Icons.refresh, color: HospitalTheme.primary),
                  label: Text(
                    'Refresh',
                    style: TextStyle(color: HospitalTheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    side: BorderSide(color: HospitalTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to create appointment screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Appointment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    backgroundColor: HospitalTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildAppointmentsList() {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter chips row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Filter by status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', Icons.all_inclusive),
                        _buildFilterChip('waiting', Icons.check_circle_outline),
                        _buildFilterChip('Pending', Icons.watch_later_outlined),
                        _buildFilterChip('Completed', Icons.task_alt),
                        _buildFilterChip('Cancelled', Icons.cancel_outlined),
                        _buildFilterChip('Rescheduled', Icons.update),
                        _buildFilterChip(
                            'Accepted',
                            Icons
                                .check_circle), // Add this line after other filter chips
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date indicator
          if (_activeFilter == 'Custom Date')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18, color: HospitalTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Showing appointments for: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _activeFilter = 'All';
                          _groupAppointmentsByDate();
                        });
                      },
                      child: Text('Clear Filter'),
                      style: TextButton.styleFrom(
                        foregroundColor: HospitalTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Appointments list with enhanced date headers
          Expanded(
            child: _sortedDates.isEmpty
                ? Center(
                    child: Text(
                      'No appointments match your current filter',
                      style: TextStyle(
                        fontSize: 16,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = _sortedDates[index];
                      final appointments = _groupedAppointments[date]!;

                      return _buildDateSection(date, appointments);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(
      String date, List<Map<String, dynamic>> appointments) {
    // Check if date is today, tomorrow, or in the future
    final DateTime parsedDate = DateTime.parse(date);
    final DateTime now = DateTime.now();
    final bool isToday = parsedDate.year == now.year &&
        parsedDate.month == now.month &&
        parsedDate.day == now.day;
    final bool isTomorrow =
        parsedDate.year == now.add(const Duration(days: 1)).year &&
            parsedDate.month == now.add(const Duration(days: 1)).month &&
            parsedDate.day == now.add(const Duration(days: 1)).day;

    // Determine color based on date
    Color headerColor = isToday
        ? HospitalTheme.success
        : isTomorrow
            ? HospitalTheme.warning
            : HospitalTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced date header
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: headerColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: headerColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Date indicator with custom styling for today/tomorrow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isToday
                      ? Icons.today
                      : isTomorrow
                          ? Icons.event_available
                          : Icons.event,
                  color: headerColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Date information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: HospitalTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: HospitalTheme.success.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.success,
                              ),
                            ),
                          ),
                        if (isTomorrow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: HospitalTheme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: HospitalTheme.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'TOMORROW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appointments.length} appointments scheduled',
                      style: TextStyle(
                        fontSize: 14,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),

              // Appointment count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: headerColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${appointments.length} appointments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Enhanced appointment cards with time indicators
        ...appointments.map((appointment) {
          // Get the time for sorting
          final String time = appointment['time'] ?? '00:00';

          return Column(
            children: [
              // Time indicator
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: HospitalTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Appointment card with appointment details and action buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAppointmentCard(appointment),
              ),
            ],
          );
        }).toList(),

        if (_sortedDates.last != date)
          Divider(color: HospitalTheme.border.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final bool isSelected = _activeFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
          _groupAppointmentsByDate();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? HospitalTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : HospitalTheme.textMedium,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : HospitalTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final String patientName = appointment['patientName'] ?? 'Patient';
    final String patientId = appointment['patientId'] ?? 'Unknown ID';
    final String status = appointment['status'] ?? 'pending';
    final String time = appointment['time'] ?? '00:00';
    final String appointmentType = appointment['appointmentType'] ?? 'offline';
    final String symptoms = appointment['symptoms'] ?? 'No symptoms recorded';
    final String paymentStatus = appointment['paymentStatus'] ?? 'pending';

    // Desktop optimized card layout
    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(0),
      hasShadow: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Time column
                Container(
                  width: 80,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HospitalTheme.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            appointmentType.toLowerCase() == 'online'
                                ? Icons.videocam
                                : Icons.person,
                            size: 12,
                            color: HospitalTheme.textMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointmentType.substring(0, 1).toUpperCase() +
                                appointmentType.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: HospitalTheme.textMedium,
                            ),
                          ),
                        ],
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
                        patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $patientId',
                        style: TextStyle(
                          fontSize: 12,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                HospitalTheme.buildStatusBadge(
                  status.substring(0, 1).toUpperCase() + status.substring(1),
                  color: _getStatusColor(status),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Details in two columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column with avatar
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: HospitalTheme.surfaceLight,
                        child: Text(
                          patientName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.primary,
                          ),
                        ),
                      ),
                    ),

                    // Right column with details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Symptoms:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: HospitalTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      symptoms,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: HospitalTheme.textMedium,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: HospitalTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          paymentStatus.toLowerCase() == 'paid'
                                              ? HospitalTheme.success
                                                  .withOpacity(0.1)
                                              : HospitalTheme.warning
                                                  .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      paymentStatus
                                              .substring(0, 1)
                                              .toUpperCase() +
                                          paymentStatus.substring(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: paymentStatus.toLowerCase() ==
                                                'paid'
                                            ? HospitalTheme.success
                                            : HospitalTheme.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(appointment, status, patientId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
      Map<String, dynamic> appointment, String status, String patientId) {
    final List<Widget> buttons = [];

    // Always show View Details button
    buttons.add(
      OutlinedButton.icon(
        onPressed: () {
          // View patient details/medical records
        },
        icon: Icon(Icons.visibility_outlined,
            size: 18, color: HospitalTheme.info),
        label: const Text('View Details'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: HospitalTheme.info),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    buttons.add(const SizedBox(width: 8));

    // Add status-specific buttons
    switch (status.toLowerCase()) {
      case 'waiting':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () {
              _showStatusUpdateConfirmationDialog(
                appointmentId: appointment['_id'] ?? '',
                patientId: patientId,
                status:
                    'accepted', // Change to 'accepted' instead of 'completed'
              );
            },
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.accent, // Use accent color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          OutlinedButton.icon(
            onPressed: () {
              _showRescheduleDialog(
                appointmentId: appointment['_id'] ?? '',
                patientId: patientId,
              );
            },
            icon: Icon(Icons.schedule, size: 18, color: HospitalTheme.warning),
            label: const Text('Reschedule'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: HospitalTheme.warning),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          OutlinedButton.icon(
            onPressed: () {
              _showCancelConfirmationDialog(appointment['_id'] ?? '');
            },
            icon: Icon(Icons.cancel_outlined,
                size: 18, color: HospitalTheme.error),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: HospitalTheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        break;

      case 'accepted': // Add a new case for 'accepted' status
        buttons.add(
          ElevatedButton.icon(
            onPressed: () {
              _showStatusUpdateConfirmationDialog(
                appointmentId: appointment['_id'] ?? '',
                patientId: patientId,
                status: 'completed',
              );
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          OutlinedButton.icon(
            onPressed: () {
              _showRescheduleDialog(
                appointmentId: appointment['_id'] ?? '',
                patientId: patientId,
              );
            },
            icon: Icon(Icons.schedule, size: 18, color: HospitalTheme.warning),
            label: const Text('Reschedule'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: HospitalTheme.warning),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          OutlinedButton.icon(
            onPressed: () {
              _showCancelConfirmationDialog(appointment['_id'] ?? '');
            },
            icon: Icon(Icons.cancel_outlined,
                size: 18, color: HospitalTheme.error),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: HospitalTheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        break;

      case 'pending':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () {
              _showStatusUpdateConfirmationDialog(
                appointmentId: appointment['_id'] ?? '',
                patientId: patientId,
                status: 'accepted', // Changed from 'confirmed' to 'accepted'
              );
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.accent, // Use accent color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        break;

      case 'rescheduled':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () {
              _showStatusUpdateConfirmationDialog(
                appointmentId: appointment['_id'] ?? '',
                patientId: patientId,
                status: 'accepted', // Changed from 'confirmed' to 'accepted'
              );
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.accent, // Use accent color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        break;

      // Rest of the cases remain the same...
    }

    return buttons;
  }

  Future<void> _showStatusUpdateConfirmationDialog({
    required String appointmentId,
    required String patientId,
    required String status,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Appointment Status'),
          content: Text(
              'Are you sure you want to mark this appointment as $status?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateAppointmentStatus(
                  patientId: patientId,
                  appointmentId: appointmentId,
                  status: status,
                );
              },
              child: Text('Confirm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Future<void> _showRescheduleDialog({
    required String appointmentId,
    required String patientId,
  }) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.schedule, color: HospitalTheme.warning),
                  const SizedBox(width: 8),
                  const Text('Reschedule Appointment'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: HospitalTheme.primary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: HospitalTheme.textDark,
                              ),
                              dialogTheme: DialogTheme(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: HospitalTheme.buildCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: HospitalTheme.primary),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HospitalTheme.textMedium,
                                ),
                              ),
                              Text(
                                DateFormat('EEE, MMM d, yyyy')
                                    .format(selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down,
                              color: HospitalTheme.textMedium),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time Picker
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: HospitalTheme.primary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: HospitalTheme.textDark,
                              ),
                              dialogTheme: DialogTheme(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedTime) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: HospitalTheme.buildCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: HospitalTheme.primary),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: HospitalTheme.textMedium,
                                ),
                              ),
                              Text(
                                selectedTime.format(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down,
                              color: HospitalTheme.textMedium),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: HospitalTheme.textMedium),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _rescheduleAppointment(
                      patientId: patientId,
                      appointmentId: appointmentId,
                      newDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                      newTime: selectedTime.format(context),
                    );
                  },
                  child: Text('Reschedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCancelConfirmationDialog(String appointmentId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: HospitalTheme.error),
              const SizedBox(width: 8),
              const Text('Cancel Appointment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this appointment?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone and the patient will be notified.',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Keep Appointment',
                style: TextStyle(color: HospitalTheme.textMedium),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Appointment'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateAppointmentStatus(
                  patientId: appointmentId.split('_').first,
                  appointmentId: appointmentId,
                  status: 'cancelled',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // Export appointments to CSV
  Future<void> _exportAppointmentsToCSV() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // In a real app, this would create a CSV file and either save it or offer it for download
      // Since this is desktop, you might save to a file using path_provider or file_picker packages

      // Simulating export process
      await Future.delayed(const Duration(seconds: 2));

      _showSnackBar(
          'Appointments exported successfully', HospitalTheme.success);
    } catch (e) {
      _showSnackBar('Failed to export appointments: $e', HospitalTheme.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
