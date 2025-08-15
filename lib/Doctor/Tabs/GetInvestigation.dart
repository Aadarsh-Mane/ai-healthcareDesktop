import 'dart:convert';
import 'package:doctordesktop/Doctor/Tabs/UploadReportScreen.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/getInvestigationModel.dart';

class InvestigationScreen1 extends StatefulWidget {
  const InvestigationScreen1({Key? key}) : super(key: key);

  @override
  _InvestigationScreenState createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen1>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Investigation> _investigations = [];
  Investigation? _selectedInvestigation;
  bool _isPanelOpen = false;

  late AnimationController _panelAnimationController;
  late Animation<double> _panelAnimation;
  late AnimationController _loadingAnimationController;

  // Enhanced filtering and sorting
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
  String _typeFilter = 'All';
  String _sortBy = 'Date (Newest)';
  DateTimeRange? _dateRange;

  final List<String> _statusOptions = [
    'All',
    'Scheduled',
    'Results Available',
    'In Progress',
    'Cancelled'
  ];

  final List<String> _priorityOptions = [
    'All',
    'Urgent',
    'High',
    'Routine',
    'Low'
  ];

  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Priority',
    'Patient Name',
    'Status'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchInvestigations();
    _setupKeyboardShortcuts();
  }

  void _initializeAnimations() {
    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _panelAnimation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeInOut,
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  void _setupKeyboardShortcuts() {
    // Add keyboard shortcuts for better desktop experience
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl/Cmd + F for search focus
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        // Focus search field (implement if needed)
        return true;
      }

      // Escape to close panel
      if (event.logicalKey == LogicalKeyboardKey.escape && _isPanelOpen) {
        _closePanel();
        return true;
      }

      // F5 to refresh
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _fetchInvestigations();
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    _loadingAnimationController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  Future<void> _fetchInvestigations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _loadingAnimationController.repeat();

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/investigate/getAllInvestigations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final investigationResponse = InvestigationResponse.fromJson(jsonData);

        // Filter out investigations with unknown patients
        final validInvestigations = investigationResponse.data
            .where((investigation) =>
                investigation.patient.name.trim().toLowerCase() != 'unknown' &&
                investigation.patient.name.trim().isNotEmpty)
            .toList();

        setState(() {
          _investigations = validInvestigations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = _getErrorMessage(response.statusCode);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _handleNetworkError(e);
        _isLoading = false;
      });
    } finally {
      _loadingAnimationController.stop();
    }
  }

  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please try again.';
      case 401:
        return 'Unauthorized access. Please login again.';
      case 403:
        return 'Access forbidden. Check your permissions.';
      case 404:
        return 'Investigation data not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Failed to load investigations (Error: $statusCode)';
    }
  }

  String _handleNetworkError(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please check your connection and try again.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else {
      return 'Network error: ${error.toString()}';
    }
  }

  void _viewInvestigationDetails(Investigation investigation) {
    setState(() {
      _selectedInvestigation = investigation;
      if (!_isPanelOpen) {
        _isPanelOpen = true;
        _panelAnimationController.forward();
      }
    });
  }

  void _closePanel() {
    _panelAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isPanelOpen = false;
          _selectedInvestigation = null;
        });
      }
    });
  }

  void _navigateToUploadReport(String investigationId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UploadReportScreen(investigationId: investigationId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openAttachment(String url) {
    try {
      Methods().openPdf(url);
    } catch (e) {
      _showSnackBar('Failed to open attachment: ${e.toString()}',
          isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? HospitalTheme.error : HospitalTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  List<Investigation> get _filteredInvestigations {
    var investigations = _investigations.where((investigation) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          investigation.patient.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.investigationType
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.reasonForInvestigation
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.doctorName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.patientIdNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Status filter
      final matchesStatus =
          _statusFilter == 'All' || investigation.status == _statusFilter;

      // Priority filter
      final matchesPriority =
          _priorityFilter == 'All' || investigation.priority == _priorityFilter;

      // Type filter
      final matchesType = _typeFilter == 'All' ||
          investigation.investigationType == _typeFilter;

      // Date range filter
      final matchesDateRange = _dateRange == null ||
          (investigation.orderDate.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1))) &&
              investigation.orderDate
                  .isBefore(_dateRange!.end.add(const Duration(days: 1))));

      return matchesSearch &&
          matchesStatus &&
          matchesPriority &&
          matchesType &&
          matchesDateRange;
    }).toList();

    // Apply sorting
    investigations.sort((a, b) {
      switch (_sortBy) {
        case 'Date (Newest)':
          return b.orderDate.compareTo(a.orderDate);
        case 'Date (Oldest)':
          return a.orderDate.compareTo(b.orderDate);
        case 'Priority':
          final priorityOrder = {
            'Urgent': 0,
            'High': 1,
            'Routine': 2,
            'Low': 3
          };
          return (priorityOrder[a.priority] ?? 4)
              .compareTo(priorityOrder[b.priority] ?? 4);
        case 'Patient Name':
          return a.patient.name
              .toLowerCase()
              .compareTo(b.patient.name.toLowerCase());
        case 'Status':
          return a.status.compareTo(b.status);
        default:
          return 0;
      }
    });

    return investigations;
  }

  // Get unique investigation types for filter
  List<String> get _investigationTypes {
    final types = ['All'];
    final uniqueTypes =
        _investigations.map((inv) => inv.investigationType).toSet().toList();
    uniqueTypes.sort();
    types.addAll(uniqueTypes);
    return types;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        title: 'Laboratory Investigations',
        context: context,
        centerTitle: false,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showAdvancedFilters,
            tooltip: 'Advanced Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchInvestigations,
            tooltip: 'Refresh (F5)',
          ),
          if (_isPanelOpen)
            IconButton(
              icon: const Icon(Icons.close_fullscreen_rounded),
              onPressed: _closePanel,
              tooltip: 'Close Panel (Esc)',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1200;

        if (_isLoading && _investigations.isEmpty) {
          return _buildLoadingState();
        }

        if (_errorMessage.isNotEmpty && _investigations.isEmpty) {
          return _buildErrorState();
        }

        if (_investigations.isEmpty) {
          return _buildEmptyState();
        }

        return Row(
          children: [
            // Main content
            Expanded(
              flex: _isPanelOpen ? (isWideScreen ? 3 : 2) : 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnhancedFilterBar(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildInvestigationTable()),
                  ],
                ),
              ),
            ),

            // Detail panel with animation
            if (_isPanelOpen && _selectedInvestigation != null)
              AnimatedBuilder(
                animation: _panelAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      (1 - _panelAnimation.value) * constraints.maxWidth * 0.4,
                      0,
                    ),
                    child: Container(
                      width: constraints.maxWidth * 0.4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: _buildDetailPanel(_selectedInvestigation!),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading investigations...',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch the latest data',
            style: TextStyle(
              color: HospitalTheme.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: HospitalTheme.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Data',
              style: TextStyle(
                color: HospitalTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchInvestigations,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.science_outlined,
                color: HospitalTheme.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Investigations Found',
              style: TextStyle(
                color: HospitalTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are no valid investigations to display.\nTry adjusting your filters or refresh the data.',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchInvestigations,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh Data'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFilterBar() {
    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with statistics
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investigations Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing ${_filteredInvestigations.length} of ${_investigations.length} investigations',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildQuickStats(),
            ],
          ),

          const SizedBox(height: 20),

          // Search and filters
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildWideScreenFilters();
              } else {
                return _buildNarrowScreenFilters();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalCount = _investigations.length;
    final scheduledCount =
        _investigations.where((inv) => inv.status == 'Scheduled').length;
    final completedCount = _investigations
        .where((inv) => inv.status == 'Results Available')
        .length;
    final urgentCount =
        _investigations.where((inv) => inv.priority == 'Urgent').length;

    return Row(
      children: [
        _buildStatChip('Total', totalCount, HospitalTheme.primary),
        const SizedBox(width: 8),
        _buildStatChip('Scheduled', scheduledCount, HospitalTheme.warning),
        const SizedBox(width: 8),
        _buildStatChip('Completed', completedCount, HospitalTheme.success),
        const SizedBox(width: 8),
        _buildStatChip('Urgent', urgentCount, HospitalTheme.error),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideScreenFilters() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchField()),
        const SizedBox(width: 16),
        Expanded(child: _buildStatusDropdown()),
        const SizedBox(width: 16),
        Expanded(child: _buildPriorityDropdown()),
        const SizedBox(width: 16),
        Expanded(child: _buildSortDropdown()),
        const SizedBox(width: 16),
        _buildDateRangeButton(),
      ],
    );
  }

  Widget _buildNarrowScreenFilters() {
    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatusDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildPriorityDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildSortDropdown()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDateRangeButton()),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error.withOpacity(0.1),
                foregroundColor: HospitalTheme.error,
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search patients, tests, doctors, or ID numbers...',
        prefixIcon: Icon(Icons.search_rounded, color: HospitalTheme.primary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon:
                    Icon(Icons.clear_rounded, color: HospitalTheme.textMedium),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _statusFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon:
            Icon(Icons.assignment_outlined, color: HospitalTheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _statusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _statusFilter = value!),
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: _priorityFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Priority',
        prefixIcon:
            Icon(Icons.priority_high_rounded, color: HospitalTheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _priorityOptions.map((priority) {
        return DropdownMenuItem<String>(
          value: priority,
          child: Text(priority, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _priorityFilter = value!),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sort By',
        prefixIcon: Icon(Icons.sort_rounded, color: HospitalTheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _sortOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _sortBy = value!),
    );
  }

  Widget _buildDateRangeButton() {
    return OutlinedButton.icon(
      onPressed: _selectDateRange,
      icon: Icon(
        Icons.date_range_rounded,
        color: _dateRange != null
            ? HospitalTheme.primary
            : HospitalTheme.textMedium,
      ),
      label: Text(
        _dateRange != null
            ? '${_formatDateShort(_dateRange!.start)} - ${_formatDateShort(_dateRange!.end)}'
            : 'Date Range',
        style: TextStyle(
          color: _dateRange != null
              ? HospitalTheme.primary
              : HospitalTheme.textMedium,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color:
              _dateRange != null ? HospitalTheme.primary : HospitalTheme.border,
        ),
      ),
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: HospitalTheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _statusFilter = 'All';
      _priorityFilter = 'All';
      _typeFilter = 'All';
      _dateRange = null;
    });
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => _buildAdvancedFilterDialog(),
    );
  }

  Widget _buildAdvancedFilterDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune_rounded, color: HospitalTheme.primary),
          const SizedBox(width: 8),
          const Text('Advanced Filters'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _typeFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Investigation Type',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _investigationTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) => setState(() => _typeFilter = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {}); // Refresh the filtered list
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildInvestigationTable() {
    return HospitalTheme.buildCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.primaryLight.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.science_rounded,
                    color: HospitalTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Investigation Results (${_filteredInvestigations.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.primary,
                  ),
                ),
                const Spacer(),
                if (_filteredInvestigations.length != _investigations.length)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HospitalTheme.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Filtered',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Table content
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: _buildDataTable(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(
        HospitalTheme.primaryLight.withOpacity(0.08),
      ),
      dataRowMinHeight: 72,
      dataRowMaxHeight: 72,
      columnSpacing: 20,
      showCheckboxColumn: false,
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: HospitalTheme.primary,
        fontSize: 14,
      ),
      columns: const [
        DataColumn(label: Text('Patient')),
        DataColumn(label: Text('Investigation')),
        DataColumn(label: Text('Reason')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Priority')),
        DataColumn(label: Text('Ordered')),
        DataColumn(label: Text('Scheduled')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _filteredInvestigations.map((investigation) {
        return DataRow(
          onSelectChanged: (_) => _viewInvestigationDetails(investigation),
          cells: [
            DataCell(_buildPatientInfo(investigation)),
            DataCell(_buildInvestigationInfo(investigation)),
            DataCell(_buildReasonInfo(investigation)),
            DataCell(_buildStatusBadge(investigation.status)),
            DataCell(_buildPriorityBadge(investigation.priority)),
            DataCell(_buildDateInfo(investigation.orderDate)),
            DataCell(_buildDateInfo(investigation.scheduledDate)),
            DataCell(_buildActionButtons(investigation)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPatientInfo(Investigation investigation) {
    return Container(
      width: 200,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HospitalTheme.medical.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                investigation.patient.name.isNotEmpty
                    ? investigation.patient.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: HospitalTheme.medical,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  investigation.patient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${investigation.patientIdNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationInfo(Investigation investigation) {
    return Container(
      width: 160,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getInvestigationIcon(investigation.investigationType),
              color: HospitalTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  investigation.investigationType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. ${investigation.doctorName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: HospitalTheme.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonInfo(Investigation investigation) {
    return Container(
      width: 180,
      child: Tooltip(
        message: investigation.reasonForInvestigation,
        child: Text(
          investigation.reasonForInvestigation,
          style: TextStyle(
            fontSize: 13,
            color: HospitalTheme.textDark,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color priorityColor = _getPriorityColor(priority);
    IconData priorityIcon = _getPriorityIcon(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priorityIcon, size: 14, color: priorityColor),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(DateTime date) {
    return Container(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatDateShort(date),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTimeShort(date),
            style: TextStyle(
              fontSize: 11,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Investigation investigation) {
    return Container(
      width: 160,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'View Details',
            child: IconButton(
              icon:
                  Icon(Icons.visibility_outlined, color: HospitalTheme.primary),
              onPressed: () => _viewInvestigationDetails(investigation),
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (investigation.attachments.isNotEmpty)
            Tooltip(
              message: 'View Report',
              child: IconButton(
                icon:
                    Icon(Icons.description_outlined, color: HospitalTheme.info),
                onPressed: () =>
                    _openAttachment(investigation.attachments.first.fileUrl),
                visualDensity: VisualDensity.compact,
              ),
            ),
          Tooltip(
            message: 'Upload Report',
            child: IconButton(
              icon: Icon(Icons.upload_file_outlined,
                  color: HospitalTheme.success),
              onPressed: () => _navigateToUploadReport(investigation.id),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(Investigation investigation) {
    return Column(
      children: [
        // Enhanced header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [HospitalTheme.primary, HospitalTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getInvestigationIcon(investigation.investigationType),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investigation.investigationType,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      investigation.patient.name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${investigation.patientIdNumber}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: _closePanel,
                tooltip: 'Close (Esc)',
              ),
            ],
          ),
        ),

        // Enhanced content
        Expanded(
          child: Container(
            color: HospitalTheme.background,
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status overview cards
                    _buildStatusOverviewCards(investigation),
                    const SizedBox(height: 24),

                    // Investigation details
                    _buildDetailSection(
                      title: 'Investigation Details',
                      icon: Icons.medical_information_rounded,
                      children: [
                        _buildDetailRow(
                            'Reason',
                            investigation.reasonForInvestigation,
                            Icons.help_outline),
                        _buildDetailRow('Ordering Doctor',
                            investigation.doctorName, Icons.person_outline),
                        _buildDetailRow(
                            'Parameters',
                            _getParametersText(
                                investigation.investigationDetails),
                            Icons.list_alt),
                        if (investigation.clinicalHistory.isNotEmpty)
                          _buildDetailRow('Clinical History',
                              investigation.clinicalHistory, Icons.history_edu),
                        _buildDetailRow(
                            'Admission Record',
                            investigation.admissionRecordId,
                            Icons.local_hospital),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Billing information
                    _buildDetailSection(
                      title: 'Billing Information',
                      icon: Icons.payments_rounded,
                      children: [
                        if (investigation.billing.cost != null)
                          _buildDetailRow(
                              'Cost',
                              '₹${investigation.billing.cost}',
                              Icons.attach_money),
                        _buildDetailRow(
                            'Payment Status',
                            investigation.billing.paymentStatus ??
                                'Not Available',
                            Icons.payment),
                        _buildDetailRow(
                            'Insurance Covered',
                            investigation.billing.insuranceCovered == true
                                ? 'Yes'
                                : 'No',
                            Icons.health_and_safety),
                      ],
                    ),

                    // Tags section (if available)
                    if (investigation.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildTagsSection(investigation.tags),
                    ],

                    // Performed by section (if available)
                    if (investigation.performedBy != null) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        title: 'Performed By',
                        icon: Icons.person_pin_rounded,
                        children: [
                          _buildDetailRow('Name',
                              investigation.performedBy!.name, Icons.person),
                          _buildDetailRow(
                              'Designation',
                              investigation.performedBy!.designation,
                              Icons.work),
                          _buildDetailRow(
                              'Facility',
                              investigation.performedBy!.facility,
                              Icons.business),
                        ],
                      ),
                    ],

                    // Attachments section (if available)
                    if (investigation.attachments.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildAttachmentsSection(investigation.attachments),
                    ],

                    // Notes section (if available)
                    if (investigation.notes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildNotesSection(investigation.notes),
                    ],

                    // Results section (if available)
                    if (investigation.results != null) ...[
                      const SizedBox(height: 20),
                      _buildResultsSection(investigation.results!),
                    ],

                    // Action buttons
                    const SizedBox(height: 32),
                    _buildActionButtonsSection(investigation),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOverviewCards(Investigation investigation) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            'Status',
            investigation.status,
            _getStatusColor(investigation.status),
            _getStatusIcon(investigation.status),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            'Priority',
            investigation.priority,
            _getPriorityColor(investigation.priority),
            _getPriorityIcon(investigation.priority),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            'Ordered',
            _formatDateShort(investigation.orderDate),
            HospitalTheme.info,
            Icons.calendar_today_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: HospitalTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: HospitalTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_rounded, color: HospitalTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(List<Attachment> attachments) {
    return _buildDetailSection(
      title: 'Attachments (${attachments.length})',
      icon: Icons.attach_file_rounded,
      children: attachments
          .map((attachment) => _buildAttachmentItem(attachment))
          .toList(),
    );
  }

  Widget _buildNotesSection(List<Note> notes) {
    return _buildDetailSection(
      title: 'Notes (${notes.length})',
      icon: Icons.note_rounded,
      children: notes.map((note) => _buildNoteItem(note)).toList(),
    );
  }

  Widget _buildResultsSection(Results results) {
    return _buildDetailSection(
      title: 'Investigation Results',
      icon: results.isAbnormal
          ? Icons.warning_rounded
          : Icons.check_circle_rounded,
      children: [_buildResultsContent(results)],
    );
  }

  Widget _buildActionButtonsSection(Investigation investigation) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: investigation.attachments.isNotEmpty
                ? () => _openAttachment(investigation.attachments.first.fileUrl)
                : null,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('View Report'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToUploadReport(investigation.id),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload Report'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for enhanced UI
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'results available':
        return HospitalTheme.success;
      case 'scheduled':
        return HospitalTheme.warning;
      case 'in progress':
        return HospitalTheme.info;
      case 'cancelled':
        return HospitalTheme.error;
      default:
        return HospitalTheme.textMedium;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return HospitalTheme.error;
      case 'high':
        return HospitalTheme.warning;
      case 'routine':
        return HospitalTheme.info;
      case 'low':
        return HospitalTheme.success;
      default:
        return HospitalTheme.textMedium;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'results available':
        return Icons.check_circle_rounded;
      case 'scheduled':
        return Icons.schedule_rounded;
      case 'in progress':
        return Icons.hourglass_top_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Icons.priority_high_rounded;
      case 'high':
        return Icons.keyboard_arrow_up_rounded;
      case 'routine':
        return Icons.radio_button_unchecked_rounded;
      case 'low':
        return Icons.keyboard_arrow_down_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  IconData _getInvestigationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'blood test':
        return Icons.opacity_rounded;
      case 'x-ray':
        return Icons.broken_image_rounded;
      case 'ct scan':
        return Icons.scanner_rounded;
      case 'mri':
        return Icons.scanner_outlined;
      case 'ultrasound':
        return Icons.waves_rounded;
      case 'ecg':
        return Icons.monitor_heart_rounded;
      case 'biopsy':
        return Icons.biotech_rounded;
      default:
        return Icons.science_rounded;
    }
  }

  String _getParametersText(InvestigationDetails details) {
    if (details.parameters != null && details.parameters!.isNotEmpty) {
      return details.parameters!.join(', ');
    } else if (details.bodySite != null && details.bodySite!.isNotEmpty) {
      return details.bodySite!;
    } else {
      return 'Standard parameters';
    }
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTimeShort(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${_formatDateShort(date)} ${_formatTimeShort(date)}';
  }

  // Implement remaining methods from original code that are needed
  Widget _buildAttachmentItem(Attachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getFileTypeColor(attachment.fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getFileTypeIcon(attachment.fileType),
              color: _getFileTypeColor(attachment.fileType),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded: ${_formatDateShort(attachment.uploadDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                if (attachment.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    attachment.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.visibility_rounded, color: HospitalTheme.info),
                onPressed: () => _openAttachment(attachment.fileUrl),
                tooltip: 'View',
              ),
              IconButton(
                icon:
                    Icon(Icons.download_rounded, color: HospitalTheme.success),
                onPressed: () => _openAttachment(attachment.fileUrl),
                tooltip: 'Download',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
        return Colors.blue;
      case 'DOCX':
      case 'DOC':
        return Colors.blue.shade800;
      case 'XLSX':
      case 'XLS':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
        return Icons.image_rounded;
      case 'DOCX':
      case 'DOC':
        return Icons.description_rounded;
      case 'XLSX':
      case 'XLS':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildNoteItem(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    note.addedBy.name.isNotEmpty
                        ? note.addedBy.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: HospitalTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${note.addedBy.name} (${note.addedBy.userType})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: HospitalTheme.primary,
                      ),
                    ),
                    Text(
                      _formatDate(note.dateAdded),
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              note.text,
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent(Results results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: results.isAbnormal
                ? HospitalTheme.warning.withOpacity(0.1)
                : HospitalTheme.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: results.isAbnormal
                  ? HospitalTheme.warning
                  : HospitalTheme.success,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                results.isAbnormal
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                size: 18,
                color: results.isAbnormal
                    ? HospitalTheme.warning
                    : HospitalTheme.success,
              ),
              const SizedBox(width: 8),
              Text(
                results.isAbnormal
                    ? 'Abnormal Results Detected'
                    : 'Normal Results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: results.isAbnormal
                      ? HospitalTheme.warning
                      : HospitalTheme.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Findings
        if (results.findings.isNotEmpty) ...[
          _buildResultSection(
              'Findings', results.findings, Icons.search_rounded),
          const SizedBox(height: 16),
        ],

        // Impression
        if (results.impression.isNotEmpty) ...[
          _buildResultSection(
              'Impression', results.impression, Icons.psychology_rounded),
          const SizedBox(height: 16),
        ],

        // Recommendations
        if (results.recommendations.isNotEmpty) ...[
          _buildResultSection('Recommendations', results.recommendations,
              Icons.recommend_rounded),
          const SizedBox(height: 16),
        ],

        // Numerical Results
        if (results.numericalResults.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.analytics_rounded,
                  color: HospitalTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Test Parameters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResultsTable(results.numericalResults, results.normalRanges),
        ],
      ],
    );
  }

  Widget _buildResultSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: HospitalTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HospitalTheme.border.withOpacity(0.5)),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTable(
      Map<String, dynamic> results, Map<String, dynamic> normalRanges) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.primaryLight.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Parameter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Result',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Normal Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ...results.entries.map((entry) {
            final parameter = entry.key;
            final value = entry.value;
            final range = normalRanges[parameter] ?? 'N/A';

            bool isAbnormal = false;
            if (value is num && range is String) {
              final rangeParts = range.split('-');
              if (rangeParts.length == 2) {
                try {
                  final min = double.parse(
                      rangeParts[0].replaceAll(RegExp(r'[^0-9.]'), ''));
                  final max = double.parse(
                      rangeParts[1].replaceAll(RegExp(r'[^0-9.]'), ''));
                  isAbnormal = value < min || value > max;
                } catch (e) {
                  // Parsing failed, assume normal
                }
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: HospitalTheme.border.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      parameter,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isAbnormal
                            ? HospitalTheme.error
                            : HospitalTheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      range.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: HospitalTheme.textMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAbnormal
                              ? HospitalTheme.error.withOpacity(0.1)
                              : HospitalTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAbnormal ? 'Abnormal' : 'Normal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAbnormal
                                ? HospitalTheme.error
                                : HospitalTheme.success,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
