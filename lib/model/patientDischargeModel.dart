class PatientDischarge {
  final String name;
  final String gender;
  final String contact;
  final String patientId;
  final LastRecord lastRecord;

  PatientDischarge({
    required this.name,
    required this.gender,
    required this.contact,
    required this.patientId,
    required this.lastRecord,
  });

  factory PatientDischarge.fromJson(Map<String, dynamic> json) {
    return PatientDischarge(
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      patientId: json['patientId'] ?? '',
      lastRecord: LastRecord.fromJson(json['lastRecord']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'contact': contact,
      'patientId': patientId,
      'lastRecord': lastRecord.toJson(),
    };
  }
}

class LastRecord {
  final String admissionId;
  final String admissionDate;
  final String dischargeDate;
  final String reasonForAdmission;
  final int amountToBePayed;
  final bool dischargedByReception;
  final String conditionAtDischarge;
  final int previousRemainingAmount;
  final String symptoms;
  final String initialDiagnosis;
  final String? patientType; // Added new field
  final Doctor doctor;
  final int weight;

  LastRecord({
    required this.admissionId,
    required this.admissionDate,
    required this.dischargeDate,
    required this.reasonForAdmission,
    required this.amountToBePayed,
    required this.dischargedByReception,
    required this.conditionAtDischarge,
    required this.previousRemainingAmount,
    required this.symptoms,
    required this.initialDiagnosis,
    this.patientType, // Optional because it might be missing in older data
    required this.doctor,
    required this.weight,
  });

  factory LastRecord.fromJson(Map<String, dynamic> json) {
    return LastRecord(
      admissionId: json['admissionId'] ?? '',
      admissionDate: json['admissionDate'] ?? '',
      dischargeDate: json['dischargeDate'] ?? '',
      reasonForAdmission: json['reasonForAdmission'] ?? '',
      // Convert double to int
      amountToBePayed: (json['amountToBePayed'] as num?)?.toInt() ?? 0,
      dischargedByReception: json['dischargedByReception'] ?? false,
      conditionAtDischarge: json['conditionAtDischarge'] ?? '',
      // Convert double to int
      previousRemainingAmount:
          (json['previousRemainingAmount'] as num?)?.toInt() ?? 0,
      symptoms: json['symptoms'] ?? '',
      initialDiagnosis: json['initialDiagnosis'] ?? '',
      patientType: json['patientType'], // Added new field
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
      // Convert double to int (if needed)
      weight: (json['weight'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admissionId': admissionId,
      'admissionDate': admissionDate,
      'dischargeDate': dischargeDate,
      'reasonForAdmission': reasonForAdmission,
      'amountToBePayed': amountToBePayed,
      'dischargedByReception': dischargedByReception,
      'conditionAtDischarge': conditionAtDischarge,
      'previousRemainingAmount': previousRemainingAmount,
      'symptoms': symptoms,
      'initialDiagnosis': initialDiagnosis,
      'patientType': patientType, // Added new field
      'doctor': doctor.toJson(),
      'weight': weight,
    };
  }
}

class Doctor {
  final String id;
  final String name;
  final String? usertype; // Added new field for doctor type

  Doctor({
    required this.id,
    required this.name,
    this.usertype, // Optional because it might be missing in older data
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      usertype: json['usertype'], // Added new field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'usertype': usertype, // Added new field
    };
  }
}
