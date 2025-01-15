import 'dart:convert';

// PatientHistory model
class PatientHistory {
  String? id;
  String? patientId;
  String? name;
  String? gender;
  String? contact;
  String? admissionId;
  DateTime? admissionDate;
  DateTime? dischargeDate;
  String? reasonForAdmission;
  String? symptoms;
  String? initialDiagnosis;
  Doctor? doctor;
  List<dynamic> reports;
  List<FollowUp>? followUps;
  List<LabReport>? labReports;

  PatientHistory({
    this.id,
    this.patientId,
    this.name,
    this.gender,
    this.contact,
    this.admissionId,
    this.admissionDate,
    this.dischargeDate,
    this.reasonForAdmission,
    this.symptoms,
    this.initialDiagnosis,
    this.doctor,
    this.reports = const [],
    this.followUps,
    this.labReports,
  });

  // Factory method to create a PatientHistory object from JSON
  factory PatientHistory.fromJson(Map<String, dynamic> json) {
    return PatientHistory(
      id: json['_id'],
      patientId: json['patientId'],
      name: json['name'],
      gender: json['gender'],
      contact: json['contact'],
      admissionId: json['admissionId'],
      admissionDate: json['admissionDate'] != null
          ? DateTime.parse(json['admissionDate'])
          : null,
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.parse(json['dischargeDate'])
          : null,
      reasonForAdmission: json['reasonForAdmission'],
      symptoms: json['symptoms'],
      initialDiagnosis: json['initialDiagnosis'],
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      reports: json['reports'] ?? [],
      followUps: json['followUps'] != null
          ? (json['followUps'] as List)
              .map((e) => FollowUp.fromJson(e))
              .toList()
          : null,
      labReports: json['labReports'] != null
          ? (json['labReports'] as List)
              .map((e) => LabReport.fromJson(e))
              .toList()
          : null,
    );
  }
}

// Doctor model
class Doctor {
  String? id;
  String? name;

  Doctor({this.id, this.name});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
    );
  }
}

// FollowUp model
class FollowUp {
  String? nurseId;
  String? date;
  String? notes;
  String? observations;
  String? id;

  FollowUp({
    this.nurseId,
    this.date,
    this.notes,
    this.observations,
    this.id,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      nurseId: json['nurseId'],
      date: json['date'],
      notes: json['notes'],
      observations: json['observations'],
      id: json['_id'],
    );
  }
}

// LabReport model
class LabReport {
  String? labTestNameGivenByDoctor;
  List<Report>? reports;

  LabReport({
    this.labTestNameGivenByDoctor,
    this.reports,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      labTestNameGivenByDoctor: json['labTestNameGivenByDoctor'],
      reports: json['reports'] != null
          ? (json['reports'] as List).map((e) => Report.fromJson(e)).toList()
          : null,
    );
  }
}

// Report model (inside labReports)
class Report {
  String? labTestName;
  String? reportUrl;
  String? labType;
  DateTime? uploadedAt;
  String? id;

  Report({
    this.labTestName,
    this.reportUrl,
    this.labType,
    this.uploadedAt,
    this.id,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      labTestName: json['labTestName'],
      reportUrl: json['reportUrl'],
      labType: json['labType'],
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : null,
      id: json['_id'],
    );
  }
}

// Main response model
class DischargedPatientsResponse {
  String? message;
  List<PatientHistory>? patientsHistory;

  DischargedPatientsResponse({this.message, this.patientsHistory});

  factory DischargedPatientsResponse.fromJson(Map<String, dynamic> json) {
    return DischargedPatientsResponse(
      message: json['message'],
      patientsHistory: json['patientsHistory'] != null
          ? (json['patientsHistory'] as List)
              .map((e) => PatientHistory.fromJson(e))
              .toList()
          : null,
    );
  }
}
