import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

class DoctorListScreen extends StatefulWidget {
  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    final response =
        await http.get(Uri.parse('${BASE_URL}/reception/listDoctors'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _doctors = (data['doctors'] as List)
            .map((doctorJson) => Doctor.fromJson(doctorJson))
            .toList();
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load doctors');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doctor List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF00BF6D),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BF6D), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of cards in a row
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    childAspectRatio: 3 / 2, // Adjust for card proportions
                  ),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return _buildDoctorCard(doctor);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.blueAccent.withOpacity(0.4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blueGrey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      _getGoogleDriveDirectLink(doctor.imageUrl),
                    ),
                    radius: 30,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      doctor.doctorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.blueGrey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Specialty: ${doctor.speciality}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Experience: ${doctor.experience} years',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Phone: ${doctor.phoneNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Email: ${doctor.email}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Call action
                    },
                    icon: Icon(Icons.call, color: Colors.white),
                    label: Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Email action
                    },
                    icon: Icon(Icons.email, color: Colors.white),
                    label: Text('Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
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

  String _getGoogleDriveDirectLink(String imageUrl) {
    final regex = RegExp(r'd/([a-zA-Z0-9_-]+)/');
    final match = regex.firstMatch(imageUrl);
    if (match != null && match.groupCount == 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return imageUrl;
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
