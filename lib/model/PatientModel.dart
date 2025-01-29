class Patient {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;
  final bool discharged;
  final int? pendingAmount;

  final List<AdmissionRecord> admissionRecords;

  Patient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    required this.discharged,
    required this.admissionRecords,
    required this.pendingAmount,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      discharged: json['discharged'] ?? false,
      pendingAmount: json['pendingAmount'] as int?,
      admissionRecords: (json['admissionRecords'] as List? ?? [])
          .map((recordJson) => AdmissionRecord.fromJson(recordJson))
          .toList(),
    );
  }
}

class AdmissionRecord {
  final String admissionDate;
  final String reasonForAdmission;
  final String symptoms;
  final Doctor doctor;
  final List<FollowUp> followUps;

  AdmissionRecord({
    required this.admissionDate,
    required this.reasonForAdmission,
    required this.symptoms,
    required this.doctor,
    required this.followUps,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    var followUpList = json['followUps'] as List? ?? [];
    List<FollowUp> followUps =
        followUpList.map((followUp) => FollowUp.fromJson(followUp)).toList();

    return AdmissionRecord(
      admissionDate: json['admissionDate'] ?? '',
      reasonForAdmission: json['reasonForAdmission'] ?? '',
      symptoms: json['symptoms'] ?? '',
      doctor: json['doctor'] != null
          ? Doctor.fromJson(json['doctor'])
          : Doctor(id: '', name: 'Unknown'),
      followUps: followUps,
    );
  }
}

class Doctor {
  final String id;
  final String name;

  Doctor({required this.id, required this.name});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
    );
  }
}

class FollowUp {
  final String nurseId;
  final String date;
  final String notes;
  final String observations;

  FollowUp({
    required this.nurseId,
    required this.date,
    required this.notes,
    required this.observations,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      nurseId: json['nurseId'] ?? '',
      date: json['date'] ?? '',
      notes: json['notes'] ?? '',
      observations: json['observations'] ?? '',
    );
  }
}
