import 'package:doctordesktop/Admin/AdminDashboard.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({Key? key}) : super(key: key);

  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _selectedSpecialty = 'All';
  final _scrollController = ScrollController();

  // Enhanced colors for consistent appearance with hospital theme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF8FBFD);
  final Color textPrimaryColor = const Color(0xFF2D3748);
  final Color textSecondaryColor = const Color(0xFF5A6B7F);
  final Color borderColor = const Color(0xFFDFEAF4);

  // Text styles for consistency
  late final TextStyle _headerStyle;
  late final TextStyle _tableHeaderStyle;
  late final TextStyle _doctorNameStyle;
  late final TextStyle _doctorEmailStyle;

  @override
  void initState() {
    super.initState();
    _initStyles();
    _fetchDoctors();
    _searchController.addListener(_filterDoctors);
  }

  void _initStyles() {
    _headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
      fontSize: 24,
    );

    _tableHeaderStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: primaryColor,
      fontSize: 14,
    );

    _doctorNameStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontFamily: 'Poppins',
      color: textPrimaryColor,
      fontSize: 16,
    );

    _doctorEmailStyle = TextStyle(
      color: textSecondaryColor,
      fontSize: 12,
      fontFamily: 'Poppins',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/listDoctors'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _doctors = (data['doctors'] as List)
              .map((doctorJson) => Doctor.fromJson(doctorJson))
              .toList();
          _filterDoctors();
        });
      } else {
        _showErrorSnackBar('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        final matchesSearch = doctor.doctorName
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        final matchesSpecialty = _selectedSpecialty == 'All' ||
            doctor.speciality == _selectedSpecialty;
        return matchesSearch && matchesSpecialty;
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
                Icons.medical_services_outlined,
                size: 32,
                color: primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Medical Team Directory',
                style: _headerStyle,
              ),
            ],
          ),
          Row(
            children: [
              _buildRefreshButton(),
              const SizedBox(width: 16),
              _buildAddDoctorButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: _fetchDoctors,
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchField(),
          ),
          const SizedBox(width: 16),
          _buildSpecialtyFilter(),
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
          hintText: 'Search doctors by name...',
          hintStyle: TextStyle(color: textSecondaryColor),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
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
          value: _selectedSpecialty,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          items: [
            'All',
            'Cardiology',
            'Neurology',
            'Pediatrics',
            'Surgeon',
            'Orthopedics',
            'Dermatology',
            'Oncology',
            'Psychiatry',
            'Endocrinology'
          ]
              .map((specialty) => DropdownMenuItem(
                    value: specialty,
                    child: Text(
                      specialty,
                      style: TextStyle(color: textPrimaryColor),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedSpecialty = value;
                _filterDoctors();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddDoctorButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add_alt_1, size: 18),
      label: const Text('Add Doctor'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        // Navigate to Register Doctor screen using the global key
        MainLayout.globalKey.currentState
            ?.navigateTo(5); // 5 is the index for DoctorRegisterScreen
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDoctorTable();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading doctors...',
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
            'No doctors found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedSpecialty != 'All'
                ? 'Try adjusting your search filters'
                : 'Add doctors to get started',
            style: TextStyle(
              color: textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedSpecialty = 'All';
                _filterDoctors();
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

  Widget _buildDoctorTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Doctor Directory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  '${_filteredDoctors.length} doctors found',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith(
                (states) => const Color(0xFFF8FAFC)),
            dataRowMinHeight: 80,
            dataRowMaxHeight: 80,
            dividerThickness: 0.5,
            horizontalMargin: 24,
            columnSpacing: 48,
            showBottomBorder: true,
            columns: [
              DataColumn(label: Text('Doctor', style: _tableHeaderStyle)),
              DataColumn(label: Text('Specialty', style: _tableHeaderStyle)),
              DataColumn(label: Text('Experience', style: _tableHeaderStyle)),
              DataColumn(label: Text('Contact', style: _tableHeaderStyle)),
              DataColumn(label: Text('Actions', style: _tableHeaderStyle)),
            ],
            rows: _filteredDoctors
                .map((doctor) => _buildDoctorRow(doctor))
                .toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDoctorRow(Doctor doctor) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              _buildDoctorAvatar(doctor),
              const SizedBox(width: 12),
              _buildDoctorInfo(doctor),
            ],
          ),
        ),
        DataCell(
          _buildSpecialtyBadge(doctor.speciality),
        ),
        DataCell(
          Text(
            '${doctor.experience} years',
            style: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: textSecondaryColor),
              const SizedBox(width: 8),
              Text(
                doctor.phoneNumber,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            children: [
              _buildActionButton(
                icon: Icons.phone,
                color: const Color(0xFF43A047),
                onPressed: () => _copyToClipboard(doctor.phoneNumber),
                tooltip: 'Copy phone number',
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.email,
                color: const Color(0xFF1E88E5),
                onPressed: () => Methods().openEmailInBrowser(doctor.email),
                tooltip: 'Send email',
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete,
                color: const Color(0xFFE53935),
                onPressed: () => _confirmDeleteDoctor(doctor.id),
                tooltip: 'Delete doctor',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorAvatar(Doctor doctor) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: accentColor.withOpacity(0.1),
      backgroundImage: _getImageProvider(doctor.imageUrl),
      child: doctor.imageUrl.isEmpty
          ? Text(
              doctor.doctorName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            )
          : null,
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const AssetImage('assets/images/placeholder.png');
    }

    return NetworkImage(_getGoogleDriveDirectLink(imageUrl));
  }

  Widget _buildDoctorInfo(Doctor doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          doctor.doctorName,
          style: _doctorNameStyle,
        ),
        const SizedBox(height: 4),
        Text(
          doctor.email,
          style: _doctorEmailStyle,
        ),
      ],
    );
  }

  Widget _buildSpecialtyBadge(String specialty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getSpecialtyColor(specialty).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getSpecialtyColor(specialty).withOpacity(0.3),
        ),
      ),
      child: Text(
        specialty,
        style: TextStyle(
          color: _getSpecialtyColor(specialty),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getSpecialtyColor(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cardiology':
        return Colors.red.shade700;
      case 'neurology':
        return Colors.purple.shade700;
      case 'pediatrics':
        return Colors.blue.shade500;
      case 'surgeon':
        return Colors.green.shade700;
      case 'orthopedics':
        return Colors.amber.shade700;
      case 'dermatology':
        return Colors.pink.shade400;
      case 'oncology':
        return Colors.indigo.shade500;
      case 'psychiatry':
        return Colors.teal.shade600;
      case 'endocrinology':
        return Colors.deepOrange.shade600;
      default:
        return primaryColor;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _confirmDeleteDoctor(String doctorId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this doctor?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDoctor(doctorId);
              },
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDoctor(String doctorId) async {
    try {
      final response = await http
          .delete(Uri.parse('${KVM_URL}/reception/deleteDoctor/$doctorId'));
      if (response.statusCode == 200) {
        setState(() {
          _doctors.removeWhere((doctor) => doctor.id == doctorId);
          _filterDoctors();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Doctor deleted successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        _showErrorSnackBar('Failed to delete doctor: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  String _getGoogleDriveDirectLink(String imageUrl) {
    if (imageUrl.isEmpty) return '';

    final regex = RegExp(r'd/([a-zA-Z0-9_-]+)/');
    final match = regex.firstMatch(imageUrl);
    if (match != null && match.groupCount == 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return imageUrl;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class Doctor {
  final String id;
  final String email;
  final String doctorName;
  final String usertype;
  final String imageUrl;
  final String speciality;
  final String experience;
  final String phoneNumber;

  Doctor({
    required this.id,
    required this.email,
    required this.doctorName,
    required this.usertype,
    required this.imageUrl,
    required this.speciality,
    required this.experience,
    required this.phoneNumber,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      doctorName: json['doctorName'] ?? '',
      usertype: json['usertype'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      speciality: json['speciality'] ?? 'Unknown',
      experience: json['experience']?.toString() ?? '0',
      phoneNumber: json['phoneNumber'] ?? 'N/A',
    );
  }
}
