import 'dart:convert';

class PatientHistory {
  final String? message;
  final History? history;

  PatientHistory({this.message, this.history});

  factory PatientHistory.fromJson(Map<String, dynamic> json) {
    return PatientHistory(
      message: json['message'] as String?,
      history:
          json['history'] != null ? History.fromJson(json['history']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'history': history?.toJson(),
    };
  }
}

class History {
  final String? id;
  final String? patientId;
  final String? name;
  final String? gender;
  final String? contact;
  final List<AdmissionRecord>? history;

  History({
    this.id,
    this.patientId,
    this.name,
    this.gender,
    this.contact,
    this.history,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['_id'] as String?,
      patientId: json['patientId'] as String?,
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      contact: json['contact'] as String?,
      history: (json['history'] as List<dynamic>?)
          ?.map((item) => AdmissionRecord.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId,
      'name': name,
      'gender': gender,
      'contact': contact,
      'history': history?.map((item) => item.toJson()).toList(),
    };
  }
}

class AdmissionRecord {
  final Doctor? doctor;
  final String? admissionId;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? reasonForAdmission;
  final List<dynamic>? doctorConsultant;
  final int? amountToBePayed;
  final String? conditionAtDischarge;
  final int? previousRemainingAmount;
  final String? symptoms;
  final String? initialDiagnosis;
  final List<dynamic>? reports;
  final List<LabReport>? labReports;
  final int? weight;
  final List<DoctorPrescription>? doctorPrescriptions;
  final List<DoctorConsulting>? doctorConsulting;
  final List<dynamic>? symptomsByDoctor;
  final List<Vital>? vitals;
  final List<String>? diagnosisByDoctor;
  final String? id;

