import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';

class IpdDetailScreen extends StatefulWidget {
  const IpdDetailScreen({Key? key}) : super(key: key);

  @override
  _IpdDetailScreenState createState() => _IpdDetailScreenState();
}

class _IpdDetailScreenState extends State<IpdDetailScreen> {
  List<Patient> admittedPatients = [];
  bool isLoading = true;
  bool isProcessing = false;
  Patient? selectedPatient;
  String searchQuery = '';
  List<Section> availableSections = [];
  bool isLoadingSections = false;

  // Selected section and bed for assignment
  String? selectedSectionId;
  int? selectedBedNumber;
  List<int> availableBedNumbers = [];

  // Form controllers
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAdmittedPatients();
    fetchAvailableSections();
  }

  @override
  void dispose() {
    reasonController.dispose();
    symptomsController.dispose();
    diagnosisController.dispose();
    super.dispose();
  }

  Future<void> fetchAdmittedPatients() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/getAdmittedPatients'));
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          admittedPatients = (data['data'] as List)
              .map((json) => Patient.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        showErrorSnackBar('Failed to load admitted patients');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      showErrorSnackBar('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAvailableSections() async {
    setState(() {
      isLoadingSections = true;
    });

    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/admin/getAllSections'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableSections = (data['data'] as List)
              .map((json) => Section.fromJson(json))
              .toList();
          isLoadingSections = false;
        });
      } else {
        showErrorSnackBar('Failed to load sections');
        setState(() {
          isLoadingSections = false;
        });
      }
    } catch (e) {
      showErrorSnackBar('Error: $e');
      setState(() {
        isLoadingSections = false;
      });
    }
  }

  Future<void> fetchAvailableBeds(String sectionId) async {
    setState(() {
      isProcessing = true;
      availableBedNumbers = [];
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/availableBeds/$sectionId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableBedNumbers =
              List<int>.from(data['data']['availableBedNumbers']);
          isProcessing = false;
        });
      } else {
        showErrorSnackBar('Failed to load available beds');
        setState(() {
          isProcessing = false;
        });
      }
    } catch (e) {
      showErrorSnackBar('Error: $e');
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> updateIpdDetails() async {
    if (selectedPatient == null || selectedPatient!.admissionRecords.isEmpty) {
      showErrorSnackBar('No patient or admission record selected');
      return;
    }

    final admissionId = selectedPatient!.admissionRecords.first.id;

    // Validate input
    if (reasonController.text.isEmpty ||
        symptomsController.text.isEmpty ||
        diagnosisController.text.isEmpty) {
      showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/addIpdDetails'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': selectedPatient!.patientId,
          'admissionId': admissionId,
          'reasonForAdmission': reasonController.text,
          'symptoms': symptomsController.text,
          'initialDiagnosis': diagnosisController.text,
          'ipdDetailsUpdated': true, // Mark as updated
        }),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar('IPD details updated successfully');

        // If a bed is also selected, assign it
        if (selectedSectionId != null && selectedBedNumber != null) {
          await assignBedToPatient();
        } else {
          // Just refresh the patients list if no bed assignment
          await fetchAdmittedPatients();
        }

        // Reset form
        clearForm();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update IPD details');
      }
    } catch (e) {
      showErrorSnackBar('Error updating IPD details: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> assignBedToPatient() async {
    if (selectedPatient == null ||
        selectedSectionId == null ||
        selectedBedNumber == null) {
      showErrorSnackBar('Please select a section and bed');
      return;
    }

    final admissionId = selectedPatient!.admissionRecords.isNotEmpty
        ? selectedPatient!.admissionRecords.first.id
        : null;

    if (admissionId == null) {
      showErrorSnackBar('No admission record found');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/assignBedToPatient'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': selectedPatient!.patientId,
          'sectionId': selectedSectionId,
          'bedNumber': selectedBedNumber,
          'admissionRecordId': admissionId,
        }),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar('Bed assigned successfully');
        await fetchAdmittedPatients(); // Refresh the list
        clearBedSelection();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to assign bed');
      }
    } catch (e) {
      showErrorSnackBar('Error assigning bed: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void selectPatient(Patient patient) {
    setState(() {
      selectedPatient = patient;

      // Pre-populate form fields if data exists
      final admissionRecord = patient.admissionRecords.isNotEmpty
          ? patient.admissionRecords.first
          : null;

      if (admissionRecord != null) {
        reasonController.text = admissionRecord.reasonForAdmission ?? '';
        symptomsController.text = admissionRecord.symptoms ?? '';
        diagnosisController.text = admissionRecord.initialDiagnosis ?? '';

        // If patient already has a bed assigned, show it as selected
        if (admissionRecord.section != null &&
            admissionRecord.bedNumber != null) {
          selectedSectionId = admissionRecord.section!.id;
          selectedBedNumber = admissionRecord.bedNumber;

          // Reset available beds since one is already assigned
          availableBedNumbers = [];
        } else {
          // Clear bed selection for new patients
          clearBedSelection();
        }
      } else {
        clearForm();
      }
    });
  }

  void clearForm() {
    setState(() {
      reasonController.clear();
      symptomsController.clear();
      diagnosisController.clear();
      clearBedSelection();
      selectedPatient = null;
    });
  }

  void clearBedSelection() {
    setState(() {
      selectedSectionId = null;
      selectedBedNumber = null;
      availableBedNumbers = [];
    });
  }

  List<Patient> get filteredPatients {
    if (searchQuery.isEmpty) {
      return admittedPatients;
    }

    final query = searchQuery.toLowerCase();
    return admittedPatients.where((patient) {
      return patient.name.toLowerCase().contains(query) ||
          patient.patientId.toLowerCase().contains(query);
    }).toList();
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
        title: Text('IPD Patient Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              fetchAdmittedPatients();
              fetchAvailableSections();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Patient list panel
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _buildPatientsList(),
                ),
              ],
            ),
          ),

          // IPD details form panel
          Expanded(
            child: selectedPatient != null
                ? _buildPatientDetailsForm()
                : _buildNoPatientSelectedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admitted Patients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or ID',
              prefixIcon: Icon(Icons.search, color: HospitalTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Showing ${filteredPatients.length} patients',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (admittedPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: HospitalTheme.textMedium),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Text(
              'No patients match your search',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        final isSelected = selectedPatient?.patientId == patient.patientId;
        return _buildPatientCard(patient, isSelected);
      },
    );
  }

  Widget _buildPatientCard(Patient patient, bool isSelected) {
    final hasAdmission = patient.admissionRecords.isNotEmpty;
    final hasBed =
        hasAdmission && patient.admissionRecords.first.bedNumber != null;
    final ipdUpdated =
        hasAdmission && patient.admissionRecords.first.ipdDetailsUpdated;

    final bedInfo = hasBed
        ? 'Bed: ${patient.admissionRecords.first.bedNumber}'
        : 'No bed assigned';

    final sectionInfo =
        hasAdmission && patient.admissionRecords.first.section != null
            ? '${patient.admissionRecords.first.section!.name}'
            : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => selectPatient(patient),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: hasBed
                        ? HospitalTheme.success.withOpacity(0.2)
                        : HospitalTheme.warning.withOpacity(0.2),
                    radius: 18,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'ID: ${patient.patientId}',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Status badges in a separate row to prevent overflow
              SizedBox(height: 8),
              Row(
                children: [
                  // Bed status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasBed
                          ? HospitalTheme.success.withOpacity(0.1)
                          : HospitalTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
                          size: 14,
                          color: hasBed
                              ? HospitalTheme.success
                              : HospitalTheme.warning,
                        ),
                        SizedBox(width: 4),
                        Text(
                          bedInfo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: hasBed
                                ? HospitalTheme.success
                                : HospitalTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // IPD status indicator
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ipdUpdated
                          ? HospitalTheme.info.withOpacity(0.1)
                          : HospitalTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ipdUpdated
                            ? HospitalTheme.info
                            : HospitalTheme.error,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ipdUpdated ? Icons.check_circle : Icons.warning,
                          size: 14,
                          color: ipdUpdated
                              ? HospitalTheme.info
                              : HospitalTheme.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          ipdUpdated ? 'IPD Updated' : 'Needs Update',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ipdUpdated
                                ? HospitalTheme.info
                                : HospitalTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Optional section info
              if (sectionInfo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 14,
                        color: HospitalTheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        sectionInfo,
                        style: TextStyle(
                          fontSize: 12,
                          color: HospitalTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: HospitalTheme.textMedium,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${patient.gender}, ${patient.age} yrs',
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
      ),
    );
  }

  Widget _buildNoPatientSelectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.personal_injury,
            size: 80,
            color: HospitalTheme.primary.withOpacity(0.3),
          ),
          SizedBox(height: 24),
          Text(
            'Select a patient from the list',
            style: TextStyle(
              fontSize: 20,
              color: HospitalTheme.textMedium,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'to update IPD details and assign bed',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsForm() {
    final admissionId = selectedPatient!.admissionRecords.isNotEmpty
        ? selectedPatient!.admissionRecords.first.id
        : '';

    final hasAdmission = selectedPatient!.admissionRecords.isNotEmpty;
    final hasBed = hasAdmission &&
        selectedPatient!.admissionRecords.first.bedNumber != null;
    final ipdDetailsUpdated = hasAdmission &&
        selectedPatient!.admissionRecords.first.ipdDetailsUpdated;

    final currentSection =
        hasAdmission && selectedPatient!.admissionRecords.first.section != null
            ? selectedPatient!.admissionRecords.first.section
            : null;

    final currentBed =
        hasAdmission ? selectedPatient!.admissionRecords.first.bedNumber : null;

    final admitNotes = hasAdmission
        ? selectedPatient!.admissionRecords.first.admitNotes ?? ''
        : '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient name
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HospitalTheme.primaryLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: HospitalTheme.primary,
                    child: Text(
                      selectedPatient!.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPatient!.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ID: ${selectedPatient!.patientId} • Gender: ${selectedPatient!.gender} • Age: ${selectedPatient!.age}',
                          style: TextStyle(
                            fontSize: 14,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // IPD Status Badge
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ipdDetailsUpdated
                              ? HospitalTheme.success.withOpacity(0.1)
                              : HospitalTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ipdDetailsUpdated
                                ? HospitalTheme.success
                                : HospitalTheme.warning,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ipdDetailsUpdated
                                  ? Icons.check_circle
                                  : Icons.pending_actions,
                              size: 16,
                              color: ipdDetailsUpdated
                                  ? HospitalTheme.success
                                  : HospitalTheme.warning,
                            ),
                            SizedBox(width: 6),
                            Text(
                              ipdDetailsUpdated
                                  ? 'IPD Details Complete'
                                  : 'IPD Details Pending',
                              style: TextStyle(
                                color: ipdDetailsUpdated
                                    ? HospitalTheme.success
                                    : HospitalTheme.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),

                      // Admit Note Badge
                      if (admitNotes.isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: HospitalTheme.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: HospitalTheme.info),
                          ),
                          child: Text(
                            'Admit Note: $admitNotes',
                            style: TextStyle(
                              color: HospitalTheme.info,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      SizedBox(height: 8),

                      // Bed Assignment Badge
                      if (currentSection != null && currentBed != null)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: HospitalTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: HospitalTheme.success),
                          ),
                          child: Text(
                            '${currentSection.name} - Bed $currentBed',
                            style: TextStyle(
                              color: HospitalTheme.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // IPD Details Form
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IPD Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                SizedBox(height: 16),

                // Reason for Admission
                _buildFormField(
                  label: 'Reason for Admission',
                  hint: 'Enter reason for admission',
                  controller: reasonController,
                  icon: Icons.medical_services,
                ),
                SizedBox(height: 16),

                // Symptoms
                _buildFormField(
                  label: 'Symptoms',
                  hint: 'Enter patient symptoms',
                  controller: symptomsController,
                  icon: Icons.sick,
                  maxLines: 3,
                ),
                SizedBox(height: 16),

                // Initial Diagnosis
                _buildFormField(
                  label: 'Initial Diagnosis',
                  hint: 'Enter initial diagnosis',
                  controller: diagnosisController,
                  icon: Icons.medical_information,
                  maxLines: 3,
                ),
              ],
            ),

            SizedBox(height: 24),

            // Bed Assignment Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bed Assignment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    if (hasBed)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: HospitalTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: HospitalTheme.success),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: HospitalTheme.success,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Bed Already Assigned',
                              style: TextStyle(
                                color: HospitalTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),

                isLoadingSections
                    ? Center(child: CircularProgressIndicator())
                    : availableSections.isEmpty
                        ? Center(
                            child: Text(
                              'No available sections found',
                              style: TextStyle(color: HospitalTheme.textMedium),
                            ),
                          )
                        : Column(
                            children: [
                              // Section Dropdown
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Section',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.business),
                                ),
                                value: selectedSectionId,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedSectionId = value;
                                      selectedBedNumber = null;
                                    });
                                    fetchAvailableBeds(value);
                                  }
                                },
                                items: availableSections.map((section) {
                                  return DropdownMenuItem<String>(
                                    value: section.id,
                                    child: Text(
                                        '${section.name} (${section.type}) - ${section.availableBeds} beds available'),
                                  );
                                }).toList(),
                              ),

                              SizedBox(height: 16),

                              // Bed Selection
                              if (selectedSectionId != null)
                                isProcessing
                                    ? Center(child: CircularProgressIndicator())
                                    : availableBedNumbers.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                'No available beds in this section',
                                                style: TextStyle(
                                                    color: HospitalTheme
                                                        .textMedium),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: HospitalTheme.border),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Available Beds',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color:
                                                        HospitalTheme.textDark,
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 12,
                                                  children: availableBedNumbers
                                                      .map((bedNumber) {
                                                    final isSelected =
                                                        selectedBedNumber ==
                                                            bedNumber;
                                                    return InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          selectedBedNumber =
                                                              bedNumber;
                                                        });
                                                      },
                                                      child: Container(
                                                        width: 80,
                                                        padding:
                                                            EdgeInsets.all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? HospitalTheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      0.2)
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? HospitalTheme
                                                                    .primary
                                                                : HospitalTheme
                                                                    .border,
                                                            width: isSelected
                                                                ? 2
                                                                : 1,
                                                          ),
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.bed,
                                                              size: 20,
                                                              color: isSelected
                                                                  ? HospitalTheme
                                                                      .primary
                                                                  : HospitalTheme
                                                                      .textMedium,
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              'Bed $bedNumber',
                                                              style: TextStyle(
                                                                fontWeight: isSelected
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .normal,
                                                                color: isSelected
                                                                    ? HospitalTheme
                                                                        .primary
                                                                    : HospitalTheme
                                                                        .textDark,
                                                              ),
                                                            ),
                                                          ],
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

                SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isProcessing ? null : updateIpdDetails,
                      icon: isProcessing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.save),
                      label: Text(hasBed && selectedSectionId == null
                          ? 'Update IPD Details'
                          : 'Update & Assign Bed'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        backgroundColor: HospitalTheme.primary,
                      ),
                    ),
                    SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: isProcessing ? null : clearForm,
                      icon: Icon(Icons.clear),
                      label: Text('Clear Form'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        side: BorderSide(color: HospitalTheme.primary),
                      ),
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

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: HospitalTheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// Model Classes
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

