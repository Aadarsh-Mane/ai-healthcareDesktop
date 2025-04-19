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
      ToastMessage().showToast(
          context, 'No image selected', '', ToastificationType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _buildOPDForm(),
          _buildIPDForm(),
        ],
      ),
    );
  }

  Widget _buildIPDForm() {
    return SafeArea(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1000),
          child: Card(
            margin: EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header section
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: HospitalTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.personal_injury_outlined,
                          color: HospitalTheme.primary,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "IPD Patient Registration",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            Text(
                              "Enter patient details for in-patient department",
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
                        // Search and Patient ID Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Search Existing Patient",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: HospitalTheme.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Autocomplete<String>(
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                      _fetchIPDSuggestions(
                                          textEditingValue.text);
                                      return _ipdPatientSuggestions.where(
                                          (option) => option
                                              .toLowerCase()
                                              .contains(textEditingValue.text
                                                  .toLowerCase()));
                                    },
                                    onSelected: (String selectedPatient) async {
                                      _ipdSearchController.text =
                                          selectedPatient;
                                      await _fetchIPDPatientId();
                                    },
                                    fieldViewBuilder: (context, controller,
                                        focusNode, onFieldSubmitted) {
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
                                              color: HospitalTheme.primary,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: HospitalTheme.border),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: HospitalTheme.primary),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: HospitalTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: HospitalTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SelectableText(
                                            _ipdPatientIdResult != null
                                                ? "$_ipdPatientIdResult"
                                                : "No patient found",
                                            style: TextStyle(
                                              color: _ipdPatientIdResult != null
                                                  ? HospitalTheme.primary
                                                  : HospitalTheme.textMedium,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (_ipdPatientIdResult != null)
                                          IconButton(
                                            icon: Icon(Icons.copy,
                                                color: HospitalTheme.primary),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: _ipdPatientIdResult!));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Patient ID copied to clipboard!"),
                                                  backgroundColor:
                                                      HospitalTheme.success,
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Personal Information
                        Container(
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
                                "Personal Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.primary,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
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
                              SizedBox(height: 16),
                              _buildGenderSelection(
                                selectedGender: _ipdSelectedGender,
                                onChanged: (newValue) => setState(
                                    () => _ipdSelectedGender = newValue!),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Medical Information
                        Container(
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
                                "Medical Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.medical,
                                ),
                              ),
                              SizedBox(height: 16),
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

                        // Patient Photo
                        Container(
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
                                  color: HospitalTheme.primary,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  // Image preview
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: HospitalTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: HospitalTheme.border),
                                    ),
                                    child: _ipdSelectedImage != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              _ipdSelectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                  color:
                                                      HospitalTheme.textMedium,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              onPressed: () => pickImage(true),
                                              icon: Icon(Icons.file_upload),
                                              label: Text("Select Image"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    HospitalTheme.primary,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            if (_ipdSelectedImage != null)
                                              TextButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    _ipdSelectedImage = null;
                                                  });
                                                },
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
                        ),

                        SizedBox(height: 32),

                        // Submit button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isIpdSubmitting
                                  ? null
                                  : () {
                                      if (_ipdFormKey.currentState!
                                          .validate()) {
                                        _showConfirmationDialog(context, true);
                                      }
                                    },
                              icon: _isIpdSubmitting
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.save),
                              label: Text(_isIpdSubmitting
                                  ? "Processing..."
                                  : "Register Patient"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HospitalTheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOPDForm() {
    return SafeArea(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1000),
          child: Card(
            margin: EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header section
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: HospitalTheme.pharmacy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_hospital_outlined,
                          color: HospitalTheme.pharmacy,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "OPD Patient Registration",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            Text(
                              "Enter patient details for out-patient department",
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
                        // Search and Patient ID Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Search Existing Patient",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: HospitalTheme.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Autocomplete<String>(
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                      _fetchOPDSuggestions(
                                          textEditingValue.text);
                                      return _opdPatientSuggestions.where(
                                          (option) => option
                                              .toLowerCase()
                                              .contains(textEditingValue.text
                                                  .toLowerCase()));
                                    },
                                    onSelected: (String selectedPatient) async {
                                      _opdSearchController.text =
                                          selectedPatient;
                                      await _fetchOPDPatientId();
                                    },
                                    fieldViewBuilder: (context, controller,
                                        focusNode, onFieldSubmitted) {
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
                                              color: HospitalTheme.pharmacy,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: HospitalTheme.border),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color:
                                                      HospitalTheme.pharmacy),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: HospitalTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: HospitalTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SelectableText(
                                            _opdPatientIdResult != null
                                                ? "$_opdPatientIdResult"
                                                : "No patient found",
                                            style: TextStyle(
                                              color: _opdPatientIdResult != null
                                                  ? HospitalTheme.pharmacy
                                                  : HospitalTheme.textMedium,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (_opdPatientIdResult != null)
                                          IconButton(
                                            icon: Icon(Icons.copy,
                                                color: HospitalTheme.pharmacy),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: _opdPatientIdResult!));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Patient ID copied to clipboard!"),
                                                  backgroundColor:
                                                      HospitalTheme.success,
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Personal Information
                        Container(
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
                                "Personal Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.pharmacy,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
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
                              SizedBox(height: 16),
                              _buildGenderSelection(
                                selectedGender: _opdSelectedGender,
                                onChanged: (newValue) => setState(
                                    () => _opdSelectedGender = newValue!),
                                color: HospitalTheme.pharmacy,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Readmission Section
                        Container(
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
                                "Visit Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.pharmacy,
                                ),
                              ),
                              SizedBox(height: 16),
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

                        // Patient Photo
                        Container(
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
                                  color: HospitalTheme.pharmacy,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  // Image preview
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: HospitalTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: HospitalTheme.border),
                                    ),
                                    child: _opdSelectedImage != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              _opdSelectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                  color:
                                                      HospitalTheme.textMedium,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              onPressed: () => pickImage(false),
                                              icon: Icon(Icons.file_upload),
                                              label: Text("Select Image"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    HospitalTheme.pharmacy,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            if (_opdSelectedImage != null)
                                              TextButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    _opdSelectedImage = null;
                                                  });
                                                },
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
                        ),

                        SizedBox(height: 32),

                        // Submit button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isOpdSubmitting
                                  ? null
                                  : () {
                                      if (_opdFormKey.currentState!
                                          .validate()) {
                                        _showConfirmationDialog(context, false);
                                      }
                                    },
                              icon: _isOpdSubmitting
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(Icons.save),
                              label: Text(_isOpdSubmitting
                                  ? "Processing..."
                                  : "Register Patient"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HospitalTheme.pharmacy,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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
            ),
          ),
        ),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: Container(
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
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxWidth: 500, maxHeight: 500),
          child: SingleChildScrollView(
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
                            isIPD ? _ipdSelectedImage! : _opdSelectedImage!,
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
                  _buildConfirmationRow(
                      "Initial Diagnosis", _ipdInitialDiagnosisController.text),
                  if (_ipdCasteController.text.isNotEmpty)
                    _buildConfirmationRow("Caste", _ipdCasteController.text),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Edit",
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
          ),
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
            ),
            child: Text("Confirm & Register"),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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

  // Add IPD Patient
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

      setState(() {
        _isIpdSubmitting = false;
      });

      // Update the _addIPDPatient method:
      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(responseString);
          print("IPD Parsed response: $responseBody");

          final patientId = responseBody['patientDetails']['patientId'];
          final admissionId =
              responseBody['patientDetails']['admissionRecords'][0]['_id'];

          print(
              "IPD Navigation data: patientId=$patientId, admissionId=$admissionId");

          // Check if the context is still valid before navigating
          // In both _addIPDPatient and _addOPDPatient methods, replace the navigation code with:

