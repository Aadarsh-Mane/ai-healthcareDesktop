import 'package:flutter/material.dart';
import '../constants/HospitalTheme.dart';

class AssignedPatientsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Function(Map<String, dynamic>)? onPatientTap;

  const AssignedPatientsWidget({
    Key? key,
    required this.patients,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onPatientTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            Expanded(
              child:
                  patients.isEmpty ? _buildEmptyState() : _buildPatientsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${patients.length} Patients',
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No patients found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return ListView.separated(
      itemCount: patients.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return _buildPatientItem(patient);
      },
    );
  }

  Widget _buildPatientItem(Map<String, dynamic> patient) {
    final String patientName = patient['name'] ?? 'Unknown';
    final String patientId = patient['patientId'] ?? 'N/A';
    final status = patient['status'] ?? 'Unknown';
    final String admissionDate = patient['admissionDate'] != null
        ? _formatDate(patient['admissionDate'])
        : 'Unknown';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Text(
          patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        patientName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            'Patient ID: $patientId',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 12, color: HospitalTheme.textMedium),
              SizedBox(width: 4),
              Text(
                'Admission: $admissionDate',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: _getStatusColor(status),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      onTap: onPatientTap != null ? () => onPatientTap!(patient) : null,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      case 'discharged':
        return HospitalTheme.info;
      case 'emergency':
        return HospitalTheme.emergency;
      default:
        return HospitalTheme.textMedium;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }
}
