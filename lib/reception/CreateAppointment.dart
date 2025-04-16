import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/reception/ExternalDoctorRegistration.dart';
import 'package:doctordesktop/reception/Sidebar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AppointmentCreationScreen extends StatefulWidget {
  const AppointmentCreationScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentCreationScreen> createState() =>
      _AppointmentCreationScreenState();
}

class _AppointmentCreationScreenState extends State<AppointmentCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  int _selectedNavIndex = 1; // Default to Appointments tab

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00 AM';
  bool _isReadmission = false;
  String _appointmentType = 'offline';

  // Doctor selection
  List<Doctor> _doctors = [];
  Doctor? _selectedDoctor;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<PatientSearchResult> _searchResults = [];
  bool _showSearchResults = false;
  late final Map<int, Widget> _screens;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _screens = {
      0: const ExternalDoctorRegister(),
      1: const AppointmentCreationScreen(),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _symptomsController.dispose();
    _patientIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch doctors from API
  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/listExternalDoctors'),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['doctors'] ?? [];
        setState(() {
          _doctors = data.map((doc) => Doctor.fromJson(doc)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load doctors. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  // Search patient
  Future<void> _searchPatient(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/searchPatientAppointment?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults =
              data.map((item) => PatientSearchResult.fromJson(item)).toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      });
    }
  }

  // Apply patient data from search
  void _applyPatientData(PatientSearchResult patient) {
    setState(() {
      _nameController.text = patient.patientName;
      _contactController.text = patient.patientContact;
      _patientIdController.text = patient.patientId;
      _showSearchResults = false;
      _searchController.clear();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return HospitalTheme.success;
      case 'cancelled':
        return HospitalTheme.error;
      case 'rescheduled':
        return HospitalTheme.warning;
      case 'confirmed':
        return HospitalTheme.info;
      default:
        return HospitalTheme.secondary;
    }
  }

  // Submit appointment
  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: HospitalTheme.error,
        ),
      );
      return;
    }

    // Check if patientId is provided for readmission cases
    if (_isReadmission && _patientIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient ID is required for readmission'),
          backgroundColor: HospitalTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final appointmentData = {
      "patientName": _nameController.text,
      "patientContact": _contactController.text,
      "patientId": _patientIdController.text.isNotEmpty
          ? _patientIdController.text
          : null,
      "doctorId": _selectedDoctor!.id,
      "doctorName": _selectedDoctor!.doctorName,
      "doctorSpecialization": _selectedDoctor!.speciality,
      "symptoms": _symptomsController.text,
      "appointmentType": _appointmentType,
      "date": DateFormat('yyyy-MM-dd').format(_selectedDate),
      "time": _selectedTime,
      "paymentStatus": "pending",
      "isReadmission": _isReadmission,
    };

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/createAppointment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(appointmentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Appointment created successfully!'),
            backgroundColor: HospitalTheme.success,
          ),
        );

        // Reset form
        _resetForm();
      } else {
        final errorMsg = json.decode(response.body)['message'] ??
            'Failed to create appointment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: HospitalTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Reset form fields
  void _resetForm() {
    _nameController.clear();
    _contactController.clear();
    _symptomsController.clear();
    _patientIdController.clear();
    _searchController.clear();
    setState(() {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = '10:00 AM';
      _isReadmission = false;
      _appointmentType = 'offline';
      _selectedDoctor = null;
      _searchResults = [];
      _showSearchResults = false;
    });
  }

  Widget buildSearchResultsPanel() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 400, // Increased height to accommodate more information
      ),
      decoration: BoxDecoration(
        border: Border.all(color: HospitalTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _searchResults.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _isSearching ? 'Searching...' : 'No patients found',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final patient = _searchResults[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient header information
                    ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient.patientName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.person_add,
                              color: HospitalTheme.primary,
                            ),
                            tooltip: 'Use Patient Information',
                            onPressed: () => _applyPatientData(patient),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.badge,
                                  size: 14,
                                  color: HospitalTheme.textMedium,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ID: ${patient.patientId}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: HospitalTheme.textMedium,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  patient.patientContact,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${patient.appointments.length} previous appointment(s)',
                              style: TextStyle(
                                color: HospitalTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      isThreeLine: true,
                    ),

                    // Appointment history section
                    if (patient.appointments.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Appointment History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: HospitalTheme.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Appointment list with timeline visualization
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: patient.appointments.length > 3
                            ? 3 // Show only the 3 most recent appointments
                            : patient.appointments.length,
                        itemBuilder: (context, appIndex) {
                          final appointment = patient.appointments[appIndex];
                          final Color statusColor =
                              _getStatusColor(appointment.status);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: HospitalTheme.borderDark
                                        .withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8),
                                color:
                                    HospitalTheme.surfaceLight.withOpacity(0.5),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        appointment.appointmentType
                                                    .toLowerCase() ==
                                                'online'
                                            ? Icons.videocam_outlined
                                            : Icons.person_outlined,
                                        size: 16,
                                        color: HospitalTheme.primary,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Dr. ${appointment.doctorName} (${appointment.doctorSpecialization})',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border:
                                              Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          appointment.status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event,
                                        size: 16,
                                        color: HospitalTheme.textMedium,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${appointment.date} at ${appointment.time}',
                                        style: TextStyle(
                                          color: HospitalTheme.textDark,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.payments_outlined,
                                        size: 16,
                                        color: HospitalTheme.textMedium,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        appointment.paymentStatus,
                                        style: TextStyle(
                                          color: appointment.paymentStatus
                                                      .toLowerCase() ==
                                                  'paid'
                                              ? HospitalTheme.success
                                              : HospitalTheme.warning,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Show rescheduling details if available
                                  if (appointment.rescheduledTo != null &&
                                      appointment
                                          .rescheduledTo!.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: HospitalTheme.warning
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.update,
                                            size: 16,
                                            color: HospitalTheme.warning,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Rescheduled to: ${appointment.rescheduledTo}',
                                              style: TextStyle(
                                                color: HospitalTheme.warning,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Show symptoms if available
                                  if (appointment.symptoms.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      'Symptoms: ${appointment.symptoms}',
                                      style: TextStyle(
                                        color: HospitalTheme.textMedium,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Show "See more" button if there are more than 3 appointments
                      if (patient.appointments.length > 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: TextButton.icon(
                            onPressed: () {
                              // This would open a detailed appointment history view
                              // For now, we'll just select the patient
                              _applyPatientData(patient);
                            },
                            icon: Icon(
                              Icons.history,
                              size: 16,
                              color: HospitalTheme.primary,
                            ),
                            label: Text(
                              'See all ${patient.appointments.length} appointments',
                              style: TextStyle(
                                color: HospitalTheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],

                    Divider(height: 24, thickness: 1),
                  ],
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = [
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '12:00 PM',
      '12:30 PM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
      '04:30 PM',
      '05:00 PM',
      '05:30 PM',
    ];

    return Theme(
      data: HospitalTheme.themeData,
      child: Scaffold(
        body: Row(
          children: [
            // ImprovedSidebar(
            //   selectedIndex: _selectedNavIndex,
            //   onDestinationSelected: (index) {
            //     setState(() {
            //       _selectedNavIndex = index;
            //     });
            //   },
            // ),
            // Main content area
            Expanded(
              child: Container(
                color: HospitalTheme.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App bar
                    HospitalTheme.buildAppBar(
                      context: context,
                      title: 'Create New Appointment',
                      showBackButton: false,
                      actions: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: HospitalTheme.primaryLight,
                              child: Icon(Icons.person,
                                  color: HospitalTheme.textOnPrimary),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Reception Staff',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: HospitalTheme.success,
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton(
                              icon: Icon(Icons.more_vert,
                                  color: HospitalTheme.textDark),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'profile',
                                  child: Text('My Profile'),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Text('Logout'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Main content with form
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: HospitalTheme.primary))
                          : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                            color: HospitalTheme.error),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _fetchDoctors,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Universal search field
                                        HospitalTheme.buildCard(
                                          hasShadow: true,
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              HospitalTheme.buildSectionHeader(
                                                'Patient Search',
                                                trailing: Text(
                                                  'Find existing patients',
                                                  style: TextStyle(
                                                    color: HospitalTheme
                                                        .textMedium,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),

                                              // Search field
                                              TextField(
                                                controller: _searchController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Search by name, ID, or contact number',
                                                  prefixIcon:
                                                      Icon(Icons.search),
                                                  suffixIcon: _isSearching
                                                      ? SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: HospitalTheme
                                                                .primary,
                                                          ),
                                                        )
                                                      : _searchController
                                                              .text.isNotEmpty
                                                          ? IconButton(
                                                              icon: Icon(
                                                                  Icons.clear),
                                                              onPressed: () {
                                                                _searchController
                                                                    .clear();
                                                                setState(() {
                                                                  _searchResults =
                                                                      [];
                                                                  _showSearchResults =
                                                                      false;
                                                                });
                                                              },
                                                            )
                                                          : null,
                                                ),
                                                onChanged: (value) {
                                                  _searchPatient(value);
                                                },
                                              ),

                                              // Search results
                                              if (_showSearchResults) ...[
                                                const SizedBox(height: 16),
                                                buildSearchResultsPanel(),
                                              ],
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Form sections
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Left column - Patient details
                                            Expanded(
                                              child: HospitalTheme.buildCard(
                                                hasShadow: true,
                                                padding:
                                                    const EdgeInsets.all(24),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    HospitalTheme
                                                        .buildSectionHeader(
                                                            'Patient Information'),
                                                    const SizedBox(height: 16),

                                                    // Patient ID
                                                    TextFormField(
                                                      controller:
                                                          _patientIdController,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText: 'Patient ID',
                                                        prefixIcon:
                                                            Icon(Icons.badge),
                                                        hintText:
                                                            'For existing patients only',
                                                      ),
                                                      validator: (value) {
                                                        if (_isReadmission &&
                                                            (value == null ||
                                                                value
                                                                    .isEmpty)) {
                                                          return 'Patient ID is required for readmission';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Patient name
                                                    TextFormField(
                                                      controller:
                                                          _nameController,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Patient Name',
                                                        prefixIcon:
                                                            Icon(Icons.person),
                                                      ),
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Please enter patient name';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Patient contact
                                                    TextFormField(
                                                      controller:
                                                          _contactController,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Contact Number',
                                                        prefixIcon:
                                                            Icon(Icons.phone),
                                                      ),
                                                      keyboardType:
                                                          TextInputType.phone,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                        LengthLimitingTextInputFormatter(
                                                            10),
                                                      ],
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Please enter contact number';
                                                        }
                                                        if (value.length !=
                                                            10) {
                                                          return 'Contact number should be 10 digits';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Symptoms
                                                    TextFormField(
                                                      controller:
                                                          _symptomsController,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText: 'Symptoms',
                                                        prefixIcon: Icon(Icons
                                                            .medical_information),
                                                      ),
                                                      maxLines: 3,
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Please enter symptoms';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Is readmission
                                                    Row(
                                                      children: [
                                                        Checkbox(
                                                          value: _isReadmission,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              _isReadmission =
                                                                  value ??
                                                                      false;
                                                            });
                                                          },
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'This is a readmission',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium,
                                                              ),
                                                              if (_isReadmission)
                                                                Text(
                                                                  'Patient ID is required for readmission',
                                                                  style:
                                                                      TextStyle(
                                                                    color: HospitalTheme
                                                                        .warning,
                                                                    fontSize:
                                                                        12,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Appointment type
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Appointment Type:',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Radio(
                                                          value: 'offline',
                                                          groupValue:
                                                              _appointmentType,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              _appointmentType =
                                                                  value
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                        const Text('In-person'),
                                                        const SizedBox(
                                                            width: 16),
                                                        Radio(
                                                          value: 'online',
                                                          groupValue:
                                                              _appointmentType,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              _appointmentType =
                                                                  value
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                        const Text(
                                                            'Tele-consultation'),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 24),

                                            // Right column - Doctor selection and appointment time
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  // Doctor selection
                                                  HospitalTheme.buildCard(
                                                    hasShadow: true,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            24),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        HospitalTheme
                                                            .buildSectionHeader(
                                                                'Select Doctor'),
                                                        const SizedBox(
                                                            height: 16),

                                                        // Doctor dropdown
                                                        DropdownButtonFormField<
                                                            Doctor>(
                                                          decoration:
                                                              const InputDecoration(
                                                            labelText:
                                                                'Select Doctor',
                                                            prefixIcon: Icon(Icons
                                                                .medical_services),
                                                          ),
                                                          value:
                                                              _selectedDoctor,
                                                          items: _doctors.map(
                                                              (Doctor doctor) {
                                                            return DropdownMenuItem<
                                                                Doctor>(
                                                              value: doctor,
                                                              child: Text(
                                                                '${doctor.doctorName} (${doctor.speciality})',
                                                              ),
                                                            );
                                                          }).toList(),
                                                          onChanged: (Doctor?
                                                              newValue) {
                                                            setState(() {
                                                              _selectedDoctor =
                                                                  newValue;
                                                            });
                                                          },
                                                          validator: (value) {
                                                            if (value == null) {
                                                              return 'Please select a doctor';
                                                            }
                                                            return null;
                                                          },
                                                        ),

                                                        if (_selectedDoctor !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 24),
                                                          DoctorCard(
                                                              doctor:
                                                                  _selectedDoctor!),
                                                        ],
                                                      ],
                                                    ),
                                                  ),

                                                  const SizedBox(height: 24),

                                                  // Appointment date and time
                                                  HospitalTheme.buildCard(
                                                    hasShadow: true,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            24),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        HospitalTheme
                                                            .buildSectionHeader(
                                                                'Appointment Schedule'),
                                                        const SizedBox(
                                                            height: 16),

                                                        // Date picker
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .calendar_today,
                                                              color:
                                                                  HospitalTheme
                                                                      .primary,
                                                            ),
                                                            const SizedBox(
                                                                width: 16),
                                                            Text(
                                                              'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                            ),
                                                            const Spacer(),
                                                            ElevatedButton(
                                                              onPressed:
                                                                  () async {
                                                                final DateTime?
                                                                    picked =
                                                                    await showDatePicker(
                                                                  context:
                                                                      context,
                                                                  initialDate:
                                                                      _selectedDate,
                                                                  firstDate:
                                                                      DateTime
                                                                          .now(),
                                                                  lastDate: DateTime
                                                                          .now()
                                                                      .add(const Duration(
                                                                          days:
                                                                              90)),
                                                                );
                                                                if (picked !=
                                                                    null) {
                                                                  setState(() {
                                                                    _selectedDate =
                                                                        picked;
                                                                  });
                                                                }
                                                              },
                                                              child: const Text(
                                                                  'Select Date'),
                                                            ),
                                                          ],
                                                        ),

                                                        const SizedBox(
                                                            height: 24),

                                                        // Time slots
                                                        Text(
                                                          'Available Time Slots:',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium,
                                                        ),
                                                        const SizedBox(
                                                            height: 16),

                                                        // Wrap in rows of 4 slots
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: timeSlots
                                                              .map((time) {
                                                            final isSelected =
                                                                _selectedTime ==
                                                                    time;
                                                            return InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _selectedTime =
                                                                      time;
                                                                });
                                                              },
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: isSelected
                                                                      ? HospitalTheme
                                                                          .primary
                                                                      : HospitalTheme
                                                                          .surfaceLight,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                  border: Border
                                                                      .all(
                                                                    color: isSelected
                                                                        ? HospitalTheme
                                                                            .primary
                                                                        : HospitalTheme
                                                                            .border,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  time,
                                                                  style:
                                                                      TextStyle(
                                                                    color: isSelected
                                                                        ? HospitalTheme
                                                                            .textOnPrimary
                                                                        : HospitalTheme
                                                                            .textDark,
                                                                    fontWeight: isSelected
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .normal,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 32),

                                        // Action buttons
                                        Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              HospitalTheme.buildGradientButton(
                                                label: 'Cancel',
                                                icon: Icons.close,
                                                onPressed: _resetForm,
                                                startColor:
                                                    HospitalTheme.textLight,
                                                endColor:
                                                    HospitalTheme.textMedium,
                                              ),
                                              const SizedBox(width: 24),
                                              HospitalTheme.buildGradientButton(
                                                label: 'Save',
                                                icon: Icons.save,
                                                onPressed: _submitAppointment,
                                                isLoading: _isSubmitting,
                                                startColor:
                                                    HospitalTheme.success,
                                                endColor: HospitalTheme.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Doctor model
class Doctor {
  final String id;
  final String doctorName;
  final String speciality;
  final String experience;
  final String department;
  final String phoneNumber;
  final String imageUrl;

  Doctor({
    required this.id,
    required this.doctorName,
    required this.speciality,
    required this.experience,
    required this.department,
    required this.phoneNumber,
    required this.imageUrl,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? '',
      doctorName: json['doctorName'] ?? '',
      speciality: json['speciality'] ?? '',
      experience: json['experience'] ?? '',
      department: json['department'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

// Doctor card widget
class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HospitalTheme.buildCard(
      backgroundColor: HospitalTheme.surfaceLight,
      borderRadius: HospitalTheme.radiusMedium,
      hasShadow: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: HospitalTheme.primaryLight,
            child: const Icon(Icons.person,
                size: 36, color: HospitalTheme.textOnPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.doctorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  doctor.speciality,
                  style: TextStyle(
                    fontSize: 16,
                    color: HospitalTheme.primary,
                  ),
                ),
                Text(
                  'Experience: ${doctor.experience}',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                Text(
                  'Department: ${doctor.department}',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Patient search result model
class PatientSearchResult {
  final String patientId;
  final String patientName;
  final String patientContact;
  final List<PatientAppointment> appointments;

  PatientSearchResult({
    required this.patientId,
    required this.patientName,
    required this.patientContact,
    required this.appointments,
  });

  factory PatientSearchResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> appointmentsJson = json['appointments'] ?? [];

    return PatientSearchResult(
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      patientContact: json['patientContact'] ?? '',
      appointments: appointmentsJson
          .map((appt) => PatientAppointment.fromJson(appt))
          .toList(),
    );
  }
}

// Patient appointment model
class PatientAppointment {
  final String doctorName;
  final String doctorSpecialization;
  final String symptoms;
  final String appointmentType;
  final String date;
  final String time;
  final String status;
  final String? rescheduledTo; // Added field for rescheduled info
  final String paymentStatus;
  final String createdAt;
  final String updatedAt;

  PatientAppointment({
    required this.doctorName,
    required this.doctorSpecialization,
    required this.symptoms,
    required this.appointmentType,
    required this.date,
    required this.time,
    required this.status,
    this.rescheduledTo,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    return PatientAppointment(
      doctorName: json['doctorName'] ?? '',
      doctorSpecialization: json['doctorSpecialization'] ?? '',
      symptoms: json['symptoms'] ?? '',
      appointmentType: json['appointmentType'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      rescheduledTo: json['rescheduledTo'],
      paymentStatus: json['paymentStatus'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
