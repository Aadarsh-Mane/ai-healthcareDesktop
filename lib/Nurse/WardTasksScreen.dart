// ward_treatment_tasks_screen.dart - Enhanced with task administration functionality
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Models (keeping existing models unchanged)
class TreatmentTask {
  final String wardName;
  final String type;
  final String patientId;
  final String patientName;
  final int age;
  final String gender;
  final int bedNumber;
  final String admissionId;
  final String taskId;
  final String name;
  final String details;
  final String status;
  final String date;
  final String time;

  const TreatmentTask({
    required this.wardName,
    required this.type,
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.bedNumber,
    required this.admissionId,
    required this.taskId,
    required this.name,
    required this.details,
    required this.status,
    required this.date,
    required this.time,
  });

  factory TreatmentTask.fromJson(Map<String, dynamic> json) {
    return TreatmentTask(
      wardName: json['wardName'] ?? '',
      type: json['type'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      bedNumber: json['bedNumber'] ?? 0,
      admissionId: json['admissionId'] ?? '',
      taskId: json['taskId'] ?? '',
      name: json['name'] ?? '',
      details: json['details'] ?? '',
      status: json['status'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
    );
  }

  TreatmentTask copyWith({
    String? wardName,
    String? type,
    String? patientId,
    String? patientName,
    int? age,
    String? gender,
    int? bedNumber,
    String? admissionId,
    String? taskId,
    String? name,
    String? details,
    String? status,
    String? date,
    String? time,
  }) {
    return TreatmentTask(
      wardName: wardName ?? this.wardName,
      type: type ?? this.type,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bedNumber: bedNumber ?? this.bedNumber,
      admissionId: admissionId ?? this.admissionId,
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      details: details ?? this.details,
      status: status ?? this.status,
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }
}

class WardInfo {
  final String wardName;
  final int patientCount;
  final int taskCount;
  final List<TreatmentTask> treatmentTasks;

  const WardInfo({
    required this.wardName,
    required this.patientCount,
    required this.taskCount,
    required this.treatmentTasks,
  });

  factory WardInfo.fromJson(Map<String, dynamic> json) {
    final tasksList = json['treatmentTasks'] as List<dynamic>? ?? [];

    return WardInfo(
      wardName: json['wardName'] ?? '',
      patientCount: json['patientCount'] ?? 0,
      taskCount: json['taskCount'] ?? 0,
      treatmentTasks:
          tasksList.map((task) => TreatmentTask.fromJson(task)).toList(),
    );
  }
}

class WardTreatmentData {
  final String currentShift;
  final List<String> assignedWards;
  final int totalPatients;
  final int totalTasks;
  final List<WardInfo> wards;

  const WardTreatmentData({
    required this.currentShift,
    required this.assignedWards,
    required this.totalPatients,
    required this.totalTasks,
    required this.wards,
  });

  factory WardTreatmentData.fromJson(Map<String, dynamic> json) {
    final wardsList = json['wards'] as List<dynamic>? ?? [];
    final assignedWardsList = json['assignedWards'] as List<dynamic>? ?? [];

    return WardTreatmentData(
      currentShift: json['currentShift'] ?? '',
      assignedWards: assignedWardsList.map((ward) => ward.toString()).toList(),
      totalPatients: json['totalPatients'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      wards: wardsList.map((ward) => WardInfo.fromJson(ward)).toList(),
    );
  }

  WardTreatmentData copyWith({
    String? currentShift,
    List<String>? assignedWards,
    int? totalPatients,
    int? totalTasks,
    List<WardInfo>? wards,
  }) {
    return WardTreatmentData(
      currentShift: currentShift ?? this.currentShift,
      assignedWards: assignedWards ?? this.assignedWards,
      totalPatients: totalPatients ?? this.totalPatients,
      totalTasks: totalTasks ?? this.totalTasks,
      wards: wards ?? this.wards,
    );
  }
}

class WardTreatmentResponse {
  final bool success;
  final String message;
  final WardTreatmentData data;
  final DateTime timestamp;

  const WardTreatmentResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory WardTreatmentResponse.fromJson(Map<String, dynamic> json) {
    return WardTreatmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: WardTreatmentData.fromJson(json['data'] ?? json),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

// Task Administration Service
class TaskAdministrationService {
  static const int _timeoutSeconds = 15;

  static Future<bool> markTaskAsAdministered({
    required String patientId,
    required String admissionId,
    required String taskId,
    required String taskType,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nurse_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      String endpoint;
      switch (taskType.toLowerCase()) {
        case 'medication':
          endpoint = '/nurse/markMedicationAdministered';
          break;
        case 'iv fluid':
          endpoint = '/nurse/markIVFluidAdministered';
          break;
        case 'procedure':
          endpoint = '/nurse/markProcedureCompleted';
          break;
        case 'special instruction':
          endpoint = '/nurse/markInstructionCompleted';
          break;
        default:
          endpoint = '/nurse/markMedicationAdministered';
      }

      final url =
          Uri.parse('$KVM_URL$endpoint/$patientId/$admissionId/$taskId');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'notes': notes ?? '',
            }),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));
      print('Response status: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['message'] != null;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        String errorMessage = 'Failed to mark task as administered';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your network');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your connection');
      }
      rethrow;
    }
  }
}

// Enhanced Providers
final wardTreatmentTasksProvider = StateNotifierProvider<
    WardTreatmentTasksNotifier, AsyncValue<WardTreatmentData>>((ref) {
  return WardTreatmentTasksNotifier(ref.read(httpClientProvider));
});

class WardTreatmentTasksNotifier
    extends StateNotifier<AsyncValue<WardTreatmentData>> {
  final http.Client _httpClient;

  WardTreatmentTasksNotifier(this._httpClient)
      : super(const AsyncValue.loading()) {
    fetchWardTreatmentTasks();
  }

  Future<void> fetchWardTreatmentTasks() async {
    state = const AsyncValue.loading();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nurse_token') ?? '';

      if (token.isEmpty) {
        state = AsyncValue.error(
            'Authentication token not found', StackTrace.current);
        return;
      }

      final url = Uri.parse('$KVM_URL/nurse/getWardTreatmentTasks');
      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('currentShift')) {
          final treatmentData = WardTreatmentData.fromJson(responseData);
          state = AsyncValue.data(treatmentData);
        } else {
          final treatmentResponse =
              WardTreatmentResponse.fromJson(responseData);
          if (treatmentResponse.success) {
            state = AsyncValue.data(treatmentResponse.data);
          } else {
            state =
                AsyncValue.error(treatmentResponse.message, StackTrace.current);
          }
        }
      } else if (response.statusCode == 401) {
        state = AsyncValue.error(
            'Authentication failed. Please login again.', StackTrace.current);
      } else {
        String errorMessage = 'Failed to fetch ward treatment tasks';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message
        }
        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } catch (e, stackTrace) {
      String errorMessage = 'An unexpected error occurred';

      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timeout. Please check your network';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your connection';
      }

      state = AsyncValue.error(errorMessage, stackTrace);
    }
  }

  Future<void> refreshTasks() async {
    await fetchWardTreatmentTasks();
  }

  // Update task status locally after successful API call
  void updateTaskStatus(String taskId, String newStatus) {
    state.whenData((data) {
      final updatedWards = data.wards.map((ward) {
        final updatedTasks = ward.treatmentTasks.map((task) {
          if (task.taskId == taskId) {
            return task.copyWith(status: newStatus);
          }
          return task;
        }).toList();

        return WardInfo(
          wardName: ward.wardName,
          patientCount: ward.patientCount,
          taskCount: ward.taskCount,
          treatmentTasks: updatedTasks,
        );
      }).toList();

      final updatedData = data.copyWith(wards: updatedWards);
      state = AsyncValue.data(updatedData);
    });
  }
}

