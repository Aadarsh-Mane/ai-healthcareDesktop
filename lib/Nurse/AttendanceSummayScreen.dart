import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Models
class AttendanceSummary {
  final String message;
  final OverallStats overallStats;
  final List<AttendanceGroup> data;

  const AttendanceSummary({
    required this.message,
    required this.overallStats,
    required this.data,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing AttendanceSummary: $json');

      final overallStatsJson = json['overallStats'];
      print('OverallStats JSON: $overallStatsJson');

      final dataJson = json['data'];
      print('Data JSON: $dataJson');

      return AttendanceSummary(
        message: json['message'] ?? '',
        overallStats: OverallStats.fromJson(overallStatsJson ?? {}),
        data: (dataJson as List<dynamic>? ?? []).map((item) {
          print('Parsing AttendanceGroup item: $item');
          return AttendanceGroup.fromJson(item);
        }).toList(),
      );
    } catch (e, stackTrace) {
      print('Error parsing AttendanceSummary: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class OverallStats {
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final int halfDay;

  const OverallStats({
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
  });

  factory OverallStats.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing OverallStats: $json');
      return OverallStats(
        totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        late: (json['late'] as num?)?.toInt() ?? 0,
        halfDay: (json['halfDay'] as num?)?.toInt() ?? 0,
      );
    } catch (e, stackTrace) {
      print('Error parsing OverallStats: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class AttendanceGroup {
  final String id;
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int totalHours;
  final List<AttendanceRecord> records;

  const AttendanceGroup({
    required this.id,
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.totalHours,
    required this.records,
  });

  factory AttendanceGroup.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing AttendanceGroup: $json');

      final recordsJson = json['records'];
      print('Records JSON: $recordsJson');

      return AttendanceGroup(
        id: json['_id']?.toString() ?? '',
        totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        late: (json['late'] as num?)?.toInt() ?? 0,
        halfDay: (json['halfDay'] as num?)?.toInt() ?? 0,
        totalHours: (json['totalHours'] as num?)?.toInt() ?? 0,
        records: (recordsJson as List<dynamic>? ?? []).map((item) {
          print('Parsing AttendanceRecord item: $item');
          return AttendanceRecord.fromJson(item);
        }).toList(),
      );
    } catch (e, stackTrace) {
      print('Error parsing AttendanceGroup: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class AttendanceRecord {
  final String id;
  final String nurseId;
  final DateTime date;
  final CheckInInfo? checkIn;
  final CheckInInfo? checkOut;
  final String status;
  final String? notes;
  final Nurse? nurseInfo;

  const AttendanceRecord({
    required this.id,
    required this.nurseId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.notes,
    this.nurseInfo,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing AttendanceRecord: $json');

      return AttendanceRecord(
        id: json['_id']?.toString() ?? '',
        nurseId: json['nurseId']?.toString() ?? '',
        date:
            DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        checkIn: json['checkIn'] != null
            ? CheckInInfo.fromJson(json['checkIn'])
            : null,
        checkOut: json['checkOut'] != null
            ? CheckInInfo.fromJson(json['checkOut'])
            : null,
        status: json['status']?.toString() ?? 'Unknown',
        notes: json['notes']?.toString(),
        nurseInfo: json['nurseInfo'] != null
            ? Nurse.fromJson(json['nurseInfo'])
            : null,
      );
    } catch (e, stackTrace) {
      print('Error parsing AttendanceRecord: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class CheckInInfo {
  final DateTime time;
  final double? latitude;
  final double? longitude;
  final bool? isWithinRadius;

  const CheckInInfo({
    required this.time,
    this.latitude,
    this.longitude,
    this.isWithinRadius,
  });

  factory CheckInInfo.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing CheckInInfo: $json');
      return CheckInInfo(
        time:
            DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isWithinRadius: json['isWithinRadius'] as bool?,
      );
    } catch (e, stackTrace) {
      print('Error parsing CheckInInfo: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
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
    try {
      print('Parsing Nurse: $json');
      return Nurse(
        id: json['_id']?.toString() ?? '',
        nurseName: json['nurseName']?.toString() ?? 'Unknown',
        email: json['email']?.toString() ?? '',
        usertype: json['usertype']?.toString() ?? 'nurse',
        status: json['status']?.toString() ?? 'Not Checked In',
        isAvailable: json['isAvailable'] as bool?,
      );
    } catch (e, stackTrace) {
      print('Error parsing Nurse: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

// Create a proper parameters class for the provider
class AttendanceParams {
  final String? startDate;
  final String? endDate;
  final String? groupBy;

  const AttendanceParams({
    this.startDate,
    this.endDate,
    this.groupBy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceParams &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          groupBy == other.groupBy;

  @override
  int get hashCode => Object.hash(startDate, endDate, groupBy);

  @override
  String toString() =>
      'AttendanceParams(startDate: $startDate, endDate: $endDate, groupBy: $groupBy)';
}

// Updated API Service with better error handling
class NurseApiService {
  static const String baseUrl = 'http://localhost:5001';

  Future<List<Nurse>> getAllNurses() async {
    try {
      print('Fetching nurses...');
      final response = await http.get(
        Uri.parse('$baseUrl/nurse/getAllNurses'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Nurses response status: ${response.statusCode}');
      print('Nurses response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nurses = (data['nurses'] as List<dynamic>? ?? [])
            .map((item) => Nurse.fromJson(item))
            .toList();
        print('Parsed ${nurses.length} nurses');
        return nurses;
      }
      throw Exception('Failed to load nurses. Status: ${response.statusCode}');
    } catch (e, stackTrace) {
      print('Error fetching nurses: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<AttendanceSummary> getAttendanceSummary({
    String? startDate,
    String? endDate,
    String? groupBy,
  }) async {
    try {
      print(
          'Fetching attendance summary with params: startDate=$startDate, endDate=$endDate, groupBy=$groupBy');

      // Build query parameters
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (groupBy != null) queryParams['groupBy'] = groupBy;

      // Create URI with query parameters
      final uri = Uri.parse('$baseUrl/nurse/getAttendanceSummary').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Attendance response status: ${response.statusCode}');
      print('Attendance response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final summary = AttendanceSummary.fromJson(data);
        print('Successfully parsed attendance summary');
        return summary;
      }
      throw Exception(
          'Failed to load attendance summary. Status: ${response.statusCode}');
    } catch (e, stackTrace) {
      print('Error fetching attendance summary: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> markAttendanceManually({
    required String nurseId,
    required String date,
    required String status,
    String? notes,
  }) async {
    try {
      print('Marking attendance for nurse: $nurseId');

      final response = await http.post(
        Uri.parse('$baseUrl/nurse/markAttendanceManually'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nurseId': nurseId,
          'date': date,
          'status': status,
          'notes': notes ?? '',
        }),
      );

      print('Mark attendance response status: ${response.statusCode}');
      print('Mark attendance response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      print('Error marking attendance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

// Updated Providers

final nurseApiServiceProvider =
    Provider<NurseApiService>((ref) => NurseApiService());

final nursesProvider = FutureProvider<List<Nurse>>((ref) async {
  final apiService = ref.read(nurseApiServiceProvider);
  return apiService.getAllNurses();
});

// Fixed provider using individual parameters instead of AttendanceParams
final attendanceSummaryProvider =
    FutureProvider.family<AttendanceSummary, AttendanceParams>(
        (ref, params) async {
  final apiService = ref.read(nurseApiServiceProvider);
  return apiService.getAttendanceSummary(
    startDate: params.startDate,
    endDate: params.endDate,
    groupBy: params.groupBy,
  );
});
final viewModeProvider = StateProvider<String>((ref) => 'calendar');
final selectedGroupByProvider = StateProvider<String>((ref) => 'date');
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final calendarFormatProvider =
    StateProvider<CalendarFormat>((ref) => CalendarFormat.month);

// Main Screen
class NurseManagementScreen extends ConsumerStatefulWidget {
  const NurseManagementScreen({super.key});

  @override
  ConsumerState<NurseManagementScreen> createState() =>
      _NurseManagementScreenState();
}

class _NurseManagementScreenState extends ConsumerState<NurseManagementScreen> {
  String? _selectedNurseId;
  final _markAttendanceFormKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedStatus = 'Present';

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              _showSearchDialog(),
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
              _showSearchDialog(),
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
              _refreshData(),
          const SingleActivator(LogicalKeyboardKey.keyR, meta: true): () =>
              _refreshData(),
        },
        child: Focus(
          autofocus: true,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(screenWidth),
                SizedBox(height: screenHeight * 0.02),
                _buildFilters(screenWidth),
                SizedBox(height: screenHeight * 0.02),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Panel - Nurses List
                      Expanded(
                        flex: 4,
                        child: _buildNursesPanel(screenHeight),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      // Right Panel - Attendance Summary
                      Expanded(
                        flex: 6,
                        child: _buildAttendancePanel(screenHeight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_hospital_outlined,
            size: 32,
            color: HospitalTheme.primary,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nurse Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              Text(
                'Monitor attendance and manage nursing staff',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
          const Spacer(),
          Tooltip(
            message: 'Search (Ctrl+F)',
            child: IconButton(
              onPressed: _showSearchDialog,
              icon: const Icon(Icons.search),
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Refresh (Ctrl+R)',
            child: IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showMarkAttendanceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Mark Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(double screenWidth) {
    final groupBy = ref.watch(selectedGroupByProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Row(
        children: [
          Text(
            'Group By:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: groupBy,
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedGroupByProvider.notifier).state = value;
              }
            },
            items: const [
              DropdownMenuItem(value: 'date', child: Text('Date')),
              DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
              DropdownMenuItem(value: 'status', child: Text('Status')),
              DropdownMenuItem(value: 'day', child: Text('Day')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
            ],
          ),
          const SizedBox(width: 24),
          Text(
            'Date Range:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(
              dateRange != null
                  ? '${DateFormat('MMM dd').format(dateRange.start)} - ${DateFormat('MMM dd').format(dateRange.end)}'
                  : 'Select Range',
            ),
          ),
          if (dateRange != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () =>
                  ref.read(selectedDateRangeProvider.notifier).state = null,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date range',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNursesPanel(double screenHeight) {
    final nursesAsync = ref.watch(nursesProvider);

    return HospitalTheme.buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: HospitalTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nursing Staff',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: nursesAsync.when(
              data: (nurses) => _buildNursesList(nurses, screenHeight),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  _buildErrorWidget('Failed to load nurses', error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNursesList(List<Nurse> nurses, double screenHeight) {
    if (nurses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No nurses found',
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: nurses.length,
      itemBuilder: (context, index) {
        final nurse = nurses[index];
        return _buildNurseCard(nurse);
      },
    );
  }

  Widget _buildNurseCard(Nurse nurse) {
    Color statusColor;
    IconData statusIcon;

    switch (nurse.status.toLowerCase()) {
      case 'present':
        statusColor = HospitalTheme.success;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'absent':
        statusColor = HospitalTheme.error;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'late':
        statusColor = HospitalTheme.warning;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = HospitalTheme.textMedium;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: HospitalTheme.buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: HospitalTheme.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: HospitalTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nurse.nurseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nurse.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: nurse.usertype == 'nurseadmin'
                                  ? HospitalTheme.primary.withOpacity(0.1)
                                  : HospitalTheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              nurse.usertype == 'nurseadmin'
                                  ? 'Admin'
                                  : 'Nurse',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: nurse.usertype == 'nurseadmin'
                                    ? HospitalTheme.primary
                                    : HospitalTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nurse.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (nurse.isAvailable != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: nurse.isAvailable!
                              ? HospitalTheme.success
                              : HospitalTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showMarkAttendanceDialog(nurseId: nurse.id),
                  icon: const Icon(Icons.access_time, size: 16),
                  label: const Text('Mark'),
                  style: TextButton.styleFrom(
                    foregroundColor: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Update the _buildAttendancePanel method to handle filters properly
  Widget _buildAttendancePanel(double screenHeight) {
    final viewMode = ref.watch(viewModeProvider);
    final groupBy = ref.watch(selectedGroupByProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);

    return HospitalTheme.buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  viewMode == 'calendar'
                      ? Icons.calendar_today
                      : Icons.assessment_outlined,
                  color: HospitalTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  viewMode == 'calendar'
                      ? 'Attendance Calendar'
                      : 'Attendance Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const Spacer(),
                // Toggle between calendar and summary view
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'calendar',
                      label: Text('Calendar'),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: 'summary',
                      label: Text('Summary'),
                      icon: Icon(Icons.list, size: 16),
                    ),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (Set<String> selection) {
                    ref.read(viewModeProvider.notifier).state = selection.first;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: viewMode == 'calendar'
                ? _buildCalendarView(screenHeight)
                : _buildSummaryView(screenHeight),
          ),
        ],
      ),
    );
  }

// Separate calendar view
  Widget _buildCalendarView(double screenHeight) {
    final selectedDate = ref.watch(selectedDateProvider);
    final calendarFormat = ref.watch(calendarFormatProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);

    return Column(
      children: [
        // Calendar - Fixed height
        SizedBox(
          height: screenHeight * 0.4, // Fixed height for calendar
          child: Container(
            padding: const EdgeInsets.all(16),
            child: _buildCalendar(selectedDate, calendarFormat, dateRange),
          ),
        ),
        const Divider(height: 1),
        // Selected date attendance - Remaining space
        Expanded(
          child: _buildSelectedDateAttendance(selectedDate),
        ),
      ],
    );
  }

// Separate summary view that respects filters
  Widget _buildSummaryView(double screenHeight) {
    final groupBy = ref.watch(selectedGroupByProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);

    final params = AttendanceParams(
      groupBy: groupBy,
      startDate: dateRange?.start != null
          ? DateFormat('yyyy-MM-dd').format(dateRange!.start)
          : null,
      endDate: dateRange?.end != null
          ? DateFormat('yyyy-MM-dd').format(dateRange!.end)
          : null,
    );

    final attendanceAsync = ref.watch(attendanceSummaryProvider(params));

    return attendanceAsync.when(
      data: (summary) {
        print('Summary view: Received ${summary.data.length} groups');
        return _buildAttendanceSummary(summary, screenHeight);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(
        'Failed to load attendance summary',
        error.toString(),
      ),
    );
  }

// Update the _buildCalendar method to use filters properly
  Widget _buildCalendar(DateTime selectedDate, CalendarFormat calendarFormat,
      DateTimeRange? dateRange) {
    // Calculate proper date range for calendar
    DateTime startDate, endDate;

    if (dateRange != null) {
      startDate = dateRange.start;
      endDate = dateRange.end;
    } else {
      // Default to current month if no filter is applied
      startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    }

    final params = AttendanceParams(
      groupBy: 'date',
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(endDate),
    );

    final attendanceAsync = ref.watch(attendanceSummaryProvider(params));

    return attendanceAsync.when(
      data: (summary) {
        print('Calendar: Received ${summary.data.length} attendance groups');

        return TableCalendar<AttendanceGroup>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: selectedDate,
          calendarFormat: calendarFormat,
          eventLoader: (day) {
            final dayStr = DateFormat('yyyy-MM-dd').format(day);
            final dayGroups =
                summary.data.where((group) => group.id == dayStr).toList();
            print('Events for $dayStr: ${dayGroups.length}');
            return dayGroups;
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.twoWeeks: '2 weeks',
            CalendarFormat.week: 'Week',
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            selectedDecoration: BoxDecoration(
              color: HospitalTheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: HospitalTheme.success,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerMargin: const EdgeInsets.symmetric(horizontal: 1.0),
            markerSize: 6.0,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: HospitalTheme.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            formatButtonTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: HospitalTheme.primary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: HospitalTheme.primary,
            ),
          ),
          selectedDayPredicate: (day) {
            return isSameDay(selectedDate, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            print('Day selected: $selectedDay');
            ref.read(selectedDateProvider.notifier).state = selectedDay;
          },
          onFormatChanged: (format) {
            ref.read(calendarFormatProvider.notifier).state = format;
          },
          onPageChanged: (focusedDay) {
            print('Page changed to: $focusedDay');
            ref.read(selectedDateProvider.notifier).state = focusedDay;
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                final group = events.first as AttendanceGroup;
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getDateStatusColor(group),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${group.totalRecords}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        );
      },
      loading: () => Container(
        height: 300,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading calendar...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: HospitalTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading calendar',
                style: TextStyle(
                  color: HospitalTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try refreshing',
                style: TextStyle(color: HospitalTheme.textMedium),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(attendanceSummaryProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Update the _buildSelectedDateAttendance method to handle errors gracefully
  Widget _buildSelectedDateAttendance(DateTime selectedDate) {
    final params = AttendanceParams(
      groupBy: 'date',
      startDate: DateFormat('yyyy-MM-dd').format(selectedDate),
      endDate: DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    final attendanceAsync = ref.watch(attendanceSummaryProvider(params));

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.today,
                  color: HospitalTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attendance for ${DateFormat('MMMM dd, yyyy').format(selectedDate)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.invalidate(attendanceSummaryProvider(params)),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh attendance data',
                  color: HospitalTheme.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: attendanceAsync.when(
              data: (summary) => _buildDayAttendanceList(summary, selectedDate),
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading attendance data...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: HospitalTheme.info,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No attendance records found for this date',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showMarkAttendanceDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Mark Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HospitalTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Add this method to show summary view when filters are applied
  Widget _buildFilteredSummaryView() {
    final groupBy = ref.watch(selectedGroupByProvider);
    final dateRange = ref.watch(selectedDateRangeProvider);

    final params = AttendanceParams(
      groupBy: groupBy,
      startDate: dateRange?.start != null
          ? DateFormat('yyyy-MM-dd').format(dateRange!.start)
          : null,
      endDate: dateRange?.end != null
          ? DateFormat('yyyy-MM-dd').format(dateRange!.end)
          : null,
    );

    final attendanceAsync = ref.watch(attendanceSummaryProvider(params));

    return attendanceAsync.when(
      data: (summary) =>
          _buildAttendanceSummary(summary, MediaQuery.of(context).size.height),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(
        'Failed to load attendance summary',
        error.toString(),
      ),
    );
  }

// Update the _buildDayAttendanceList method to handle empty data better
  Widget _buildDayAttendanceList(
      AttendanceSummary summary, DateTime selectedDate) {
    final dayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final dayData = summary.data.where((group) => group.id == dayStr).toList();

    if (dayData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy,
                  size: 48,
                  color: HospitalTheme.textMedium,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No attendance records',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No attendance data found for ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showMarkAttendanceDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Mark Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final group = dayData.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day summary stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat(
                    'Present', group.present, HospitalTheme.success),
                _buildQuickStat('Absent', group.absent, HospitalTheme.error),
                _buildQuickStat('Late', group.late, HospitalTheme.warning),
                _buildQuickStat('Half Day', group.halfDay, HospitalTheme.info),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Individual records
          if (group.records.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Individual Records',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.records.length} records',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...group.records.map((record) => _buildDayAttendanceRecord(record)),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No individual records available',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

// Add this method to build selected date attendance

// Add this method for quick stats
  Widget _buildQuickStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: HospitalTheme.textMedium,
          ),
        ),
      ],
    );
  }

// Add this method for individual day records
  Widget _buildDayAttendanceRecord(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: HospitalTheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.nurseInfo?.nurseName ?? 'Unknown Nurse',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (record.checkIn != null)
                  Text(
                    'Check-in: ${DateFormat('HH:mm').format(record.checkIn!.time)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                if (record.checkOut != null)
                  Text(
                    'Check-out: ${DateFormat('HH:mm').format(record.checkOut!.time)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
              ],
            ),
          ),
          HospitalTheme.buildStatusBadge(
            record.status,
            color: _getStatusColor(record.status),
          ),
        ],
      ),
    );
  }

// Add this helper method for date status colors
  Color _getDateStatusColor(AttendanceGroup group) {
    if (group.absent > 0) return HospitalTheme.error;
    if (group.late > 0) return HospitalTheme.warning;
    if (group.present > 0) return HospitalTheme.success;
    return HospitalTheme.textLight;
  }

  Widget _buildAttendanceSummary(
      AttendanceSummary summary, double screenHeight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallStats(summary.overallStats),
          const SizedBox(height: 24),
          if (summary.data.isNotEmpty) ...[
            Text(
              'Detailed Records',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ...summary.data.map((group) => _buildAttendanceGroup(group)),
          ] else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: HospitalTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found',
                    style: TextStyle(
                      fontSize: 16,
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

  Widget _buildOverallStats(OverallStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Total Records',
                value: stats.totalRecords.toString(),
                icon: Icons.assignment,
                iconColor: HospitalTheme.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Present',
                value: stats.present.toString(),
                icon: Icons.check_circle,
                iconColor: HospitalTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Absent',
                value: stats.absent.toString(),
                icon: Icons.cancel,
                iconColor: HospitalTheme.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Late',
                value: stats.late.toString(),
                icon: Icons.access_time,
                iconColor: HospitalTheme.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceGroup(AttendanceGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: HospitalTheme.buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  group.id,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                HospitalTheme.buildStatusBadge(
                  '${group.totalRecords} records',
                  color: HospitalTheme.info,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Present', group.present, HospitalTheme.success),
                _buildStatItem('Absent', group.absent, HospitalTheme.error),
                _buildStatItem('Late', group.late, HospitalTheme.warning),
                _buildStatItem('Half Day', group.halfDay, HospitalTheme.info),
              ],
            ),
            if (group.records.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...group.records.map((record) => _buildAttendanceRecord(record)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: HospitalTheme.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRecord(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: HospitalTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.nurseInfo?.nurseName ?? 'Unknown Nurse',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (record.checkIn != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Check-in: ${DateFormat('HH:mm').format(record.checkIn!.time)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          HospitalTheme.buildStatusBadge(
            record.status,
            color: _getStatusColor(record.status),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String title, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: HospitalTheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return HospitalTheme.success;
      case 'absent':
        return HospitalTheme.error;
      case 'late':
        return HospitalTheme.warning;
      case 'half day':
        return HospitalTheme.info;
      default:
        return HospitalTheme.textMedium;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Search nurses...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    ref.invalidate(nursesProvider);
    ref.invalidate(attendanceSummaryProvider);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: ref.read(selectedDateRangeProvider),
    );

    if (picked != null) {
      ref.read(selectedDateRangeProvider.notifier).state = picked;
    }
  }

  void _showMarkAttendanceDialog({String? nurseId}) {
    final nurses = ref.read(nursesProvider).value ?? [];

    if (nurseId != null) {
      _selectedNurseId = nurseId;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Attendance Manually'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _markAttendanceFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedNurseId,
                  decoration: const InputDecoration(
                    labelText: 'Select Nurse',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: nurses.map((nurse) {
                    return DropdownMenuItem(
                      value: nurse.id,
                      child: Text(nurse.nurseName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedNurseId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a nurse';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'YYYY-MM-DD',
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      _dateController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.assignment_turned_in),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Present', child: Text('Present')),
                    DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                    DropdownMenuItem(value: 'Late', child: Text('Late')),
                    DropdownMenuItem(
                        value: 'Half Day', child: Text('Half Day')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'Present';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Additional notes...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _markAttendance,
            child: const Text('Mark Attendance'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAttendance() async {
    if (!_markAttendanceFormKey.currentState!.validate()) {
      return;
    }

    if (_selectedNurseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a nurse'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final apiService = ref.read(nurseApiServiceProvider);
      final success = await apiService.markAttendanceManually(
        nurseId: _selectedNurseId!,
        date: _dateController.text,
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (success) {
        Navigator.pop(context);
        _clearForm();
        _refreshData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance marked successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _selectedNurseId = null;
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _notesController.clear();
    _selectedStatus = 'Present';
  }
}

// Extension for HospitalTheme import
class HospitalTheme {
  // Primary colors
  static const Color primaryDark = Color(0xFF00477A);
  static const Color primary = Color(0xFF005F9E);
  static const Color primaryLight = Color(0xFF0288D1);
  static const Color accent = Color(0xFF00B8D4);

  // Secondary colors
  static const Color secondary = Color(0xFF00B8D4);
  static const Color secondaryLight = Color(0xFF4DD0E1);

  // Background colors
  static const Color background = Color(0xFFF8FBFD);
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFE1F5FE);
  static const Color navBackground = Color(0xFF005F9E);

  // Medical-themed colors
  static const Color medical = Color(0xFF2196F3);
  static const Color pharmacy = Color(0xFF26A69A);
  static const Color laboratory = Color(0xFF7E57C2);
  static const Color emergency = Color(0xFFEF5350);

  // Status colors
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF039BE5);

  // Text colors
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMedium = Color(0xFF5A6B7F);
  static const Color textLight = Color(0xFF8FA3B8);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  // Border colors
  static const Color border = Color(0xFFDFEAF4);
  static const Color borderDark = Color(0xFFB5C9D8);

  // Shadow
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // Border radius
  static BorderRadius get radiusSmall => BorderRadius.circular(8);
  static BorderRadius get radiusMedium => BorderRadius.circular(12);
  static BorderRadius get radiusLarge => BorderRadius.circular(16);
  static BorderRadius get radiusXLarge => BorderRadius.circular(24);

  // Custom widgets
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool hasShadow = true,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? cardBackground,
        borderRadius: borderRadius ?? radiusMedium,
        border: Border.all(color: border),
        boxShadow: hasShadow ? shadowSmall : null,
      ),
      child: child,
    );
  }

  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
    String? subtitle,
    bool showIncrease = false,
    String? percentageChange,
  }) {
    final iconBgColor = (iconColor ?? primary).withOpacity(0.1);

    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? primary,
                  size: 24,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textMedium,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildStatusBadge(
    String text, {
    Color? color,
    bool outline = false,
  }) {
    final badgeColor = color ?? info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: badgeColor,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
