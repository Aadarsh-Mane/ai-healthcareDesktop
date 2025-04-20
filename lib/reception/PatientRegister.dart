import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

// Import local dependencies
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/ToastMessage.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/reception/AssignScreen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // IPD Controllers and State Variables
  final TextEditingController _ipdSearchController = TextEditingController();
  final GlobalKey<FormState> _ipdFormKey = GlobalKey<FormState>();
  final TextEditingController _ipdNameController = TextEditingController();
  final TextEditingController _ipdAgeController = TextEditingController();
  final TextEditingController _ipdContactController = TextEditingController();
  final TextEditingController _ipdAddressController = TextEditingController();
  final TextEditingController _ipdWeightController = TextEditingController();
  final TextEditingController _ipdReasonForAdmissionController =
      TextEditingController();
  final TextEditingController _ipdSymptomsController = TextEditingController();
  final TextEditingController _ipdInitialDiagnosisController =
      TextEditingController();
  final TextEditingController _ipdCasteController = TextEditingController();
  final TextEditingController _ipdPatientIdController = TextEditingController();
  File? _ipdSelectedImage;
  String _ipdSelectedGender = "Male";
  bool _ipdIsReadmission = false;
  String? _ipdPatientIdResult;
  List<String> _ipdPatientSuggestions = [];
  bool _isIpdSubmitting = false;

  // OPD Controllers and State Variables
  final TextEditingController _opdSearchController = TextEditingController();
  final GlobalKey<FormState> _opdFormKey = GlobalKey<FormState>();
  final TextEditingController _opdNameController = TextEditingController();
  final TextEditingController _opdAgeController = TextEditingController();
  final TextEditingController _opdContactController = TextEditingController();
  final TextEditingController _opdAddressController = TextEditingController();
  final TextEditingController _opdWeightController = TextEditingController();
  final TextEditingController _opdPatientIdController = TextEditingController();
  File? _opdSelectedImage;
  String _opdSelectedGender = "Male";
  bool _opdIsReadmission = false;
  String? _opdPatientIdResult;
  List<String> _opdPatientSuggestions = [];
  bool _isOpdSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipdNameController.dispose();
    _ipdAgeController.dispose();
    _ipdContactController.dispose();
    _ipdAddressController.dispose();
    _ipdWeightController.dispose();
    _ipdReasonForAdmissionController.dispose();
    _ipdSymptomsController.dispose();
    _ipdInitialDiagnosisController.dispose();
    _ipdCasteController.dispose();
    _ipdPatientIdController.dispose();
    _opdNameController.dispose();
    _opdAgeController.dispose();
    _opdContactController.dispose();
    _opdAddressController.dispose();
    _opdWeightController.dispose();
    _opdPatientIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchIPDPatientId() async {
    final name = _ipdSearchController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a name to search."),
          backgroundColor: HospitalTheme.error,
        ),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/info?name=$name'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ipdPatientIdResult = data['patientId'];
          // Auto-fill patient information
          _ipdNameController.text = data['name'] ?? '';
          _ipdAgeController.text = data['age']?.toString() ?? '';
          _ipdSelectedGender = data['gender'] ?? 'Male';
          _ipdContactController.text = data['contact'] ?? '';
          _ipdAddressController.text = data['address'] ?? '';
        });
      } else {
        setState(() {
          _ipdPatientIdResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No patient found with that name."),
            backgroundColor: HospitalTheme.warning,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred. Please try again."),
          backgroundColor: HospitalTheme.error,
        ),
      );
    }
  }

  Future<void> _fetchOPDPatientId() async {
    final name = _opdSearchController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a name to search."),
          backgroundColor: HospitalTheme.error,
        ),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/info?name=$name'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _opdPatientIdResult = data['patientId'];
          // Auto-fill patient information
          _opdNameController.text = data['name'] ?? '';
          _opdAgeController.text = data['age']?.toString() ?? '';
          _opdSelectedGender = data['gender'] ?? 'Male';
          _opdContactController.text = data['contact'] ?? '';
          _opdAddressController.text = data['address'] ?? '';
        });
      } else {
        setState(() {
          _opdPatientIdResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No patient found with that name."),
            backgroundColor: HospitalTheme.warning,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred. Please try again."),
          backgroundColor: HospitalTheme.error,
        ),
      );
    }
  }

  Future<void> _fetchIPDSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _ipdPatientSuggestions = []);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/suggestions?name=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() => _ipdPatientSuggestions = data.cast<String>());
      }
    } catch (e) {
      print("Error fetching IPD suggestions: $e");
    }
  }

  Future<void> _fetchOPDSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _opdPatientSuggestions = []);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/suggestions?name=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() => _opdPatientSuggestions = data.cast<String>());
      }
    } catch (e) {
      print("Error fetching OPD suggestions: $e");
    }
  }

  Future<void> pickImage(bool isIPD) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        if (isIPD) {
          _ipdSelectedImage = File(result.files.single.path!);
        } else {
          _opdSelectedImage = File(result.files.single.path!);
        }
      });
    } else {
      // Only show toast if context is still valid
      if (mounted) {
        ToastMessage().showToast(
            context, 'No image selected', '', ToastificationType.warning);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to handle responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: AppBar(
        title: Text(
          "Patient Registration",
          style: TextStyle(
            color: HospitalTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: HospitalTheme.primary,
          labelColor: HospitalTheme.primary,
          unselectedLabelColor: HospitalTheme.textMedium,
          tabs: [
            Tab(
              text: "OPD Registration",
              icon: Icon(Icons.local_hospital_outlined),
            ),
            Tab(
              text: "IPD Registration",
              icon: Icon(Icons.personal_injury_outlined),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOPDForm(isSmallScreen),
          _buildIPDForm(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildIPDForm(bool isSmallScreen) {
    return SafeArea(
      child: Center(
        child: Container(
          constraints:
              BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 1000),
          child: Card(
            margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header section with responsive layout
                  _buildHeaderSection(
                    title: "IPD Patient Registration",
                    subtitle: "Enter patient details for in-patient department",
                    icon: Icons.personal_injury_outlined,
                    color: HospitalTheme.primary,
                    isSmallScreen: isSmallScreen,
                  ),

                  Divider(
                    color: HospitalTheme.border,
                    height: 32,
                  ),

                  // Form section
                  Form(
                    key: _ipdFormKey,
                    child: Column(
                      children: [
                        // Search and Patient ID Row - Stacks vertically on small screens
                        isSmallScreen
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSearchSection(
                                    label: "Search Existing Patient",
                                    controller: _ipdSearchController,
                                    searchFn: _fetchIPDPatientId,
                                    suggestions: _ipdPatientSuggestions,
                                    fetchSuggestions: _fetchIPDSuggestions,
                                    color: HospitalTheme.primary,
                                  ),
                                  SizedBox(height: 16),
                                  _buildPatientIdResultSection(
                                    patientId: _ipdPatientIdResult,
                                    color: HospitalTheme.primary,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildSearchSection(
                                      label: "Search Existing Patient",
                                      controller: _ipdSearchController,
                                      searchFn: _fetchIPDPatientId,
                                      suggestions: _ipdPatientSuggestions,
                                      fetchSuggestions: _fetchIPDSuggestions,
                                      color: HospitalTheme.primary,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _buildPatientIdResultSection(
                                      patientId: _ipdPatientIdResult,
                                      color: HospitalTheme.primary,
                                    ),
                                  ),
                                ],
                              ),

                        SizedBox(height: 24),

                        // Personal Information Section
                        _buildInfoSection(
                          title: "Personal Information",
                          color: HospitalTheme.primary,
                          isSmallScreen: isSmallScreen,
                          content: isSmallScreen
                              ? Column(
                                  children: [
                                    _buildStyledField(
                                      label: "Full Name",
                                      controller: _ipdNameController,
                                      hintText: 'Enter patient full name',
                                      icon: Icons.person,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter patient name';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Age",
                                      controller: _ipdAgeController,
                                      hintText: 'Age in years',
                                      keyboardType: TextInputType.number,
                                      icon: Icons.calendar_today,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter age';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Weight (kg)",
                                      controller: _ipdWeightController,
                                      hintText: 'Weight in kg',
                                      keyboardType: TextInputType.number,
                                      icon: Icons.monitor_weight,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter weight';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Phone Number",
                                      controller: _ipdContactController,
                                      hintText: 'Enter contact number',
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Address",
                                      controller: _ipdAddressController,
                                      hintText: 'Enter home address',
                                      icon: Icons.home,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildStyledField(
                                            label: "Full Name",
                                            controller: _ipdNameController,
                                            hintText: 'Enter patient full name',
                                            icon: Icons.person,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter patient name';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildStyledField(
                                                  label: "Age",
                                                  controller: _ipdAgeController,
                                                  hintText: 'Age in years',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  icon: Icons.calendar_today,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Enter age';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: _buildStyledField(
                                                  label: "Weight (kg)",
                                                  controller:
                                                      _ipdWeightController,
                                                  hintText: 'Weight in kg',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  icon: Icons.monitor_weight,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Enter weight';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    // Right column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildStyledField(
                                            label: "Phone Number",
                                            controller: _ipdContactController,
                                            hintText: 'Enter contact number',
                                            keyboardType: TextInputType.phone,
                                            icon: Icons.phone,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Enter phone number';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          _buildStyledField(
                                            label: "Address",
                                            controller: _ipdAddressController,
                                            hintText: 'Enter home address',
                                            icon: Icons.home,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Enter address';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          footer: _buildGenderSelection(
                            selectedGender: _ipdSelectedGender,
                            onChanged: (newValue) =>
                                setState(() => _ipdSelectedGender = newValue!),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Medical Information
                        _buildInfoSection(
                          title: "Medical Information",
                          color: HospitalTheme.medical,
                          isSmallScreen: isSmallScreen,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Medical details
                              _buildStyledField(
                                label: "Reason for Admission",
                                controller: _ipdReasonForAdmissionController,
                                hintText: 'Enter reason for admission',
                                icon: Icons.local_hospital,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter reason for admission';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildStyledField(
                                label: "Symptoms",
                                controller: _ipdSymptomsController,
                                hintText: 'Enter symptoms',
                                icon: Icons.sick,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter symptoms';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildStyledField(
                                label: "Initial Diagnosis",
                                controller: _ipdInitialDiagnosisController,
                                hintText: 'Enter initial diagnosis if any',
                                icon: Icons.medical_services,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter initial diagnosis';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              // Caste Field
                              _buildStyledField(
                                label: "Caste (Optional)",
                                controller: _ipdCasteController,
                                hintText: 'Enter caste if applicable',
                                icon: Icons.group,
                              ),
                              SizedBox(height: 16),
                              // Readmission
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.rotate_left,
                                        color: HospitalTheme.primary,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Is this a readmission?",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: HospitalTheme.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _ipdIsReadmission,
                                    onChanged: (value) {
                                      setState(() {
                                        _ipdIsReadmission = value;
                                      });
                                    },
                                    activeColor: HospitalTheme.success,
                                  ),
                                ],
                              ),
                              // Patient ID field for readmission
                              if (_ipdIsReadmission)
                                _buildStyledField(
                                  label: "Patient ID for Readmission",
                                  controller: _ipdPatientIdController,
                                  hintText: 'Enter previous patient ID',
                                  icon: Icons.badge,
                                  validator: (value) {
                                    if (_ipdIsReadmission &&
                                        (value == null || value.isEmpty)) {
                                      return 'Patient ID is required for readmission';
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Patient Photo Section
                        _buildPatientPhotoSection(
                          image: _ipdSelectedImage,
                          onPick: () => pickImage(true),
                          onRemove: () =>
                              setState(() => _ipdSelectedImage = null),
                          color: HospitalTheme.primary,
                          isSmallScreen: isSmallScreen,
                        ),

                        SizedBox(height: 32),

                        // Submit button
                        _buildSubmitButton(
                          isSubmitting: _isIpdSubmitting,
                          onPressed: () {
                            if (_ipdFormKey.currentState!.validate()) {
                              _showConfirmationDialog(context, true);
                            }
                          },
                          color: HospitalTheme.primary,
                          text: "Register IPD Patient",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOPDForm(bool isSmallScreen) {
    return SafeArea(
      child: Center(
        child: Container(
          constraints:
              BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 1000),
          child: Card(
            margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header section
                  _buildHeaderSection(
                    title: "OPD Patient Registration",
                    subtitle:
                        "Enter patient details for out-patient department",
                    icon: Icons.local_hospital_outlined,
                    color: HospitalTheme.pharmacy,
                    isSmallScreen: isSmallScreen,
                  ),

                  Divider(
                    color: HospitalTheme.border,
                    height: 32,
                  ),

                  // Form section
                  Form(
                    key: _opdFormKey,
                    child: Column(
                      children: [
                        // Search and Patient ID Row - Stacks vertically on small screens
                        isSmallScreen
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSearchSection(
                                    label: "Search Existing Patient",
                                    controller: _opdSearchController,
                                    searchFn: _fetchOPDPatientId,
                                    suggestions: _opdPatientSuggestions,
                                    fetchSuggestions: _fetchOPDSuggestions,
                                    color: HospitalTheme.pharmacy,
                                  ),
                                  SizedBox(height: 16),
                                  _buildPatientIdResultSection(
                                    patientId: _opdPatientIdResult,
                                    color: HospitalTheme.pharmacy,
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildSearchSection(
                                      label: "Search Existing Patient",
                                      controller: _opdSearchController,
                                      searchFn: _fetchOPDPatientId,
                                      suggestions: _opdPatientSuggestions,
                                      fetchSuggestions: _fetchOPDSuggestions,
                                      color: HospitalTheme.pharmacy,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _buildPatientIdResultSection(
                                      patientId: _opdPatientIdResult,
                                      color: HospitalTheme.pharmacy,
                                    ),
                                  ),
                                ],
                              ),

                        SizedBox(height: 24),

                        // Personal Information Section
                        _buildInfoSection(
                          title: "Personal Information",
                          color: HospitalTheme.pharmacy,
                          isSmallScreen: isSmallScreen,
                          content: isSmallScreen
                              ? Column(
                                  children: [
                                    _buildStyledField(
                                      label: "Full Name",
                                      controller: _opdNameController,
                                      hintText: 'Enter patient full name',
                                      icon: Icons.person,
                                      color: HospitalTheme.pharmacy,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter patient name';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Age",
                                      controller: _opdAgeController,
                                      hintText: 'Age in years',
                                      keyboardType: TextInputType.number,
                                      icon: Icons.calendar_today,
                                      color: HospitalTheme.pharmacy,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter age';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Weight (kg)",
                                      controller: _opdWeightController,
                                      hintText: 'Weight in kg',
                                      keyboardType: TextInputType.number,
                                      icon: Icons.monitor_weight,
                                      color: HospitalTheme.pharmacy,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter weight';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Phone Number",
                                      controller: _opdContactController,
                                      hintText: 'Enter contact number',
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone,
                                      color: HospitalTheme.pharmacy,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    _buildStyledField(
                                      label: "Address",
                                      controller: _opdAddressController,
                                      hintText: 'Enter home address',
                                      icon: Icons.home,
                                      color: HospitalTheme.pharmacy,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildStyledField(
                                            label: "Full Name",
                                            controller: _opdNameController,
                                            hintText: 'Enter patient full name',
                                            icon: Icons.person,
                                            color: HospitalTheme.pharmacy,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter patient name';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildStyledField(
                                                  label: "Age",
                                                  controller: _opdAgeController,
                                                  hintText: 'Age in years',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  icon: Icons.calendar_today,
                                                  color: HospitalTheme.pharmacy,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Enter age';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: _buildStyledField(
                                                  label: "Weight (kg)",
                                                  controller:
                                                      _opdWeightController,
                                                  hintText: 'Weight in kg',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  icon: Icons.monitor_weight,
                                                  color: HospitalTheme.pharmacy,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Enter weight';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    // Right column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildStyledField(
                                            label: "Phone Number",
                                            controller: _opdContactController,
                                            hintText: 'Enter contact number',
                                            keyboardType: TextInputType.phone,
                                            icon: Icons.phone,
                                            color: HospitalTheme.pharmacy,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Enter phone number';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 16),
                                          _buildStyledField(
                                            label: "Address",
                                            controller: _opdAddressController,
                                            hintText: 'Enter home address',
                                            icon: Icons.home,
                                            color: HospitalTheme.pharmacy,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Enter address';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          footer: _buildGenderSelection(
                            selectedGender: _opdSelectedGender,
                            onChanged: (newValue) =>
                                setState(() => _opdSelectedGender = newValue!),
                            color: HospitalTheme.pharmacy,
                          ),
                        ),

                        SizedBox(height: 24),

                        // Readmission Section
                        _buildInfoSection(
                          title: "Visit Information",
                          color: HospitalTheme.pharmacy,
                          isSmallScreen: isSmallScreen,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Readmission toggle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.rotate_left,
                                        color: HospitalTheme.pharmacy,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Is this a return visit?",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: HospitalTheme.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _opdIsReadmission,
                                    onChanged: (value) {
                                      setState(() {
                                        _opdIsReadmission = value;
                                      });
                                    },
                                    activeColor: HospitalTheme.success,
                                  ),
                                ],
                              ),
                              // Patient ID field for readmission
                              if (_opdIsReadmission)
                                _buildStyledField(
                                  label: "Previous Patient ID",
                                  controller: _opdPatientIdController,
                                  hintText: 'Enter previous patient ID',
                                  icon: Icons.badge,
                                  color: HospitalTheme.pharmacy,
                                  validator: (value) {
                                    if (_opdIsReadmission &&
                                        (value == null || value.isEmpty)) {
                                      return 'Patient ID is required for return patients';
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Patient Photo Section
                        _buildPatientPhotoSection(
                          image: _opdSelectedImage,
                          onPick: () => pickImage(false),
                          onRemove: () =>
                              setState(() => _opdSelectedImage = null),
                          color: HospitalTheme.pharmacy,
                          isSmallScreen: isSmallScreen,
                        ),

                        SizedBox(height: 32),

                        // Submit button
                        _buildSubmitButton(
                          isSubmitting: _isOpdSubmitting,
                          onPressed: () {
                            if (_opdFormKey.currentState!.validate()) {
                              _showConfirmationDialog(context, false);
                            }
                          },
                          color: HospitalTheme.pharmacy,
                          text: "Register OPD Patient",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header section with logo and title
  Widget _buildHeaderSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Image.asset("${AppImages.logo}", height: 40),
              ),
            ],
          )
        : Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Container(
                height: 50,
                child: Center(
                  child: Image.asset("${AppImages.logo}", height: 50),
                ),
              ),
            ],
          );
  }

  // Search section with autocomplete
  Widget _buildSearchSection({
    required String label,
    required TextEditingController controller,
    required VoidCallback searchFn,
    required List<String> suggestions,
    required Function(String) fetchSuggestions,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            fetchSuggestions(textEditingValue.text);
            return suggestions.where((option) => option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selectedPatient) async {
            controller.text = selectedPatient;
            searchFn();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return Container(
              height: 50,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: "Patient Name",
                  hintText: "Search by patient name",
                  prefixIcon: Icon(
                    Icons.search,
                    color: color,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: HospitalTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Patient ID Result Section
  Widget _buildPatientIdResultSection({
    required String? patientId,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Patient ID Result",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  patientId != null ? "$patientId" : "No patient found",
                  style: TextStyle(
                    color: patientId != null ? color : HospitalTheme.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (patientId != null)
                IconButton(
                  icon: Icon(Icons.copy, color: color),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: patientId));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Patient ID copied to clipboard!"),
                          backgroundColor: HospitalTheme.success,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Information Section Container
  Widget _buildInfoSection({
    required String title,
    required Color color,
    required Widget content,
    required bool isSmallScreen,
    Widget? footer,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: HospitalTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 16),
          content,
          if (footer != null) ...[
            SizedBox(height: 16),
            footer,
          ],
        ],
      ),
    );
  }

  // Helper widget for styled form fields
  Widget _buildStyledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Color color = HospitalTheme.primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: color),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: HospitalTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: HospitalTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: HospitalTheme.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Gender selection widget
  Widget _buildGenderSelection({
    required String selectedGender,
    required ValueChanged<String?> onChanged,
    Color color = HospitalTheme.primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            _buildGenderOption(
              label: "Male",
              icon: Icons.male,
              isSelected: selectedGender == "Male",
              onTap: () => onChanged("Male"),
              color: color,
            ),
            SizedBox(width: 16),
            _buildGenderOption(
              label: "Female",
              icon: Icons.female,
              isSelected: selectedGender == "Female",
              onTap: () => onChanged("Female"),
              color: color,
            ),
            SizedBox(width: 16),
            _buildGenderOption(
              label: "Other",
              icon: Icons.transgender,
              isSelected: selectedGender == "Other",
              onTap: () => onChanged("Other"),
              color: color,
            ),
          ],
        ),
      ],
    );
  }

  // Gender option widget
  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : HospitalTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : HospitalTheme.textMedium,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : HospitalTheme.textDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Patient Photo Section
  Widget _buildPatientPhotoSection({
    required File? image,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Patient Photo",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 16),
          isSmallScreen
              ? Column(
                  children: [
                    // Image container centered
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: HospitalTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HospitalTheme.border),
                        ),
                        child: image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  image,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    color: HospitalTheme.textMedium,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "No image selected",
                                    style: TextStyle(
                                      color: HospitalTheme.textMedium,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Upload instructions
                    Text(
                      "Please upload a clear photo of the patient's face for identification purposes.",
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    // Upload buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onPick,
                          icon: Icon(Icons.file_upload),
                          label: Text("Select Image"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        if (image != null)
                          TextButton.icon(
                            onPressed: onRemove,
                            icon:
                                Icon(Icons.delete, color: HospitalTheme.error),
                            label: Text(
                              "Remove",
                              style: TextStyle(
                                color: HospitalTheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Image preview
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: HospitalTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: HospitalTheme.border),
                      ),
                      child: image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                image,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: HospitalTheme.textMedium,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "No image selected",
                                  style: TextStyle(
                                    color: HospitalTheme.textMedium,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                    SizedBox(width: 24),
                    // Upload button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Upload patient photo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Please upload a clear photo of the patient's face for identification purposes.",
                            style: TextStyle(
                              color: HospitalTheme.textMedium,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: onPick,
                                icon: Icon(Icons.file_upload),
                                label: Text("Select Image"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              if (image != null)
                                TextButton.icon(
                                  onPressed: onRemove,
                                  icon: Icon(Icons.delete,
                                      color: HospitalTheme.error),
                                  label: Text(
                                    "Remove",
                                    style: TextStyle(
                                      color: HospitalTheme.error,
                                    ),
                                  ),
                                ),
                            ],
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

  // Submit Button
  Widget _buildSubmitButton({
    required bool isSubmitting,
    required VoidCallback onPressed,
    required Color color,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: isSubmitting ? null : onPressed,
          icon: isSubmitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.save),
          label: Text(isSubmitting ? "Processing..." : text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  // Confirmation dialog
  void _showConfirmationDialog(BuildContext context, bool isIPD) {
    final name = isIPD ? _ipdNameController.text : _opdNameController.text;
    final age = isIPD ? _ipdAgeController.text : _opdAgeController.text;
    final gender = isIPD ? _ipdSelectedGender : _opdSelectedGender;
    final contact =
        isIPD ? _ipdContactController.text : _opdContactController.text;
    final address =
        isIPD ? _ipdAddressController.text : _opdAddressController.text;
    final weight =
        isIPD ? _ipdWeightController.text : _opdWeightController.text;
    final isReadmission = isIPD ? _ipdIsReadmission : _opdIsReadmission;
    final patientId =
        isIPD ? _ipdPatientIdController.text : _opdPatientIdController.text;

    final themeColor = isIPD ? HospitalTheme.primary : HospitalTheme.pharmacy;

    // Get screen width to handle responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: isSmallScreen ? double.infinity : 500,
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.medical_information,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Confirm Patient Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((isIPD && _ipdSelectedImage != null) ||
                          (!isIPD && _opdSelectedImage != null))
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(color: themeColor, width: 2),
                              image: DecorationImage(
                                image: FileImage(
                                  isIPD
                                      ? _ipdSelectedImage!
                                      : _opdSelectedImage!,
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      _buildConfirmationSectionHeader(
                          "Personal Information", themeColor),
                      _buildConfirmationRow("Full Name", name),
                      _buildConfirmationRow("Age", "$age years"),
                      _buildConfirmationRow("Gender", gender),
                      _buildConfirmationRow("Phone", contact),
                      _buildConfirmationRow("Address", address),
                      _buildConfirmationRow("Weight", "$weight kg"),
                      if (isIPD) ...[
                        SizedBox(height: 16),
                        _buildConfirmationSectionHeader(
                            "Medical Information", themeColor),
                        _buildConfirmationRow("Reason for Admission",
                            _ipdReasonForAdmissionController.text),
                        _buildConfirmationRow(
                            "Symptoms", _ipdSymptomsController.text),
                        _buildConfirmationRow("Initial Diagnosis",
                            _ipdInitialDiagnosisController.text),
                        if (_ipdCasteController.text.isNotEmpty)
                          _buildConfirmationRow(
                              "Caste", _ipdCasteController.text),
                      ],
                      SizedBox(height: 16),
                      _buildConfirmationSectionHeader(
                          "Visit Information", themeColor),
                      _buildConfirmationRow(
                          isIPD ? "Is Readmission" : "Is Return Visit",
                          isReadmission ? "Yes" : "No"),
                      if (isReadmission)
                        _buildConfirmationRow("Previous Patient ID", patientId),
                    ],
                  ),
                ),
              ),
              // Footer with action buttons
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Edit",
                        style: TextStyle(color: HospitalTheme.textMedium),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (isIPD) {
                          _addIPDPatient(context);
                        } else {
                          _addOPDPatient(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Confirm & Register"),
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

  // Confirmation section header
  Widget _buildConfirmationSectionHeader(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Divider(color: color.withOpacity(0.5)),
        SizedBox(height: 8),
      ],
    );
  }

  // Confirmation row
  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
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

  // Add IPD Patient with improved navigation handling
  Future<void> _addIPDPatient(BuildContext context) async {
    final currentContext = context;

    setState(() {
      _isIpdSubmitting = true;
    });

    try {
      final uri = Uri.parse('${KVM_URL}/reception/addPatient');
      print("IPD Request URL: $uri");
      final request = http.MultipartRequest('POST', uri);

      // Add IPD-specific fields
      request.fields['name'] = _ipdNameController.text;
      request.fields['age'] = _ipdAgeController.text;
      request.fields['gender'] = _ipdSelectedGender;
      request.fields['contact'] = _ipdContactController.text;
      request.fields['address'] = _ipdAddressController.text;
      request.fields['weight'] = _ipdWeightController.text;
      request.fields['reasonForAdmission'] =
          _ipdReasonForAdmissionController.text;
      request.fields['symptoms'] = _ipdSymptomsController.text;
      request.fields['initialDiagnosis'] = _ipdInitialDiagnosisController.text;
      request.fields['caste'] = _ipdCasteController.text;
      request.fields['isReadmission'] = _ipdIsReadmission.toString();

      if (_ipdIsReadmission) {
        if (_ipdPatientIdController.text.isEmpty) {
          setState(() {
            _isIpdSubmitting = false;
          });
          if (currentContext.mounted) {
            ToastMessage().showToast(
                currentContext,
                'Patient ID is required for readmission',
                '',
                ToastificationType.error);
          }
          return;
        }
        request.fields['patientId'] = _ipdPatientIdController.text;
      }

      if (_ipdSelectedImage != null) {
        final imageFile = await http.MultipartFile.fromPath(
          'image',
          _ipdSelectedImage!.path,
        );
        request.files.add(imageFile);
      }

      print("Sending IPD request...");
      final response = await request.send();
      print("IPD Response status code: ${response.statusCode}");

      // Read the response body once and store it
      final responseString = await response.stream.bytesToString();
      print("IPD Response body: $responseString");

      // Update submission state
      setState(() {
        _isIpdSubmitting = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(responseString);
          print("IPD Parsed response: $responseBody");

          final patientId = responseBody['patientDetails']['patientId'];
          final admissionId =
              responseBody['patientDetails']['admissionRecords'][0]['_id'];

          print(
              "IPD Navigation data: patientId=$patientId, admissionId=$admissionId");

          // Improved navigation logic that works across platforms
          if (currentContext.mounted) {
            // Wait for the next frame to ensure state is updated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Use Navigator.of(context).pushAndRemoveUntil to clear previous routes
              Navigator.of(currentContext).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => AssignScreen(
                    patientId: patientId,
                    admissionId: admissionId,
                  ),
                ),
                (route) => false, // This will remove all previous routes
              );
            });

            // Show a toast to indicate successful registration
            // Small delay to ensure navigation has started
            Future.delayed(Duration(milliseconds: 100), () {
              if (currentContext.mounted) {
                ToastMessage().showToast(
                  currentContext,
                  'Patient Registered Successfully',
                  '',
                  ToastificationType.success,
                );
              }
            });
          }
        } catch (parseError) {
          print("Error parsing IPD response: $parseError");
          if (currentContext.mounted) {
            ToastMessage().showToast(
              currentContext,
              'Error processing response: $parseError',
              '',
              ToastificationType.error,
            );
          }
        }
      } else {
        String errorMessage = 'An unknown error occurred';
        try {
          final errorData = jsonDecode(responseString);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          print("Error parsing error response: $e");
        }

        if (currentContext.mounted) {
          ToastMessage().showToast(
              currentContext, errorMessage, '', ToastificationType.error);
        }
      }
    } catch (e) {
      print("Exception in _addIPDPatient: $e");
      setState(() {
        _isIpdSubmitting = false;
      });

      if (currentContext.mounted) {
        ToastMessage().showToast(currentContext,
            'Failed to register patient: $e', '', ToastificationType.error);
      }
    }
  }

  // Add OPD Patient with improved navigation handling
  Future<void> _addOPDPatient(BuildContext context) async {
    final currentContext = context;

    setState(() {
      _isOpdSubmitting = true;
    });

    try {
      final uri = Uri.parse('${KVM_URL}/reception/addPatient');
      print("OPD Request URL: $uri");
      final request = http.MultipartRequest('POST', uri);

      // Add OPD-specific fields
      request.fields['name'] = _opdNameController.text;
      request.fields['age'] = _opdAgeController.text;
      request.fields['gender'] = _opdSelectedGender;
      request.fields['contact'] = _opdContactController.text;
      request.fields['address'] = _opdAddressController.text;
      request.fields['weight'] = _opdWeightController.text;
      request.fields['isReadmission'] = _opdIsReadmission.toString();

      if (_opdIsReadmission) {
        if (_opdPatientIdController.text.isEmpty) {
          setState(() {
            _isOpdSubmitting = false;
          });
          if (currentContext.mounted) {
            ToastMessage().showToast(
                currentContext,
                'Patient ID is required for return visit',
                '',
                ToastificationType.error);
          }
          return;
        }
        request.fields['patientId'] = _opdPatientIdController.text;
      }

      if (_opdSelectedImage != null) {
        final imageFile = await http.MultipartFile.fromPath(
          'image',
          _opdSelectedImage!.path,
        );
        request.files.add(imageFile);
      }

      print("Sending OPD request...");
      final response = await request.send();
      print("OPD Response status code: ${response.statusCode}");

      // Read the response body once and store it
      final responseString = await response.stream.bytesToString();
      print("OPD Response body: $responseString");

      setState(() {
        _isOpdSubmitting = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(responseString);
          print("OPD Parsed response: $responseBody");

          final patientId = responseBody['patientDetails']['patientId'];
          final admissionId =
              responseBody['patientDetails']['admissionRecords'][0]['_id'];

          print(
              "OPD Navigation data: patientId=$patientId, admissionId=$admissionId");

          // Improved navigation logic that works across platforms
          if (currentContext.mounted) {
            // Wait for the next frame to ensure state is updated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Use Navigator.of(context).pushAndRemoveUntil to clear previous routes
              Navigator.of(currentContext).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => AssignScreen(
                    patientId: patientId,
                    admissionId: admissionId,
                  ),
                ),
                (route) => false, // This will remove all previous routes
              );
            });

            // Show a toast to indicate successful registration
            // Small delay to ensure navigation has started
            Future.delayed(Duration(milliseconds: 100), () {
              if (currentContext.mounted) {
                ToastMessage().showToast(
                  currentContext,
                  'Patient Registered Successfully',
                  '',
                  ToastificationType.success,
                );
              }
            });
          }
        } catch (parseError) {
          print("Error parsing OPD response: $parseError");
          if (currentContext.mounted) {
            ToastMessage().showToast(
              currentContext,
              'Error processing response: $parseError',
              '',
              ToastificationType.error,
            );
          }
        }
      } else {
        String errorMessage = 'An unknown error occurred';
        try {
          final errorData = jsonDecode(responseString);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          print("Error parsing error response: $e");
        }

        if (currentContext.mounted) {
          ToastMessage().showToast(
              currentContext, errorMessage, '', ToastificationType.error);
        }
      }
    } catch (e) {
      print("Exception in _addOPDPatient: $e");
      setState(() {
        _isOpdSubmitting = false;
      });

      if (currentContext.mounted) {
        ToastMessage().showToast(currentContext,
            'Failed to register patient: $e', '', ToastificationType.error);
      }
    }
  }
}
