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

class Doctor {
  final String id;
  final String name;
  final String usertype;

  const Doctor({
    required this.id,
    required this.name,
    required this.usertype,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Doctor',
      usertype: json['usertype']?.toString() ?? 'doctor',
    );
  }
}

class AdmissionRecord {
  final String id;
  final String admissionDate;
  final String? reasonForAdmission;
  final String status;
  final List<String> doctorConsultant;
  final String? symptoms;
  final String? initialDiagnosis;
  final List<dynamic> reports;
  final List<FollowUp> followUps;
  final List<DoctorPrescription> doctorPrescriptions;
  final List<String> symptomsByDoctor;
  final List<String> diagnosisByDoctor;
  final List<Vitals> vitals;
  final List<DoctorConsulting> doctorConsulting;

  // New fields from the JSON
  final String? patientType;
  final String? conditionAtDischarge;
  final int? weight;
  final bool? ipdDetailsUpdated;
  final Doctor? doctor;
  final List<dynamic> fourHrFollowUpSchema;
  final List<dynamic> doctorNotes;
  final List<dynamic> medications;
  final List<dynamic> ivFluids;
  final List<dynamic> procedures;
  final List<dynamic> specialInstructions;

  AdmissionRecord({
    required this.id,
    required this.admissionDate,
    this.reasonForAdmission,
    this.symptoms,
    required this.status,
    required this.doctorConsultant,
    this.initialDiagnosis,
    required this.reports,
    required this.followUps,
    required this.doctorPrescriptions,
    required this.symptomsByDoctor,
    required this.diagnosisByDoctor,
    required this.vitals,
    required this.doctorConsulting,
    // New fields
    this.patientType,
    this.conditionAtDischarge,
    this.weight,
    this.ipdDetailsUpdated,
    this.doctor,
    required this.fourHrFollowUpSchema,
    required this.doctorNotes,
    required this.medications,
    required this.ivFluids,
    required this.procedures,
    required this.specialInstructions,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      id: json['_id']?.toString() ?? '',
      admissionDate: json['admissionDate']?.toString() ?? '',
      reasonForAdmission: json['reasonForAdmission']?.toString(),
      symptoms: json['symptoms']?.toString(),
      status: json['status']?.toString() ?? 'Pending',

      // Safe list parsing with null checks
      doctorConsultant: _parseStringList(json['doctorConsultant']),
      initialDiagnosis: json['initialDiagnosis']?.toString(),
      reports: _parseDynamicList(json['reports']),

      // Parse complex objects with null safety
      followUps: _parseFollowUps(json['followUps']),
      doctorPrescriptions:
          _parseDoctorPrescriptions(json['doctorPrescriptions']),
      symptomsByDoctor: _parseStringList(json['symptomsByDoctor']),
      diagnosisByDoctor: _parseStringList(json['diagnosisByDoctor']),
      vitals: _parseVitals(json['vitals']),
      doctorConsulting: _parseDoctorConsulting(json['doctorConsulting']),

      // New fields with safe parsing
      patientType: json['patientType']?.toString(),
      conditionAtDischarge: json['conditionAtDischarge']?.toString(),
      weight: _parseIntSafely(json['weight']),
      ipdDetailsUpdated: json['ipdDetailsUpdated'] as bool?,
      doctor: json['doctor'] != null
          ? Doctor.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      fourHrFollowUpSchema: _parseDynamicList(json['fourHrFollowUpSchema']),
      doctorNotes: _parseDynamicList(json['doctorNotes']),
      medications: _parseDynamicList(json['medications']),
      ivFluids: _parseDynamicList(json['ivFluids']),
      procedures: _parseDynamicList(json['procedures']),
      specialInstructions: _parseDynamicList(json['specialInstructions']),
    );
  }

