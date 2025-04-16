import 'dart:convert';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/ToastMessage.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doctordesktop/constants/Url.dart';
import 'package:toastification/toastification.dart';
import 'package:doctordesktop/reception/ReceptionDashBoard.dart';

class AssignScreen extends StatefulWidget {
  final String patientId;
  final String admissionId;

  const AssignScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _selectedDoctorId;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/listDoctors'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _doctors = (data['doctors'] as List).map((d) {
            return {
              'id': d['_id'],
              'name': d['doctorName'],
              'email': d['email'],
              'speciality': d['speciality'] ?? 'General',
              'imageUrl': d['imageUrl'],
              'patients': d['patients'] != null ? d['patients'].length : 0,
              'department': d['department'] ?? 'General Medicine',
              'experience':
                  d['experience'] ?? '${(5 + (d['_id'].hashCode % 15))} years',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Failed to load doctors. Server returned ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load doctors: $e';
      });
    }
  }

  Future<void> _assignDoctor(String doctorId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/assign-Doctor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': widget.patientId,
          'doctorId': doctorId,
          'admissionId': widget.admissionId,
          'isReadmission': false,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ToastMessage().showToast(
            context,
            'Patient successfully assigned to doctor',
            '',
            ToastificationType.success);

        // After successful assignment, navigate back to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceptionDashBoard(),
          ),
        );
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Unknown error occurred';
        ToastMessage().showToast(context, 'Failed to assign doctor: $errorMsg',
            '', ToastificationType.error);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ToastMessage().showToast(
          context, 'Error assigning doctor: $e', '', ToastificationType.error);
    }
  }

  // Prevent going back with Android back button
  Future<bool> _onWillPop() async {
    if (_selectedDoctorId != null) {
      // Allow back navigation if doctor is already selected
      return true;
    }

    // Show a dialog requesting doctor assignment
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Doctor Assignment Required'),
        content: Text(
            'Please assign a doctor to this patient before leaving this screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('OK'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: Text(
            'Assign Doctor to Patient',
            style: TextStyle(
              color: HospitalTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Help button
            IconButton(
              icon: Icon(Icons.help_outline, color: HospitalTheme.primary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Doctor Assignment'),
                    content: Text(
                        'Please assign a doctor to the patient to proceed. '
                        'This step is mandatory for patient registration. '
                        'Click on a doctor card to assign the patient to that doctor.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingView()
            : _hasError
                ? _buildErrorView()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: HospitalTheme.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Loading available doctors...',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: HospitalTheme.error,
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load doctors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchDoctors,
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Patient info panel
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: HospitalTheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient ID: ${widget.patientId}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Admission ID: ${widget.admissionId}',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Doctor assignment instructions
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Doctor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please select a doctor to assign to this patient. The patient will be added to the doctor\'s assigned patients list.',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                ),
              ),
              SizedBox(height: 16),
              _buildFilterChips(),
            ],
          ),
        ),

        // Doctors grid
        Expanded(
          child: _doctors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        color: HospitalTheme.textLight,
                        size: 60,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No doctors available',
                        style: TextStyle(
                          fontSize: 18,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 1200
                          ? 4
                          : MediaQuery.of(context).size.width > 800
                              ? 3
                              : 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = _doctors[index];
                      return _buildDoctorCard(doctor);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    // Extract unique specialities
    final specialities = _doctors
        .map((doctor) => doctor['speciality'] as String)
        .toSet()
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          HospitalTheme.buildSpecialtyChip(
            label: 'All Doctors',
            icon: Icons.people_outline,
            isSelected: true,
            onTap: () {},
          ),
          SizedBox(width: 8),
          ...specialities.map((speciality) => Padding(
                padding: EdgeInsets.only(right: 8),
                child: HospitalTheme.buildSpecialtyChip(
                  label: speciality,
                  icon: _getSpecialtyIcon(speciality),
                  isSelected: false,
                  onTap: () {},
                ),
              )),
        ],
      ),
    );
  }

  IconData _getSpecialtyIcon(String speciality) {
    switch (speciality.toLowerCase()) {
      case 'cardiology':
        return Icons.favorite;
      case 'neurology':
        return Icons.psychology;
      case 'pediatrics':
        return Icons.child_care;
      case 'orthopedics':
        return Icons.accessibility_new;
      case 'general':
        return Icons.medical_services;
      default:
        return Icons.local_hospital;
    }
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final isSelected = _selectedDoctorId == doctor['id'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? HospitalTheme.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _showAssignConfirmation(doctor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Doctor Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: HospitalTheme.surfaceLight,
                    backgroundImage: doctor['imageUrl'] != null
                        ? NetworkImage(
                            Methods()
                                .getGoogleDriveDirectLink(doctor['imageUrl']),
                          )
                        : null,
                    child: doctor['imageUrl'] == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: HospitalTheme.textMedium,
                          )
                        : null,
                  ),
                  if (isSelected)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: HospitalTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),

              // Doctor Name
              Text(
                doctor['name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: HospitalTheme.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Specialty
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  doctor['speciality'] ?? 'General',
                  style: TextStyle(
                    color: HospitalTheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),

              // Doctor Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoRow(
                      Icons.email_outlined,
                      doctor['email'] ?? 'No email provided',
                    ),
                    SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.work_outline,
                      doctor['experience'] ?? 'Experience not specified',
                    ),
                    SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.people_outline,
                      '${doctor['patients']} assigned patients',
                    ),
                  ],
                ),
              ),

              // Assign Button
              ElevatedButton.icon(
                onPressed: () => _showAssignConfirmation(doctor),
                icon: Icon(Icons.person_add),
                label: Text('Assign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? HospitalTheme.success
                      : HospitalTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: HospitalTheme.textMedium,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAssignConfirmation(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Confirm Doctor Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to assign this patient to:',
              style: TextStyle(color: HospitalTheme.textDark),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: HospitalTheme.surfaceLight,
                  backgroundImage: doctor['imageUrl'] != null
                      ? NetworkImage(
                          Methods()
                              .getGoogleDriveDirectLink(doctor['imageUrl']),
                        )
                      : null,
                  child: doctor['imageUrl'] == null
                      ? Icon(
                          Icons.person,
                          size: 25,
                          color: HospitalTheme.textMedium,
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      Text(
                        doctor['speciality'] ?? 'General',
                        style: TextStyle(
                          color: HospitalTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Patient ID: ${widget.patientId}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: HospitalTheme.textMedium,
              ),
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
              setState(() {
                _selectedDoctorId = doctor['id'];
              });
              _assignDoctor(doctor['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.success,
            ),
            child: Text('Confirm Assignment'),
          ),
        ],
      ),
    );
  }
}