// Task administration state provider
final taskAdministrationProvider =
    StateNotifierProvider<TaskAdministrationNotifier, Map<String, bool>>((ref) {
  return TaskAdministrationNotifier();
});

class TaskAdministrationNotifier extends StateNotifier<Map<String, bool>> {
  TaskAdministrationNotifier() : super({});

  Future<bool> administrateTask({
    required String patientId,
    required String admissionId,
    required String taskId,
    required String taskType,
    String? notes,
  }) async {
    // Set loading state for this task
    state = {...state, taskId: true};

    try {
      final success = await TaskAdministrationService.markTaskAsAdministered(
        patientId: patientId,
        admissionId: admissionId,
        taskId: taskId,
        taskType: taskType,
        notes: notes,
      );

      // Remove loading state
      final newState = Map<String, bool>.from(state);
      newState.remove(taskId);
      state = newState;

      return success;
    } catch (e) {
      // Remove loading state on error
      final newState = Map<String, bool>.from(state);
      newState.remove(taskId);
      state = newState;
      rethrow;
    }
  }

  bool isTaskLoading(String taskId) {
    return state[taskId] ?? false;
  }
}

// Keep existing providers
final tasksSearchProvider =
    StateNotifierProvider<TasksSearchNotifier, String>((ref) {
  return TasksSearchNotifier();
});

