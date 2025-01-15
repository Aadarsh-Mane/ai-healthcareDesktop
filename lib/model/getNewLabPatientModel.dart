// Model for a single report
class Report {
  final String? labTestName;
  final String? reportUrl;
  final String? labType;
  final DateTime? uploadedAt;
  final String? id;

  Report({
    this.labTestName,
    this.reportUrl,
    this.labType,
    this.uploadedAt,
    this.id,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      labTestName: json['labTestName'] as String?,
      reportUrl: json['reportUrl'] as String?,
      labType: json['labType'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'labTestName': labTestName,
        'reportUrl': reportUrl,
        'labType': labType,
        'uploadedAt': uploadedAt?.toIso8601String(),
        '_id': id,
      };
}

// Model for Patient
class Patient {
  final String? id;
  final String? name;
  final int? age;
  final String? gender;
  final String? contact;
  final bool? discharged;

  Patient({
    this.id,
    this.name,
    this.age,
    this.gender,
    this.contact,
    this.discharged,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      contact: json['contact'] as String?,
      discharged: json['discharged'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'contact': contact,
        'discharged': discharged,
      };
}

// Model for Doctor
class Doctor {
  final String? id;
  final String? email;
  final String? doctorName;

  Doctor({
    this.id,
    this.email,
    this.doctorName,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] as String?,
      email: json['email'] as String?,
      doctorName: json['doctorName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'doctorName': doctorName,
      };
}

// Model for LabReport
class LabReport1 {
  final String? id;
  final String? admissionId;
  final Patient? patient;
  final Doctor? doctor;
  final String? labTestNameGivenByDoctor;
  final List<Report>? reports;
  final int? version;

  LabReport1({
    this.id,
    this.admissionId,
    this.patient,
    this.doctor,
    this.labTestNameGivenByDoctor,
    this.reports,
    this.version,
  });

  factory LabReport1.fromJson(Map<String, dynamic> json) {
    return LabReport1(
      id: json['_id'] as String?,
      admissionId: json['admissionId'] as String?,
      patient: json['patientId'] != null
          ? Patient.fromJson(json['patientId'] as Map<String, dynamic>)
          : null,
      doctor: json['doctorId'] != null
          ? Doctor.fromJson(json['doctorId'] as Map<String, dynamic>)
          : null,
      labTestNameGivenByDoctor: json['labTestNameGivenByDoctor'] as String?,
      reports: (json['reports'] as List<dynamic>?)
          ?.map((e) => Report.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'admissionId': admissionId,
        'patientId': patient?.toJson(),
        'doctorId': doctor?.toJson(),
        'labTestNameGivenByDoctor': labTestNameGivenByDoctor,
        'reports': reports?.map((e) => e.toJson()).toList(),
        '__v': version,
      };
}

// Wrapper model for the response
class LabReportResponse {
  final String? message;
  final List<LabReport1>? labReports;

  LabReportResponse({
    this.message,
    this.labReports,
  });

  factory LabReportResponse.fromJson(Map<String, dynamic> json) {
    return LabReportResponse(
      message: json['message'] as String?,
      labReports: (json['labReports'] as List<dynamic>?)
          ?.map((e) => LabReport1.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'labReports': labReports?.map((e) => e.toJson()).toList(),
      };
}
