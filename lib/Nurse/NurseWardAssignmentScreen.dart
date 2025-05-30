// models/nurse_model.dart
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nurseName': nurseName,
      'email': email,
      'usertype': usertype,
      'status': status,
      'isAvailable': isAvailable,
    };
  }

  bool get isPresent => status == 'Present';
  bool get canBeAssigned => isPresent && (isAvailable ?? true);
}

// models/ward_model.dart
class Ward {
  final String id;
  final String name;
  final String type;
  final int floor;
  final int totalBeds;
  final int occupiedBeds;
  final List<BedOccupancy> bedOccupancy;
  final NursesByShift nursesByShift;
  final String sectionId;
  final SectionInfo? sectionInfo;
  final int patientsCount;

  const Ward({
    required this.id,
    required this.name,
    required this.type,
    required this.floor,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.bedOccupancy,
    required this.nursesByShift,
    required this.sectionId,
    this.sectionInfo,
    required this.patientsCount,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      floor: json['floor'] ?? 0,
      totalBeds: json['totalBeds'] ?? 0,
      occupiedBeds: json['occupiedBeds'] ?? 0,
      bedOccupancy: (json['bedOccupancy'] as List<dynamic>?)
              ?.map((e) => BedOccupancy.fromJson(e))
              .toList() ??
          [],
      nursesByShift: NursesByShift.fromJson(json['nursesByShift'] ?? {}),
      sectionId: json['sectionId'] ?? '',
      sectionInfo: json['sectionInfo'] != null
          ? SectionInfo.fromJson(json['sectionInfo'])
          : null,
      patientsCount: json['patientsCount'] ?? 0,
    );
  }

  int get availableBeds => totalBeds - occupiedBeds;
  double get occupancyRate => totalBeds > 0 ? (occupiedBeds / totalBeds) : 0.0;
}

class BedOccupancy {
  final int bedNumber;
  final bool isOccupied;
  final PatientInfo? patientInfo;

  const BedOccupancy({
    required this.bedNumber,
    required this.isOccupied,
    this.patientInfo,
  });

  factory BedOccupancy.fromJson(Map<String, dynamic> json) {
    return BedOccupancy(
      bedNumber: json['bedNumber'] ?? 0,
      isOccupied: json['isOccupied'] ?? false,
      patientInfo: json['patientInfo'] != null
          ? PatientInfo.fromJson(json['patientInfo'])
          : null,
    );
  }
}

class PatientInfo {
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String admissionId;
  final DateTime admissionDate;
  final Doctor doctor;

  const PatientInfo({
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.admissionId,
    required this.admissionDate,
    required this.doctor,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      admissionId: json['admissionId'] ?? '',
      admissionDate:
          DateTime.tryParse(json['admissionDate'] ?? '') ?? DateTime.now(),
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      usertype: json['usertype'] ?? '',
    );
  }
}

class NursesByShift {
  final List<AssignedNurse> morning;
  final List<AssignedNurse> evening;
  final List<AssignedNurse> night;

  const NursesByShift({
    required this.morning,
    required this.evening,
    required this.night,
  });

  factory NursesByShift.fromJson(Map<String, dynamic> json) {
    return NursesByShift(
      morning: (json['Morning'] as List<dynamic>?)
              ?.map((e) => AssignedNurse.fromJson(e))
              .toList() ??
          [],
      evening: (json['Evening'] as List<dynamic>?)
              ?.map((e) => AssignedNurse.fromJson(e))
              .toList() ??
          [],
      night: (json['Night'] as List<dynamic>?)
              ?.map((e) => AssignedNurse.fromJson(e))
              .toList() ??
          [],
    );
  }

  List<AssignedNurse> getByShift(String shift) {
    switch (shift.toLowerCase()) {
      case 'morning':
        return morning;
      case 'evening':
        return evening;
      case 'night':
        return night;
      default:
        return [];
    }
  }

  int get totalAssignedNurses => morning.length + evening.length + night.length;
}

class AssignedNurse {
  final NurseInfo nurseId;
  final String shift;
  final DateTime assignedDate;
  final bool isActive;
  final String id;

