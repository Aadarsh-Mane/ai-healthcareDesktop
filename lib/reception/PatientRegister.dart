import 'dart:convert';
import 'dart:io';
import 'package:doctordesktop/constants/ToastMessage.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/reception/AssignScreen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PatientAddScreen extends StatefulWidget {
  const PatientAddScreen({super.key});

  @override
  State<PatientAddScreen> createState() => _PatientAddScreenState();
}

class _PatientAddScreenState extends State<PatientAddScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _patientIdResult;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _weightController = TextEditingController();
  final _reasonForAdmissionController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _initialDiagnosisController = TextEditingController();
  final _casteController = TextEditingController();
  final _patientIdController = TextEditingController();
  File? _selectedImage;
  String _selectedGender = "Male";
  bool _isReadmission = false;
  late TabController _tabController;
  Future<void> _fetchPatientId() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a name to search.")),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/reception/info?name=$name'),
      );
      print("Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Parsed data: $data");
        setState(() {
          _patientIdResult = data['patientId'];
        });
        print("Patient ID set: $_patientIdResult");
      } else {
        setState(() {
          _patientIdResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No patient found with that name.")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }
  }

  List<String> _patientSuggestions = []; // Store patient name suggestions

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _patientSuggestions = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/reception/suggestions?name=$query'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _patientSuggestions =
              data.cast<String>(); // Assuming API returns a list of names
        });
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    } else {
      ToastMessage().showToast(
          context, 'No image selected', '', ToastificationType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Patient"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "IPD"),
            Tab(text: "OPD"),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIPDForm(),
          _buildOPDForm(),
        ],
      ),
    );
  }

  Widget _buildIPDForm() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset("assets/images/saideep.ico", height: 100),
                ),
                Text(
                  "IPD Patient Registration",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5.0),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(
                        label: "Full Name",
                        controller: _nameController,
                        hintText: 'Enter full name',
                      ),
                      const SizedBox(height: 24.0),
                      // Search by name to get Patient ID
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          _fetchSuggestions(textEditingValue.text);
                          return _patientSuggestions.where((option) {
                            return option
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selectedPatient) async {
                          _searchController.text = selectedPatient;
                          await _fetchPatientId(); // Fetch patient ID for selected name
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Search Patient by Name",
                              hintText: "Enter patient name",
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color:
                              Colors.grey[200], // Background color for the box
                          border: Border.all(
                              color: Colors.grey), // Border color and style
                          borderRadius:
                              BorderRadius.circular(8.0), // Rounded corners
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SelectableText(
                              _patientIdResult != null
                                  ? "Patient ID: $_patientIdResult"
                                  : "No patient found.",
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: () {
                                if (_patientIdResult != null) {
                                  Clipboard.setData(ClipboardData(
                                      text: _patientIdResult ?? ''));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Patient ID copied to clipboard!")),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      const SizedBox(height: 24.0),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: "Age",
                              controller: _ageController,
                              hintText: 'Enter age',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Weight",
                              controller: _weightController,
                              hintText: 'Enter weight',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: "Phone",
                              controller: _contactController,
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Address",
                              controller: _addressController,
                              hintText: 'Enter address',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Reason for Admission",
                        controller: _reasonForAdmissionController,
                        hintText: 'Enter reason for admission',
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Symptoms",
                        controller: _symptomsController,
                        hintText: 'Enter symptoms',
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Initial Diagnosis",
                        controller: _initialDiagnosisController,
                        hintText: 'Enter initial diagnosis',
                      ),
                      const SizedBox(height: 24.0),
                      _genderSelection(),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Patient ID",
                              controller: _patientIdController,
                              hintText: 'Enter patient ID',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _readmissionSelection(),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                if (_selectedImage != null)
                  Column(
                    children: [
                      Text(
                        "Selected Image:",
                        style: GoogleFonts.poppins(fontSize: 16.sp),
                      ),
                      SizedBox(height: 12.h),
                      Image.file(
                        _selectedImage!,
                        height: 150.h,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _selectedImage!.path,
                        style: GoogleFonts.poppins(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedImage = null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Remove Image"),
                      ),
                    ],
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF00BF6D),
                    foregroundColor: Colors.white,
                    minimumSize: Size(33, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Pick Image"),
                ),
                SizedBox(height: 36),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _addPatient(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF00BF6D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 50),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Submit"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOPDForm() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset("assets/images/saideep.ico", height: 100),
                ),
                Text(
                  "OPD Patient Registration",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5.0),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(
                        label: "Full Name",
                        controller: _nameController,
                        hintText: 'Enter full name',
                      ),
                      const SizedBox(height: 24.0),
                      // Search by name to get Patient ID
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          _fetchSuggestions(textEditingValue.text);
                          return _patientSuggestions.where((option) {
                            return option
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selectedPatient) async {
                          _searchController.text = selectedPatient;
                          await _fetchPatientId(); // Fetch patient ID for selected name
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Search Patient by Name",
                              hintText: "Enter patient name",
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Container(
                        padding: const EdgeInsets.all(7.0),
                        margin: const EdgeInsets.symmetric(vertical: 3.0),
                        decoration: BoxDecoration(
                          color:
                              Colors.grey[200], // Background color for the box
                          border: Border.all(
                              color: Colors.grey), // Border color and style
                          borderRadius:
                              BorderRadius.circular(8.0), // Rounded corners
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SelectableText(
                              _patientIdResult != null
                                  ? "Patient ID: $_patientIdResult"
                                  : "No patient found.",
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: () {
                                if (_patientIdResult != null) {
                                  Clipboard.setData(ClipboardData(
                                      text: _patientIdResult ?? ''));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Patient ID copied to clipboard!")),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24.0),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: "Age",
                              controller: _ageController,
                              hintText: 'Enter age',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Weight",
                              controller: _weightController,
                              hintText: 'Enter weight',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: "Phone",
                              controller: _contactController,
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Address",
                              controller: _addressController,
                              hintText: 'Enter address',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Reason for Admission",
                        controller: _reasonForAdmissionController,
                        hintText: 'Enter reason for admission',
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Symptoms",
                        controller: _symptomsController,
                        hintText: 'Enter symptoms',
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Initial Diagnosis",
                        controller: _initialDiagnosisController,
                        hintText: 'Enter initial diagnosis',
                      ),
                      const SizedBox(height: 24.0),
                      _genderSelection(),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Patient ID",
                              controller: _patientIdController,
                              hintText: 'Enter patient ID',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _readmissionSelection(),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                if (_selectedImage != null)
                  Column(
                    children: [
                      Text(
                        "Selected Image:",
                        style: GoogleFonts.poppins(fontSize: 16.sp),
                      ),
                      SizedBox(height: 12.h),
                      Image.file(
                        _selectedImage!,
                        height: 150.h,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _selectedImage!.path,
                        style: GoogleFonts.poppins(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedImage = null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Remove Image"),
                      ),
                    ],
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF00BF6D),
                    foregroundColor: Colors.white,
                    minimumSize: Size(33, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Pick Image"),
                ),
                SizedBox(height: 36),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _addPatient(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF00BF6D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 50),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Submit"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 50,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: const Color(0xFFF5FCF9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            keyboardType: keyboardType,
          ),
        ),
      ],
    );
  }

  Widget _genderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            _buildRadioButton("Male"),
            _buildRadioButton("Female"),
            _buildRadioButton("Other"),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioButton(String value) {
    return Expanded(
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _selectedGender,
            onChanged: (newValue) {
              setState(() {
                _selectedGender = newValue!;
              });
            },
            activeColor: const Color(0xFF00BF6D),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _readmissionSelection() {
    return Row(
      children: [
        const Text("Readmission:"),
        Switch(
          value: _isReadmission,
          onChanged: (value) {
            setState(() {
              _isReadmission = value;
            });
          },
          activeColor: const Color(0xFF00BF6D),
        ),
      ],
    );
  }

  Future<void> _addPatient(BuildContext context) async {
    try {
      final uri = Uri.parse('${VERCEL_URL}/reception/addPatient');
      final request = http.MultipartRequest('POST', uri);

      // Adding text fields
      request.fields['name'] = _nameController.text;
      request.fields['age'] = _ageController.text;
      request.fields['gender'] = _selectedGender;
      request.fields['contact'] = _contactController.text;
      request.fields['address'] = _addressController.text;
      request.fields['weight'] = _weightController.text;
      request.fields['reasonForAdmission'] = _reasonForAdmissionController.text;
      request.fields['symptoms'] = _symptomsController.text;
      request.fields['initialDiagnosis'] = _initialDiagnosisController.text;
      request.fields['caste'] = _casteController.text;
      request.fields['isReadmission'] = _isReadmission.toString();

      // Handle Patient ID only if Readmission is toggled
      if (_isReadmission) {
        if (_patientIdController.text.isEmpty) {
          ToastMessage().showToast(
              context,
              'Patient ID is required for readmission',
              '',
              ToastificationType.error);
          return;
        }
        request.fields['patientId'] = _patientIdController.text;
      }

      // Adding an image file if present
      if (_selectedImage != null) {
        final imageFile = await http.MultipartFile.fromPath(
          'image', // The field name expected by the server
          _selectedImage!.path,
        );
        request.files.add(imageFile);
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(await response.stream.bytesToString());
        final patientId = responseBody['patientDetails']['patientId'];
        final admissionId =
            responseBody['patientDetails']['admissionRecords'][0]['_id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AssignScreen(patientId: patientId, admissionId: admissionId),
          ),
        );
        ToastMessage().showToast(context, 'Patient Registered Successfully', '',
            ToastificationType.success);
      } else {
        final responseBody = jsonDecode(await response.stream.bytesToString());
        print("this should be the error: $responseBody");
        final errorMessage =
            responseBody['message'] ?? 'An unknown error occurred';
        ToastMessage()
            .showToast(context, errorMessage, '', ToastificationType.error);
      }
    } catch (e) {
      ToastMessage().showToast(context, 'Failed to register patient: $e', '',
          ToastificationType.error);
    }
  }
}
