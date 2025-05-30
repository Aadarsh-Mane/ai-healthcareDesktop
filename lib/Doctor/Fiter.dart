// Add these classes to your project (create a new file: models/filter_models.dart)

import 'package:doctordesktop/model/getNewPatientModel.dart';

class PatientFilters {
  final String? search;
  final String? gender;
  final int? minAge;
  final int? maxAge;
  final String? city;
  final String? state;
  final String? patientType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String sortBy;
  final String sortOrder;
  final int page;
  final int limit;

  PatientFilters({
    this.search,
    this.gender,
    this.minAge,
    this.maxAge,
    this.city,
    this.state,
    this.patientType,
    this.dateFrom,
    this.dateTo,
    this.sortBy = 'admissionDate',
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 10,
  });

  PatientFilters copyWith({
    String? search,
    String? gender,
    int? minAge,
    int? maxAge,
    String? city,
    String? state,
    String? patientType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return PatientFilters(
      search: search ?? this.search,
      gender: gender ?? this.gender,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      city: city ?? this.city,
      state: state ?? this.state,
      patientType: patientType ?? this.patientType,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (gender != null && gender!.isNotEmpty) params['gender'] = gender;
    if (minAge != null) params['minAge'] = minAge;
    if (maxAge != null) params['maxAge'] = maxAge;
    if (city != null && city!.isNotEmpty) params['city'] = city;
    if (state != null && state!.isNotEmpty) params['state'] = state;
    if (patientType != null && patientType!.isNotEmpty)
      params['patientType'] = patientType;
    if (dateFrom != null) params['dateFrom'] = dateFrom!.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo!.toIso8601String();
    params['sortBy'] = sortBy;
    params['sortOrder'] = sortOrder;
    params['page'] = page;
    params['limit'] = limit;
    return params;
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int limit;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.limit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      limit: json['limit'] ?? 10,
    );
  }
}

// Enhanced response model to include pagination info
class PatientsResponse {
  final List<Patient1> patients;
  final PaginationInfo pagination;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> sorting;

  PatientsResponse({
    required this.patients,
    required this.pagination,
    required this.filters,
    required this.sorting,
  });

  factory PatientsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    return PatientsResponse(
      patients: (data['patients'] as List<dynamic>)
          .map((patientJson) =>
              Patient1.fromJson(patientJson as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(data['pagination'] as Map<String, dynamic>),
      filters: data['filters'] as Map<String, dynamic>,
      sorting: data['sorting'] as Map<String, dynamic>,
    );
  }
}
