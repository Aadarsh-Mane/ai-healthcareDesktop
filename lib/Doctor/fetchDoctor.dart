import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorListScreen extends StatefulWidget {
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
  final _headerStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: Color(0xFF2A4D7E),
    fontSize: 14,
  );

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchController.addListener(_filterDoctors);
  }

  Future<void> _fetchDoctors() async {
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
          _isLoading = false;
        });
      }
    } catch (e) {
      // _showErrorSnackBar('Failed to load doctors: $e');
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Image.asset('${AppImages.logo}', height: 32),
          SizedBox(width: 16.0),
          Text('Medical Team Directory',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _buildSearchField(),
              SizedBox(width: 24),
              _buildSpecialtyFilter(),
              Spacer(),
              _buildAddDoctorButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          hintText: 'Search doctors...',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        style: TextStyle(color: Colors.white),
        onChanged: (value) =>
            _filterDoctors(), // Maintain existing filter functionality
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSpecialty,
          isExpanded: true,
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
                    child: Text(specialty),
                  ))
              .toList(),
          onChanged: (value) => setState(() {
            _selectedSpecialty = value!;
            _filterDoctors();
          }),
        ),
      ),
    );
  }

  Widget _buildAddDoctorButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.person_add_alt_1, size: 18),
      label: Text('New Doctor'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1A8FE3),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      //  onPressed: () => _showAddDoctorDialog(),
      onPressed: () => {},
    );
  }

  Widget _buildDoctorTable() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints:
              BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: DataTable(
            headingRowColor:
                MaterialStateColor.resolveWith((states) => Color(0xFFF8FAFC)),
            dataRowHeight: 70, // Increased row height
            dividerThickness: 0.5,
            horizontalMargin: 24,
            columnSpacing: 48,
            columns: [
              DataColumn(label: Text('Doctor', style: _headerStyle)),
              DataColumn(label: Text('Specialty', style: _headerStyle)),
              DataColumn(label: Text('Experience', style: _headerStyle)),
              DataColumn(label: Text('Contact', style: _headerStyle)),
              DataColumn(label: Text('Actions', style: _headerStyle)),
            ],
            rows: _filteredDoctors
                .map((doctor) => _buildDoctorRow(doctor))
                .toList(),
          ),
        ),
      ),
    );
  }

// Update the DataRow with improved spacing
  DataRow _buildDoctorRow(Doctor doctor) {
    return DataRow(
      cells: [
        DataCell(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24, // Increased avatar size
                  backgroundImage:
                      NetworkImage(_getGoogleDriveDirectLink(doctor.imageUrl)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(doctor.doctorName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Color(0xFF2A4D7E),
                            fontSize: 22)),
                    SizedBox(height: 6), // Increased spacing
                    Text(doctor.email,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontFamily: 'Poppins')),
                  ],
                )
              ],
            ),
          ),
        ),
        DataCell(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(doctor.speciality),
          ),
        ),
        DataCell(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('${doctor.experience} years'),
          ),
        ),
        DataCell(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.blueGrey),
                SizedBox(width: 12), // Increased spacing
                Text(
                  doctor.phoneNumber,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildTableActionButton(
                  icon: Icons.phone,
                  color: Colors.green,
                  onPressed: () => _copyToClipboard(doctor.phoneNumber),
                ),
                SizedBox(width: 12), // Increased spacing
                _buildTableActionButton(
                  icon: Icons.email,
                  color: Colors.blue,
                  onPressed: () => Methods().openEmailInBrowser(doctor.email),
                ),
                SizedBox(width: 12), // Increased spacing
                _buildTableActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onPressed: () => _confirmDeleteDoctor(doctor.id),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteDoctor(String doctorId) async {
    try {
      final response = await http
          .delete(Uri.parse('${KVM_URL}/reception/deleteDoctor/$doctorId'));
      if (response.statusCode == 200) {
        setState(() {
          _doctors.removeWhere((doctor) => doctor.id == doctorId);
          _filterDoctors(); // Add this line to refresh the filtered list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete doctor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteDoctor(String doctorId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this doctor?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteDoctor(doctorId); // Proceed with deletion
                setState(() {
                  _doctors.removeWhere((doctor) => doctor.id == doctorId);
                });
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: _getActionTooltip(icon),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        hoverColor: color.withOpacity(0.1),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  String _getActionTooltip(IconData icon) {
    switch (icon) {
      case Icons.phone:
        return 'Copy phone number';
      case Icons.email:
        return 'Send email';
      case Icons.delete:
        return 'Delete doctor';
      default:
        return '';
    }
  }

  // Widget _buildAppBar() {
  //   return AppBar(
  //     title: Row(
  //       children: [
  //         Image.asset('assets/hospital_logo.png', height: 32),
  //         SizedBox(width: 16),
  //         Text('Medical Team Directory',
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.white,
  //             )),
  //       ],
  //     ),
  //     flexibleSpace: Container(
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [Color(0xFF0A4DA2), Color(0xFF1A8FE3)],
  //         ),
  //       ),
  //     ),
  //     bottom: PreferredSize(
  //       preferredSize: Size.fromHeight(60),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  //         child: Row(
  //           children: [
  //             _buildSearchField(),
  //             SizedBox(width: 24),
  //             _buildSpecialtyFilter(),
  //             Spacer(),
  //             _buildAddDoctorButton(),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredDoctors.isEmpty
              ? Center(child: Text('No doctors found'))
              : _buildDoctorTable(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1A8FE3),
        child: Icon(Icons.refresh),
        onPressed: _fetchDoctors,
      ),
    );
  }

  // ... (Keep existing methods like _confirmDeleteDoctor, _copyToClipboard, etc) ...

  String _getGoogleDriveDirectLink(String imageUrl) {
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
        // backgroundColor: gradientColors[0],
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
      id: json['_id'],
      email: json['email'],
      doctorName: json['doctorName'],
      usertype: json['usertype'],
      imageUrl: json['imageUrl'] ?? '',
      speciality: json['speciality'] ?? 'Unknown',
      experience: json['experience'] ?? '0',
      phoneNumber: json['phoneNumber'] ?? 'N/A',
    );
  }
}
