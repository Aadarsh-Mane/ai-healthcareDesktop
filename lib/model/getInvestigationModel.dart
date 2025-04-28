// lib/model/investigation_model.dart

class Investigation {
  final String id;
  final Patient patient;
  final String patientIdNumber;
  final String doctorId;
  final String doctorName;
  final String investigationType;
  final String status;
  final DateTime orderDate;
  final String reasonForInvestigation;
  final String priority;
  final InvestigationDetails investigationDetails;
  final String admissionRecordId;
  final Billing billing;
  final List<String> tags;
  final List<Attachment> attachments;
  final List<Note> notes;
  final DateTime scheduledDate;
  final String clinicalHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int daysSinceOrdered;
  final bool isOverdue;
  final bool hasAttachments;
  final bool hasResults;
  final DateTime? completionDate;
  final PerformedBy? performedBy;
  final Results? results;

  Investigation({
    required this.id,
    required this.patient,
    required this.patientIdNumber,
    required this.doctorId,
    required this.doctorName,
    required this.investigationType,
    required this.status,
    required this.orderDate,
    required this.reasonForInvestigation,
    required this.priority,
    required this.investigationDetails,
    required this.admissionRecordId,
    required this.billing,
    required this.tags,
    required this.attachments,
    required this.notes,
    required this.scheduledDate,
    required this.clinicalHistory,
    required this.createdAt,
    required this.updatedAt,
    required this.daysSinceOrdered,
    required this.isOverdue,
    required this.hasAttachments,
    required this.hasResults,
    this.completionDate,
    this.performedBy,
    this.results,
  });

  factory Investigation.fromJson(Map<String, dynamic> json) {
    // Safe handling for patientId which could be an object or just an ID
    Patient patient;
    try {
      if (json['patientId'] is Map<String, dynamic>) {
        patient = Patient.fromJson(json['patientId']);
      } else {
        // Create a default patient if we don't have the data
        patient = Patient(
          id: json['patientId']?.toString() ?? '',
          name: 'Unknown',
          age: 0,
          gender: 'Unknown',
          contact: 'N/A',
        );
      }
    } catch (e) {
      // Fallback for any parsing errors
      patient = Patient(
        id: '',
        name: 'Unknown',
        age: 0,
        gender: 'Unknown',
        contact: 'N/A',
      );
    }

    // Helper function for safe date parsing
    DateTime parseDateTime(String? dateStr, {DateTime? defaultValue}) {
      if (dateStr == null) return defaultValue ?? DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return defaultValue ?? DateTime.now();
      }
    }

