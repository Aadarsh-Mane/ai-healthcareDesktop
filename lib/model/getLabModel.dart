import 'dart:convert';

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
      id: json['_id'] ?? '', // Provide default empty string if null
      name: json['name'] ?? '', // Provide default empty string if null
      age: json['age'] ?? 0, // Provide default value 0 if null
      gender: json['gender'] ?? '', // Provide default empty string if null
      contact: json['contact'] ?? '', // Provide default empty string if null
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
      id: json['_id'] ?? '', // Provide default empty string if null
      email: json['email'] ?? '', // Provide default empty string if null
      doctorName:
          json['doctorName'] ?? '', // Provide default empty string if null
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
      labTestName:
          json['labTestName'] ?? '', // Provide default empty string if null
      reportUrl:
          json['reportUrl'] ?? '', // Provide default empty string if null
      labType: json['labType'] ?? '', // Provide default empty string if null
      uploadedAt:
          json['uploadedAt'] ?? '', // Provide default empty string if null
      id: json['_id'] ?? '', // Provide default empty string if null
    );
  }
}

class LabPatient {
  final String id;
  final String admissionId;
  final Patient patient;
  final Doctor doctor;
  final String labTestNameGivenByDoctor;
  final List<LabReport> reports;

  LabPatient({
    required this.id,
    required this.admissionId,
    required this.patient,
    required this.doctor,
    required this.labTestNameGivenByDoctor,
    required this.reports,
  });

  factory LabPatient.fromJson(Map<String, dynamic> json) {
    var reportsJson =
        json['reports'] as List? ?? []; // Default to empty list if null
    List<LabReport> reportsList =
        reportsJson.map((i) => LabReport.fromJson(i)).toList();

    return LabPatient(
      id: json['_id'] ?? '', // Provide default empty string if null
      admissionId:
          json['admissionId'] ?? '', // Provide default empty string if null
      patient: Patient.fromJson(
          json['patientId'] ?? {}), // Provide default empty map if null
      doctor: Doctor.fromJson(
          json['doctorId'] ?? {}), // Provide default empty map if null
      labTestNameGivenByDoctor: json['labTestNameGivenByDoctor'] ??
          '', // Provide default empty string if null
      reports: reportsList,
    );
  }
}

class LabPatientsResponse {
  final String message;
  final List<LabPatient> labReports;

  LabPatientsResponse({
    required this.message,
    required this.labReports,
  });

  factory LabPatientsResponse.fromJson(Map<String, dynamic> json) {
    var labReportsJson =
        json['labReports'] as List? ?? []; // Default to empty list if null
    List<LabPatient> labReportsList =
        labReportsJson.map((i) => LabPatient.fromJson(i)).toList();

    return LabPatientsResponse(
      message: json['message'] ?? '', // Provide default empty string if null
      labReports: labReportsList,
    );
  }
}
