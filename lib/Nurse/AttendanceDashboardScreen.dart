// models/attendance_model.dart
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceRecord {
  final String id;
  final String nurseId;
  final DateTime date;
  final String status;
  final String notes;
  final CheckInOut? checkIn;
  final CheckInOut? checkOut;
  final double? totalHours;
  final NurseInfo nurse;

  const AttendanceRecord({
    required this.id,
    required this.nurseId,
    required this.date,
    required this.status,
    required this.notes,
    this.checkIn,
    this.checkOut,
    this.totalHours,
    required this.nurse,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? '',
      nurseId: json['nurseId'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      checkIn:
          json['checkIn'] != null ? CheckInOut.fromJson(json['checkIn']) : null,
      checkOut: json['checkOut'] != null
          ? CheckInOut.fromJson(json['checkOut'])
          : null,
      totalHours: json['totalHours']?.toDouble(),
      nurse: NurseInfo.fromJson(json['nurse'] ?? {}),
    );
  }
}

class CheckInOut {
  final DateTime time;
  final double? latitude;
  final double? longitude;
  final bool isWithinRadius;

  const CheckInOut({
    required this.time,
    this.latitude,
    this.longitude,
    required this.isWithinRadius,
  });

  factory CheckInOut.fromJson(Map<String, dynamic> json) {
    return CheckInOut(
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isWithinRadius: json['isWithinRadius'] ?? false,
    );
  }
}

class NurseInfo {
  final String id;
  final String name;
  final String nurseName;
  final String email;
  final String usertype;

  const NurseInfo({
    required this.id,
    required this.name,
    required this.nurseName,
    required this.email,
    required this.usertype,
  });

  factory NurseInfo.fromJson(Map<String, dynamic> json) {
    return NurseInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? json['nurseName'] ?? '',
      nurseName: json['nurseName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      usertype: json['usertype'] ?? '',
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

class NurseAttendanceData {
  final List<AttendanceRecord> attendanceRecords;
  final AttendanceStatistics statistics;
  final Map<String, dynamic> filters;

  const NurseAttendanceData({
    required this.attendanceRecords,
    required this.statistics,
    required this.filters,
  });

  factory NurseAttendanceData.fromJson(Map<String, dynamic> json) {
    return NurseAttendanceData(
      attendanceRecords: (json['attendanceRecords'] as List<dynamic>?)
              ?.map((e) => AttendanceRecord.fromJson(e))
              .toList() ??
          [],
      statistics: AttendanceStatistics.fromJson(json['statistics'] ?? {}),
      filters: json['filters'] ?? {},
    );
  }
}

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
      status: json['status'] ?? 'Not Checked In',
      isAvailable: json['isAvailable'],
    );
  }
}

// API Service
class AttendanceService {
  Future<List<Nurse>> getAllNurses() async {
    try {
      final response = await http.get(
        Uri.parse('$KVM_URL/nurse/getAllNurses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['nurses'] != null) {
          return (data['nurses'] as List)
              .map((nurseJson) => Nurse.fromJson(nurseJson))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch nurses: $e');
    }
  }

  Future<NurseAttendanceData> getAllNurseAttendance({
    String? nurseId,
    String? status,
    String? date,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (nurseId != null) queryParams['nurseId'] = nurseId;
      if (status != null) queryParams['status'] = status;
      if (date != null) queryParams['date'] = date;

      final uri = Uri.parse('$KVM_URL/nurse/getAllNurseAttendance')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['success'] == true && data['data'] != null) {
          return NurseAttendanceData.fromJson(data['data']);
        }
      }
      return const NurseAttendanceData(
        attendanceRecords: [],
        statistics: AttendanceStatistics(
          total: 0,
          present: 0,
          absent: 0,
          late: 0,
          halfDay: 0,
          presentPercentage: 0,
        ),
        filters: {},
      );
    } catch (e) {
      throw Exception('Failed to fetch attendance data: $e');
    }
  }
}

// State Management
class AttendanceState {
  final List<Nurse> nurses;
  final NurseAttendanceData attendanceData;
  final bool isLoading;
  final String? error;
  final Nurse? selectedNurse;
  final AttendanceRecord? selectedRecord;
  final String selectedDateFilter;

  const AttendanceState({
    this.nurses = const [],
    this.attendanceData = const NurseAttendanceData(
      attendanceRecords: [],
      statistics: AttendanceStatistics(
        total: 0,
        present: 0,
        absent: 0,
        late: 0,
        halfDay: 0,
        presentPercentage: 0,
      ),
      filters: {},
    ),
    this.isLoading = false,
    this.error,
    this.selectedNurse,
    this.selectedRecord,
    this.selectedDateFilter = 'all',
  });

  AttendanceState copyWith({
    List<Nurse>? nurses,
    NurseAttendanceData? attendanceData,
    bool? isLoading,
    String? error,
    Nurse? selectedNurse,
    AttendanceRecord? selectedRecord,
    String? selectedDateFilter,
  }) {
    return AttendanceState(
      nurses: nurses ?? this.nurses,
      attendanceData: attendanceData ?? this.attendanceData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedNurse: selectedNurse ?? this.selectedNurse,
      selectedRecord: selectedRecord ?? this.selectedRecord,
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
    );
  }
}

// Providers
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ref.watch(attendanceServiceProvider));
});

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceService _service;

  AttendanceNotifier(this._service) : super(const AttendanceState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final nurses = await _service.getAllNurses();
      final attendanceData = await _service.getAllNurseAttendance();

      state = state.copyWith(
        nurses: nurses,
        attendanceData: attendanceData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> selectNurse(Nurse nurse) async {
    state = state.copyWith(selectedNurse: nurse, isLoading: true);

    try {
      final attendanceData = await _service.getAllNurseAttendance(
        nurseId: nurse.id,
      );

      state = state.copyWith(
        attendanceData: attendanceData,
        isLoading: false,
        selectedRecord: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectRecord(AttendanceRecord record) {
    state = state.copyWith(selectedRecord: record);
  }

  void clearSelection() {
    state = state.copyWith(
      selectedNurse: null,
      selectedRecord: null,
    );
    loadData();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Main Screen
class NurseAttendanceDashboard extends ConsumerStatefulWidget {
  const NurseAttendanceDashboard({super.key});

  @override
  ConsumerState<NurseAttendanceDashboard> createState() =>
      _NurseAttendanceDashboardState();
}

class _NurseAttendanceDashboardState
    extends ConsumerState<NurseAttendanceDashboard> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Nurse Attendance Dashboard',
          showBackButton: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(attendanceProvider.notifier).loadData(),
              tooltip: 'Refresh Data (F5)',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: const AttendanceDashboardLayout(),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        ref.read(attendanceProvider.notifier).loadData();
      } else if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyR) {
        ref.read(attendanceProvider.notifier).loadData();
      }
    }
  }
}

class AttendanceDashboardLayout extends ConsumerWidget {
  const AttendanceDashboardLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);

    if (state.isLoading && state.nurses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _ErrorWidget(
        error: state.error!,
        onRetry: () => ref.read(attendanceProvider.notifier).loadData(),
      );
    }

    return Row(
      children: [
        // Column 1: Nurses List (25%)
        Expanded(
          flex: 25,
          child: _NursesColumn(
            nurses: state.nurses,
            selectedNurse: state.selectedNurse,
            onNurseSelected: (nurse) =>
                ref.read(attendanceProvider.notifier).selectNurse(nurse),
            onClearSelection: () =>
                ref.read(attendanceProvider.notifier).clearSelection(),
          ),
        ),

        // Divider
        Container(width: 1, color: HospitalTheme.border),

        // Column 2: Attendance Records (45%)
        Expanded(
          flex: 45,
          child: _AttendanceRecordsColumn(
            attendanceData: state.attendanceData,
            selectedNurse: state.selectedNurse,
            selectedRecord: state.selectedRecord,
            isLoading: state.isLoading,
            onRecordSelected: (record) =>
                ref.read(attendanceProvider.notifier).selectRecord(record),
          ),
        ),

        // Divider
        Container(width: 1, color: HospitalTheme.border),

        // Column 3: Details & Statistics (30%)
        Expanded(
          flex: 30,
          child: _DetailsColumn(
            selectedRecord: state.selectedRecord,
            statistics: state.attendanceData.statistics,
            selectedNurse: state.selectedNurse,
          ),
        ),
      ],
    );
  }
}

