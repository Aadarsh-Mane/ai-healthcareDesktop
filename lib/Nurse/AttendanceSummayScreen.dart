import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

// Models
class Nurse {
  final String id;
  final String nurseName;
  final String email;
  final String usertype;
  final String status;
  final bool? isAvailable;

  const Nurse({
    required this.id,
    required this.nurseName,
    required this.email,
    required this.usertype,
    required this.status,
    this.isAvailable,
  });

  factory Nurse.fromJson(Map<String, dynamic> json) {
    return Nurse(
      id: json['_id'] ?? '',
      nurseName: json['nurseName'] ?? '',
      email: json['email'] ?? '',
      usertype: json['usertype'] ?? '',
      status: json['status'] ?? '',
      isAvailable: json['isAvailable'],
    );
  }
}

class AttendanceRecord {
  final String id;
  final String nurseId;
  final DateTime date;
  final CheckInOut? checkIn;
  final CheckInOut? checkOut;
  final String status;
  final String? notes;
  final double? totalHours;
  final NurseInfo? nurse;

  const AttendanceRecord({
    required this.id,
    required this.nurseId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.notes,
    this.totalHours,
    this.nurse,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? '',
      nurseId: json['nurseId'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      checkIn:
          json['checkIn'] != null ? CheckInOut.fromJson(json['checkIn']) : null,
      checkOut: json['checkOut'] != null
          ? CheckInOut.fromJson(json['checkOut'])
          : null,
      status: json['status'] ?? '',
      notes: json['notes'],
      totalHours: json['totalHours']?.toDouble(),
      nurse: json['nurse'] != null ? NurseInfo.fromJson(json['nurse']) : null,
    );
  }
}

class CheckInOut {
  final DateTime time;
  final double? latitude;
  final double? longitude;
  final bool? isWithinRadius;

  const CheckInOut({
    required this.time,
    this.latitude,
    this.longitude,
    this.isWithinRadius,
  });

  factory CheckInOut.fromJson(Map<String, dynamic> json) {
    return CheckInOut(
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isWithinRadius: json['isWithinRadius'],
    );
  }
}

class NurseInfo {
  final String id;
  final String email;

  const NurseInfo({
    required this.id,
    required this.email,
  });