class AdmissionRecord {
  final String id;
  final DateTime admissionDate;
  final String status;
  final String? admitNotes;
  final String? reasonForAdmission;
  final String? symptoms;
  final String? initialDiagnosis;
  final int? bedNumber;
  final SectionInfo? section;
  final bool ipdDetailsUpdated;

  AdmissionRecord({
    required this.id,
    required this.admissionDate,
    required this.status,
    this.admitNotes,
    this.reasonForAdmission,
    this.symptoms,
    this.initialDiagnosis,
    this.bedNumber,
    this.section,
    required this.ipdDetailsUpdated,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      id: json['_id'],
      admissionDate: DateTime.parse(json['admissionDate']),
      status: json['status'],
      admitNotes: json['admitNotes'],
      reasonForAdmission: json['reasonForAdmission'],
      symptoms: json['symptoms'],
      initialDiagnosis: json['initialDiagnosis'],
      bedNumber: json['bedNumber'],
      section: json['section'] != null
          ? SectionInfo.fromJson(json['section'])
          : null,
      ipdDetailsUpdated: json['ipdDetailsUpdated'] ?? false,
    );
  }
}

class Section {
  final String id;
  final String name;
  final String type;
  final int totalBeds;
  final int availableBeds;
  final bool isActive;

  Section({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBeds,
    required this.availableBeds,
    required this.isActive,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      totalBeds: json['totalBeds'],
      availableBeds: json['availableBeds'],
      isActive: json['isActive'],
    );
  }
}