// Column 1: Nurses List
class _NursesColumn extends StatefulWidget {
  final List<Nurse> nurses;
  final Nurse? selectedNurse;
  final Function(Nurse) onNurseSelected;
  final VoidCallback onClearSelection;

  const _NursesColumn({
    required this.nurses,
    required this.selectedNurse,
    required this.onNurseSelected,
    required this.onClearSelection,
  });

  @override
  State<_NursesColumn> createState() => _NursesColumnState();
}

class _NursesColumnState extends State<_NursesColumn> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  static const List<String> statusFilters = [
    'All',
    'Present',
    'Half-Day',
    'Not Checked In',
    'Absent'
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNurses = _getFilteredNurses();

    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, color: HospitalTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Nurses (${filteredNurses.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const Spacer(),
                    if (widget.selectedNurse != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: widget.onClearSelection,
                        tooltip: 'Clear Selection',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search Bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search nurses...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Status Filter
                DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: statusFilters
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statusFilter = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Nurses List
          Expanded(
            child: filteredNurses.isEmpty
                ? const Center(
                    child: Text(
                      'No nurses found',
                      style: TextStyle(color: HospitalTheme.textMedium),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNurses.length,
                    itemBuilder: (context, index) {
                      final nurse = filteredNurses[index];
                      final isSelected = widget.selectedNurse?.id == nurse.id;

                      return _NurseCard(
                        nurse: nurse,
                        isSelected: isSelected,
                        onTap: () => widget.onNurseSelected(nurse),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Nurse> _getFilteredNurses() {
    return widget.nurses.where((nurse) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            nurse.nurseName.toLowerCase().contains(_searchQuery) ||
                nurse.email.toLowerCase().contains(_searchQuery);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (_statusFilter != 'All') {
        if (nurse.status != _statusFilter) return false;
      }

      return true;
    }).toList();
  }
}

class _NurseCard extends StatelessWidget {
  final Nurse nurse;
  final bool isSelected;
  final VoidCallback onTap;

  const _NurseCard({
    required this.nurse,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(nurse.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? HospitalTheme.shadowSmall : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: HospitalTheme.radiusSmall,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.person,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nurse.nurseName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? HospitalTheme.primary
                                : HospitalTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nurse.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getUserTypeColor(nurse.usertype).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      nurse.usertype.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getUserTypeColor(nurse.usertype),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      nurse.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return HospitalTheme.success;
      case 'half-day':
        return HospitalTheme.warning;
      case 'absent':
        return HospitalTheme.error;
      default:
        return HospitalTheme.textMedium;
    }
  }

  Color _getUserTypeColor(String usertype) {
    switch (usertype.toLowerCase()) {
      case 'nurse':
        return HospitalTheme.primary;
      case 'nurseadmin':
        return HospitalTheme.secondary;
      default:
        return HospitalTheme.textMedium;
    }
  }
}

// Column 2: Attendance Records
class _AttendanceRecordsColumn extends StatelessWidget {
  final NurseAttendanceData attendanceData;
  final Nurse? selectedNurse;
  final AttendanceRecord? selectedRecord;
  final bool isLoading;
  final Function(AttendanceRecord) onRecordSelected;

  const _AttendanceRecordsColumn({
    required this.attendanceData,
    required this.selectedNurse,
    required this.selectedRecord,
    required this.isLoading,
    required this.onRecordSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: HospitalTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      selectedNurse != null
                          ? 'Attendance - ${selectedNurse!.nurseName}'
                          : 'All Attendance Records',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${attendanceData.attendanceRecords.length} records',
                  style: const TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : attendanceData.attendanceRecords.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: HospitalTheme.textLight,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No attendance records found',
                              style: TextStyle(
                                fontSize: 16,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: attendanceData.attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record =
                              attendanceData.attendanceRecords[index];
                          final isSelected = selectedRecord?.id == record.id;

                          return _AttendanceRecordCard(
                            record: record,
                            isSelected: isSelected,
                            onTap: () => onRecordSelected(record),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _AttendanceRecordCard({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? HospitalTheme.shadowSmall : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: HospitalTheme.radiusSmall,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getStatusIcon(record.status),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.nurse.nurseName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? HospitalTheme.primary
                                : HospitalTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(record.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (record.checkIn != null) ...[
                    Icon(Icons.login, size: 16, color: HospitalTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(record.checkIn!.time),
                      style: const TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                  if (record.checkIn != null && record.checkOut != null)
                    const SizedBox(width: 16),
                  if (record.checkOut != null) ...[
                    Icon(Icons.logout, size: 16, color: HospitalTheme.error),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(record.checkOut!.time),
                      style: const TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (record.totalHours != null)
                    Text(
                      '${record.totalHours!.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return HospitalTheme.success;
      case 'half-day':
        return HospitalTheme.warning;
      case 'absent':
        return HospitalTheme.error;
      case 'late':
        return HospitalTheme.warning;
      default:
        return HospitalTheme.textMedium;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'half-day':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Column 3: Details & Statistics
class _DetailsColumn extends StatelessWidget {
  final AttendanceRecord? selectedRecord;
  final AttendanceStatistics statistics;
  final Nurse? selectedNurse;

  const _DetailsColumn({
    required this.selectedRecord,
    required this.statistics,
    required this.selectedNurse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: HospitalTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Details & Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  _buildStatisticsSection(),

                  const SizedBox(height: 24),

                  // Selected Record Details
                  if (selectedRecord != null)
                    _buildRecordDetails()
                  else
                    _buildNoSelectionMessage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedNurse != null
              ? '${selectedNurse!.nurseName} Statistics'
              : 'Overall Statistics',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total Records',
          statistics.total.toString(),
          Icons.assignment,
          HospitalTheme.primary,
        ),
        const SizedBox(height: 8),
        _buildStatCard(
          'Present',
          statistics.present.toString(),
          Icons.check_circle,
          HospitalTheme.success,
        ),
        const SizedBox(height: 8),
        _buildStatCard(
          'Half-Day',
          statistics.halfDay.toString(),
          Icons.schedule,
          HospitalTheme.warning,
        ),
        const SizedBox(height: 8),
        _buildStatCard(
          'Absent',
          statistics.absent.toString(),
          Icons.cancel,
          HospitalTheme.error,
        ),
        const SizedBox(height: 8),
        _buildStatCard(
          'Late',
          statistics.late.toString(),
          Icons.access_time,
          HospitalTheme.warning,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.primary.withOpacity(0.1),
            borderRadius: HospitalTheme.radiusSmall,
            border: Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.percent, color: HospitalTheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${statistics.presentPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                    ),
                  ),
                  const Text(
                    'Attendance Rate',
                    style: TextStyle(
                      fontSize: 14,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Record Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nurse', selectedRecord!.nurse.nurseName),
              _buildDetailRow('Date', _formatDate(selectedRecord!.date)),
              _buildDetailRow('Status', selectedRecord!.status),
              if (selectedRecord!.checkIn != null)
                _buildDetailRow(
                    'Check In', _formatDateTime(selectedRecord!.checkIn!.time)),
              if (selectedRecord!.checkOut != null)
                _buildDetailRow('Check Out',
                    _formatDateTime(selectedRecord!.checkOut!.time)),
              if (selectedRecord!.totalHours != null)
                _buildDetailRow('Total Hours',
                    '${selectedRecord!.totalHours!.toStringAsFixed(2)} hours'),
              if (selectedRecord!.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Notes:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedRecord!.notes,
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelectionMessage() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 64,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a record to view details',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: HospitalTheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
