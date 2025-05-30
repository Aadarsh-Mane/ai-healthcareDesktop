// ward_treatment_tasks_screen.dart
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Models
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

// Providers
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

  // Update the fetchWardTreatmentTasks method in WardTreatmentTasksNotifier
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle direct response without wrapper
        if (responseData.containsKey('currentShift')) {
          // Direct response
          final treatmentData = WardTreatmentData.fromJson(responseData);
          state = AsyncValue.data(treatmentData);
        } else {
          // Wrapped response
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
      print('Error: $e');
      print('StackTrace: $stackTrace');

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
}

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

      // Filter by selected ward
      if (selectedWard != null && selectedWard.isNotEmpty) {
        allTasks =
            allTasks.where((task) => task.wardName == selectedWard).toList();
      }

      // Filter by search query
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

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

// Main Screen
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
      // Ctrl/Cmd + F to focus search
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
      }
      // F5 to refresh
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _handleRefresh();
      }
      // Escape to clear search
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
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Ward Treatment Tasks',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
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
        // Header and Controls
        Container(
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
                data: (data) => _buildSummaryCards(context, data, isDesktop),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16.0),
              // Ward Filter and Search
              _buildFiltersAndSearch(context, isDesktop),
            ],
          ),
        ),
        // Tasks List
        Expanded(
          child: _buildTasksList(context, filteredTasks, isDesktop, true),
        ),
        // Keyboard Shortcuts (Desktop only)
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
        // Detail Header
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Detail Content
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
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Current Shift',
            data.currentShift,
            Icons.schedule,
            HospitalTheme.info,
            isDesktop,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total Patients',
            data.totalPatients.toString(),
            Icons.people,
            HospitalTheme.primary,
            isDesktop,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total Tasks',
            data.totalTasks.toString(),
            Icons.assignment,
            HospitalTheme.success,
            isDesktop,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Assigned Wards',
            data.assignedWards.length.toString(),
            Icons.local_hospital,
            HospitalTheme.secondary,
            isDesktop,
          ),
        ),
      ],
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
        // Ward Filter
        treatmentDataAsync.when(
          data: (data) => Container(
            width: double.infinity,
            child: DropdownButtonFormField<String?>(
              value: selectedWard,
              decoration: InputDecoration(
                labelText: 'Filter by Ward',
                prefixIcon: const Icon(Icons.local_hospital),
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
        // Search Bar
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

        if (isMasterView) {
          return _buildTasksListView(context, tasks, isDesktop);
        } else {
          return _buildTasksGrid(context, tasks, isDesktop);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _buildErrorState(context, error.toString(), isDesktop),
    );
  }

  Widget _buildTasksListView(
      BuildContext context, List<TreatmentTask> tasks, bool isDesktop) {
    return ListView.builder(
      padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskListItem(context, task, isDesktop);
      },
    );
  }

  Widget _buildTaskListItem(
      BuildContext context, TreatmentTask task, bool isDesktop) {
    final selectedTask = ref.watch(selectedTaskProvider);
    final isSelected = selectedTask?.taskId == task.taskId;

    Color statusColor;
    IconData statusIcon;

    switch (task.status.toLowerCase()) {
      case 'completed':
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
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '${task.patientName} - Bed ${task.bedNumber}',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 12.0,
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
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: HospitalTheme.radiusSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12.0, color: statusColor),
                            const SizedBox(width: 4.0),
                            Text(
                              task.status,
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
                  Text(
                    task.wardName,
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12.0,
                    ),
                  ),
                  const Spacer(),
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

  Widget _buildTasksGrid(
      BuildContext context, List<TreatmentTask> tasks, bool isDesktop) {
    return ListView.separated(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      itemCount: tasks.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: isDesktop ? 16.0 : 12.0),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(context, task, isDesktop);
      },
    );
  }

  Widget _buildTaskCard(
      BuildContext context, TreatmentTask task, bool isDesktop) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status.toLowerCase()) {
      case 'completed':
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

    return HospitalTheme.buildCard(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            Row(
              children: [
                Container(
                  width: isDesktop ? 50.0 : 45.0,
                  height: isDesktop ? 50.0 : 45.0,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: HospitalTheme.radiusMedium,
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: isDesktop ? 25.0 : 22.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        task.type,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16.0, color: statusColor),
                      const SizedBox(width: 8.0),
                      Text(
                        task.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Patient Information
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: HospitalTheme.radiusSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: 16.0, color: HospitalTheme.textMedium),
                      const SizedBox(width: 8.0),
                      Text(
                        'Patient Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('Name', task.patientName),
                      ),
                      Expanded(
                        child: _buildInfoRow('Patient ID', task.patientId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('Age', '${task.age} years'),
                      ),
                      Expanded(
                        child: _buildInfoRow('Gender', task.gender),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('Ward', task.wardName),
                      ),
                      Expanded(
                        child: _buildInfoRow('Bed', 'Bed ${task.bedNumber}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Task Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description,
                        size: 16.0, color: HospitalTheme.textMedium),
                    const SizedBox(width: 8.0),
                    Text(
                      'Task Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: HospitalTheme.border),
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  child: Text(
                    task.details,
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 13.0,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Schedule Information
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: HospitalTheme.info.withOpacity(0.05),
                borderRadius: HospitalTheme.radiusSmall,
                border: Border.all(color: HospitalTheme.info.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 16.0, color: HospitalTheme.info),
                      const SizedBox(width: 8.0),
                      Text(
                        'Schedule Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('Date', _formatDate(task.date)),
                      ),
                      Expanded(
                        child: _buildInfoRow('Time', _formatTime(task.time)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  _buildInfoRow('Admission ID', task.admissionId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetails(
      BuildContext context, TreatmentTask task, bool isDesktop) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status.toLowerCase()) {
      case 'completed':
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
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.05),
                  border: Border.all(color: typeColor.withOpacity(0.2)),
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Text(
                  task.details,
                  style: TextStyle(
                    color: HospitalTheme.textDark,
                    fontSize: 14.0,
                    height: 1.5,
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

        // Action Buttons Card
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
              Row(
                children: [
                  if (task.status.toLowerCase() == 'pending') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement start task functionality
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                  if (task.status.toLowerCase() == 'in progress') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement complete task functionality
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Complete Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement add notes functionality
                      },
                      icon: const Icon(Icons.note_add),
                      label: const Text('Add Notes'),
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

  Widget _buildDetailInfoGrid(List<_DetailInfo> items, bool isDesktop) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 12.0,
      children:
          items.map((item) => _buildDetailInfoItem(item, isDesktop)).toList(),
    );
  }

  Widget _buildDetailInfoItem(_DetailInfo item, bool isDesktop) {
    return SizedBox(
      width: isDesktop ? 200.0 : double.infinity,
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
          ),
        ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (searchQuery.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Search'),
                    ),
                  if (searchQuery.isNotEmpty && selectedWard != null)
                    const SizedBox(width: 12.0),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.0,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.0,
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.0,
                color: HospitalTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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