  factory NurseInfo.fromJson(Map<String, dynamic> json) {
    return NurseInfo(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class AttendanceStatistics {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final double presentPercentage;

  const AttendanceStatistics({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.presentPercentage,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    return AttendanceStatistics(
      total: json['total'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      late: json['late'] ?? 0,
      halfDay: json['halfDay'] ?? 0,
      presentPercentage: (json['presentPercentage'] ?? 0).toDouble(),
    );
  }
}

class AttendanceResponse {
  final List<AttendanceRecord> attendanceRecords;
  final AttendanceStatistics statistics;
  final Map<String, dynamic> pagination;
  final Map<String, dynamic> filters;

  const AttendanceResponse({
    required this.attendanceRecords,
    required this.statistics,
    required this.pagination,
    required this.filters,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return AttendanceResponse(
      attendanceRecords: (data['attendanceRecords'] as List? ?? [])
          .map((e) => AttendanceRecord.fromJson(e))
          .toList(),
      statistics: AttendanceStatistics.fromJson(data['statistics'] ?? {}),
      pagination: data['pagination'] ?? {},
      filters: data['filters'] ?? {},
    );
  }
}

// API Service
class NurseApiService {
  static Future<List<Nurse>> getAllNurses() async {
    try {
      final response = await http.get(
        Uri.parse('$KVM_URL/nurse/getAllNurses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['nurses'] as List? ?? [])
            .map((e) => Nurse.fromJson(e))
            .toList();
      }
      throw Exception('Failed to load nurses: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<AttendanceResponse> getAllNurseAttendance({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
    String? nurseId,
    String? status,
    String? sortBy = 'date',
    String? sortOrder = 'desc',
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy ?? 'date',
        'sortOrder': sortOrder ?? 'desc',
      };

      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (nurseId != null && nurseId.isNotEmpty)
        queryParams['nurseId'] = nurseId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$KVM_URL/nurse/getAllNurseAttendance')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return AttendanceResponse.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load attendance: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> markAttendanceManually({
    required String nurseId,
    required String date,
    required String status,
    String? notes,
  }) async {
    try {
      final body = {
        'nurseId': nurseId,
        'date': date,
        'status': status,
        'notes': notes ?? 'Manual attendance marked',
      };

      final response = await http.post(
        Uri.parse('$KVM_URL/nurse/markAttendanceManually'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// Providers
final nursesProvider = FutureProvider<List<Nurse>>((ref) async {
  return await NurseApiService.getAllNurses();
});

final attendanceFiltersProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

final attendanceProvider =
    FutureProvider.family<AttendanceResponse, Map<String, dynamic>>(
        (ref, filters) async {
  return await NurseApiService.getAllNurseAttendance(
    page: filters['page'] ?? 1,
    limit: filters['limit'] ?? 10,
    startDate: filters['startDate'],
    endDate: filters['endDate'],
    nurseId: filters['nurseId'],
    status: filters['status'],
    sortBy: filters['sortBy'],
    sortOrder: filters['sortOrder'],
    search: filters['search'],
  );
});

// Main Screen
class NurseManagementScreen extends ConsumerStatefulWidget {
  const NurseManagementScreen({super.key});

  @override
  ConsumerState<NurseManagementScreen> createState() =>
      _NurseManagementScreenState();
}

class _NurseManagementScreenState extends ConsumerState<NurseManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final filters = ref.read(attendanceFiltersProvider);
      ref.read(attendanceFiltersProvider.notifier).state = {
        ...filters,
        'search': value.isEmpty ? null : value,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Nurse Management',
        showBackButton: false,
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            _searchController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _searchController.text.length,
            );
            FocusScope.of(context).requestFocus();
          },
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              // Header with search and filters
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: HospitalTheme.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search nurses... (Ctrl+F)',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    HospitalTheme.buildGradientButton(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () {
                        ref.invalidate(nursesProvider);
                        ref.invalidate(attendanceProvider);
                      },
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: HospitalTheme.border),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Nurses Overview'),
                    Tab(text: 'Attendance Records'),
                    Tab(text: 'Manual Attendance'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNursesOverview(screenWidth, screenHeight),
                    _buildAttendanceRecords(screenWidth, screenHeight),
                    _buildManualAttendance(screenWidth, screenHeight),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNursesOverview(double screenWidth, double screenHeight) {
    final nursesAsync = ref.watch(nursesProvider);

    return nursesAsync.when(
      data: (nurses) => Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Total Nurses',
                    value: nurses.length.toString(),
                    icon: Icons.people,
                    iconColor: HospitalTheme.primary,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Available',
                    value: nurses
                        .where((n) => n.isAvailable == true)
                        .length
                        .toString(),
                    icon: Icons.check_circle,
                    iconColor: HospitalTheme.success,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Present Today',
                    value: nurses
                        .where((n) => n.status == 'Present')
                        .length
                        .toString(),
                    icon: Icons.access_time,
                    iconColor: HospitalTheme.info,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Admins',
                    value: nurses
                        .where((n) => n.usertype == 'nurseadmin')
                        .length
                        .toString(),
                    icon: Icons.admin_panel_settings,
                    iconColor: HospitalTheme.secondary,
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.03),

            // Nurses List
            Expanded(
              child: HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader('Nurses List'),
                    Expanded(
                      child: ListView.builder(
                        itemCount: nurses.length,
                        itemBuilder: (context, index) {
                          final nurse = nurses[index];
                          return _buildNurseListItem(nurse);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: HospitalTheme.error),
            const SizedBox(height: 16),
            Text('Error loading nurses: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(nursesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNurseListItem(Nurse nurse) {
    Color statusColor;
    IconData statusIcon;

    switch (nurse.status) {
      case 'Present':
        statusColor = HospitalTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'Absent':
        statusColor = HospitalTheme.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = HospitalTheme.warning;
        statusIcon = Icons.schedule;
    }

    return HospitalTheme.buildListTile(
      title: nurse.nurseName,
      subtitle: '${nurse.email} • ${nurse.usertype}',
      leading: CircleAvatar(
        backgroundColor: HospitalTheme.surfaceLight,
        child: Icon(
          nurse.usertype == 'nurseadmin'
              ? Icons.admin_panel_settings
              : Icons.local_hospital,
          color: HospitalTheme.primary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (nurse.isAvailable != null)
            HospitalTheme.buildStatusBadge(
              nurse.isAvailable! ? 'Available' : 'Busy',
              color: nurse.isAvailable!
                  ? HospitalTheme.success
                  : HospitalTheme.warning,
            ),
          const SizedBox(width: 8),
          HospitalTheme.buildStatusBadge(
            nurse.status,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Icon(statusIcon, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecords(double screenWidth, double screenHeight) {
    final filters = ref.watch(attendanceFiltersProvider);
    final attendanceAsync = ref.watch(attendanceProvider(filters));

    return Column(
      children: [
        // Filters
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border),
            ),
          ),
          child: _buildAttendanceFilters(),
        ),

        // Attendance Data
        Expanded(
          child: attendanceAsync.when(
            data: (attendanceResponse) => Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Column(
                children: [
                  // Statistics
                  Row(
                    children: [
                      Expanded(
                        child: HospitalTheme.buildStatCard(
                          title: 'Total Records',
                          value: attendanceResponse.statistics.total.toString(),
                          icon: Icons.list_alt,
                          iconColor: HospitalTheme.primary,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: HospitalTheme.buildStatCard(
                          title: 'Present',
                          value:
                              attendanceResponse.statistics.present.toString(),
                          icon: Icons.check_circle,
                          iconColor: HospitalTheme.success,
                          percentageChange:
                              '${attendanceResponse.statistics.presentPercentage.toStringAsFixed(1)}%',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: HospitalTheme.buildStatCard(
                          title: 'Absent',
                          value:
                              attendanceResponse.statistics.absent.toString(),
                          icon: Icons.cancel,
                          iconColor: HospitalTheme.error,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: HospitalTheme.buildStatCard(
                          title: 'Late',
                          value: attendanceResponse.statistics.late.toString(),
                          icon: Icons.schedule,
                          iconColor: HospitalTheme.warning,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Records List
                  Expanded(
                    child: HospitalTheme.buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HospitalTheme.buildSectionHeader(
                            'Attendance Records',
                            trailing: Text(
                              'Page ${attendanceResponse.pagination['currentPage']} of ${attendanceResponse.pagination['totalPages']}',
                              style: const TextStyle(
                                  color: HospitalTheme.textMedium),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount:
                                  attendanceResponse.attendanceRecords.length,
                              itemBuilder: (context, index) {
                                final record =
                                    attendanceResponse.attendanceRecords[index];
                                return _buildAttendanceRecord(record);
                              },
                            ),
                          ),
                          if (attendanceResponse.pagination['totalPages'] > 1)
                            _buildPagination(attendanceResponse.pagination),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: HospitalTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading attendance: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(attendanceProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceFilters() {
    final filters = ref.watch(attendanceFiltersProvider);
    final nursesAsync = ref.watch(nursesProvider);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Nurse Filter
        SizedBox(
          width: 200,
          child: nursesAsync.when(
            data: (nurses) => DropdownButtonFormField<String>(
              value: filters['nurseId'],
              decoration: const InputDecoration(
                labelText: 'Select Nurse',
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Nurses'),
                ),
                ...nurses.map((nurse) => DropdownMenuItem<String>(
                      value: nurse.id,
                      child: Text(nurse.nurseName),
                    )),
              ],
              onChanged: (value) {
                final newFilters = {...filters};
                newFilters['nurseId'] = value;
                ref.read(attendanceFiltersProvider.notifier).state = newFilters;
              },
            ),
            loading: () => DropdownButtonFormField<String>(
              items: [],
              onChanged: null,
              decoration: InputDecoration(
                labelText: 'Loading...',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            error: (_, __) => DropdownButtonFormField<String>(
              items: [],
              onChanged: null,
              decoration: InputDecoration(
                labelText: 'Error',
                prefixIcon: Icon(Icons.error),
              ),
            ),
          ),
        ),

        // Status Filter
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: filters['status'],
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.check_circle),
            ),
            items: const [
              DropdownMenuItem<String>(
                value: null,
                child: Text('All Status'),
              ),
              DropdownMenuItem<String>(
                value: 'Present',
                child: Text('Present'),
              ),
              DropdownMenuItem<String>(
                value: 'Absent',
                child: Text('Absent'),
              ),
              DropdownMenuItem<String>(
                value: 'Late',
                child: Text('Late'),
              ),
              DropdownMenuItem<String>(
                value: 'Half Day',
                child: Text('Half Day'),
              ),
            ],
            onChanged: (value) {
              final newFilters = {...filters};
              newFilters['status'] = value;
              ref.read(attendanceFiltersProvider.notifier).state = newFilters;
            },
          ),
        ),

        // Date Range
        SizedBox(
          width: 150,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Start Date',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final newFilters = {...filters};
                newFilters['startDate'] = DateFormat('yyyy-MM-dd').format(date);
                ref.read(attendanceFiltersProvider.notifier).state = newFilters;
              }
            },
            controller: TextEditingController(
              text: filters['startDate'] ?? '',
            ),
          ),
        ),

        SizedBox(
          width: 150,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'End Date',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final newFilters = {...filters};
                newFilters['endDate'] = DateFormat('yyyy-MM-dd').format(date);
                ref.read(attendanceFiltersProvider.notifier).state = newFilters;
              }
            },
            controller: TextEditingController(
              text: filters['endDate'] ?? '',
            ),
          ),
        ),

        // Clear Filters
        ElevatedButton.icon(
          onPressed: () {
            ref.read(attendanceFiltersProvider.notifier).state = {};
          },
          icon: const Icon(Icons.clear),
          label: const Text('Clear Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: HospitalTheme.error,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRecord(AttendanceRecord record) {
    Color statusColor;
    IconData statusIcon;

    switch (record.status) {
      case 'Present':
        statusColor = HospitalTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'Absent':
        statusColor = HospitalTheme.error;
        statusIcon = Icons.cancel;
        break;
      case 'Late':
        statusColor = HospitalTheme.warning;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = HospitalTheme.info;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: HospitalTheme.border),
        borderRadius: HospitalTheme.radiusSmall,
      ),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          record.nurse?.email ?? 'Unknown Nurse',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy').format(record.date),
          style: const TextStyle(color: HospitalTheme.textMedium),
        ),
        trailing: HospitalTheme.buildStatusBadge(
          record.status,
          color: statusColor,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.checkIn != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.login,
                          size: 16, color: HospitalTheme.success),
                      const SizedBox(width: 8),
                      Text(
                        'Check In: ${DateFormat('HH:mm:ss').format(record.checkIn!.time)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (record.checkIn!.isWithinRadius == true) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on,
                            size: 16, color: HospitalTheme.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (record.checkOut != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.logout,
                          size: 16, color: HospitalTheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'Check Out: ${DateFormat('HH:mm:ss').format(record.checkOut!.time)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (record.checkOut!.isWithinRadius == true) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on,
                            size: 16, color: HospitalTheme.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (record.totalHours != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: HospitalTheme.info),
                      const SizedBox(width: 8),
                      Text(
                        'Total Hours: ${record.totalHours!.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (record.notes != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes,
                          size: 16, color: HospitalTheme.textMedium),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notes: ${record.notes}',
                          style:
                              const TextStyle(color: HospitalTheme.textMedium),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(Map<String, dynamic> pagination) {
    final currentPage = pagination['currentPage'] ?? 1;
    final totalPages = pagination['totalPages'] ?? 1;
    final hasNextPage = pagination['hasNextPage'] ?? false;
    final hasPrevPage = pagination['hasPrevPage'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: HospitalTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${pagination['totalRecords'] ?? 0} records',
            style: const TextStyle(color: HospitalTheme.textMedium),
          ),
          Row(
            children: [
              IconButton(
                onPressed: hasPrevPage
                    ? () {
                        final filters = ref.read(attendanceFiltersProvider);
                        ref.read(attendanceFiltersProvider.notifier).state = {
                          ...filters,
                          'page': currentPage - 1,
                        };
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$currentPage / $totalPages'),
              IconButton(
                onPressed: hasNextPage
                    ? () {
                        final filters = ref.read(attendanceFiltersProvider);
                        ref.read(attendanceFiltersProvider.notifier).state = {
                          ...filters,
                          'page': currentPage + 1,
                        };
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualAttendance(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.02),
      child: HospitalTheme.buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HospitalTheme.buildSectionHeader('Manual Attendance Marking'),
            Expanded(
              child: _ManualAttendanceForm(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualAttendanceForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManualAttendanceForm> createState() =>
      _ManualAttendanceFormState();
}

class _ManualAttendanceFormState extends ConsumerState<_ManualAttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedNurseId;
  String? _selectedStatus = 'Present';
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNurseId == null || _selectedDate == null) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await NurseApiService.markAttendanceManually(
        nurseId: _selectedNurseId!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        status: _selectedStatus!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (success) {
        // Refresh attendance data
        ref.invalidate(attendanceProvider);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance marked successfully'),
              backgroundColor: HospitalTheme.success,
            ),
          );
        }

        // Clear form
        _clearForm();
      } else {
        throw Exception('Failed to mark attendance');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedNurseId = null;
      _selectedStatus = 'Present';
      _selectedDate = null;
    });
    _notesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final nursesAsync = ref.watch(nursesProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.info.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusSmall,
                border: Border.all(color: HospitalTheme.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: HospitalTheme.info),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Use this form to manually mark attendance when automatic check-in/out is not available (e.g., biometric system issues).',
                      style: TextStyle(color: HospitalTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Fields
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nurse Selection
                      const Text(
                        'Select Nurse *',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      nursesAsync.when(
                        data: (nurses) => DropdownButtonFormField<String>(
                          value: _selectedNurseId,
                          decoration: InputDecoration(
                            hintText: 'Choose a nurse',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: HospitalTheme.radiusSmall,
                            ),
                          ),
                          validator: (value) =>
                              value == null ? 'Please select a nurse' : null,
                          items: nurses
                              .map((nurse) => DropdownMenuItem<String>(
                                    value: nurse.id,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          nurse.nurseName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          nurse.email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: HospitalTheme.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedNurseId = value),
                        ),
                        loading: () => DropdownButtonFormField<String>(
                          items: [],
                          onChanged: null,
                          decoration: InputDecoration(
                            hintText: 'Loading nurses...',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        error: (error, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HospitalTheme.error.withOpacity(0.1),
                            borderRadius: HospitalTheme.radiusSmall,
                          ),
                          child: Text('Error loading nurses: $error'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Date Selection
                      const Text(
                        'Date *',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Select date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _selectedDate = null),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                          ),
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: _selectedDate != null
                              ? DateFormat('MMM dd, yyyy')
                                  .format(_selectedDate!)
                              : '',
                        ),
                        validator: (value) => _selectedDate == null
                            ? 'Please select a date'
                            : null,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(width: screenWidth * 0.03),

                // Right Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Selection
                      const Text(
                        'Attendance Status *',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.check_circle),
                          border: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Present',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: HospitalTheme.success, size: 20),
                                SizedBox(width: 8),
                                Text('Present'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Absent',
                            child: Row(
                              children: [
                                Icon(Icons.cancel,
                                    color: HospitalTheme.error, size: 20),
                                SizedBox(width: 8),
                                Text('Absent'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Late',
                            child: Row(
                              children: [
                                Icon(Icons.schedule,
                                    color: HospitalTheme.warning, size: 20),
                                SizedBox(width: 8),
                                Text('Late'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Half Day',
                            child: Row(
                              children: [
                                Icon(Icons.access_time,
                                    color: HospitalTheme.info, size: 20),
                                SizedBox(width: 8),
                                Text('Half Day'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedStatus = value),
                      ),

                      const SizedBox(height: 24),

                      // Notes
                      const Text(
                        'Notes (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Add any relevant notes (e.g., "Biometric system issue - attendance verified with supervisor")',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _clearForm,
                  child: const Text('Clear Form'),
                ),
                const SizedBox(width: 16),
                HospitalTheme.buildGradientButton(
                  label: 'Mark Attendance',
                  icon: Icons.save,
                  onPressed: _isSubmitting ? () {} : _submitAttendance,
                  isLoading: _isSubmitting,
                  width: 180,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Manual Entries
            HospitalTheme.buildDividerWithLabel('Recent Manual Entries'),

            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final recentAttendance = ref.watch(attendanceProvider({
                  'limit': 5,
                  'sortBy': 'date',
                  'sortOrder': 'desc',
                }));

                return recentAttendance.when(
                  data: (data) => data.attendanceRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'No recent entries',
                            style: TextStyle(color: HospitalTheme.textMedium),
                          ),
                        )
                      : Column(
                          children: data.attendanceRecords
                              .take(3)
                              .map(
                                (record) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: HospitalTheme.surfaceLight,
                                    borderRadius: HospitalTheme.radiusSmall,
                                    border:
                                        Border.all(color: HospitalTheme.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        record.status == 'Present'
                                            ? Icons.check_circle
                                            : record.status == 'Absent'
                                                ? Icons.cancel
                                                : Icons.schedule,
                                        color: record.status == 'Present'
                                            ? HospitalTheme.success
                                            : record.status == 'Absent'
                                                ? HospitalTheme.error
                                                : HospitalTheme.warning,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record.nurse?.email ?? 'Unknown',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${DateFormat('MMM dd, yyyy').format(record.date)} - ${record.status}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: HospitalTheme.textMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      HospitalTheme.buildStatusBadge(
                                        record.status,
                                        color: record.status == 'Present'
                                            ? HospitalTheme.success
                                            : record.status == 'Absent'
                                                ? HospitalTheme.error
                                                : HospitalTheme.warning,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