// Check if the context is still valid before navigating
          if (currentContext.mounted) {
            // Use Future.microtask to ensure the navigation happens after the current build cycle
            Future.microtask(() {
              Navigator.of(currentContext).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AssignScreen(
                      patientId: patientId, admissionId: admissionId),
                ),
              );
            });
          }

          // Show toast after navigation
          Future.delayed(Duration(milliseconds: 300), () {
            if (currentContext.mounted) {
              ToastMessage().showToast(
                currentContext,
                'Patient Registered Successfully',
                '',
                ToastificationType.success,
              );
            }
          });
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

// Add OPD Patient
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

      // Update the _addOPDPatient method:
      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(responseString);
          print("OPD Parsed response: $responseBody");

          final patientId = responseBody['patientDetails']['patientId'];
          final admissionId =
              responseBody['patientDetails']['admissionRecords'][0]['_id'];

          print(
              "OPD Navigation data: patientId=$patientId, admissionId=$admissionId");

          // Check if the context is still valid before navigating
          // if (currentContext.mounted) {
          //   Navigator.of(currentContext).pushReplacement(
          //     MaterialPageRoute(
          //       builder: (context) => AssignScreen(
          //           patientId: patientId, admissionId: admissionId),
          //     ),
          //   );
          // }
          // In both _addIPDPatient and _addOPDPatient methods, replace the navigation code with:

// Check if the context is still valid before navigating
          if (currentContext.mounted) {
            // Use Future.microtask to ensure the navigation happens after the current build cycle
            Future.microtask(() {
              Navigator.of(currentContext).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AssignScreen(
                      patientId: patientId, admissionId: admissionId),
                ),
              );
            });
          }

          // Show toast after navigation
          Future.delayed(Duration(milliseconds: 300), () {
            if (currentContext.mounted) {
              ToastMessage().showToast(
                currentContext,
                'Patient Registered Successfully',
                '',
                ToastificationType.success,
              );
            }
          });
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
