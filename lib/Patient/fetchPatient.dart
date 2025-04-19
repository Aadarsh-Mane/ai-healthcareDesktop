import 'package:doctordesktop/model/PatientModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedFilter;
  bool _showDischargedPatients = false;

  // Enhanced colors for consistent appearance with hospital theme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF8FBFD);
  final Color textPrimaryColor = const Color(0xFF2D3748);
  final Color textSecondaryColor = const Color(0xFF5A6B7F);
  final Color borderColor = const Color(0xFFDFEAF4);

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/listPatients'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _patients = (data['patients'] as List)
              .map((patientJson) => Patient.fromJson(patientJson))
              .toList();
          _filterPatients();
        });
      } else {
        _showErrorSnackBar('Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPatients = _patients.where((patient) {
        // Filter by search text
        final nameMatch = patient.name.toLowerCase().contains(query);
        final idMatch = patient.patientId.toLowerCase().contains(query);

        // Filter by discharged status
        final matchesDischargedFilter =
            _showDischargedPatients || !patient.discharged;

        // Filter by selected filter (e.g. gender)
        bool matchesSelectedFilter = true;
        if (_selectedFilter != null) {
          switch (_selectedFilter) {
            case 'Male':
            case 'Female':
              matchesSelectedFilter = patient.gender == _selectedFilter;
              break;
            case 'Child':
              matchesSelectedFilter = patient.age < 18;
              break;
            case 'Adult':
              matchesSelectedFilter = patient.age >= 18 && patient.age < 65;
              break;
            case 'Senior':
              matchesSelectedFilter = patient.age >= 65;
              break;
            // case 'Has Balance':
            //   matchesSelectedFilter = patient.pendingAmount > 0;
            //   break;
          }
        }

        return (nameMatch || idMatch) &&
            matchesDischargedFilter &&
            matchesSelectedFilter;
      }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Directory'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Back',
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 32,
                color: primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Patient Directory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildRefreshButton(),
              const SizedBox(width: 16),
              _buildAddPatientButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: _fetchPatients,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Refresh'),
      style: ElevatedButton.styleFrom(
        foregroundColor: primaryColor,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildAddPatientButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add_alt_1, size: 18),
      label: const Text('Add Patient'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {},
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSearchField(),
              ),
              const SizedBox(width: 16),
              _buildFilterDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by patient name or ID...',
          hintStyle: TextStyle(color: textSecondaryColor),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      height: 48,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          hint: Text('Filter by', style: TextStyle(color: textSecondaryColor)),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          items: [
            'Male',
            'Female',
            'Child',
            'Adult',
            'Senior',
            'Has Balance',
          ]
              .map((filter) => DropdownMenuItem(
                    value: filter,
                    child: Text(
                      filter,
                      style: TextStyle(color: textPrimaryColor),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedFilter = value;
              _filterPatients();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        FilterChip(
          label: const Text('Show Discharged Patients'),
          selected: _showDischargedPatients,
          selectedColor: accentColor.withOpacity(0.2),
          checkmarkColor: accentColor,
          onSelected: (selected) {
            setState(() {
              _showDischargedPatients = selected;
              _filterPatients();
            });
          },
        ),
        if (_selectedFilter != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Filter: $_selectedFilter'),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 16),
                ],
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = null;
                  _filterPatients();
                });
              },
              backgroundColor: primaryColor.withOpacity(0.1),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_filteredPatients.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPatientsList();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading patients...',
            style: TextStyle(color: textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No patients found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedFilter != null
                ? 'Try adjusting your search filters'
                : 'Add patients to get started',
            style: TextStyle(
              color: textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedFilter = null;
                _showDischargedPatients = false;
                _filterPatients();
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              foregroundColor: primaryColor,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return _buildPatientCard(patient);
        },
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: patient.discharged ? Colors.grey.shade300 : borderColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(patient),
            _buildPatientDetails(patient),
            _buildAdmissionRecords(patient),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(Patient patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: patient.discharged
            ? Colors.grey.shade100
            : primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: patient.discharged ? Colors.grey.shade300 : borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildPatientAvatar(patient),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: patient.discharged
                        ? Colors.grey.shade700
                        : textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${patient.patientId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: patient.discharged
                        ? Colors.grey.shade600
                        : textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(patient),
        ],
      ),
    );
  }

  Widget _buildPatientAvatar(Patient patient) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: patient.discharged
          ? Colors.grey.shade200
          : primaryColor.withOpacity(0.2),
      child: Icon(
        Icons.person,
        color: patient.discharged ? Colors.grey.shade600 : primaryColor,
        size: 32,
      ),
    );
  }

  Widget _buildStatusBadge(Patient patient) {
    if (patient.discharged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Discharged',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      );
    }

    if (patient.pendingAmount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withOpacity(0.5),
          ),
        ),
        child: Text(
          'Balance: ₹${patient.pendingAmount}',
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.5),
        ),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPatientDetails(Patient patient) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: patient.discharged ? Colors.grey.shade700 : primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.cake,
                  label: 'Age',
                  value: '${patient.age} years',
                  color:
                      patient.discharged ? Colors.grey.shade600 : Colors.purple,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person_outline,
                  label: 'Gender',
                  value: patient.gender,
                  color:
                      patient.discharged ? Colors.grey.shade600 : Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.phone,
                  label: 'Contact',
                  value: patient.contact,
                  color:
                      patient.discharged ? Colors.grey.shade600 : Colors.green,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.location_on,
                  label: 'Address',
                  value: patient.address,
                  color:
                      patient.discharged ? Colors.grey.shade600 : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdmissionRecords(Patient patient) {
    if (patient.admissionRecords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No admission records found',
          style: TextStyle(
            color: textSecondaryColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        colorScheme: ColorScheme.light(
          primary: patient.discharged ? Colors.grey.shade700 : primaryColor,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          'Admission Records (${patient.admissionRecords.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: patient.discharged ? Colors.grey.shade700 : primaryColor,
          ),
        ),
        leading: Icon(
          Icons.local_hospital_outlined,
          color: patient.discharged ? Colors.grey.shade600 : primaryColor,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: patient.admissionRecords.map((record) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: patient.discharged ? Colors.grey.shade300 : borderColor,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                colorScheme: ColorScheme.light(
                  primary:
                      patient.discharged ? Colors.grey.shade700 : accentColor,
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  'Admitted on ${record.admissionDate}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: patient.discharged
                        ? Colors.grey.shade700
                        : textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  'Doctor: ${record.doctor.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: patient.discharged
                        ? Colors.grey.shade600
                        : textSecondaryColor,
                  ),
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  _buildAdmissionDetails(record, patient.discharged),
                  const SizedBox(height: 16),
                  _buildFollowUps(record, patient.discharged),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdmissionDetails(AdmissionRecord record, bool isDischarged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admission Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDischarged ? Colors.grey.shade700 : primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          icon: Icons.local_hospital,
          detail: 'Doctor: ${record.doctor.name}',
          iconColor: isDischarged ? Colors.grey.shade600 : Colors.red,
        ),
        _buildDetailRow(
          icon: Icons.calendar_today,
          detail: 'Admission Date: ${record.admissionDate}',
          iconColor: isDischarged ? Colors.grey.shade600 : Colors.blue,
        ),
        _buildDetailRow(
          icon: Icons.sick,
          detail: 'Reason: ${record.reasonForAdmission}',
          iconColor: isDischarged ? Colors.grey.shade600 : Colors.purple,
        ),
        _buildDetailRow(
          icon: Icons.notes,
          detail: 'Symptoms: ${record.symptoms}',
          iconColor: isDischarged ? Colors.grey.shade600 : Colors.teal,
        ),
        // _buildDetailRow(
        //   icon: Icons.medical_services,
        //   detail: 'Initial Diagnosis: ${record.initialDiagnosis}',
        //   iconColor: isDischarged ? Colors.grey.shade600 : accentColor,
        // ),
      ],
    );
  }

  Widget _buildFollowUps(AdmissionRecord record, bool isDischarged) {
    if (record.followUps.isEmpty) {
      return Text(
        'No follow-ups recorded',
        style: TextStyle(
          color: textSecondaryColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow-ups',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDischarged ? Colors.grey.shade700 : primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...record.followUps.map((followUp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDischarged ? Colors.grey.shade300 : borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  icon: Icons.date_range,
                  detail: 'Date: ${followUp.date}',
                  iconColor:
                      isDischarged ? Colors.grey.shade600 : Colors.indigo,
                ),
                _buildDetailRow(
                  icon: Icons.notes,
                  detail: 'Notes: ${followUp.notes}',
                  iconColor:
                      isDischarged ? Colors.grey.shade600 : Colors.deepOrange,
                ),
                _buildDetailRow(
                  icon: Icons.visibility,
                  detail: 'Observations: ${followUp.observations}',
                  iconColor: isDischarged ? Colors.grey.shade600 : Colors.brown,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String detail,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
