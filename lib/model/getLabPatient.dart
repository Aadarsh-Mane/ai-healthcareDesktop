class AssignedLab {
  final String id;
  final String admissionId;
  final Patient patient;
  final Doctor doctor;
  final List<LabReport> reports;
  final String labTestNameGivenByDoctor; // New field
  final String uploadedAt;
  final String reportUrl;

  AssignedLab({
    required this.id,
    required this.admissionId,
    required this.patient,
    required this.doctor,
    required this.reports,
    required this.labTestNameGivenByDoctor,
    required this.uploadedAt,
    required this.reportUrl,
  });

  factory AssignedLab.fromJson(Map<String, dynamic> json) {
    return AssignedLab(
      id: json['_id'] ?? '', // Default empty string if null
      admissionId: json['admissionId'] ?? '', // Default empty string if null
      patient: Patient.fromJson(json['patientId'] ?? {}),
      doctor: Doctor.fromJson(json['doctorId'] ?? {}),
      reports: (json['reports'] as List<dynamic>?)
              ?.map((report) => LabReport.fromJson(report))
              .toList() ??
          [], // Default to empty list if null
      labTestNameGivenByDoctor: json['labTestNameGivenByDoctor'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '', // Default empty string if null
      reportUrl: json['reportUrl'] ?? '', // Default empty string if null
    );
  }
}

class LabReport {
  final String labTestName;
  final String reportUrl;
  final String labType;
  final String uploadedAt;
  final String id;

  LabReport({
    required this.labTestName,
    required this.reportUrl,
    required this.labType,
    required this.uploadedAt,
    required this.id,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      labTestName: json['labTestName'] ?? '', // Default empty string if null
      reportUrl: json['reportUrl'] ?? '', // Default empty string if null
      labType: json['labType'] ?? '', // Default empty string if null
      uploadedAt: json['uploadedAt'] ?? '', // Default empty string if null
      id: json['_id'] ?? '', // Default empty string if null
    );
  }
}

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contact;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '', // Default empty string if null
      name: json['name'] ?? '', // Default empty string if null
      age: json['age'] ?? 0, // Default to 0 if null
      gender: json['gender'] ?? '', // Default empty string if null
      contact: json['contact'] ?? '', // Default empty string if null
    );
  }
}

class Doctor {
  final String id;
  final String email;
  final String doctorName;

  Doctor({
    required this.id,
    required this.email,
    required this.doctorName,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? '', // Default empty string if null
      email: json['email'] ?? '', // Default empty string if null
      doctorName: json['doctorName'] ?? '', // Default empty string if null
    );
  }
}
