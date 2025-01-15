class FollowUp {
  final String nurseId;
  final String date;
  final String notes;
  final String observations;
  final String id;
  final double temperature;
  final int pulse;
  final int respirationRate;
  final String bloodPressure;
  final int oxygenSaturation;
  final int bloodSugarLevel;
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
  final int setRate;
  final double fiO2;
  final int pip;
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
    required this.nurseId,
    required this.date,
    required this.notes,
    required this.observations,
    required this.id,
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
    required this.otherVentilator,
    required this.fourhrpulse,
    required this.fourhrbloodPressure,
    required this.fourhroxygenSaturation,
    required this.fourhrTemperature,
    required this.fourhrbloodSugarLevel,
    required this.fourhrotherVitals,
    required this.fourhrurine,
    required this.fourhrivFluid,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      nurseId: json['nurseId'] ?? '', // Default to empty string if missing
      date: json['date'] ?? '', // Default to empty string if missing
      notes: json['notes'] ?? '', // Default to empty string if missing
      observations:
          json['observations'] ?? '', // Default to empty string if missing
      id: json['_id'] ?? '', // Default to empty string if missing
      temperature:
          json['temperature']?.toDouble() ?? 0.0, // Default to 0.0 if null
      pulse: json['pulse'] ?? 0, // Default to 0 if missing
      respirationRate: json['respirationRate'] ?? 0, // Default to 0 if missing
      bloodPressure:
          json['bloodPressure'] ?? '', // Default to empty string if missing
      oxygenSaturation:
          json['oxygenSaturation'] ?? 0, // Default to 0 if missing
      bloodSugarLevel: json['bloodSugarLevel'] ?? 0, // Default to 0 if missing
      otherVitals:
          json['otherVitals'] ?? '', // Default to empty string if missing
      ivFluid: json['ivFluid'] ?? '', // Default to empty string if missing
      nasogastric:
          json['nasogastric'] ?? '', // Default to empty string if missing
      rtFeedOral:
          json['rtFeedOral'] ?? '', // Default to empty string if missing
      totalIntake:
          json['totalIntake'] ?? '', // Default to empty string if missing
      cvp: json['cvp'] ?? '', // Default to empty string if missing
      urine: json['urine'] ?? '', // Default to empty string if missing
      stool: json['stool'] ?? '', // Default to empty string if missing
      rtAspirate:
          json['rtAspirate'] ?? '', // Default to empty string if missing
      otherOutput:
          json['otherOutput'] ?? '', // Default to empty string if missing
      ventyMode: json['ventyMode'] ?? '', // Default to empty string if missing
      setRate: json['setRate'] ?? 0, // Default to 0 if missing
      fiO2: json['fiO2']?.toDouble() ?? 0.0, // Default to 0.0 if null
      pip: json['pip'] ?? 0, // Default to 0 if missing
      peepCpap: json['peepCpap'] ?? '', // Default to empty string if missing
      ieRatio: json['ieRatio'] ?? '', // Default to empty string if missing
      otherVentilator:
          json['otherVentilator'] ?? '', // Default to empty string if missing
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
}

class Medicine {
  final String name;
  final String morning;
  final String afternoon;
  final String night;
  final String comment;
  final DateTime? date;

  Medicine(
      {required this.name,
      required this.morning,
      required this.afternoon,
      required this.night,
      required this.comment,
      this.date});

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'] ?? '',
      morning: json['morning'] ?? '',
      afternoon: json['afternoon'] ?? '',
      night: json['night'] ?? '',
      comment: json['comment'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
              .add(const Duration(hours: 5, minutes: 30))
          : null,
      // date: json['date'] ?? '',
      // date: json['date']
    );
  }
}

class DoctorPrescription {
  final Medicine medicine;

  DoctorPrescription({required this.medicine});

  factory DoctorPrescription.fromJson(Map<String, dynamic> json) {
    return DoctorPrescription(
      medicine: Medicine.fromJson(json['medicine']),
    );
  }
}

class Vitals {
  final double temperature;
  final int pulse;
  final int bloodPressure;
  final int bloodSugarLevel;
  final String other;
  // final String recordedAt;

  Vitals({
    required this.temperature,
    required this.pulse,
    required this.bloodPressure,
    required this.bloodSugarLevel,
    required this.other,
    // required this.recordedAt,
  });

  factory Vitals.fromJson(Map<String, dynamic> json) {
    return Vitals(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      pulse: json['pulse'] ?? 0,
      bloodPressure: json['bloodPressure'] ?? 0,
      bloodSugarLevel: json['bloodSugarLevel'] ?? 0,
      other: json['other'] ?? '',
      // recordedAt: json['recordedAt'] ?? '',
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
      id: json['_id'],
      admissionDate: json['admissionDate'],
      reasonForAdmission: json['reasonForAdmission'],
      symptoms: json['symptoms'],
      status: json['status'] ?? '' as String,
      initialDiagnosis: json['initialDiagnosis'],
      doctorConsultant: List<String>.from(json['doctorConsultant'] ?? []),
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
      id: json['_id'],
      patientId: json['patientId'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      contact: json['contact'],
      address: json['address'],
      imageUrl: json['imageUrl'] ?? '',
      pendingAmount: json['pendingAmount'] as int?,
      admissionRecords: (json['admissionRecords'] as List<dynamic>)
          .map((e) => AdmissionRecord.fromJson(e))
          .toList(),
    );
  }
}
