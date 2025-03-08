class FollowUp {
  final String date;
  final String notes;
  final String observations;
  final String temperature;
  final String pulse;
  final String respirationRate;
  final String bloodPressure;
  final String oxygenSaturation;
  final String bloodSugarLevel;
  final String otherVitals;

  final String ivFluid;
  final String nasogastric;
  final String rtFeedOral;
  final String totalIntake;

  final String cvp;
  final String urine;
  final String stool;
  final String rtAspirate;
  final String otherOutput;

  final String ventyMode;
  final String setRate;
  final String fiO2;
  final String pip;
  final String peepCpap;
  final String ieRatio;
  final String otherVentilator;
  final String fourhrpulse;
  final String fourhrbloodPressure;
  final String fourhroxygenSaturation;
  final String fourhrTemperature;
  final String fourhrbloodSugarLevel;
  final String fourhrotherVitals;
  final String fourhrurine;
  final String fourhrivFluid;

  FollowUp({
    required this.date,
    required this.notes,
    required this.observations,
    required this.temperature,
    required this.pulse,
    required this.respirationRate,
    required this.bloodPressure,
    required this.oxygenSaturation,
    required this.bloodSugarLevel,
    required this.otherVitals,
    required this.ivFluid,
    required this.nasogastric,
    required this.rtFeedOral,
    required this.totalIntake,
    required this.otherVentilator,
    required this.cvp,
    required this.urine,
    required this.stool,
    required this.rtAspirate,
    required this.otherOutput,
    required this.ventyMode,
    required this.setRate,
    required this.fiO2,
    required this.pip,
    required this.peepCpap,
    required this.ieRatio,
    required this.fourhrpulse,
    required this.fourhrbloodPressure,
    required this.fourhroxygenSaturation,
    required this.fourhrTemperature,
    required this.fourhrbloodSugarLevel,
    required this.fourhrotherVitals,
    required this.fourhrurine,
    required this.fourhrivFluid,
    // Add more fields as needed
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      date: json['date'] ?? '',
      notes: json['notes'] ?? '',
      observations: json['observations'] ?? '',
      temperature:
          json['temperature']?.toString() ?? '', // Ensure it's a string
      pulse: json['pulse']?.toString() ?? '',
      respirationRate: json['respirationRate']?.toString() ?? '',
      bloodPressure: json['bloodPressure']?.toString() ?? '',
      oxygenSaturation: json['oxygenSaturation']?.toString() ?? '',
      bloodSugarLevel: json['bloodSugarLevel']?.toString() ?? '',
      otherVitals: json['otherVitals'] ?? '',
      ivFluid: json['ivFluid']?.toString() ?? '', // Ensure it's a string
      nasogastric: json['nasogastric'] ?? '',
      rtFeedOral: json['rtFeedOral'] ?? '',
      totalIntake: json['totalIntake'] ?? '',
      cvp: json['cvp'] ?? '',
      urine: json['urine'] ?? '',
      otherVentilator: json['otherVentilator'] ?? '',
      stool: json['stool'] ?? '',
      rtAspirate: json['rtAspirate'] ?? '',
      otherOutput: json['otherOutput'] ?? '',
      ventyMode: json['ventyMode'] ?? '',
      setRate: json['setRate'] ?? '',
      fiO2: json['fiO2'] ?? '',
      pip: json['pip'] ?? '',
      peepCpap: json['peepCpap'] ?? '',
      ieRatio: json['ieRatio'] ?? '',
      fourhrpulse: json['fourhrpulse'] ?? '',
      fourhrbloodPressure: json['fourhrbloodPressure'] ?? '',
      fourhroxygenSaturation: json['fourhroxygenSaturation'] ?? '',
      fourhrTemperature: json['fourhrTemperature'] ?? '',
      fourhrbloodSugarLevel: json['fourhrbloodSugarLevel'] ?? '',
      fourhrotherVitals: json['fourhrotherVitals'] ?? '',
      fourhrurine: json['fourhrurine'] ?? '',
      fourhrivFluid: json['fourhrivFluid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'notes': notes,
      'observations': observations,
      'temperature': temperature,
      'pulse': pulse,
      'respirationRate': respirationRate,
      'bloodPressure': bloodPressure,
      'oxygenSaturation': oxygenSaturation,
      'bloodSugarLevel': bloodSugarLevel,
      'otherVitals': otherVitals,
      'ivFluid': ivFluid,
      'nasogastric': nasogastric,
      'rtFeedOral': rtFeedOral,
      'totalIntake': totalIntake,
      'otherVentilator': otherVentilator,
      'cvp': cvp,
      'urine': urine,
      'stool': stool,
      'rtAspirate': rtAspirate,
      'otherOutput': otherOutput,
      'ventyMode': ventyMode,
      'setRate': setRate,
      'fiO2': fiO2,
      'pip': pip,
      'peepCpap': peepCpap,
      'ieRatio': ieRatio,

      'fourhrpulse': fourhrpulse,
      'fourhrbloodPressure': fourhrbloodPressure,
      'fourhroxygenSaturation': fourhroxygenSaturation,
      'fourhrTemperature': fourhrTemperature,
      'fourhrbloodSugarLevel': fourhrbloodSugarLevel,
      'fourhrotherVitals': fourhrotherVitals,
      'fourhrurine': fourhrurine,
      'fourhrivFluid': fourhrivFluid,
      // Add more fields as needed
    };
  }
}

class Medicine {
  final String? id; // MongoDB ID
  final String name;
  final String morning;
  final String afternoon;
  final String night;
  final String comment;
  final DateTime? date;

  Medicine({
    this.id,
    required this.name,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.comment,
    this.date,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? '', // Extract the ID from the JSON
      name: json['name'] ?? '',
      morning: json['morning'] ?? '',
      afternoon: json['afternoon'] ?? '',
      night: json['night'] ?? '',
      comment: json['comment'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
              .add(const Duration(hours: 5, minutes: 30))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'morning': morning,
      'afternoon': afternoon,
      'night': night,
      'comment': comment,
      'date': date?.toIso8601String(),
    };
  }
}

class DoctorPrescription {
  final Medicine medicine;

  DoctorPrescription({required this.medicine});

  factory DoctorPrescription.fromJson(Map<String, dynamic> json) {
    return DoctorPrescription(
      medicine: Medicine.fromJson({
        ...json['medicine'],
        '_id': json['_id'], // Pass the ID to the Medicine model
      }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicine.toJson(),
    };
  }
}

class Vitals {
  final String temperature;
  final String pulse;
  final String bloodPressure;
  final String bloodSugarLevel;
  final String other;
  final String? recordedAt;
  final String? id;

  Vitals({
    required this.temperature,
    required this.pulse,
    required this.bloodPressure,
    required this.bloodSugarLevel,
    required this.other,
    this.recordedAt,
    this.id,
  });

  factory Vitals.fromJson(Map<String, dynamic> json) {
    return Vitals(
      temperature: json['temperature'] ?? '',
      pulse: json['pulse'] ?? '',
      bloodPressure: json['bloodPressure'] ?? '',
      bloodSugarLevel: json['bloodSugarLevel'] ?? '',
      other: json['other'] ?? '',
      recordedAt: json['recordedAt'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

class DoctorConsulting {
  final String allergies;
  final String cheifComplaint;
  final String describeAllergies;
  final String historyOfPresentIllness;
  final String personalHabits;
  final String familyHistory;
  final String menstrualHistory;
  final String wongBaker;
  final String visualAnalogue;
  final String relevantPreviousInvestigations;
  final String immunizationHistory;
  final String pastMedicalHistory;
  final String date;

  DoctorConsulting({
    required this.allergies,
    required this.cheifComplaint,
    required this.describeAllergies,
    required this.historyOfPresentIllness,
    required this.personalHabits,
    required this.familyHistory,
    required this.menstrualHistory,
    required this.wongBaker,
    required this.visualAnalogue,
    required this.relevantPreviousInvestigations,
    required this.immunizationHistory,
    required this.pastMedicalHistory,
    required this.date,
  });

  factory DoctorConsulting.fromJson(Map<String, dynamic> json) {
    return DoctorConsulting(
      allergies: json['allergies'] ?? '',
      cheifComplaint: json['cheifComplaint'] ?? '',
      describeAllergies: json['describeAllergies'] ?? '',
      historyOfPresentIllness: json['historyOfPresentIllness'] ?? '',
      personalHabits: json['personalHabits'] ?? '',
      familyHistory: json['familyHistory'] ?? '',
      menstrualHistory: json['menstrualHistory'] ?? '',
      wongBaker: json['wongBaker'] ?? '',
      visualAnalogue: json['visualAnalogue'] ?? '',
      relevantPreviousInvestigations:
          json['relevantPreviousInvestigations'] ?? '',
      immunizationHistory: json['immunizationHistory'] ?? '',
      pastMedicalHistory: json['pastMedicalHistory'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class AdmissionRecord {
  final String id;
  final String admissionDate;
  final String reasonForAdmission;
  final String status;
  final List<String> doctorConsultant;

  final String symptoms;
  final String initialDiagnosis;
  final List<dynamic> reports;
  final List<FollowUp> followUps;
  final List<DoctorPrescription> doctorPrescriptions;
  late final List<String> symptomsByDoctor;
  final List<String> diagnosisByDoctor;
  final List<Vitals> vitals;
  final List<DoctorConsulting> doctorConsulting;

  AdmissionRecord({
    required this.id,
    required this.admissionDate,
    required this.reasonForAdmission,
    required this.symptoms,
    required this.status,
    required this.doctorConsultant, // Default to empty list if missing

    required this.initialDiagnosis,
    required this.reports,
    required this.followUps,
    required this.doctorPrescriptions,
    required this.symptomsByDoctor,
    required this.diagnosisByDoctor,
    required this.vitals,
    required this.doctorConsulting,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      id: json['_id'] ?? '',
      admissionDate: json['admissionDate'] ?? '',
      reasonForAdmission: json['reasonForAdmission'] ?? '', // Add default
      symptoms: json['symptoms'] ?? '', // Add default
      status: json['status'] ?? '',
      doctorConsultant: List<String>.from(json['doctorConsultant'] ?? []),
      initialDiagnosis: json['initialDiagnosis'] ?? '', // Add default
      reports: json['reports'] ?? [],
      followUps: (json['followUps'] as List<dynamic>)
          .map((e) => FollowUp.fromJson(e))
          .toList(),
      doctorPrescriptions: (json['doctorPrescriptions'] as List<dynamic>?)
              ?.map((e) => DoctorPrescription.fromJson(e))
              .toList() ??
          [],
      symptomsByDoctor: List<String>.from(json['symptomsByDoctor'] ?? []),
      diagnosisByDoctor: List<String>.from(json['diagnosisByDoctor'] ?? []),
      vitals: (json['vitals'] as List<dynamic>?)
              ?.map((e) => Vitals.fromJson(e))
              .toList() ??
          [],
      doctorConsulting: (json['doctorConsulting'] as List<dynamic>?)
              ?.map((e) => DoctorConsulting.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Patient1 {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;
  final String imageUrl;
  final int? pendingAmount;
  final List<AdmissionRecord> admissionRecords;

  Patient1(
      {required this.id,
      required this.patientId,
      required this.name,
      required this.age,
      required this.gender,
      required this.contact,
      required this.address,
      required this.imageUrl,
      required this.admissionRecords,
      required this.pendingAmount});

  factory Patient1.fromJson(Map<String, dynamic> json) {
    return Patient1(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? 'N/A',
      name: json['name']?.toString() ?? 'N/A',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age'].toString()) ?? 0,
      gender: json['gender']?.toString() ?? 'N/A',
      contact: json['contact']?.toString() ?? 'N/A',
      address: json['address']?.toString() ?? 'N/A',
      imageUrl: json['imageUrl']?.toString() ?? '',
      pendingAmount: json['pendingAmount'] is int
          ? json['pendingAmount']
          : int.tryParse(json['pendingAmount'] ?? 0),
      admissionRecords: (json['admissionRecords'] as List<dynamic>? ?? [])
          .map((e) => AdmissionRecord.fromJson(e))
          .toList(),
    );
  }
}
