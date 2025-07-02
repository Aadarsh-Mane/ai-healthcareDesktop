// lib/models/DoctorProfile.dart
class DoctorProfile {
  final String id;
  final String doctorName;
  final String usertype;
  final String email;
  final String? specialization;
  final String? experience;
  final String? phone;
  final String? department;
  final String? imageUrl;

  DoctorProfile({
    required this.id,
    required this.doctorName,
    required this.usertype,
    required this.email,
    this.specialization,
    this.phone,
    this.experience,
    this.department,
    this.imageUrl,
  });

  // Factory constructor to create a DoctorProfile instance from JSON
  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['_id'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? 'Unknown Doctor',
      usertype: json['usertype'] as String? ?? 'doctor',
      email: json['email'] as String? ?? '',
      specialization: json['specialization'] as String?,
      phone: json['phone'] as String?,
      experience: json['experience'] as String? ?? '0 years',
      department: json['department'] as String? ?? 'General',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  // Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'doctorName': doctorName,
      'usertype': usertype,
      'email': email,
      'specialization': specialization,
      'phone': phone,
      'experience': experience,
      'department': department,
      'imageUrl': imageUrl,
    };
  }

  // Copy with method for updating specific fields
  DoctorProfile copyWith({
    String? id,
    String? doctorName,
    String? usertype,
    String? email,
    String? specialization,
    String? phone,
    String? experience,
    String? department,
    String? imageUrl,
  }) {
    return DoctorProfile(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      usertype: usertype ?? this.usertype,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
      phone: phone ?? this.phone,
      experience: experience ?? this.experience,
      department: department ?? this.department,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Override toString for debugging
}
