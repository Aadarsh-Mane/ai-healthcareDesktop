// lib/models/DoctorProfile.dart
class DoctorProfile {
  final String id;
  final String doctorName;
  final String usertype;
  final String email;

  DoctorProfile({
    required this.id,
    required this.doctorName,
    required this.usertype,
    required this.email,
  });

  // Factory constructor to create a DoctorProfile instance from JSON
  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['_id'],
      doctorName: json['doctorName'],
      usertype: json['usertype'],
      email: json['email'],
    );
  }
}
