import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;
  String _selectedFilter = 'All';
  DateTime? _selectedDate;
  bool _filterByDate = false;
  String _searchQuery = '';
  bool _latestOnly = true; // Default to showing only latest appointments
  bool _groupByPatient = false; // Option to group appointments by patient
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = [
    'All',
    'waiting',
    'accepted',
    'canceled',
    'completed',
    'rescheduled',
    'no-show'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchAppointments();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token not found';
        });
        return;
      }

      // Build the URL with proper parameters
      String baseUrl =
          '${KVM_URL}/doctors/getDoctorAppointments?page=$_currentPage&limit=$_limit';

      // Only add date parameter if we want to filter by date
      if (_filterByDate && _selectedDate != null) {
        String dateParam = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        baseUrl += '&date=$dateParam';
      }

      final url = Uri.parse(baseUrl);

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
          final appointments = (data['appointments'] as List)
              .map((appointment) => Appointment.fromJson(appointment))
              .toList();

          final pagination = data['pagination'];

          setState(() {
            _appointments = appointments;
            _filterAppointments();
            _totalPages = pagination['totalPages'] ?? 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Failed to fetch appointments: ${responseData['message'] ?? 'Unknown error'}';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to fetch appointments: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _filterAppointments() {
    setState(() {
      // First apply search and status filters
      var filtered = _appointments.where((appointment) {
        final matchesSearch = appointment.patientName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            appointment.patientId
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesStatus = _selectedFilter == 'All' ||
            appointment.status.toLowerCase() == _selectedFilter.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();

      // Then apply "Latest Only" filter if enabled
      if (_latestOnly) {
        filtered =
            filtered.where((appointment) => appointment.isLatest).toList();
      }

      _filteredAppointments = filtered;
    });
  }

  Future<void> _updateAppointmentStatus(
      Appointment appointment, String newStatus,
      {String? rescheduledDate, String? rescheduledTime}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      final url = Uri.parse(
          '${KVM_URL}/doctors/updateAppointmentStatus/${appointment.patientId}/${appointment.appointmentId}');

      Map<String, dynamic> body = {
        'status': newStatus,
      };

      if (newStatus == 'rescheduled' &&
          rescheduledDate != null &&
          rescheduledTime != null) {
        body['rescheduledDate'] = rescheduledDate;
        body['rescheduledTime'] = rescheduledTime;
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment status updated successfully')),
          );

          // Update local appointment data
          setState(() {
            appointment.status = newStatus;
            if (newStatus == 'rescheduled' &&
                rescheduledDate != null &&
                rescheduledTime != null) {
              appointment.rescheduledTo = '$rescheduledDate $rescheduledTime';
            }
          });

          // Refresh appointments
          _fetchAppointments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to update status: ${responseData['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Show confirmation dialog before updating appointment status
  void _showStatusConfirmationDialog(
      Appointment appointment, String newStatus, String actionText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $actionText'),
        content: Text(
            'Are you sure you want to mark this appointment as $newStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointment, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(newStatus),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  // Get color based on status for buttons and UI elements
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return HospitalTheme.success;
      case 'completed':
        return HospitalTheme.primary;
      case 'canceled':
        return HospitalTheme.error;
      case 'rescheduled':
        return HospitalTheme.warning;
      case 'no-show':
        return Colors.grey.shade700;
      default:
        return HospitalTheme.primary;
    }
  }

  void _showRescheduleDialog(Appointment appointment) {
    // Use DateTime.now() as initial date if no selected date
    DateTime selectedDate = DateTime.now();
    // For time, default to a TimeOfDay value (6:00 PM)
    TimeOfDay selectedTime = TimeOfDay(hour: 18, minute: 0);

    // Format for display
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reschedule Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient: ${appointment.patientName}'),
              Text('Current Date: ${appointment.date}'),
              Text('Current Time: ${appointment.time}'),
              SizedBox(height: 20),
              Row(
                children: [
                  Text('New Date: '),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 90)),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: ColorScheme.light(
                                primary: HospitalTheme.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                          formattedDate =
                              DateFormat('yyyy-MM-dd').format(selectedDate);
                        });
                      }
                    },
                    child: Text(
                      formattedDate,
                      style: TextStyle(color: HospitalTheme.primary),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('New Time: '),
                  TextButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: ColorScheme.light(
                                primary: HospitalTheme.primary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Text(
                      _formatTimeOfDay(selectedTime),
                      style: TextStyle(color: HospitalTheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Show a confirmation dialog before proceeding
                _showRescheduleConfirmationDialog(
                  appointment,
                  formattedDate,
                  _formatTimeOfDay(selectedTime),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.warning,
              ),
              child: Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format TimeOfDay to string in 12-hour format
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

    return DateFormat('h:mm a').format(dateTime);
  }

  // Additional confirmation dialog specifically for rescheduling
  void _showRescheduleConfirmationDialog(
    Appointment appointment,
    String newDate,
    String newTime,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Reschedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reschedule this appointment?'),
            SizedBox(height: 16),
            Text('Current Date: ${appointment.date}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Current Time: ${appointment.time}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('New Date: $newDate',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: HospitalTheme.warning)),
            Text('New Time: $newTime',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: HospitalTheme.warning)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(
                appointment,
                'rescheduled',
                rescheduledDate: newDate,
                rescheduledTime: newTime,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.warning,
            ),
            child: Text('Confirm Reschedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusBadge(String status) {
    Color badgeColor;
    IconData badgeIcon;

    switch (status.toLowerCase()) {
      case 'waiting':
        badgeColor = Colors.blue;
        badgeIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        break;
      case 'canceled':
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        break;
      case 'completed':
        badgeColor = Colors.purple;
        badgeIcon = Icons.done_all;
        break;
      case 'rescheduled':
        badgeColor = Colors.orange;
        badgeIcon = Icons.event_repeat;
        break;
      case 'no-show':
        badgeColor = Colors.grey;
        badgeIcon = Icons.person_off;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Appointments'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Divider(),
          _isLoading
              ? Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? Expanded(
                      child: Center(
                        child: Text(_errorMessage,
                            style: TextStyle(color: Colors.red)),
                      ),
                    )
                  : _filteredAppointments.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Text('No appointments found'),
                          ),
                        )
                      : Expanded(
                          child: _groupByPatient
                              ? _buildGroupedAppointmentsList()
                              : _buildAppointmentsList(),
                        ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search patients',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterAppointments();
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              // Date filter row with toggle
              Row(
                children: [
                  Switch(
                    value: _filterByDate,
                    activeColor: HospitalTheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _filterByDate = value;
                        _currentPage = 1; // Reset to first page
                        _fetchAppointments();
                      });
                    },
                  ),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2026),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                          _filterByDate = true; // Enable date filtering
                          _currentPage = 1; // Reset to first page
                          _fetchAppointments();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            _filterByDate ? HospitalTheme.surfaceLight : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 20,
                              color: _filterByDate
                                  ? HospitalTheme.primary
                                  : Colors.grey.shade700),
                          SizedBox(width: 8),
                          Text(
                            _filterByDate
                                ? DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate!)
                                : "Filter by date",
                            style: TextStyle(
                              color: _filterByDate
                                  ? HospitalTheme.primary
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          // Latest Only and Group By Patient filters
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text('Latest Only:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Switch(
                      value: _latestOnly,
                      activeColor: HospitalTheme.primary,
                      onChanged: (value) {
                        setState(() {
                          _latestOnly = value;
                          _filterAppointments();
                        });
                      },
                    ),
                    Text(
                      _latestOnly ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: _latestOnly
                            ? HospitalTheme.primary
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Tooltip(
                      message:
                          'When ON, only shows the most recent appointment for each patient',
                      child: Icon(Icons.info_outline,
                          size: 16, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text('Group By Patient:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Switch(
                      value: _groupByPatient,
                      activeColor: HospitalTheme.primary,
                      onChanged: (value) {
                        setState(() {
                          _groupByPatient = value;
                        });
                      },
                    ),
                    Text(
                      _groupByPatient ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: _groupByPatient
                            ? HospitalTheme.primary
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Tooltip(
                      message: 'Groups all appointments by patient',
                      child: Icon(Icons.info_outline,
                          size: 16, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          Text(
            'Filter by Status:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusFilters.map((status) {
              return FilterChip(
                selected: _selectedFilter == status,
                label: Text(status),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = status;
                    _filterAppointments();
                  });
                },
                selectedColor: HospitalTheme.primary.withOpacity(0.2),
                checkmarkColor: HospitalTheme.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _filteredAppointments.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final appointment = _filteredAppointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildGroupedAppointmentsList() {
    // Group appointments by patient ID
    Map<String, List<Appointment>> groupedAppointments = {};

    for (var appointment in _filteredAppointments) {
      if (!groupedAppointments.containsKey(appointment.patientId)) {
        groupedAppointments[appointment.patientId] = [];
      }
      groupedAppointments[appointment.patientId]!.add(appointment);
    }

    // Sort each patient's appointments by creation date (newest first)
    groupedAppointments.forEach((patientId, appointments) {
      appointments.sort((a, b) {
        DateTime dateA = DateTime.parse(a.createdAt);
        DateTime dateB = DateTime.parse(b.createdAt);
        return dateB.compareTo(dateA);
      });
    });

    // Convert the map to a list of patients
    List<String> patientIds = groupedAppointments.keys.toList();

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: patientIds.length,
      separatorBuilder: (context, index) => SizedBox(height: 24),
      itemBuilder: (context, index) {
        String patientId = patientIds[index];
        List<Appointment> appointments = groupedAppointments[patientId]!;

        // The latest appointment (should be the first one)
        Appointment latestAppointment = appointments
            .firstWhere((a) => a.isLatest, orElse: () => appointments.first);

        // All other appointments for this patient
        List<Appointment> historicalAppointments = appointments
            .where((a) => a.appointmentId != latestAppointment.appointmentId)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: HospitalTheme.primary,
                    radius: 16,
                    child: Text(
                      latestAppointment.patientName.isNotEmpty
                          ? latestAppointment.patientName
                              .substring(0, 1)
                              .toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestAppointment.patientName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Patient ID: ${latestAppointment.patientId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    'Total: ${appointments.length} appointment${appointments.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: HospitalTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Latest appointment
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'CURRENT APPOINTMENT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildAppointmentCard(latestAppointment),
              ],
            ),

            // Historical appointments if any
            if (historicalAppointments.isNotEmpty) ...[
              SizedBox(height: 12),

              // Expandable history section
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  title: Text(
                    'APPOINTMENT HISTORY (${historicalAppointments.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textMedium,
                      fontSize: 12,
                    ),
                  ),
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: historicalAppointments.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildAppointmentCard(
                            historicalAppointments[index],
                            isHistorical: true);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment,
      {bool isHistorical = false}) {
    // If not explicitly marked as historical, check if it's not the latest
    if (!isHistorical && !appointment.isLatest) {
      isHistorical = true;
    }

    return HospitalTheme.buildCard(
      hasShadow: !isHistorical,
      padding: EdgeInsets.zero,
      backgroundColor: isHistorical ? Colors.grey.shade50 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHistorical
                  ? Colors.grey.shade200
                  : HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Only show patient avatar in non-grouped view
                    if (!_groupByPatient) ...[
                      CircleAvatar(
                        backgroundColor: isHistorical
                            ? Colors.grey.shade400
                            : HospitalTheme.primary.withOpacity(0.2),
                        radius: 18,
                        child: Text(
                          appointment.patientName.isNotEmpty
                              ? appointment.patientName
                                  .substring(0, 1)
                                  .toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: isHistorical
                                ? Colors.grey.shade700
                                : HospitalTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                    ],

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // If grouped, don't show the name again
                        if (!_groupByPatient) ...[
                          Text(
                            appointment.patientName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isHistorical
                                  ? Colors.grey.shade700
                                  : HospitalTheme.textDark,
                            ),
                          ),
                          Text(
                            'ID: ${appointment.patientId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isHistorical
                                  ? Colors.grey.shade600
                                  : HospitalTheme.textMedium,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Appointment ID: ${appointment.appointmentId}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isHistorical
                                  ? Colors.grey.shade700
                                  : HospitalTheme.textDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isHistorical)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade500),
                        ),
                        child: Text(
                          'HISTORY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    _buildAppointmentStatusBadge(appointment.status),
                  ],
                ),
              ],
            ),
          ),

          // Appointment details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  icon: Icons.event,
                  label: 'Date',
                  value: appointment.date,
                  isHistorical: isHistorical,
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: appointment.time,
                  isHistorical: isHistorical,
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.medical_services,
                  label: 'Symptoms',
                  value: appointment.symptoms,
                  isHistorical: isHistorical,
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  icon: appointment.appointmentType.toLowerCase() == 'online'
                      ? Icons.videocam_outlined
                      : Icons.person,
                  label: 'Type',
                  value: appointment.appointmentType.toUpperCase(),
                  isHistorical: isHistorical,
                ),
                if (appointment.status == 'rescheduled' &&
                    appointment.rescheduledTo != null) ...[
                  SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.event_repeat,
                    label: 'Rescheduled To',
                    value: appointment.rescheduledTo!,
                    valueColor: HospitalTheme.warning,
                    isHistorical: isHistorical,
                  ),
                ],

                // Creation date for historical appointments
                if (isHistorical) ...[
                  SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.history,
                    label: 'Created',
                    value: _formatDateTime(appointment.createdAt),
                    isHistorical: isHistorical,
                  ),
                ],

                // Action buttons - only show on current (non-historical) appointments
                if (!isHistorical) ...[
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (appointment.status == 'waiting') ...[
                        OutlinedButton.icon(
                          icon: Icon(Icons.check, size: 18),
                          label: Text('Accept'),
                          onPressed: () => _showStatusConfirmationDialog(
                              appointment, 'accepted', 'Accept'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HospitalTheme.success,
                            side: BorderSide(color: HospitalTheme.success),
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: Icon(Icons.event_repeat, size: 18),
                          label: Text('Reschedule'),
                          onPressed: () => _showRescheduleDialog(appointment),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HospitalTheme.warning,
                            side: BorderSide(color: HospitalTheme.warning),
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: Icon(Icons.cancel, size: 18),
                          label: Text('Cancel'),
                          onPressed: () => _showStatusConfirmationDialog(
                              appointment, 'canceled', 'Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HospitalTheme.error,
                            side: BorderSide(color: HospitalTheme.error),
                          ),
                        ),
                      ] else if (appointment.status == 'accepted') ...[
                        OutlinedButton.icon(
                          icon: Icon(Icons.done_all, size: 18),
                          label: Text('Complete'),
                          onPressed: () => _showStatusConfirmationDialog(
                              appointment, 'completed', 'Complete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HospitalTheme.success,
                            side: BorderSide(color: HospitalTheme.success),
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: Icon(Icons.person_off, size: 18),
                          label: Text('No Show'),
                          onPressed: () => _showStatusConfirmationDialog(
                              appointment, 'no-show', 'Mark as No-Show'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HospitalTheme.textMedium,
                            side: BorderSide(color: HospitalTheme.textMedium),
                          ),
                        ),
                      ] else if (appointment.status == 'canceled' ||
                          appointment.status == 'no-show') ...[
                        OutlinedButton.icon(
                          icon: Icon(Icons.event_repeat, size: 18),
                          label: Text('Reschedule'),
                          onPressed: () => _showRescheduleDialog(appointment),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HospitalTheme.warning,
                            side: BorderSide(color: HospitalTheme.warning),
                          ),
                        ),
                      ],
                      SizedBox(width: 8),
                      HospitalTheme.buildFloatingActionButton(
                        icon: Icons.visibility,
                        onPressed: () {
                          // View patient details
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'View patient details not implemented')),
                          );
                        },
                        tooltip: 'View patient details',
                        backgroundColor: HospitalTheme.primary,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isHistorical = false,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color:
                isHistorical ? Colors.grey.shade500 : HospitalTheme.textMedium),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color:
                isHistorical ? Colors.grey.shade600 : HospitalTheme.textMedium,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor != null
                  ? valueColor
                  : (isHistorical
                      ? Colors.grey.shade700
                      : HospitalTheme.textDark),
              fontWeight:
                  valueColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Format ISO datetime to more readable format
  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                      _fetchAppointments();
                    });
                  }
                : null,
            color: HospitalTheme.primary,
            disabledColor: Colors.grey.shade400,
          ),
          SizedBox(width: 16),
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                      _fetchAppointments();
                    });
                  }
                : null,
            color: HospitalTheme.primary,
            disabledColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

class Appointment {
  final String patientId;
  final String patientName;
  final String patientContact;
  final String appointmentId;
  final String symptoms;
  final String appointmentType;
  final String date;
  final String time;
  String status;
  final String paymentStatus;
  String? rescheduledTo;
  final String createdAt;
  final String updatedAt;
  final bool isLatest;

  Appointment({
    required this.patientId,
    required this.patientName,
    required this.patientContact,
    required this.appointmentId,
    required this.symptoms,
    required this.appointmentType,
    required this.date,
    required this.time,
    required this.status,
    required this.paymentStatus,
    this.rescheduledTo,
    required this.createdAt,
    required this.updatedAt,
    required this.isLatest,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      patientContact: json['patientContact'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      symptoms: json['symptoms'] ?? '',
      appointmentType: json['appointmentType'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      rescheduledTo: json['rescheduledTo'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isLatest: json['isLatest'] ?? false,
    );
  }
}