class TasksSearchNotifier extends StateNotifier<String> {
  TasksSearchNotifier() : super('');

  void updateSearchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

final selectedTaskProvider =
    StateNotifierProvider<SelectedTaskNotifier, TreatmentTask?>((ref) {
  return SelectedTaskNotifier();
});

class SelectedTaskNotifier extends StateNotifier<TreatmentTask?> {
  SelectedTaskNotifier() : super(null);

  void selectTask(TreatmentTask task) {
    state = task;
  }

  void clearSelection() {
    state = null;
  }

  void updateSelectedTask(TreatmentTask updatedTask) {
    if (state?.taskId == updatedTask.taskId) {
      state = updatedTask;
    }
  }
}

final selectedWardProvider =
    StateNotifierProvider<SelectedWardNotifier, String?>((ref) {
  return SelectedWardNotifier();
});

class SelectedWardNotifier extends StateNotifier<String?> {
  SelectedWardNotifier() : super(null);

  void selectWard(String? wardName) {
    state = wardName;
  }

  void clearSelection() {
    state = null;
  }
}

final filteredTasksProvider = Provider<AsyncValue<List<TreatmentTask>>>((ref) {
  final treatmentDataAsync = ref.watch(wardTreatmentTasksProvider);
  final searchQuery = ref.watch(tasksSearchProvider);
  final selectedWard = ref.watch(selectedWardProvider);

  return treatmentDataAsync.when(
    data: (treatmentData) {
      List<TreatmentTask> allTasks = [];

      for (final ward in treatmentData.wards) {
        allTasks.addAll(ward.treatmentTasks);
      }

      if (selectedWard != null && selectedWard.isNotEmpty) {
        allTasks =
            allTasks.where((task) => task.wardName == selectedWard).toList();
      }

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        allTasks = allTasks.where((task) {
          return task.name.toLowerCase().contains(query) ||
              task.patientName.toLowerCase().contains(query) ||
              task.patientId.toLowerCase().contains(query) ||
              task.type.toLowerCase().contains(query) ||
              task.status.toLowerCase().contains(query);
        }).toList();
      }

      return AsyncValue.data(allTasks);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

// Main Screen with Enhanced Task Administration
class WardTreatmentTasksScreen extends ConsumerStatefulWidget {
  const WardTreatmentTasksScreen({super.key});

  @override
  ConsumerState<WardTreatmentTasksScreen> createState() =>
      _WardTreatmentTasksScreenState();
}

class _WardTreatmentTasksScreenState
    extends ConsumerState<WardTreatmentTasksScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
      }
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _handleRefresh();
      }
      if (event.logicalKey == LogicalKeyboardKey.escape &&
          _searchController.text.isNotEmpty) {
        _clearSearch();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(wardTreatmentTasksProvider.notifier).refreshTasks();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(tasksSearchProvider.notifier).clearSearch();
  }

  Future<void> _handleTaskAdministration(TreatmentTask task) async {
    try {
      final success =
          await ref.read(taskAdministrationProvider.notifier).administrateTask(
                patientId: task.patientId,
                admissionId: task.admissionId,
                taskId: task.taskId,
                taskType: task.type,
                notes: null, // You can add a dialog to collect notes
              );

      if (success && mounted) {
        // Update the task status locally
        ref
            .read(wardTreatmentTasksProvider.notifier)
            .updateTaskStatus(task.taskId, 'Administered');

        // Update selected task if it's the same task
        final updatedTask = task.copyWith(status: 'Administered');
        ref.read(selectedTaskProvider.notifier).updateSelectedTask(updatedTask);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.type} administered successfully'),
            backgroundColor: HospitalTheme.success,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Refresh',
              textColor: Colors.white,
              onPressed: _handleRefresh,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to administer task: ${e.toString()}'),
            backgroundColor: HospitalTheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleTaskAdministration(task),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showTaskNotesDialog(TreatmentTask task) async {
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Administration Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task: ${task.name}'),
            const SizedBox(height: 8),
            Text('Patient: ${task.patientName}'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Enter administration notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Administer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await ref
            .read(taskAdministrationProvider.notifier)
            .administrateTask(
              patientId: task.patientId,
              admissionId: task.admissionId,
              taskId: task.taskId,
              taskType: task.type,
              notes: notesController.text.trim().isNotEmpty
                  ? notesController.text.trim()
                  : null,
            );

        if (success && mounted) {
          // Update the task status locally
          ref
              .read(wardTreatmentTasksProvider.notifier)
              .updateTaskStatus(task.taskId, 'Administered');

          // Update selected task if it's the same task
          final updatedTask = task.copyWith(status: 'Administered');
          ref
              .read(selectedTaskProvider.notifier)
              .updateSelectedTask(updatedTask);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${task.type} administered successfully'),
              backgroundColor: HospitalTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to administer task: ${e.toString()}'),
              backgroundColor: HospitalTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;
    final isTablet = screenSize.width > 600 && screenSize.width <= 768;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: AppBar(
          backgroundColor: HospitalTheme.primary,
          foregroundColor: Colors.white,
          title: const Text('Ward Treatment Tasks'),
          elevation: 2,
          actions: [
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.refresh),
              onPressed: _handleRefresh,
              tooltip: 'Refresh (F5)',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: _buildResponsiveLayout(context, isDesktop, isTablet),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
      BuildContext context, bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return _buildDesktopSplitView(context);
    } else if (isTablet) {
      return _buildTabletView(context);
    } else {
      return _buildMobileView(context);
    }
  }

  Widget _buildDesktopSplitView(BuildContext context) {
    return Row(
      children: [
        // Master Panel (Left Side)
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: HospitalTheme.border),
              ),
            ),
            child: _buildMasterPanel(context, true),
          ),
        ),
        // Detail Panel (Right Side)
        Expanded(
          flex: 7,
          child: Container(
            color: HospitalTheme.background,
            child: _buildDetailPanel(context, true),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletView(BuildContext context) {
    final selectedTask = ref.watch(selectedTaskProvider);

    if (selectedTask != null) {
      return _buildDetailPanel(context, false);
    }

    return _buildMasterPanel(context, false);
  }

  Widget _buildMobileView(BuildContext context) {
    final selectedTask = ref.watch(selectedTaskProvider);

    if (selectedTask != null) {
      return _buildDetailPanel(context, false);
    }

    return _buildMasterPanel(context, false);
  }

  Widget _buildMasterPanel(BuildContext context, bool isDesktop) {
    final treatmentDataAsync = ref.watch(wardTreatmentTasksProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);

    return Column(
      children: [
        // Header and Controls - Fixed at top
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: HospitalTheme.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDesktop) ...[
                    _buildHeaderSection(context, isDesktop),
                    const SizedBox(height: 16.0),
                  ] else ...[
                    Text(
                      'Ward Treatment Tasks',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HospitalTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                  // Summary Cards
                  treatmentDataAsync.when(
                    data: (data) =>
                        _buildSummaryCards(context, data, isDesktop),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16.0),
                  // Ward Filter and Search
                  _buildFiltersAndSearch(context, isDesktop),
                ],
              ),
            ),
          ),
        ),
        // Tasks List - Scrollable
        Expanded(
          child: _buildTasksList(context, filteredTasks, isDesktop, true),
        ),
        // Keyboard Shortcuts (Desktop only) - Fixed at bottom
        if (isDesktop) _buildKeyboardShortcuts(context),
      ],
    );
  }

  Widget _buildDetailPanel(BuildContext context, bool isDesktop) {
    final selectedTask = ref.watch(selectedTaskProvider);

    if (selectedTask == null) {
      return _buildEmptyDetailPanel(context, isDesktop);
    }

    return Column(
      children: [
        // Detail Header - Fixed at top
        Container(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border),
            ),
          ),
          child: Row(
            children: [
              if (!isDesktop)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      ref.read(selectedTaskProvider.notifier).clearSelection(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HospitalTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      selectedTask.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HospitalTheme.textMedium,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Detail Content - Scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: _buildTaskDetails(context, selectedTask, isDesktop),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDetailPanel(BuildContext context, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.0,
              height: 120.0,
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 60.0,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Select a Task',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Choose a treatment task from the list to view its details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetails(
      BuildContext context, TreatmentTask task, bool isDesktop) {
    final administrationState = ref.watch(taskAdministrationProvider);
    final isTaskLoading = administrationState[task.taskId] ?? false;

    Color statusColor;
    IconData statusIcon;

    switch (task.status.toLowerCase()) {
      case 'completed':
      case 'administered':
        statusColor = HospitalTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'in progress':
        statusColor = HospitalTheme.warning;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'pending':
      default:
        statusColor = HospitalTheme.info;
        statusIcon = Icons.pending;
        break;
    }

    Color typeColor;
    IconData typeIcon;

    switch (task.type.toLowerCase()) {
      case 'medication':
        typeColor = HospitalTheme.pharmacy;
        typeIcon = Icons.medication;
        break;
      case 'iv fluid':
        typeColor = HospitalTheme.medical;
        typeIcon = Icons.opacity;
        break;
      case 'procedure':
        typeColor = HospitalTheme.laboratory;
        typeIcon = Icons.healing;
        break;
      case 'special instruction':
        typeColor = HospitalTheme.warning;
        typeIcon = Icons.assignment_outlined;
        break;
      default:
        typeColor = HospitalTheme.textMedium;
        typeIcon = Icons.task;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task Header Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isDesktop ? 60.0 : 50.0,
                    height: isDesktop ? 60.0 : 50.0,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: HospitalTheme.radiusMedium,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: isDesktop ? 30.0 : 25.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: HospitalTheme.textDark,
                                  ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          task.type,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: typeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, size: 20.0, color: statusColor),
                    const SizedBox(width: 12.0),
                    Text(
                      task.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Patient Information Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, size: 20.0, color: HospitalTheme.primary),
                  const SizedBox(width: 8.0),
                  Text(
                    'Patient Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildDetailInfoGrid([
                _DetailInfo('Name', task.patientName),
                _DetailInfo('Patient ID', task.patientId),
                _DetailInfo('Age', '${task.age} years'),
                _DetailInfo('Gender', task.gender),
                _DetailInfo('Ward', task.wardName),
                _DetailInfo('Bed Number', 'Bed ${task.bedNumber}'),
              ], isDesktop),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Task Details Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, size: 20.0, color: typeColor),
                  const SizedBox(width: 8.0),
                  Text(
                    'Task Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: isDesktop ? 200.0 : 150.0,
                ),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.05),
                  border: Border.all(color: typeColor.withOpacity(0.2)),
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    task.details,
                    style: TextStyle(
                      color: HospitalTheme.textDark,
                      fontSize: 14.0,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Schedule Information Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 20.0, color: HospitalTheme.info),
                  const SizedBox(width: 8.0),
                  Text(
                    'Schedule Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildDetailInfoGrid([
                _DetailInfo('Date', _formatDate(task.date)),
                _DetailInfo('Time', _formatTime(task.time)),
                _DetailInfo('Task ID', task.taskId),
                _DetailInfo('Admission ID', task.admissionId),
              ], isDesktop),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Enhanced Action Buttons Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.touch_app,
                      size: 20.0, color: HospitalTheme.primary),
                  const SizedBox(width: 8.0),
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (task.status.toLowerCase() == 'pending') ...[
                      SizedBox(
                        width: isDesktop ? 150.0 : 130.0,
                        child: ElevatedButton.icon(
                          onPressed: isTaskLoading
                              ? null
                              : () => _showTaskNotesDialog(task),
                          icon: isTaskLoading
                              ? SizedBox(
                                  width: 16.0,
                                  height: 16.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                              isTaskLoading ? 'Processing...' : 'Start Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                    if (task.status.toLowerCase() == 'in progress') ...[
                      SizedBox(
                        width: isDesktop ? 160.0 : 140.0,
                        child: ElevatedButton.icon(
                          onPressed: isTaskLoading
                              ? null
                              : () => _showTaskNotesDialog(task),
                          icon: isTaskLoading
                              ? SizedBox(
                                  width: 16.0,
                                  height: 16.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(isTaskLoading
                              ? 'Processing...'
                              : 'Complete Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                    if (task.status.toLowerCase() == 'completed' ||
                        task.status.toLowerCase() == 'administered') ...[
                      SizedBox(
                        width: isDesktop ? 160.0 : 140.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: HospitalTheme.success.withOpacity(0.1),
                            borderRadius: HospitalTheme.radiusSmall,
                            border: Border.all(color: HospitalTheme.success),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: HospitalTheme.success,
                                size: 18.0,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'Task Completed',
                                style: TextStyle(
                                  color: HospitalTheme.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                    SizedBox(
                      width: isDesktop ? 140.0 : 120.0,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement add notes functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Add notes functionality coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.note_add),
                        label: const Text('Add Notes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Add bottom padding for the last item
        const SizedBox(height: 20.0),
      ],
    );
  }

  // Keep all existing helper methods unchanged...
  Widget _buildDetailInfoGrid(List<_DetailInfo> items, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16.0,
          runSpacing: 12.0,
          children: items
              .map((item) => _buildDetailInfoItem(item, isDesktop, constraints))
              .toList(),
        );
      },
    );
  }

  Widget _buildDetailInfoItem(
      _DetailInfo item, bool isDesktop, BoxConstraints constraints) {
    final itemWidth = isDesktop
        ? (constraints.maxWidth > 400 ? 180.0 : constraints.maxWidth * 0.45)
        : constraints.maxWidth;

    return SizedBox(
      width: itemWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12.0,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 14.0,
              color: HospitalTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        Container(
          width: isDesktop ? 60.0 : 50.0,
          height: isDesktop ? 60.0 : 50.0,
          decoration: BoxDecoration(
            color: HospitalTheme.primary.withOpacity(0.1),
            borderRadius: HospitalTheme.radiusMedium,
          ),
          child: Icon(
            Icons.assignment,
            color: HospitalTheme.primary,
            size: isDesktop ? 30.0 : 25.0,
          ),
        ),
        SizedBox(width: isDesktop ? 16.0 : 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ward Treatment Tasks',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HospitalTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Manage treatment tasks for assigned wards',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HospitalTheme.textMedium,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, WardTreatmentData data, bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSummaryCard(
            context,
            'Current Shift',
            data.currentShift,
            Icons.schedule,
            HospitalTheme.info,
            isDesktop,
          ),
          const SizedBox(width: 12.0),
          _buildSummaryCard(
            context,
            'Total Patients',
            data.totalPatients.toString(),
            Icons.people,
            HospitalTheme.primary,
            isDesktop,
          ),
          const SizedBox(width: 12.0),
          _buildSummaryCard(
            context,
            'Total Tasks',
            data.totalTasks.toString(),
            Icons.assignment,
            HospitalTheme.success,
            isDesktop,
          ),
          const SizedBox(width: 12.0),
          _buildSummaryCard(
            context,
            'Assigned Wards',
            data.assignedWards.length.toString(),
            Icons.local_hospital,
            HospitalTheme.secondary,
            isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDesktop,
  ) {
    return Container(
      width: isDesktop ? null : 120.0,
      padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isDesktop ? 24.0 : 20.0),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 18.0 : 16.0,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 12.0 : 11.0,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSearch(BuildContext context, bool isDesktop) {
    final treatmentDataAsync = ref.watch(wardTreatmentTasksProvider);
    final selectedWard = ref.watch(selectedWardProvider);

    return Column(
      children: [
        treatmentDataAsync.when(
          data: (data) => Container(
            width: double.infinity,
            child: DropdownButtonFormField<String?>(
              value: selectedWard,
              decoration: const InputDecoration(
                labelText: 'Filter by Ward',
                prefixIcon: Icon(Icons.local_hospital),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Wards'),
                ),
                ...data.wards.map((ward) => DropdownMenuItem<String?>(
                      value: ward.wardName,
                      child: Text('${ward.wardName} (${ward.taskCount} tasks)'),
                    )),
              ],
              onChanged: (value) =>
                  ref.read(selectedWardProvider.notifier).selectWard(value),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12.0),
        TextFormField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) =>
              ref.read(tasksSearchProvider.notifier).updateSearchQuery(value),
          decoration: InputDecoration(
            hintText: 'Search tasks, patients, or types...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList(
      BuildContext context,
      AsyncValue<List<TreatmentTask>> filteredTasks,
      bool isDesktop,
      bool isMasterView) {
    return filteredTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyState(context, isDesktop);
        }

        return ListView.builder(
          padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskListItem(context, task, isDesktop);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _buildErrorState(context, error.toString(), isDesktop),
    );
  }

  Widget _buildTaskListItem(
      BuildContext context, TreatmentTask task, bool isDesktop) {
    final selectedTask = ref.watch(selectedTaskProvider);
    final administrationState = ref.watch(taskAdministrationProvider);
    final isSelected = selectedTask?.taskId == task.taskId;
    final isTaskLoading = administrationState[task.taskId] ?? false;

    Color statusColor;
    IconData statusIcon;

    switch (task.status.toLowerCase()) {
      case 'completed':
      case 'administered':
        statusColor = HospitalTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'in progress':
        statusColor = HospitalTheme.warning;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'pending':
      default:
        statusColor = HospitalTheme.info;
        statusIcon = Icons.pending;
        break;
    }

    Color typeColor;
    IconData typeIcon;

    switch (task.type.toLowerCase()) {
      case 'medication':
        typeColor = HospitalTheme.pharmacy;
        typeIcon = Icons.medication;
        break;
      case 'iv fluid':
        typeColor = HospitalTheme.medical;
        typeIcon = Icons.opacity;
        break;
      case 'procedure':
        typeColor = HospitalTheme.laboratory;
        typeIcon = Icons.healing;
        break;
      case 'special instruction':
        typeColor = HospitalTheme.warning;
        typeIcon = Icons.assignment_outlined;
        break;
      default:
        typeColor = HospitalTheme.textMedium;
        typeIcon = Icons.task;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? HospitalTheme.shadow : null,
      ),
      child: InkWell(
        borderRadius: HospitalTheme.radiusMedium,
        onTap: () => ref.read(selectedTaskProvider.notifier).selectTask(task),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: HospitalTheme.radiusSmall,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                            fontSize: 14.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '${task.patientName} - Bed ${task.bedNumber}',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 12.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: HospitalTheme.radiusSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isTaskLoading)
                              SizedBox(
                                width: 12.0,
                                height: 12.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: statusColor,
                                ),
                              )
                            else
                              Icon(statusIcon, size: 12.0, color: statusColor),
                            const SizedBox(width: 4.0),
                            Text(
                              isTaskLoading ? 'Processing...' : task.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        task.type,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14.0, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      task.wardName,
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 12.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.access_time,
                      size: 14.0, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4.0),
                  Text(
                    _formatTime(task.time),
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12.0,
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

  Widget _buildEmptyState(BuildContext context, bool isDesktop) {
    final searchQuery = ref.watch(tasksSearchProvider);
    final selectedWard = ref.watch(selectedWardProvider);
    final isFiltered = searchQuery.isNotEmpty || selectedWard != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 120.0 : 100.0,
              height: isDesktop ? 120.0 : 100.0,
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.search_off : Icons.assignment_outlined,
                size: isDesktop ? 60.0 : 50.0,
                color: HospitalTheme.textMedium,
              ),
            ),
            SizedBox(height: isDesktop ? 24.0 : 16.0),
            Text(
              isFiltered ? 'No tasks found' : 'No treatment tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              isFiltered
                  ? 'Try adjusting your search or filter criteria'
                  : 'No treatment tasks are currently assigned',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textLight,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16.0),
              Wrap(
                spacing: 12.0,
                children: [
                  if (searchQuery.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Search'),
                    ),
                  if (selectedWard != null)
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(selectedWardProvider.notifier)
                          .clearSelection(),
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filter'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 120.0 : 100.0,
              height: isDesktop ? 120.0 : 100.0,
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: isDesktop ? 60.0 : 50.0,
                color: HospitalTheme.error,
              ),
            ),
            SizedBox(height: isDesktop ? 24.0 : 16.0),
            Text(
              'Error Loading Tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardShortcuts(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: HospitalTheme.buildCard(
        padding: const EdgeInsets.all(12.0),
        backgroundColor: HospitalTheme.surfaceLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keyboard Shortcuts',
              style: TextStyle(
                color: HospitalTheme.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              '• Ctrl+F: Focus search • F5: Refresh • Esc: Clear search',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String timeString) {
    try {
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period IST';
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }
}

// Helper class for detail information
class _DetailInfo {
  final String label;
  final String value;

  const _DetailInfo(this.label, this.value);
}