  // Helper methods for safe parsing
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return [];
  }

  static List<dynamic> _parseDynamicList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    return [];
  }

  static List<FollowUp> _parseFollowUps(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => FollowUp.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<DoctorPrescription> _parseDoctorPrescriptions(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => DoctorPrescription.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<Vitals> _parseVitals(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => Vitals.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<DoctorConsulting> _parseDoctorConsulting(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => DoctorConsulting.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
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
  final String? city;
  final String? state;
  final String? country;
  final String? dob;
  final String imageUrl;
  final int? pendingAmount;
  final List<AdmissionRecord> admissionRecords;

  // New fields from the JSON
  final int? totalPendingAdmissions;
  final int? totalActiveAdmissions;
  final String? latestAdmissionDate;
  final String? earliestAdmissionDate;
  final int? totalFollowUps;
  final int? totalPrescriptions;
  final int? highestUrgencyScore;
  final List<int>? currentBedNumbers;
  final List<String>? currentSections;
  final double? averageStayDuration;

  Patient1({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    this.city,
    this.state,
    this.country,
    this.dob,
    required this.imageUrl,
    this.pendingAmount,
    required this.admissionRecords,
    // New fields
    this.totalPendingAdmissions,
    this.totalActiveAdmissions,
    this.latestAdmissionDate,
    this.earliestAdmissionDate,
    this.totalFollowUps,
    this.totalPrescriptions,
    this.highestUrgencyScore,
    this.currentBedNumbers,
    this.currentSections,
    this.averageStayDuration,
  });

  factory Patient1.fromJson(Map<String, dynamic> json) {
    return Patient1(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? 'N/A',
      name: json['name']?.toString() ?? 'Unknown Patient',
      age: _parseAge(json['age']),
      gender: json['gender']?.toString() ?? 'N/A',
      contact: json['contact']?.toString() ?? 'N/A',
      address: json['address']?.toString() ?? 'N/A',
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      dob: json['dob']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      pendingAmount: _parseIntSafely(json['pendingAmount']),
      admissionRecords: _parseAdmissionRecords(json['admissionRecords']),

      // New fields with safe parsing
      totalPendingAdmissions: _parseIntSafely(json['totalPendingAdmissions']),
      totalActiveAdmissions: _parseIntSafely(json['totalActiveAdmissions']),
      latestAdmissionDate: json['latestAdmissionDate']?.toString(),
      earliestAdmissionDate: json['earliestAdmissionDate']?.toString(),
      totalFollowUps: _parseIntSafely(json['totalFollowUps']),
      totalPrescriptions: _parseIntSafely(json['totalPrescriptions']),
      highestUrgencyScore: _parseIntSafely(json['highestUrgencyScore']),
      currentBedNumbers: _parseIntList(json['currentBedNumbers']),
      currentSections: _parseStringList(json['currentSections']),
      averageStayDuration: _parseDoubleSafely(json['averageStayDuration']),
    );
  }

  // Helper methods for safe parsing
  static int _parseAge(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _parseDoubleSafely(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return null;
  }

  static List<int>? _parseIntList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => e is int ? e : int.tryParse(e?.toString() ?? '') ?? 0)
          .toList();
    }
    return null;
  }

  static List<AdmissionRecord> _parseAdmissionRecords(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => AdmissionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Utility getters for easy access to commonly used data
  String get displayStatus {
    if (admissionRecords.isEmpty) return 'No Records';
    return admissionRecords.first.status;
  }

  String get doctorName {
    if (admissionRecords.isEmpty || admissionRecords.first.doctor == null) {
      return 'No Doctor Assigned';
    }
    return admissionRecords.first.doctor!.name;
  }

  String get patientTypeDisplay {
    if (admissionRecords.isEmpty) return 'N/A';
    return admissionRecords.first.patientType ?? 'N/A';
  }

  String get sectionDisplay {
    if (currentSections != null && currentSections!.isNotEmpty) {
      return currentSections!.first;
    }
    return 'No Section Assigned';
  }

  String get bedDisplay {
    if (currentBedNumbers != null && currentBedNumbers!.isNotEmpty) {
      return 'Bed ${currentBedNumbers!.first}';
    }
    return 'No Bed Assigned';
  }

  int get stayDurationDays {
    return averageStayDuration?.toInt() ?? 0;
  }

  bool get hasMultipleSections {
    return currentSections != null && currentSections!.length > 1;
  }

  bool get hasMultipleBeds {
    return currentBedNumbers != null && currentBedNumbers!.length > 1;
  }

  // Additional utility methods
  String get fullAddress {
    final parts = [address, city, state, country]
        .where((part) => part != null && part.isNotEmpty);
    return parts.join(', ');
  }

  bool get hasValidContact {
    return contact != 'N/A' && contact.isNotEmpty;
  }

  bool get hasAdmissionRecords {
    return admissionRecords.isNotEmpty;
  }

  String get admissionDateFormatted {
    if (admissionRecords.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(admissionRecords.first.admissionDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
