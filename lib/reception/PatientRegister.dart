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
  late TabController _tabController;

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
        const SnackBar(content: Text("Please enter a name to search.")),
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
        });
      } else {
        setState(() {
          _ipdPatientIdResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No patient found with that name.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }
  }

  Future<void> _fetchOPDPatientId() async {
    final name = _opdSearchController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name to search.")),
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
        });
      } else {
        setState(() {
          _opdPatientIdResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No patient found with that name.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred. Please try again.")),
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
      appBar: AppBar(
        title: const Text("Add New Patient"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "OPD"),
            Tab(text: "IPD"),
          ],
        ),
      ),
      backgroundColor: Colors.white,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset("assets/images/logo2.png", height: 100),
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
                  key: _ipdFormKey,
                  child: Column(
                    children: [
                      _buildField(
                        label: "Full Name",
                        controller: _ipdNameController,
                        hintText: 'Enter full name',
                      ),
                      const SizedBox(height: 24.0),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          _fetchIPDSuggestions(textEditingValue.text);
                          return _ipdPatientSuggestions.where((option) => option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selectedPatient) async {
                          _ipdSearchController.text = selectedPatient;
                          await _fetchIPDPatientId();
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            cursorColor: Colors.black,
                            controller: controller,
                            decoration: const InputDecoration(
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
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SelectableText(
                              _ipdPatientIdResult != null
                                  ? "Patient ID: $_ipdPatientIdResult"
                                  : "No patient found.",
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                if (_ipdPatientIdResult != null) {
                                  Clipboard.setData(ClipboardData(
                                      text: _ipdPatientIdResult ?? ''));
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
                              controller: _ipdAgeController,
                              hintText: 'Enter age',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Weight",
                              controller: _ipdWeightController,
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
                              controller: _ipdContactController,
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Address",
                              controller: _ipdAddressController,
                              hintText: 'Enter address',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Reason for Admission",
                        controller: _ipdReasonForAdmissionController,
                        hintText: 'Enter reason for admission',
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Symptoms",
                        controller: _ipdSymptomsController,
                        hintText: 'Enter symptoms',
                      ),
                      const SizedBox(height: 24.0),
                      _buildField(
                        label: "Initial Diagnosis",
                        controller: _ipdInitialDiagnosisController,
                        hintText: 'Enter initial diagnosis',
                      ),
                      const SizedBox(height: 24.0),
                      _genderSelection(
                        selectedGender: _ipdSelectedGender,
                        onChanged: (newValue) =>
                            setState(() => _ipdSelectedGender = newValue!),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Patient ID",
                              controller: _ipdPatientIdController,
                              hintText: 'Enter patient ID',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _readmissionSelection(
                        isReadmission: _ipdIsReadmission,
                        onChanged: (value) =>
                            setState(() => _ipdIsReadmission = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                if (_ipdSelectedImage != null)
                  Column(
                    children: [
                      Text(
                        "Selected Image:",
                        style: GoogleFonts.poppins(fontSize: 16.sp),
                      ),
                      SizedBox(height: 12.h),
                      Image.file(
                        _ipdSelectedImage!,
                        height: 150.h,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _ipdSelectedImage!.path,
                        style: GoogleFonts.poppins(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _ipdSelectedImage = null),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text("Remove Image"),
                      ),
                    ],
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => pickImage(true),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF00BF6D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(33, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Pick Image"),
                ),
                SizedBox(height: 36),
                // ElevatedButton(
                //   onPressed: () {
                //     if (_ipdFormKey.currentState!.validate()) {
                //       _showPreviewDialog(context, true); // Show IPD preview
                //     }
                //   },
                //   // ... rest of button styling
                //   child: const Text("Submit"),
                // ),
                ElevatedButton(
                  onPressed: () {
                    if (_ipdFormKey.currentState!.validate()) {
                      _addIPDPatient(context);
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

  void _showPreviewDialog(BuildContext context, bool isIPD) {
    final name = isIPD ? _ipdNameController.text : _opdNameController.text;
    final age = isIPD ? _ipdAgeController.text : _opdAgeController.text;
    final gender = isIPD ? _ipdSelectedGender : _opdSelectedGender;
    final contact =
        isIPD ? _ipdContactController.text : _opdContactController.text;
    final address =
        isIPD ? _ipdAddressController.text : _opdAddressController.text;
    final weight =
        isIPD ? _ipdWeightController.text : _opdWeightController.text;
    final image = isIPD ? _ipdSelectedImage : _opdSelectedImage;
    final readmission = isIPD ? _ipdIsReadmission : _opdIsReadmission;
    final patientId =
        isIPD ? _ipdPatientIdController.text : _opdPatientIdController.text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Patient Details Preview"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null) ...[
                Center(
                  child: Image.file(
                    image,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _buildPreviewRow("Name:", name),
              _buildPreviewRow("Age:", age),
              _buildPreviewRow("Gender:", gender),
              _buildPreviewRow("Contact:", contact),
              _buildPreviewRow("Address:", address),
              _buildPreviewRow("Weight:", weight),
              if (isIPD) ...[
                _buildPreviewRow("Reason for Admission:",
                    _ipdReasonForAdmissionController.text),
                _buildPreviewRow("Symptoms:", _ipdSymptomsController.text),
                _buildPreviewRow(
                    "Initial Diagnosis:", _ipdInitialDiagnosisController.text),
              ],
              _buildPreviewRow("Readmission:", readmission ? "Yes" : "No"),
              if (readmission) _buildPreviewRow("Patient ID:", patientId),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Edit"),
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
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "Not provided",
              softWrap: true,
            ),
          ),
        ],
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
                  child: Image.asset("assets/images/logo2.png", height: 100),
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
                  key: _opdFormKey,
                  child: Column(
                    children: [
                      _buildField(
                        label: "Full Name",
                        controller: _opdNameController,
                        hintText: 'Enter full name',
                      ),
                      const SizedBox(height: 24.0),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          _fetchOPDSuggestions(textEditingValue.text);
                          return _opdPatientSuggestions.where((option) => option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selectedPatient) async {
                          _opdSearchController.text = selectedPatient;
                          await _fetchOPDPatientId();
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
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
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SelectableText(
                              _opdPatientIdResult != null
                                  ? "Patient ID: $_opdPatientIdResult"
                                  : "No patient found.",
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                if (_opdPatientIdResult != null) {
                                  Clipboard.setData(ClipboardData(
                                      text: _opdPatientIdResult ?? ''));
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
                              controller: _opdAgeController,
                              hintText: 'Enter age',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Weight",
                              controller: _opdWeightController,
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
                              controller: _opdContactController,
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Address",
                              controller: _opdAddressController,
                              hintText: 'Enter address',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _genderSelection(
                        selectedGender: _opdSelectedGender,
                        onChanged: (newValue) =>
                            setState(() => _opdSelectedGender = newValue!),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: _buildField(
                              label: "Patient ID",
                              controller: _opdPatientIdController,
                              hintText: 'Enter patient ID',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      _readmissionSelection(
                        isReadmission: _opdIsReadmission,
                        onChanged: (value) =>
                            setState(() => _opdIsReadmission = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                if (_opdSelectedImage != null)
                  Column(
                    children: [
                      Text(
                        "Selected Image:",
                        style: GoogleFonts.poppins(fontSize: 16.sp),
                      ),
                      SizedBox(height: 12.h),
                      Image.file(
                        _opdSelectedImage!,
                        height: 150.h,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _opdSelectedImage!.path,
                        style: GoogleFonts.poppins(fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _opdSelectedImage = null),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text("Remove Image"),
                      ),
                    ],
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => pickImage(false),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF00BF6D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(33, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Pick Image"),
                ),
                SizedBox(height: 36),
                ElevatedButton(
                  onPressed: () {
                    if (_opdFormKey.currentState!.validate()) {
                      _addOPDPatient(context);
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
            cursorColor: Colors.black,
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

  Widget _genderSelection({
    required String selectedGender,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            _buildRadioButton("Male", selectedGender, onChanged),
            _buildRadioButton("Female", selectedGender, onChanged),
            _buildRadioButton("Other", selectedGender, onChanged),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioButton(
    String value,
    String groupValue,
    ValueChanged<String?> onChanged,
  ) {
    return Expanded(
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: const Color(0xFF00BF6D),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _readmissionSelection({
    required bool isReadmission,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        const Text("Readmission:"),
        Switch(
          value: isReadmission,
          onChanged: onChanged,
          activeColor: const Color(0xFF00BF6D),
        ),
      ],
    );
  }

  Future<void> _addIPDPatient(BuildContext context) async {
    try {
      final uri = Uri.parse('${KVM_URL}/reception/addPatient');
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
          ToastMessage().showToast(
              context,
              'Patient ID is required for readmission',
              '',
              ToastificationType.error);
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

  Future<void> _addOPDPatient(BuildContext context) async {
    try {
      final uri = Uri.parse('${KVM_URL}/reception/addPatient');
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
          ToastMessage().showToast(
              context,
              'Patient ID is required for readmission',
              '',
              ToastificationType.error);
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
