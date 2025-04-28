import 'package:doctordesktop/Doctor/AddSymptomsScreen.dart';
import 'package:doctordesktop/Doctor/Dashboard/SymptomsAnalytics.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/colors.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

final symptomsProvider =
    StateNotifierProvider<SymptomsNotifier, List<String>>((ref) {
  return SymptomsNotifier();
});

class SymptomsNotifier extends StateNotifier<List<String>> {
  SymptomsNotifier() : super([]);

  final doctor = DoctorRepository();

  Future<void> fetchSymptoms(String patientId, String admissionId) async {
    final symptoms = await doctor.fetchSymptomsByDoctor(patientId, admissionId);
    state = symptoms;
  }

  Future<void> deleteSymptoms(
      String patientId, String admissionId, String symptom) async {
    try {
      await doctor.deleteSymptoms(patientId, admissionId, symptom);

      // Remove the deleted symptom from the state
      state = state.where((s) => s != symptom).toList();
    } catch (e) {
      print("Error deleting symptom: $e");
    }
  }
}

class SymptomsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const SymptomsScreen({
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  _SymptomsScreenState createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  // Key colors for consistent styling
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF8FBFD);
  final Color cardBackground = Colors.white;
  final Color textDark = const Color(0xFF2D3748);
  final Color textMedium = const Color(0xFF5A6B7F);
  final Color success = const Color(0xFF43A047);
  final Color error = const Color(0xFFE53935);
  final Color warning = const Color(0xFFFFA000);

  // Filtering/sorting options
  String _searchTerm = '';
  String _sortOption = 'date_desc';
  bool _isSearchExpanded = false;
  bool _showImportantOnly = false;
  final TextEditingController _searchController = TextEditingController();

  // Responsive layouts
  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1200;

  @override
  void initState() {
    super.initState();
    // Fetch symptoms on initialization
    ref
        .read(symptomsProvider.notifier)
        .fetchSymptoms(widget.patientId, widget.admissionId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symptomsList = ref.watch(symptomsProvider);
    final filteredSymptoms = _filterAndSortSymptoms(symptomsList);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final responsivePadding = _getResponsivePadding();

    return Scaffold(
      backgroundColor: backgroundColor,
      // Add a responsive AppBar for mobile view
      appBar: _isMobile
          ? AppBar(
              title: const Text('Symptoms'),
              backgroundColor: primaryColor,
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _openAddSymptomsScreen(
                      ref, context, widget.patientId, widget.admissionId),
                ),
              ],
            )
          : null,
      // Add a floating action button for mobile view
      floatingActionButton: _isMobile
          ? FloatingActionButton(
              onPressed: () => _openAddSymptomsScreen(
                  ref, context, widget.patientId, widget.admissionId),
              backgroundColor: primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/bb1.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
            colorFilter: ColorFilter.mode(
              primaryColor.withOpacity(0.05),
              BlendMode.lighten,
            ),
          ),
        ),
        width: screenWidth,
        height: screenHeight,
        child: Padding(
          padding: responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section - Hide on mobile
              if (!_isMobile) ...[
                _buildHeaderSection(),
                const SizedBox(height: 16),
              ],

              // Controls Section - Adapt for mobile
              _buildControlsSection(),
              const SizedBox(height: 16),

              // Symptoms List Section
              Expanded(
                child: _buildSymptomsListSection(filteredSymptoms),
              ),

              // Add Button Section - Hide on mobile (using FAB instead)
              if (!_isMobile) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _getResponsivePadding() {
    if (_isMobile) {
      return const EdgeInsets.all(8.0);
    } else if (_isTablet) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  PageRouteBuilder _createFallingPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -1), // Starts from the top
            end: Offset(0, 0), // Ends at the normal position
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut, // Smooth falling effect
          )),
          child: child,
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    // Simplified header for tablet
    if (_isTablet) {
      return Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(FontAwesomeIcons.notesMedical,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Symptoms Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Full header for desktop
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Title with Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(FontAwesomeIcons.notesMedical,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symptoms Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  'Track and manage patient reported symptoms',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Export and Print Buttons
          Row(
            children: [
              _buildActionButton(
                icon: Icons.print,
                label: 'Symptos Analytics',
                color: textMedium,
                onPressed: () {
                  Navigator.push(
                    context,
                    _createFallingPageRoute(SymptomAnalyticsDashboard()),
                  );
                  // Implement print functionality
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.save_alt,
                label: 'Export Data',
                color: accentColor,
                onPressed: () {
                  // Implement export functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    // Mobile controls - simplified search only
    if (_isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search symptoms...',
            prefixIcon: Icon(Icons.search, color: primaryColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchTerm = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFDFEAF4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchTerm = value;
            });
          },
        ),
      );
    }

    // Tablet controls - row of main controls
    if (_isTablet) {
      return Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search symptoms...',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchTerm = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFDFEAF4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Sort Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: 'Sort',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFDFEAF4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'date_desc', child: Text('Newest')),
                      DropdownMenuItem(
                          value: 'date_asc', child: Text('Oldest')),
                      DropdownMenuItem(value: 'alpha_asc', child: Text('A-Z')),
                      DropdownMenuItem(value: 'alpha_desc', child: Text('Z-A')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortOption = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Show important toggle
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: CheckboxListTile(
                title: const Text('Show important symptoms only'),
                value: _showImportantOnly,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (bool? value) {
                  setState(() {
                    _showImportantOnly = value!;
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    // Desktop controls - full featured
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter & Sort',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Search Field (can expand/collapse)
              Expanded(
                flex: _isSearchExpanded ? 2 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search symptoms...',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchTerm = '';
                                });
                              },
                            )
                          : IconButton(
                              icon: Icon(
                                _isSearchExpanded
                                    ? Icons.unfold_less
                                    : Icons.unfold_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearchExpanded = !_isSearchExpanded;
                                });
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFDFEAF4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Sort Options
              if (!_isSearchExpanded)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFDFEAF4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'date_desc', child: Text('Newest First')),
                      DropdownMenuItem(
                          value: 'date_asc', child: Text('Oldest First')),
                      DropdownMenuItem(value: 'alpha_asc', child: Text('A-Z')),
                      DropdownMenuItem(value: 'alpha_desc', child: Text('Z-A')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortOption = value!;
                      });
                    },
                  ),
                ),

              if (!_isSearchExpanded) const SizedBox(width: 16),

              // Important Symptoms Toggle
              if (!_isSearchExpanded)
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Show Important Only'),
                    value: _showImportantOnly,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool? value) {
                      setState(() {
                        _showImportantOnly = value!;
                      });
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsListSection(List<Map<String, dynamic>> symptoms) {
    if (symptoms.isEmpty) {
      return _buildEmptyState();
    }

    // On mobile, use a simplified list view
    if (_isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Symptoms (${symptoms.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: symptoms.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final symptom = symptoms[index];
                  final severityLevel = _determineSeverity(symptom['text']);

                  // Try to parse date
                  DateTime? dt;
                  try {
                    if (symptom['date'] != null &&
                        symptom['date'].contains('Date:')) {
                      final datePart = symptom['date'].split('Date:')[1].trim();
                      dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(datePart);
                    }
                  } catch (e) {
                    // Keep dt as null if parsing fails
                  }

                  final formattedDate = dt != null
                      ? DateFormat('dd/MM/yyyy').format(dt)
                      : 'Date N/A';

                  return Dismissible(
                    key: Key(symptom['original']),
                    background: Container(
                      color: error,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Symptom?'),
                            content: const Text(
                                'Are you sure you want to delete this symptom?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      ref.read(symptomsProvider.notifier).deleteSymptoms(
                            widget.patientId,
                            widget.admissionId,
                            symptom['original'],
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Symptom deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: ListTile(
                      title: Text(
                        symptom['text'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMedium,
                        ),
                      ),
                      trailing: _buildCompactSeverityIndicator(severityLevel),
                      onTap: () {
                        _showSymptomDetails(context, symptom);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Get column configuration based on screen size
    final columnConfig = _getResponsiveTableColumns();

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: _isTablet ? const EdgeInsets.all(12) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patient Symptoms',
                style: TextStyle(
                  fontSize: _isTablet ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              Text(
                '${symptoms.length} symptoms found',
                style: TextStyle(
                  fontSize: _isTablet ? 12 : 14,
                  color: textMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: _isTablet ? 12 : 16),

          // Symptoms Table with Horizontal Scrolling
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              // Layout constraints available width
              final availableWidth = constraints.maxWidth;

              return Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    // Set width to full available width
                    width: availableWidth,
                    child: _buildResponsiveDataTable(
                        symptoms, columnConfig, availableWidth),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Build a responsive data table that adapts to the available width
  Widget _buildResponsiveDataTable(List<Map<String, dynamic>> symptoms,
      List<DataColumn> columns, double availableWidth) {
    return DataTable(
      columnSpacing: _isTablet ? 16 : 24,
      headingRowColor: MaterialStateColor.resolveWith(
        (states) => primaryColor.withOpacity(0.05),
      ),
      headingRowHeight: _isTablet ? 48 : 56,
      dataRowMinHeight: _isTablet ? 56 : 64,
      dataRowMaxHeight: _isTablet ? 80 : 100,
      horizontalMargin: _isTablet ? 8 : 16,
      border: TableBorder.all(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      columns: columns,
      rows: symptoms.asMap().entries.map((entry) {
        final index = entry.key;
        final symptom = entry.value;

        // Determine severity based on keyword analysis
        final severityLevel = _determineSeverity(symptom['text']);
        final formatter = DateFormat('dd/MM/yyyy, HH:mm');
        DateTime? dt;
        try {
          if (symptom['date'] != null && symptom['date'].contains('Date:')) {
            final datePart = symptom['date'].split('Date:')[1].trim();
            dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(datePart);
          } else {
            // Try parsing with more flexible approach
            final datePart = symptom['date'] ?? '';
            dt = DateFormat('yyyy-MM-dd HH:mm:ss a').parse(datePart);
          }
        } catch (e) {
          // Keep dt as null if parsing fails
        }

        List<DataCell> cells = [];

        // Add cells based on which columns we're displaying
        for (var i = 0; i < columns.length; i++) {
          // If tablet, skip some columns
          if (_isTablet) {
            switch (i) {
              case 0: // Number
                cells.add(DataCell(
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ));
                break;

              case 1: // Symptom text
                cells.add(DataCell(
                  Tooltip(
                    message: symptom['text'],
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        symptom['text'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ));
                break;

              case 2: // Severity indicator
                cells.add(DataCell(
                  _buildCompactSeverityIndicator(severityLevel),
                ));
                break;

              case 3: // Actions
                cells.add(DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: error,
                          size: 16,
                        ),
                        onPressed: () {
                          _showDeleteConfirmation(context, symptom['original']);
                        },
                        constraints: BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ));
                break;
            }
          } else {
            // Desktop view - full featured cells
            switch (i) {
              case 0: // Number
                cells.add(DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ));
                break;

              case 1: // Symptom text with tooltip for longer texts
                cells.add(DataCell(
                  Tooltip(
                    message: symptom['text'],
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        symptom['text'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ));
                break;

              case 2: // Formatted date
                cells.add(DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dt != null ? formatter.format(dt) : 'N/A',
                        style: TextStyle(
                          color: textMedium,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ));
                break;

              // case 3: // Source - Doctor or Patient
              //   cells.add(DataCell(
              //     Container(
              //       padding:
              //           const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //       decoration: BoxDecoration(
              //         color: primaryColor.withOpacity(0.1),
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       child: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           Icon(
              //             Icons.medical_services,
              //             size: 16,
              //             color: primaryColor,
              //           ),
              //           const SizedBox(width: 4),
              //           const Text(
              //             'Doctor',
              //             style: TextStyle(
              //               fontWeight: FontWeight.w500,
              //               fontSize: 13,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ));
              // break;

              case 3: // Severity indicator
                cells.add(DataCell(
                  _buildSeverityIndicator(severityLevel),
                ));
                break;

              case 4: // Actions
                cells.add(DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: error,
                        ),
                        onPressed: () {
                          _showDeleteConfirmation(context, symptom['original']);
                        },
                        tooltip: 'Delete Symptom',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: primaryColor,
                        ),
                        onPressed: () {
                          _showSymptomDetails(context, symptom);
                        },
                        tooltip: 'View Details',
                      ),
                    ],
                  ),
                ));
                break;
            }
          }
        }

        return DataRow(
          color: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (index % 2 == 0) {
                return Colors.grey.shade50;
              }
              return Colors.white;
            },
          ),
          cells: cells,
        );
      }).toList(),
    );
  }

  // Get the appropriate columns based on screen size
  List<DataColumn> _getResponsiveTableColumns() {
    if (_isTablet) {
      // Simplified columns for tablet
      return [
        DataColumn(
          label: Row(
            children: [
              Icon(Icons.format_list_numbered, color: primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'No.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        DataColumn(
          label: Row(
            children: [
              Icon(FontAwesomeIcons.disease, color: primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'Symptom',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        DataColumn(
          label: Row(
            children: [
              Icon(Icons.priority_high, color: primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'Severity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        DataColumn(
          label: Row(
            children: [
              Icon(Icons.edit, color: primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Full featured columns for desktop
    return [
      DataColumn(
        label: Row(
          children: [
            Icon(Icons.format_list_numbered, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'No.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
      DataColumn(
        label: Row(
          children: [
            Icon(FontAwesomeIcons.disease, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Symptom',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
      DataColumn(
        label: Row(
          children: [
            Icon(Icons.calendar_today, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
      // DataColumn(
      //   label: Row(
      //     children: [
      //       Icon(Icons.supervised_user_circle, color: primaryColor, size: 18),
      //       const SizedBox(width: 8),
      //       Text(
      //         'Entered By',
      //         style: TextStyle(
      //           fontWeight: FontWeight.bold,
      //           color: primaryColor,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      DataColumn(
        label: Row(
          children: [
            Icon(Icons.priority_high, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Severity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
      DataColumn(
        label: Row(
          children: [
            Icon(Icons.edit, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // Compact severity indicator for mobile/tablet views
  Widget _buildCompactSeverityIndicator(String severity) {
    Color color;
    IconData icon;

    switch (severity) {
      case 'high':
        color = error;
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = warning;
        icon = Icons.warning_amber;
        break;
      default:
        color = success;
        icon = Icons.check_circle;
    }

    return Icon(icon, color: color, size: 20);
  }

  Widget _buildEmptyState() {
    // Simplified empty state for mobile
    if (_isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.notesMedical,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Symptoms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add symptoms',
                style: TextStyle(
                  fontSize: 14,
                  color: textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.notesMedical,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Symptoms Recorded',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No symptoms have been recorded for this patient yet.',
              style: TextStyle(
                fontSize: 16,
                color: textMedium,
              ),
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              icon: Icons.add,
              label: 'Add New Symptom',
              onPressed: () => _openAddSymptomsScreen(
                  ref, context, widget.patientId, widget.admissionId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildPrimaryButton(
            icon: Icons.add,
            label: 'Add New Symptom',
            onPressed: () => _openAddSymptomsScreen(
                ref, context, widget.patientId, widget.admissionId),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSeverityIndicator(String severity) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (severity) {
      case 'high':
        bgColor = error.withOpacity(0.1);
        textColor = error;
        icon = Icons.priority_high;
        label = 'High';
        break;
      case 'medium':
        bgColor = warning.withOpacity(0.1);
        textColor = warning;
        icon = Icons.warning_amber;
        label = 'Medium';
        break;
      default:
        bgColor = success.withOpacity(0.1);
        textColor = success;
        icon = Icons.check_circle;
        label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<Map<String, dynamic>> _filterAndSortSymptoms(List<String> symptoms) {
    // Parse symptoms into structured data
    final List<Map<String, dynamic>> parsedSymptoms = [];

    for (final symptom in symptoms) {
      // Split symptom text from date
      final parts = symptom.split(' - ');
      final text = parts.isNotEmpty ? parts[0] : symptom;
      final date = parts.length > 1 ? parts[1] : '';

      // Check if it contains any important keywords for filtering
      final isImportant = _isSymptomImportant(text);

      // Only include if not filtering, or filtering and important
      if (!_showImportantOnly || (_showImportantOnly && isImportant)) {
        // Only include if matches search term
        if (_searchTerm.isEmpty ||
            text.toLowerCase().contains(_searchTerm.toLowerCase())) {
          parsedSymptoms.add({
            'text': text,
            'date': date,
            'important': isImportant,
            'original': symptom,
          });
        }
      }
    }

    // Sort based on current sort option
    switch (_sortOption) {
      case 'date_desc':
        parsedSymptoms.sort((a, b) {
          // Try to extract dates for comparison
          final dateA = _extractDate(a['date'] ?? '');
          final dateB = _extractDate(b['date'] ?? '');

          if (dateA != null && dateB != null) {
            return dateB.compareTo(dateA); // Newest first
          } else if (dateA != null) {
            return -1; // A has date, B doesn't
          } else if (dateB != null) {
            return 1; // B has date, A doesn't
          }
          return 0; // Neither has valid date
        });
        break;

      case 'date_asc':
        parsedSymptoms.sort((a, b) {
          // Try to extract dates for comparison
          final dateA = _extractDate(a['date'] ?? '');
          final dateB = _extractDate(b['date'] ?? '');

          if (dateA != null && dateB != null) {
            return dateA.compareTo(dateB); // Oldest first
          } else if (dateA != null) {
            return -1; // A has date, B doesn't
          } else if (dateB != null) {
            return 1; // B has date, A doesn't
          }
          return 0; // Neither has valid date
        });
        break;

      case 'alpha_asc':
        parsedSymptoms.sort((a, b) => (a['text'] ?? '')
            .toLowerCase()
            .compareTo((b['text'] ?? '').toLowerCase()));
        break;

      case 'alpha_desc':
        parsedSymptoms.sort((a, b) => (b['text'] ?? '')
            .toLowerCase()
            .compareTo((a['text'] ?? '').toLowerCase()));
        break;
    }

    return parsedSymptoms;
  }

  DateTime? _extractDate(String dateStr) {
    // Check if the input has "Date:" prefix
    if (dateStr.contains('Date:')) {
      final datePart = dateStr.split('Date:')[1].trim();
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(datePart);
      } catch (e) {
        try {
          return DateFormat('yyyy-MM-dd HH:mm:ss a').parse(datePart);
        } catch (e) {
          return null;
        }
      }
    }

    // Try various date formats in order of likelihood
    final formats = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm:ss a',
      'dd/MM/yyyy, HH:mm:ss',
      'dd/MM/yyyy HH:mm:ss',
    ];
    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (e) {
        // Continue to next format if this one fails
      }
    }

    return null; // Return null if all parsing attempts fail
  }

  bool _isSymptomImportant(String symptomText) {
    // List of important/critical keywords to check for
    final criticalKeywords = [
      'severe',
      'extreme',
      'intense',
      'acute',
      'pain',
      'shortness of breath',
      'difficulty breathing',
      'chest pain',
      'fever',
      'high fever',
      'seizure',
      'unconscious',
      'bleeding',
      'vomiting',
      'headache',
      'migraine',
      'dizziness',
    ];

    final lowerText = symptomText.toLowerCase();
    return criticalKeywords.any((keyword) => lowerText.contains(keyword));
  }

  String _determineSeverity(String symptomText) {
    // High severity keywords
    final highSeverityKeywords = [
      'severe',
      'extreme',
      'intense',
      'acute',
      'unbearable',
      'chest pain',
      'difficulty breathing',
      'shortness of breath',
      'unconscious',
      'seizure',
      'high fever',
      'excessive bleeding',
    ];

    // Medium severity keywords
    final mediumSeverityKeywords = [
      'moderate',
      'significant',
      'fever',
      'pain',
      'headache',
      'migraine',
      'vomiting',
      'dizziness',
      'fatigue',
      'weakness',
      'bleeding',
    ];

    final lowerText = symptomText.toLowerCase();

    if (highSeverityKeywords.any((keyword) => lowerText.contains(keyword))) {
      return 'high';
    } else if (mediumSeverityKeywords
        .any((keyword) => lowerText.contains(keyword))) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  void _showDeleteConfirmation(BuildContext context, String symptom) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Symptom?'),
          content: const Text(
              'Are you sure you want to delete this symptom record? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: error,
              ),
              onPressed: () {
                ref.read(symptomsProvider.notifier).deleteSymptoms(
                    widget.patientId, widget.admissionId, symptom);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Symptom deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSymptomDetails(BuildContext context, Map<String, dynamic> symptom) {
    DateTime? dt;
    try {
      if (symptom['date'] != null && symptom['date'].contains('Date:')) {
        final datePart = symptom['date'].split('Date:')[1].trim();
        dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(datePart);
      } else {
        // Try parsing with more flexible approach
        final datePart = symptom['date'] ?? '';
        dt = DateFormat('yyyy-MM-dd HH:mm:ss a').parse(datePart);
      }
    } catch (e) {
      // Keep dt as null if parsing fails
    }

    final formattedDate = dt != null
        ? DateFormat('dd MMMM yyyy, HH:mm').format(dt)
        : 'Date not available';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FontAwesomeIcons.notesMedical,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Symptom Details'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  icon: FontAwesomeIcons.disease,
                  title: 'Symptom',
                  value: symptom['text'],
                ),
                const SizedBox(height: 12),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  title: 'Date Recorded',
                  value: formattedDate,
                ),
                // const SizedBox(height: 12),
                // _buildDetailItem(
                //   icon: Icons.person,
                //   title: 'Recorded By',
                //   value: 'Doctor',
                // ),
                const SizedBox(height: 12),
                _buildDetailItem(
                  icon: Icons.priority_high,
                  title: 'Severity',
                  value: _determineSeverity(symptom['text']).toUpperCase(),
                  customValueWidget: _buildSeverityIndicator(
                      _determineSeverity(symptom['text'])),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Widget? customValueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textMedium,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              customValueWidget ??
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

void _openAddSymptomsScreen(
    WidgetRef ref, BuildContext context, String patientId, String admissionId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddSymptomScreen(
        patientId: patientId,
        admissionId: admissionId,
      ),
    ),
  ).then((value) {
    if (value != null && value) {
      // Refresh data after returning from the screen
      ref.read(symptomsProvider.notifier).fetchSymptoms(patientId, admissionId);
    }
  });
}