  AdmissionRecord({
    this.doctor,
    this.admissionId,
    this.admissionDate,
    this.dischargeDate,
    this.reasonForAdmission,
    this.doctorConsultant,
    this.amountToBePayed,
    this.conditionAtDischarge,
    this.previousRemainingAmount,
    this.symptoms,
    this.initialDiagnosis,
    this.reports,
    this.labReports,
    this.weight,
    this.doctorPrescriptions,
    this.doctorConsulting,
    this.symptomsByDoctor,
    this.vitals,
    this.diagnosisByDoctor,
    this.id,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      admissionId: json['admissionId'] as String?,
      admissionDate: json['admissionDate'] != null
          ? DateTime.parse(json['admissionDate'])
          : null,
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.parse(json['dischargeDate'])
          : null,
      reasonForAdmission: json['reasonForAdmission'] as String?,
      doctorConsultant: json['doctorConsultant'] as List<dynamic>?,
      amountToBePayed: json['amountToBePayed'] as int?,
      conditionAtDischarge: json['conditionAtDischarge'] as String?,
      previousRemainingAmount: json['previousRemainingAmount'] as int?,
      symptoms: json['symptoms'] as String?,
      initialDiagnosis: json['initialDiagnosis'] as String?,
      reports: json['reports'] as List<dynamic>?,
      labReports: (json['labReports'] as List<dynamic>?)
          ?.map((item) => LabReport.fromJson(item))
          .toList(),
      weight: json['weight'] as int?,
      doctorPrescriptions: (json['doctorPrescriptions'] as List<dynamic>?)
          ?.map((item) => DoctorPrescription.fromJson(item))
          .toList(),
      doctorConsulting: (json['doctorConsulting'] as List<dynamic>?)
          ?.map((item) => DoctorConsulting.fromJson(item))
          .toList(),
      symptomsByDoctor: json['symptomsByDoctor'] as List<dynamic>?,
      vitals: (json['vitals'] as List<dynamic>?)
          ?.map((item) => Vital.fromJson(item))
          .toList(),
      diagnosisByDoctor: (json['diagnosisByDoctor'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(),
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor': doctor?.toJson(),
      'admissionId': admissionId,
      'admissionDate': admissionDate?.toIso8601String(),
      'dischargeDate': dischargeDate?.toIso8601String(),
      'reasonForAdmission': reasonForAdmission,
      'doctorConsultant': doctorConsultant,
      'amountToBePayed': amountToBePayed,
      'conditionAtDischarge': conditionAtDischarge,
      'previousRemainingAmount': previousRemainingAmount,
      'symptoms': symptoms,
      'initialDiagnosis': initialDiagnosis,
      'reports': reports,
      'labReports': labReports?.map((item) => item.toJson()).toList(),
      'weight': weight,
      'doctorPrescriptions':
          doctorPrescriptions?.map((item) => item.toJson()).toList(),
      'doctorConsulting':
          doctorConsulting?.map((item) => item.toJson()).toList(),
      'symptomsByDoctor': symptomsByDoctor,
      'vitals': vitals?.map((item) => item.toJson()).toList(),
      'diagnosisByDoctor': diagnosisByDoctor,
      '_id': id,
    };
  }
}

class Doctor {
  final String? id;
  final String? name;

  Doctor({this.id, this.name});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class LabReport {
  final String? labTestNameGivenByDoctor;
  final List<LabTestReport>? reports;

  LabReport({this.labTestNameGivenByDoctor, this.reports});

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      labTestNameGivenByDoctor: json['labTestNameGivenByDoctor'] as String?,
      reports: (json['reports'] as List<dynamic>?)
          ?.map((item) => LabTestReport.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labTestNameGivenByDoctor': labTestNameGivenByDoctor,
      'reports': reports?.map((item) => item.toJson()).toList(),
    };
  }
}

class LabTestReport {
  final String? labTestName;
  final String? reportUrl;
  final String? labType;
  final DateTime? uploadedAt;
  final String? id;

  LabTestReport({
    this.labTestName,
    this.reportUrl,
    this.labType,
    this.uploadedAt,
    this.id,
  });

  factory LabTestReport.fromJson(Map<String, dynamic> json) {
    return LabTestReport(
      labTestName: json['labTestName'] as String?,
      reportUrl: json['reportUrl'] as String?,
      labType: json['labType'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : null,
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labTestName': labTestName,
      'reportUrl': reportUrl,
      'labType': labType,
      'uploadedAt': uploadedAt?.toIso8601String(),
      '_id': id,
    };
  }
}

class DoctorPrescription {
  final Medicine? medicine;
  final String? id;

  DoctorPrescription({this.medicine, this.id});

  factory DoctorPrescription.fromJson(Map<String, dynamic> json) {
    return DoctorPrescription(
      medicine:
          json['medicine'] != null ? Medicine.fromJson(json['medicine']) : null,
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicine?.toJson(),
      '_id': id,
    };
  }
}

class Medicine {
  final String? name;
  final String? morning;
  final String? afternoon;
  final String? night;
  final String? comment;
  final DateTime? date;

  Medicine({
    this.name,
    this.morning,
    this.afternoon,
    this.night,
    this.comment,
    this.date,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'] as String?,
      morning: json['morning'] as String?,
      afternoon: json['afternoon'] as String?,
      night: json['night'] as String?,
      comment: json['comment'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'morning': morning,
      'afternoon': afternoon,
      'night': night,
      'comment': comment,
      'date': date?.toIso8601String(),
    };
  }
}

class DoctorConsulting {
  final String? allergies;
  final String? cheifComplaint;
  final String? id;

  DoctorConsulting({this.allergies, this.cheifComplaint, this.id});

  factory DoctorConsulting.fromJson(Map<String, dynamic> json) {
    return DoctorConsulting(
      allergies: json['allergies'] as String?,
      cheifComplaint: json['cheifComplaint'] as String?,
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergies': allergies,
      'cheifComplaint': cheifComplaint,
      '_id': id,
    };
  }
}

class Vital {
  final double? temperature;
  final int? pulse;
  final String? other;
  final DateTime? recordedAt;
  final String? id;

  Vital({
    this.temperature,
    this.pulse,
    this.other,
    this.recordedAt,
    this.id,
  });

  factory Vital.fromJson(Map<String, dynamic> json) {
    return Vital(
      temperature: (json['temperature'] as num?)?.toDouble(),
      pulse: json['pulse'] as int?,
      other: json['other'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'])
          : null,
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'pulse': pulse,
      'other': other,
      'recordedAt': recordedAt?.toIso8601String(),
      '_id': id,
    };
  }
}