    return Investigation(
      id: json['_id'] ?? '',
      patient: patient,
      patientIdNumber: json['patientIdNumber'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      investigationType: json['investigationType'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      orderDate: parseDateTime(json['orderDate']),
      reasonForInvestigation: json['reasonForInvestigation'] ?? '',
      priority: json['priority'] ?? 'Routine',
      investigationDetails: json['investigationDetails'] is Map
          ? InvestigationDetails.fromJson(json['investigationDetails'])
          : InvestigationDetails(
              bodySite: json['investigationDetails']?.toString()),
      admissionRecordId: json['admissionRecordId'] ?? '',
      billing: json['billing'] is Map
          ? Billing.fromJson(json['billing'])
          : Billing(),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      attachments: json['attachments'] is List
          ? List<Attachment>.from(
              (json['attachments']).map((x) => Attachment.fromJson(x)))
          : [],
      notes: json['notes'] is List
          ? List<Note>.from((json['notes']).map((x) => Note.fromJson(x)))
          : [],
      scheduledDate: parseDateTime(json['scheduledDate']),
      clinicalHistory: json['clinicalHistory'] ?? '',
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      daysSinceOrdered: json['daysSinceOrdered'] ?? 0,
      isOverdue: json['isOverdue'] ?? false,
      hasAttachments: json['hasAttachments'] ?? false,
      hasResults: json['hasResults'] ?? false,
      completionDate: json['completionDate'] != null
          ? parseDateTime(json['completionDate'])
          : null,
      performedBy: json['performedBy'] != null
          ? PerformedBy.fromJson(json['performedBy'])
          : null,
      results:
          json['results'] != null ? Results.fromJson(json['results']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patient.toJson(),
      'patientIdNumber': patientIdNumber,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'investigationType': investigationType,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'reasonForInvestigation': reasonForInvestigation,
      'priority': priority,
      'investigationDetails': investigationDetails.toJson(),
      'admissionRecordId': admissionRecordId,
      'billing': billing.toJson(),
      'tags': tags,
      'attachments': attachments.map((x) => x.toJson()).toList(),
      'notes': notes.map((x) => x.toJson()).toList(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'clinicalHistory': clinicalHistory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'daysSinceOrdered': daysSinceOrdered,
      'isOverdue': isOverdue,
      'hasAttachments': hasAttachments,
      'hasResults': hasResults,
      'completionDate': completionDate?.toIso8601String(),
      'performedBy': performedBy?.toJson(),
      'results': results?.toJson(),
    };
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
    // Handle cases where only id and name are provided
    return Patient(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      age: json['age'] ?? 0, // Use 0 as default if age is missing
      gender: json['gender'] ??
          'Unknown', // Use 'Unknown' as default if gender is missing
      contact: json['contact'] ??
          'N/A', // Use 'N/A' as default if contact is missing
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'contact': contact,
    };
  }
}

class InvestigationDetails {
  final String? bodySite;
  final bool? contrastUsed;
  final List<String>? parameters;

  InvestigationDetails({
    this.bodySite,
    this.contrastUsed,
    this.parameters,
  });

  factory InvestigationDetails.fromJson(Map<String, dynamic> json) {
    return InvestigationDetails(
      bodySite: json['bodySite'],
      contrastUsed: json['contrastUsed'],
      parameters: json['parameters'] != null
          ? List<String>.from(json['parameters'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (bodySite != null) data['bodySite'] = bodySite;
    if (contrastUsed != null) data['contrastUsed'] = contrastUsed;
    if (parameters != null) data['parameters'] = parameters;
    return data;
  }
}

class Billing {
  final bool? insuranceCovered;
  final String? paymentStatus;
  final double? cost;

  Billing({
    this.insuranceCovered,
    this.paymentStatus,
    this.cost,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    // Handle cost that could be string, number, or null
    double? parseCost(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return Billing(
      insuranceCovered: json['insuranceCovered'],
      paymentStatus: json['paymentStatus'],
      cost: parseCost(json['cost']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (insuranceCovered != null) data['insuranceCovered'] = insuranceCovered;
    if (paymentStatus != null) data['paymentStatus'] = paymentStatus;
    if (cost != null) data['cost'] = cost;
    return data;
  }
}

class Attachment {
  final String fileName;
  final String fileType;
  final String fileUrl;
  final DateTime uploadDate;
  final String description;
  final String id;

  Attachment({
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    required this.uploadDate,
    required this.description,
    required this.id,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    // Helper function for safe date parsing
    DateTime parseDateTime(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return Attachment(
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      uploadDate: parseDateTime(json['uploadDate']),
      description: json['description'] ?? '',
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'uploadDate': uploadDate.toIso8601String(),
      'description': description,
      '_id': id,
    };
  }
}

class Note {
  final String text;
  final AddedBy addedBy;
  final DateTime dateAdded;
  final String id;

  Note({
    required this.text,
    required this.addedBy,
    required this.dateAdded,
    required this.id,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    // Helper function for safe date parsing
    DateTime parseDateTime(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return Note(
      text: json['text'] ?? '',
      addedBy: json['addedBy'] is Map
          ? AddedBy.fromJson(json['addedBy'])
          : AddedBy(userId: '', userType: '', name: ''),
      dateAdded: parseDateTime(json['dateAdded']),
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'addedBy': addedBy.toJson(),
      'dateAdded': dateAdded.toIso8601String(),
      '_id': id,
    };
  }
}

class AddedBy {
  final String userId;
  final String userType;
  final String name;

  AddedBy({
    required this.userId,
    required this.userType,
    required this.name,
  });

  factory AddedBy.fromJson(Map<String, dynamic> json) {
    return AddedBy(
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
      'name': name,
    };
  }
}

class PerformedBy {
  final String designation;
  final String facility;
  final String name;

  PerformedBy({
    required this.designation,
    required this.facility,
    required this.name,
  });

  factory PerformedBy.fromJson(Map<String, dynamic> json) {
    return PerformedBy(
      designation: json['designation'] ?? '',
      facility: json['facility'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'designation': designation,
      'facility': facility,
      'name': name,
    };
  }
}

class Results {
  final String findings;
  final String impression;
  final bool isAbnormal;
  final Map<String, dynamic> normalRanges;
  final Map<String, dynamic> numericalResults;
  final String recommendations;

  Results({
    required this.findings,
    required this.impression,
    required this.isAbnormal,
    required this.normalRanges,
    required this.numericalResults,
    required this.recommendations,
  });

  factory Results.fromJson(Map<String, dynamic> json) {
    return Results(
      findings: json['findings'] ?? '',
      impression: json['impression'] ?? '',
      isAbnormal: json['isAbnormal'] ?? false,
      normalRanges: json['normalRanges'] is Map ? json['normalRanges'] : {},
      numericalResults:
          json['numericalResults'] is Map ? json['numericalResults'] : {},
      recommendations: json['recommendations'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'findings': findings,
      'impression': impression,
      'isAbnormal': isAbnormal,
      'normalRanges': normalRanges,
      'numericalResults': numericalResults,
      'recommendations': recommendations,
    };
  }
}

class InvestigationResponse {
  final bool success;
  final int count;
  final Pagination pagination;
  final List<Investigation> data;

  InvestigationResponse({
    required this.success,
    required this.count,
    required this.pagination,
    required this.data,
  });

  factory InvestigationResponse.fromJson(Map<String, dynamic> json) {
    return InvestigationResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      pagination: json['pagination'] is Map
          ? Pagination.fromJson(json['pagination'])
          : Pagination(
              currentPage: 1, totalPages: 1, pageSize: 10, totalItems: 0),
      data: json['data'] is List
          ? List<Investigation>.from(
              json['data'].map((x) => Investigation.fromJson(x)))
          : [],
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int totalItems;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalItems,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class CreateInvestigationRequest {
  final String patientId;
  final String admissionId;
  final String investigationType;
  final String reasonForInvestigation;
  final String? priority;
  final String scheduledDate;
  final String clinicalHistory;
  final String investigationDetails;
  final List<String> tags;
  final String? otherInvestigationType;

  CreateInvestigationRequest({
    required this.patientId,
    required this.admissionId,
    required this.investigationType,
    required this.reasonForInvestigation,
    this.priority,
    required this.scheduledDate,
    required this.clinicalHistory,
    required this.investigationDetails,
    required this.tags,
    this.otherInvestigationType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'patientId': patientId,
      'admissionId': admissionId,
      'investigationType': investigationType,
      'reasonForInvestigation': reasonForInvestigation,
      'scheduledDate': scheduledDate,
      'clinicalHistory': clinicalHistory,
      'investigationDetails': investigationDetails,
      'tags': tags,
    };

    if (priority != null) data['priority'] = priority;
    if (otherInvestigationType != null) {
      data['otherInvestigationType'] = otherInvestigationType;
    }

    return data;
  }
}

// Helper method to safely process the investigation response