  const AssignedNurse({
    required this.nurseId,
    required this.shift,
    required this.assignedDate,
    required this.isActive,
    required this.id,
  });

  factory AssignedNurse.fromJson(Map<String, dynamic> json) {
    return AssignedNurse(
      nurseId: NurseInfo.fromJson(json['nurseId'] ?? {}),
      shift: json['shift'] ?? '',
      assignedDate:
          DateTime.tryParse(json['assignedDate'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? false,
      id: json['_id'] ?? '',
    );
  }
}

class NurseInfo {
  final String id;
  final String email;
  final String nurseName;
  final String usertype;

  const NurseInfo({
    required this.id,
    required this.email,
    required this.nurseName,
    required this.usertype,
  });

  factory NurseInfo.fromJson(Map<String, dynamic> json) {
    return NurseInfo(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      nurseName: json['nurseName'] ?? '',
      usertype: json['usertype'] ?? '',
    );
  }
}

class SectionInfo {
  final String id;
  final int totalBeds;
  final int availableBeds;
  final bool isActive;

  const SectionInfo({
    required this.id,
    required this.totalBeds,
    required this.availableBeds,
    required this.isActive,
  });

  factory SectionInfo.fromJson(Map<String, dynamic> json) {
    return SectionInfo(
      id: json['_id'] ?? '',
      totalBeds: json['totalBeds'] ?? 0,
      availableBeds: json['availableBeds'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}

// providers/nurse_ward_provider.dart

// API Service
class NurseWardService {
  Future<List<Ward>> getAllWards() async {
    try {
      final response = await http.get(
        Uri.parse('$KVM_URL/nurse/getAllWards'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['wards'] != null) {
          return (data['wards'] as List)
              .map((wardJson) => Ward.fromJson(wardJson))
              .toList();
        }
      } else {
        throw Exception('Failed to load wards: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch wards: $e');
    }
  }

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
      } else {
        throw Exception('Failed to load nurses: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch nurses: $e');
    }
  }

  Future<bool> assignNurseToWard({
    required String nurseId,
    required String wardId,
    required String shift,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$KVM_URL/nurse/assignNurseToWard'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nurseId': nurseId,
          'wardId': wardId,
          'shift': shift,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to assign nurse to ward: $e');
    }
  }

  Future<bool> markAttendanceManually({
    required String nurseId,
    required String date,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$KVM_URL/nurse/markAttendanceManually'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nurseId': nurseId,
          'date': date,
          'status': status,
          'notes': notes ?? 'Attendance marked by admin',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }
}

// State classes
// State classes
class NurseWardState {
  final List<Ward> wards;
  final List<Nurse> nurses;
  final bool isLoading;
  final String? error;
  final Ward? selectedWard;
  final String selectedShift;

  const NurseWardState({
    this.wards = const [],
    this.nurses = const [],
    this.isLoading = false,
    this.error,
    this.selectedWard,
    this.selectedShift = 'Morning',
  });

  NurseWardState copyWith({
    List<Ward>? wards,
    List<Nurse>? nurses,
    bool? isLoading,
    String? error,
    Ward? selectedWard,
    String? selectedShift,
  }) {
    return NurseWardState(
      wards: wards ?? this.wards,
      nurses: nurses ?? this.nurses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedWard: selectedWard ?? this.selectedWard,
      selectedShift: selectedShift ?? this.selectedShift,
    );
  }
}

// Providers
final nurseWardServiceProvider = Provider<NurseWardService>((ref) {
  return NurseWardService();
});

final nurseWardProvider =
    StateNotifierProvider<NurseWardNotifier, NurseWardState>((ref) {
  return NurseWardNotifier(ref.watch(nurseWardServiceProvider));
});

class NurseWardNotifier extends StateNotifier<NurseWardState> {
  final NurseWardService _service;

  NurseWardNotifier(this._service) : super(const NurseWardState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final futures = await Future.wait([
        _service.getAllWards(),
        _service.getAllNurses(),
      ]);

      final wards = futures[0] as List<Ward>;
      final nurses = futures[1] as List<Nurse>;

      state = state.copyWith(
        wards: wards,
        nurses: nurses,
        isLoading: false,
        selectedWard: wards.isNotEmpty ? wards.first : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectWard(Ward ward) {
    state = state.copyWith(selectedWard: ward);
  }

  void selectShift(String shift) {
    state = state.copyWith(selectedShift: shift);
  }

  Future<bool> assignNurse({
    required String nurseId,
    required String wardId,
    required String shift,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.assignNurseToWard(
        nurseId: nurseId,
        wardId: wardId,
        shift: shift,
      );

      if (success) {
        // Reload data to reflect changes
        await loadData();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> markAttendance({
    required String nurseId,
    required String status,
    String? notes,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final success = await _service.markAttendanceManually(
        nurseId: nurseId,
        date: today,
        status: status,
        notes: notes,
      );

      if (success) {
        await loadData();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers

// nurse_ward_assignment_screen.dart

class NurseWardAssignmentScreen extends ConsumerStatefulWidget {
  const NurseWardAssignmentScreen({super.key});

  @override
  ConsumerState<NurseWardAssignmentScreen> createState() =>
      _NurseWardAssignmentScreenState();
}

class _NurseWardAssignmentScreenState
    extends ConsumerState<NurseWardAssignmentScreen> {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Nurse Ward Assignment',
          showBackButton: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(nurseWardProvider.notifier).loadData(),
              tooltip: 'Refresh Data (F5)',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            if (isMobile) {
              return const _MobileLayout();
            } else {
              return _DesktopLayout(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              );
            }
          },
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        ref.read(nurseWardProvider.notifier).loadData();
      } else if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyR) {
        ref.read(nurseWardProvider.notifier).loadData();
      }
    }
  }
}

class _DesktopLayout extends ConsumerWidget {
  final double screenWidth;
  final double screenHeight;

  const _DesktopLayout({
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nurseWardProvider);

    if (state.isLoading && state.wards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return _ErrorWidget(
        error: state.error!,
        onRetry: () => ref.read(nurseWardProvider.notifier).loadData(),
      );
    }

    // Use flexible ratios instead of fixed pixels
    return Row(
      children: [
        // Master Panel - Ward List (flexible)
        Expanded(
          flex: 35, // 35% of available width
          child: _MasterPanel(
            wards: state.wards,
            selectedWard: state.selectedWard,
            onWardSelected: (ward) =>
                ref.read(nurseWardProvider.notifier).selectWard(ward),
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: HospitalTheme.border,
        ),

        // Detail Panel - Ward Details & Nurse Assignment (flexible)
        Expanded(
          flex: 65, // 65% of available width
          child: _DetailPanel(
            selectedWard: state.selectedWard,
            nurses: state.nurses,
            selectedShift: state.selectedShift,
            isLoading: state.isLoading,
            onShiftChanged: (shift) =>
                ref.read(nurseWardProvider.notifier).selectShift(shift),
            onAssignNurse: (nurseId, wardId, shift) =>
                ref.read(nurseWardProvider.notifier).assignNurse(
                      nurseId: nurseId,
                      wardId: wardId,
                      shift: shift,
                    ),
            onMarkAttendance: (nurseId, status) =>
                ref.read(nurseWardProvider.notifier).markAttendance(
                      nurseId: nurseId,
                      status: status,
                    ),
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nurseWardProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Wards', icon: Icon(Icons.local_hospital)),
              Tab(text: 'Assignment', icon: Icon(Icons.assignment_ind)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MasterPanel(
                  wards: state.wards,
                  selectedWard: state.selectedWard,
                  onWardSelected: (ward) =>
                      ref.read(nurseWardProvider.notifier).selectWard(ward),
                ),
                _DetailPanel(
                  selectedWard: state.selectedWard,
                  nurses: state.nurses,
                  selectedShift: state.selectedShift,
                  isLoading: state.isLoading,
                  onShiftChanged: (shift) =>
                      ref.read(nurseWardProvider.notifier).selectShift(shift),
                  onAssignNurse: (nurseId, wardId, shift) =>
                      ref.read(nurseWardProvider.notifier).assignNurse(
                            nurseId: nurseId,
                            wardId: wardId,
                            shift: shift,
                          ),
                  onMarkAttendance: (nurseId, status) =>
                      ref.read(nurseWardProvider.notifier).markAttendance(
                            nurseId: nurseId,
                            status: status,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterPanel extends StatelessWidget {
  final List<Ward> wards;
  final Ward? selectedWard;
  final ValueChanged<Ward> onWardSelected;

  const _MasterPanel({
    required this.wards,
    required this.selectedWard,
    required this.onWardSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: HospitalTheme.border),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital, color: HospitalTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Wards (${wards.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: wards.isEmpty
                ? const Center(
                    child: Text(
                      'No wards available',
                      style: TextStyle(color: HospitalTheme.textMedium),
                    ),
                  )
                : ListView.builder(
                    itemCount: wards.length,
                    itemBuilder: (context, index) {
                      final ward = wards[index];
                      final isSelected = selectedWard?.id == ward.id;

                      return _WardListTile(
                        ward: ward,
                        isSelected: isSelected,
                        onTap: () => onWardSelected(ward),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WardListTile extends StatelessWidget {
  final Ward ward;
  final bool isSelected;
  final VoidCallback onTap;

  const _WardListTile({
    required this.ward,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final occupancyRate = ward.occupancyRate;
    final Color occupancyColor = occupancyRate > 0.8
        ? HospitalTheme.error
        : occupancyRate > 0.6
            ? HospitalTheme.warning
            : HospitalTheme.success;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 2 : 1,
        ),
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
                  Expanded(
                    child: Text(
                      ward.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? HospitalTheme.primary
                            : HospitalTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getWardTypeColor(ward.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ward.type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getWardTypeColor(ward.type),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Floor ${ward.floor}',
                style: const TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textMedium,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.bed,
                    label: '${ward.occupiedBeds}/${ward.totalBeds}',
                    color: occupancyColor,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${ward.nursesByShift.totalAssignedNurses} nurses',
                    color: HospitalTheme.info,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: occupancyRate,
                backgroundColor: HospitalTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getWardTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'icu':
        return HospitalTheme.emergency;
      case 'general':
        return HospitalTheme.primary;
      case 'special ward':
        return HospitalTheme.secondary;
      default:
        return HospitalTheme.textMedium;
    }
  }
}

class _DetailPanel extends StatefulWidget {
  final Ward? selectedWard;
  final List<Nurse> nurses;
  final String selectedShift;
  final bool isLoading;
  final ValueChanged<String> onShiftChanged;
  final Future<bool> Function(String nurseId, String wardId, String shift)
      onAssignNurse;
  final Future<bool> Function(String nurseId, String status) onMarkAttendance;

  const _DetailPanel({
    required this.selectedWard,
    required this.nurses,
    required this.selectedShift,
    required this.isLoading,
    required this.onShiftChanged,
    required this.onAssignNurse,
    required this.onMarkAttendance,
  });

  @override
  State<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends State<_DetailPanel> {
  @override
  Widget build(BuildContext context) {
    if (widget.selectedWard == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'Select a ward to view details',
              style: TextStyle(
                fontSize: 18,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // War
          // Ward Header
          _WardHeader(ward: widget.selectedWard!),

          // Shift Selector
          _ShiftSelector(
            selectedShift: widget.selectedShift,
            onShiftChanged: widget.onShiftChanged,
          ),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Assignments
                  _CurrentAssignments(
                    ward: widget.selectedWard!,
                    selectedShift: widget.selectedShift,
                  ),

                  const SizedBox(height: 24),

                  // Available Nurses
                  _AvailableNurses(
                    nurses: widget.nurses,
                    selectedWard: widget.selectedWard!,
                    selectedShift: widget.selectedShift,
                    isLoading: widget.isLoading,
                    onAssignNurse: widget.onAssignNurse,
                    onMarkAttendance: widget.onMarkAttendance,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WardHeader extends StatelessWidget {
  final Ward ward;

  const _WardHeader({required this.ward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20 to 16
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced from 12 to 8
                decoration: BoxDecoration(
                  color: _getWardTypeColor(ward.type).withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(8), // Reduced from 12 to 8
                ),
                child: Icon(
                  _getWardIcon(ward.type),
                  color: _getWardTypeColor(ward.type),
                  size: 20, // Reduced from 24 to 20
                ),
              ),
              const SizedBox(width: 12), // Reduced from 16 to 12
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ward.name,
                      style: const TextStyle(
                        fontSize: 20, // Reduced from 24 to 20
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced from 4 to 2
                    Text(
                      '${ward.type} • Floor ${ward.floor}',
                      style: const TextStyle(
                        fontSize: 14, // Reduced from 16 to 14
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 20 to 12
          // Make stats responsive with LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              if (isNarrow) {
                // Stack stats in 2x2 grid for narrow screens
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Beds',
                            ward.totalBeds.toString(),
                            Icons.bed,
                            HospitalTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6), // Reduced from 8 to 6
                        Expanded(
                          child: _buildStatCard(
                            'Occupied',
                            ward.occupiedBeds.toString(),
                            Icons.person,
                            ward.occupancyRate > 0.8
                                ? HospitalTheme.error
                                : HospitalTheme.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6), // Reduced from 8 to 6
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Available',
                            ward.availableBeds.toString(),
                            Icons.bed_outlined,
                            HospitalTheme.success,
                          ),
                        ),
                        const SizedBox(width: 6), // Reduced from 8 to 6
                        Expanded(
                          child: _buildStatCard(
                            'Nurses',
                            ward.nursesByShift.totalAssignedNurses.toString(),
                            Icons.people,
                            HospitalTheme.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Single row for wider screens
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Beds',
                        ward.totalBeds.toString(),
                        Icons.bed,
                        HospitalTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced from 12 to 8
                    Expanded(
                      child: _buildStatCard(
                        'Occupied',
                        ward.occupiedBeds.toString(),
                        Icons.person,
                        ward.occupancyRate > 0.8
                            ? HospitalTheme.error
                            : HospitalTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced from 12 to 8
                    Expanded(
                      child: _buildStatCard(
                        'Available',
                        ward.availableBeds.toString(),
                        Icons.bed_outlined,
                        HospitalTheme.success,
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced from 12 to 8
                    Expanded(
                      child: _buildStatCard(
                        'Nurses',
                        ward.nursesByShift.totalAssignedNurses.toString(),
                        Icons.people,
                        HospitalTheme.info,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 12 to 8
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16), // Reduced from 18 to 16
          const SizedBox(height: 4), // Reduced from 6 to 4
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Reduced from 18 to 16
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1), // Reduced from 2 to 1
          Text(
            title,
            style: const TextStyle(
              fontSize: 10, // Reduced from 11 to 10
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getWardTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'icu':
        return HospitalTheme.emergency;
      case 'general':
        return HospitalTheme.primary;
      case 'special ward':
        return HospitalTheme.secondary;
      default:
        return HospitalTheme.textMedium;
    }
  }

  IconData _getWardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'icu':
        return Icons.emergency;
      case 'general':
        return Icons.local_hospital;
      case 'special ward':
        return Icons.local_pharmacy;
      default:
        return Icons.bed;
    }
  }
}

class _ShiftSelector extends StatelessWidget {
  final String selectedShift;
  final ValueChanged<String> onShiftChanged;

  const _ShiftSelector({
    required this.selectedShift,
    required this.onShiftChanged,
  });

  static const List<String> shifts = ['Morning', 'Evening', 'Night'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Shift:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(width: 16),
          ...shifts.map((shift) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(shift),
                  selected: selectedShift == shift,
                  onSelected: (selected) {
                    if (selected) onShiftChanged(shift);
                  },
                  selectedColor: HospitalTheme.primary.withOpacity(0.2),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: selectedShift == shift
                        ? HospitalTheme.primary
                        : HospitalTheme.textMedium,
                    fontWeight: selectedShift == shift
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selectedShift == shift
                        ? HospitalTheme.primary
                        : HospitalTheme.border,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _CurrentAssignments extends StatelessWidget {
  final Ward ward;
  final String selectedShift;

  const _CurrentAssignments({
    required this.ward,
    required this.selectedShift,
  });

  @override
  Widget build(BuildContext context) {
    final assignedNurses = ward.nursesByShift.getByShift(selectedShift);

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Current Assignments - $selectedShift Shift',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: assignedNurses.isEmpty
                    ? HospitalTheme.error.withOpacity(0.1)
                    : HospitalTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${assignedNurses.length} assigned',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: assignedNurses.isEmpty
                      ? HospitalTheme.error
                      : HospitalTheme.success,
                ),
              ),
            ),
          ),
          if (assignedNurses.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: HospitalTheme.warning.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusSmall,
                border:
                    Border.all(color: HospitalTheme.warning.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: HospitalTheme.warning,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No nurses assigned to $selectedShift shift',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Assign nurses from the available list below',
                    style: TextStyle(
                      fontSize: 14,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            ...assignedNurses.map((assignedNurse) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.success.withOpacity(0.05),
                    borderRadius: HospitalTheme.radiusSmall,
                    border: Border.all(
                        color: HospitalTheme.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HospitalTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: HospitalTheme.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignedNurse.nurseId.nurseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assignedNurse.nurseId.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: assignedNurse.isActive
                                  ? HospitalTheme.success.withOpacity(0.2)
                                  : HospitalTheme.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              assignedNurse.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: assignedNurse.isActive
                                    ? HospitalTheme.success
                                    : HospitalTheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assigned: ${_formatDate(assignedNurse.assignedDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HospitalTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _AvailableNurses extends StatefulWidget {
  final List<Nurse> nurses;
  final Ward selectedWard;
  final String selectedShift;
  final bool isLoading;
  final Future<bool> Function(String nurseId, String wardId, String shift)
      onAssignNurse;
  final Future<bool> Function(String nurseId, String status) onMarkAttendance;

  const _AvailableNurses({
    required this.nurses,
    required this.selectedWard,
    required this.selectedShift,
    required this.isLoading,
    required this.onAssignNurse,
    required this.onMarkAttendance,
  });

  @override
  State<_AvailableNurses> createState() => _AvailableNursesState();
}

class _AvailableNursesState extends State<_AvailableNurses> {
  String _searchQuery = '';
  String _filterStatus = 'All';
  Set<String> _assigningNurses = {};

  static const List<String> statusFilters = [
    'All',
    'Present',
    'Not Checked In'
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNurses = _getFilteredNurses();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Available Nurses',
            trailing: Text(
              '${filteredNurses.length} of ${widget.nurses.length}',
              style: const TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
          ),

          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
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
                        _filterStatus = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nurses List
          if (filteredNurses.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: HospitalTheme.info.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusSmall,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    color: HospitalTheme.info,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No nurses found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Try adjusting your search or filter criteria',
                    style: TextStyle(
                      fontSize: 14,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredNurses.map((nurse) => _NurseCard(
                  nurse: nurse,
                  selectedWard: widget.selectedWard,
                  selectedShift: widget.selectedShift,
                  isAssigning: _assigningNurses.contains(nurse.id),
                  onAssign: () => _handleAssignNurse(nurse),
                  onMarkAttendance: () => _handleMarkAttendance(nurse),
                )),
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
      if (_filterStatus != 'All') {
        if (_filterStatus == 'Present' && !nurse.isPresent) return false;
        if (_filterStatus == 'Not Checked In' && nurse.isPresent) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _handleAssignNurse(Nurse nurse) async {
    if (!nurse.canBeAssigned) {
      _showSnackBar(
        'Cannot assign ${nurse.nurseName}. Nurse must be present and available.',
        isError: true,
      );
      return;
    }

    setState(() {
      _assigningNurses.add(nurse.id);
    });

    try {
      final success = await widget.onAssignNurse(
        nurse.id,
        widget.selectedWard.id,
        widget.selectedShift,
      );

      if (success) {
        _showSnackBar(
          '${nurse.nurseName} assigned to ${widget.selectedWard.name} - ${widget.selectedShift} shift',
        );
      } else {
        _showSnackBar(
          'Failed to assign ${nurse.nurseName}. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error assigning nurse: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _assigningNurses.remove(nurse.id);
      });
    }
  }

  Future<void> _handleMarkAttendance(Nurse nurse) async {
    final newStatus = nurse.isPresent ? 'Not Checked In' : 'Present';

    try {
      final success = await widget.onMarkAttendance(nurse.id, newStatus);

      if (success) {
        _showSnackBar(
          '${nurse.nurseName} marked as $newStatus',
        );
      } else {
        _showSnackBar(
          'Failed to mark attendance for ${nurse.nurseName}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error marking attendance: $e',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? HospitalTheme.error : HospitalTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _NurseCard extends StatelessWidget {
  final Nurse nurse;
  final Ward selectedWard;
  final String selectedShift;
  final bool isAssigning;
  final VoidCallback onAssign;
  final VoidCallback onMarkAttendance;

  const _NurseCard({
    required this.nurse,
    required this.selectedWard,
    required this.selectedShift,
    required this.isAssigning,
    required this.onAssign,
    required this.onMarkAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(nurse.status);
    final isAlreadyAssigned = _isNurseAlreadyAssigned();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          if (isNarrow) {
            // Stack layout for narrow screens
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.textDark,
                            ),
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
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _getUserTypeColor(nurse.usertype).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        nurse.usertype.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: _getUserTypeColor(nurse.usertype),
                        ),
                      ),
                    ),
                    if (nurse.isAvailable == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: HospitalTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AVAILABLE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.success,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Action Buttons
                    SizedBox(
                      width: 80,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: isAlreadyAssigned ||
                                !nurse.canBeAssigned ||
                                isAssigning
                            ? null
                            : onAssign,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAlreadyAssigned
                              ? HospitalTheme.success
                              : HospitalTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                        child: isAssigning
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                isAlreadyAssigned ? 'Done' : 'Assign',
                                style: const TextStyle(fontSize: 10),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 60,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: onMarkAttendance,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: nurse.isPresent
                              ? HospitalTheme.error
                              : HospitalTheme.success,
                          side: BorderSide(
                            color: nurse.isPresent
                                ? HospitalTheme.error
                                : HospitalTheme.success,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                        ),
                        child: Text(
                          nurse.isPresent ? 'Out' : 'In',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Original row layout for wider screens
            return Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.person,
                    color: statusColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Nurse Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nurse.nurseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              nurse.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nurse.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(nurse.usertype)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
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
                          if (nurse.isAvailable == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: HospitalTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'AVAILABLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Action Buttons
                Column(
                  children: [
                    // Assign Button
                    SizedBox(
                      width: 100,
                      child: ElevatedButton.icon(
                        onPressed: isAlreadyAssigned ||
                                !nurse.canBeAssigned ||
                                isAssigning
                            ? null
                            : onAssign,
                        icon: isAssigning
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                isAlreadyAssigned ? Icons.check : Icons.add,
                                size: 14,
                              ),
                        label: Text(
                          isAlreadyAssigned ? 'Assigned' : 'Assign',
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAlreadyAssigned
                              ? HospitalTheme.success
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Attendance Button
                    SizedBox(
                      width: 100,
                      child: OutlinedButton.icon(
                        onPressed: onMarkAttendance,
                        icon: Icon(
                          nurse.isPresent ? Icons.logout : Icons.login,
                          size: 14,
                        ),
                        label: Text(
                          nurse.isPresent ? 'Check Out' : 'Check In',
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: nurse.isPresent
                              ? HospitalTheme.error
                              : HospitalTheme.success,
                          side: BorderSide(
                            color: nurse.isPresent
                                ? HospitalTheme.error
                                : HospitalTheme.success,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // ... rest of the methods remain the same
  bool _isNurseAlreadyAssigned() {
    final assignedNurses = selectedWard.nursesByShift.getByShift(selectedShift);
    return assignedNurses.any((assigned) => assigned.nurseId.id == nurse.id);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return HospitalTheme.success;
      case 'not checked in':
        return HospitalTheme.warning;
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
