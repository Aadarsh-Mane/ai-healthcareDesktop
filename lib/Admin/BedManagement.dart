import 'dart:convert';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(HospitalBedManagementApp());
}

class HospitalBedManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Bed Management',
      theme: HospitalTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const BedManagementDashboard(),
    );
  }
}

class Section {
  final String id;
  final String name;
  final String type;
  final int totalBeds;
  final int availableBeds;
  final bool isActive;
  final DateTime createdAt;
  List<int> availableBedNumbers = [];
  List<OccupiedBed> occupiedBeds = [];
  bool isBedsDataLoaded = false;

  Section({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBeds,
    required this.availableBeds,
    required this.isActive,
    required this.createdAt,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      totalBeds: json['totalBeds'],
      availableBeds: json['availableBeds'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class OccupiedBed {
  final int bedNumber;
  final String patientId;
  final String patientName;
  final DateTime admissionDate;

  OccupiedBed({
    required this.bedNumber,
    required this.patientId,
    required this.patientName,
    required this.admissionDate,
  });

  factory OccupiedBed.fromJson(Map<String, dynamic> json) {
    return OccupiedBed(
      bedNumber: json['bedNumber'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      admissionDate: DateTime.parse(json['admissionDate']),
    );
  }
}

class TypeStat {
  final String id;
  final int count;
  final int totalBeds;
  final int availableBeds;

  TypeStat({
    required this.id,
    required this.count,
    required this.totalBeds,
    required this.availableBeds,
  });

  factory TypeStat.fromJson(Map<String, dynamic> json) {
    return TypeStat(
      id: json['_id'],
      count: json['count'],
      totalBeds: json['totalBeds'],
      availableBeds: json['availableBeds'],
    );
  }

  double get occupancyRate {
    if (totalBeds == 0) return 0.0;
    return (totalBeds - availableBeds) / totalBeds;
  }
}

class BedManagementDashboard extends StatefulWidget {
  const BedManagementDashboard({Key? key}) : super(key: key);

  @override
  _BedManagementDashboardState createState() => _BedManagementDashboardState();
}

class _BedManagementDashboardState extends State<BedManagementDashboard> {
  List<Section> sections = [];
  List<TypeStat> typeStats = [];
  bool isLoading = false;
  bool isCreatingSection = false;
  bool isEditingSection = false;
  String selectedSectionId = '';
  int expandedSectionIndex = -1; // Track which section is expanded

  // Controllers for add/edit section
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController bedsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSections();
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    bedsController.dispose();
    super.dispose();
  }

  Future<void> fetchSections() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/admin/getAllSections'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          sections = (data['data'] as List)
              .map((json) => Section.fromJson(json))
              .toList();
          typeStats = (data['typeStats'] as List)
              .map((json) => TypeStat.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackBar('Error loading sections: $e');
    }
  }

  Future<void> fetchSectionBedDetails(Section section, int sectionIndex) async {
    if (section.isBedsDataLoaded) return; // Skip if already loaded

    try {
      // Fetch available beds
      final availableResponse = await http.get(
        Uri.parse('${KVM_URL}/reception/availableBeds/${section.id}'),
      );

      if (availableResponse.statusCode == 200) {
        final availableData = json.decode(availableResponse.body);
        final availableBedsList =
            List<int>.from(availableData['data']['availableBedNumbers']);

        // Fetch occupied beds
        final occupiedResponse = await http.get(
          Uri.parse('${KVM_URL}/reception/occupiedBeds/${section.id}'),
        );

        if (occupiedResponse.statusCode == 200) {
          final occupiedData = json.decode(occupiedResponse.body);
          final occupiedBedsList =
              (occupiedData['data']['occupiedBeds'] as List)
                  .map((bed) => OccupiedBed.fromJson(bed))
                  .toList();

          setState(() {
            sections[sectionIndex].availableBedNumbers = availableBedsList;
            sections[sectionIndex].occupiedBeds = occupiedBedsList;
            sections[sectionIndex].isBedsDataLoaded = true;
          });
        }
      }
    } catch (e) {
      showErrorSnackBar('Error loading bed details: $e');
    }
  }

  Future<void> createSection() async {
    if (nameController.text.isEmpty ||
        typeController.text.isEmpty ||
        bedsController.text.isEmpty) {
      showErrorSnackBar('Please fill all fields');
      return;
    }

    setState(() {
      isCreatingSection = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/admin/createSection'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': nameController.text,
          'type': typeController.text,
          'totalBeds': int.parse(bedsController.text),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        clearSectionForm();
        fetchSections();
        showSuccessSnackBar('Section created successfully');
      } else {
        throw Exception('Failed to create section');
      }
    } catch (e) {
      showErrorSnackBar('Error creating section: $e');
    } finally {
      setState(() {
        isCreatingSection = false;
      });
    }
  }

  Future<void> updateSection() async {
    if (nameController.text.isEmpty ||
        typeController.text.isEmpty ||
        bedsController.text.isEmpty) {
      showErrorSnackBar('Please fill all fields');
      return;
    }

    setState(() {
      isEditingSection = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('${KVM_URL}/admin/updateSection/$selectedSectionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': nameController.text,
          'type': typeController.text,
          'totalBeds': int.parse(bedsController.text),
        }),
      );

      if (response.statusCode == 200) {
        clearSectionForm();
        fetchSections();
        showSuccessSnackBar('Section updated successfully');
      } else {
        throw Exception('Failed to update section');
      }
    } catch (e) {
      showErrorSnackBar('Error updating section: $e');
    } finally {
      setState(() {
        isEditingSection = false;
        selectedSectionId = '';
      });
    }
  }

  Future<void> deleteSection(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${KVM_URL}/admin/deleteSection/$id'),
      );

      if (response.statusCode == 200) {
        fetchSections();
        showSuccessSnackBar('Section deleted successfully');
      } else {
        throw Exception('Failed to delete section');
      }
    } catch (e) {
      showErrorSnackBar('Error deleting section: $e');
    }
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HospitalTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HospitalTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void editSection(Section section) {
    setState(() {
      selectedSectionId = section.id;
      nameController.text = section.name;
      typeController.text = section.type;
      bedsController.text = section.totalBeds.toString();
    });
  }

  void clearSectionForm() {
    setState(() {
      selectedSectionId = '';
      nameController.clear();
      typeController.clear();
      bedsController.clear();
    });
  }

  void toggleSectionExpansion(int index) {
    setState(() {
      if (expandedSectionIndex == index) {
        expandedSectionIndex = -1; // Collapse if already expanded
      } else {
        expandedSectionIndex = index; // Expand this section
        // Load bed details if not already loaded
        if (!sections[index].isBedsDataLoaded) {
          fetchSectionBedDetails(sections[index], index);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hospital Bed Management System'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchSections,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left sidebar - Navigation and stats
          // Container(
          //   width: 280,
          //   color: HospitalTheme.background,
          //   child: Column(
          //     children: [
          //       Container(
          //         padding: EdgeInsets.all(16),
          //         decoration: BoxDecoration(
          //           gradient: LinearGradient(
          //             colors: [
          //               HospitalTheme.primary,
          //               HospitalTheme.primaryLight
          //             ],
          //             begin: Alignment.topLeft,
          //             end: Alignment.bottomRight,
          //           ),
          //         ),
          //         child: Row(
          //           children: [
          //             Icon(Icons.local_hospital, color: Colors.white, size: 32),
          //             SizedBox(width: 12),
          //             Expanded(
          //               child: Text(
          //                 'Bed Manager',
          //                 style: TextStyle(
          //                   color: Colors.white,
          //                   fontSize: 20,
          //                   fontWeight: FontWeight.bold,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       Expanded(
          //         child: ListView(
          //           padding: EdgeInsets.symmetric(vertical: 8),
          //           children: [
          //             _buildNavItem(
          //               icon: Icons.dashboard,
          //               title: 'Dashboard',
          //               isSelected: true,
          //             ),
          //             _buildNavItem(
          //               icon: Icons.bed,
          //               title: 'Bed Management',
          //             ),
          //             _buildNavItem(
          //               icon: Icons.people,
          //               title: 'Patients',
          //             ),
          //             _buildNavItem(
          //               icon: Icons.settings,
          //               title: 'Settings',
          //             ),
          //           ],
          //         ),
          //       ),
          //       Container(
          //         padding: EdgeInsets.all(16),
          //         decoration: BoxDecoration(
          //           color: HospitalTheme.cardBackground,
          //           border: Border(
          //             top: BorderSide(color: HospitalTheme.border),
          //           ),
          //         ),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Hospital Stats',
          //               style: TextStyle(
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //                 color: HospitalTheme.textDark,
          //               ),
          //             ),
          //             SizedBox(height: 12),
          //             if (isLoading)
          //               Center(child: CircularProgressIndicator())
          //             else
          //               ...typeStats.map((stat) => _buildStatItem(stat)),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with action buttons
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hospital Sections',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => _buildSectionFormDialog(
                              dialogContext: context,
                              isEditing: false,
                            ),
                          );
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add Section'),
                      ),
                    ],
                  ),
                ),

                // Main content - Sections overview and bed layout
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : sections.isEmpty
                          ? Center(
                              child: Text(
                                'No sections found. Create a new section to get started.',
                                style:
                                    TextStyle(color: HospitalTheme.textMedium),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: sections.length,
                              itemBuilder: (context, index) {
                                return _buildSectionCard(
                                    sections[index], index);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? HospitalTheme.primary : HospitalTheme.textMedium,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? HospitalTheme.primary : HospitalTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          // Handle navigation
        },
        selected: isSelected,
      ),
    );
  }

  Widget _buildStatItem(TypeStat stat) {
    Color statColor;
    IconData statIcon;

    switch (stat.id) {
      case 'Icu':
        statColor = HospitalTheme.medical;
        statIcon = Icons.medical_services;
        break;
      case 'Ward':
        statColor = HospitalTheme.laboratory;
        statIcon = Icons.local_hospital;
        break;
      default:
        statColor = HospitalTheme.pharmacy;
        statIcon = Icons.bed;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statIcon, color: statColor, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${stat.availableBeds}/${stat.totalBeds} beds available',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                SizedBox(height: 6),
                LinearProgressIndicator(
                  value: stat.occupancyRate,
                  backgroundColor: HospitalTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    stat.occupancyRate > 0.8
                        ? HospitalTheme.error
                        : stat.occupancyRate > 0.6
                            ? HospitalTheme.warning
                            : HospitalTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Section section, int index) {
    bool isExpanded = index == expandedSectionIndex;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with expand button
          InkWell(
            onTap: () => toggleSectionExpansion(index),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getSectionColor(section.type).withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: HospitalTheme.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSectionIcon(section.type),
                    color: _getSectionColor(section.type),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ),
                  HospitalTheme.buildStatusBadge(
                    section.type,
                    color: _getSectionColor(section.type),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: HospitalTheme.primary,
                    ),
                    onPressed: () => toggleSectionExpansion(index),
                    tooltip: isExpanded ? 'Collapse' : 'Expand',
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: HospitalTheme.textMedium),
                    onPressed: () {
                      editSection(section);
                      showDialog(
                        context: context,
                        useRootNavigator: false, // This is critical
                        builder: (BuildContext dialogContext) {
                          return _buildSectionFormDialog(
                            isEditing: true,
                            dialogContext: dialogContext,
                          );
                        },
                      );
                    },
                    tooltip: 'Edit Section',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: HospitalTheme.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        useRootNavigator: false, // This is critical
                        builder: (BuildContext dialogContext) => AlertDialog(
                          title: Text('Delete Section'),
                          content: Text(
                              'Are you sure you want to delete ${section.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                deleteSection(section.id);
                              },
                              child: Text(
                                'Delete',
                                style: TextStyle(color: HospitalTheme.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Delete Section',
                  ),
                ],
              ),
            ),
          ),

          // Overview stats
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSectionInfoCard(
                  icon: Icons.bed,
                  title: 'Total Beds',
                  value: section.totalBeds.toString(),
                  color: HospitalTheme.primary,
                ),
                SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.check_circle,
                  title: 'Available',
                  value: section.availableBeds.toString(),
                  color: HospitalTheme.success,
                ),
                SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.person,
                  title: 'Occupied',
                  value: (section.totalBeds - section.availableBeds).toString(),
                  color: HospitalTheme.warning,
                ),
                SizedBox(width: 16),
                _buildSectionInfoCard(
                  icon: Icons.timeline,
                  title: 'Occupancy Rate',
                  value: section.availableBeds == 0
                      ? '100%'
                      : '${(((section.totalBeds - section.availableBeds) / section.totalBeds) * 100).toStringAsFixed(1)}%',
                  color: HospitalTheme.laboratory,
                ),
              ],
            ),
          ),

          // Expanded section with bed layout
          if (isExpanded)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bed Layout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Show loading indicator while fetching bed details
                  section.isBedsDataLoaded
                      ? _buildBedLayout(section)
                      : Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Loading bed details...'),
                            ],
                          ),
                        ),

                  // Show occupied beds details if any
                  if (section.isBedsDataLoaded &&
                      section.occupiedBeds.isNotEmpty)
                    _buildOccupiedBedsTable(section),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
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
      ),
    );
  }

  Widget _buildBedLayout(Section section) {
    // Calculate the number of rows and columns
    int bedsPerRow = 10; // Adjust as needed
    int rows = (section.totalBeds / bedsPerRow).ceil();

    return Container(
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.border),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Legend for the bed layout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Available', HospitalTheme.success),
              SizedBox(width: 24),
              _buildLegendItem('Occupied', HospitalTheme.error),
            ],
          ),
          SizedBox(height: 16),

          // Theater-style layout for beds
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Entrance indicator
                Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ENTRANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Beds layout
                for (int row = 0; row < rows; row++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int col = 0; col < bedsPerRow; col++) ...[
                        if (row * bedsPerRow + col < section.totalBeds)
                          _buildBedItem(
                            bedNumber: row * bedsPerRow + col + 1,
                            isAvailable: section.isBedsDataLoaded
                                ? section.availableBedNumbers
                                    .contains(row * bedsPerRow + col + 1)
                                : row * bedsPerRow + col <
                                    section.availableBeds,
                            type: section.type,
                            patientInfo: section.isBedsDataLoaded
                                ? _getPatientInfoForBed(
                                    section, row * bedsPerRow + col + 1)
                                : null,
                          ),
                        if (col < bedsPerRow - 1) SizedBox(width: 12),
                      ],
                    ],
                  ),
                  SizedBox(height: 12),
                ],

                // Nurse station
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HospitalTheme.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_services,
                          color: HospitalTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'NURSING STATION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  OccupiedBed? _getPatientInfoForBed(Section section, int bedNumber) {
    if (!section.isBedsDataLoaded) return null;

    try {
      return section.occupiedBeds
          .firstWhere((bed) => bed.bedNumber == bedNumber);
    } catch (e) {
      return null; // No patient in this bed
    }
  }

  Widget _buildOccupiedBedsTable(Section section) {
    if (section.occupiedBeds.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Occupied Beds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: HospitalTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  HospitalTheme.surfaceLight,
                ),
                columns: [
                  DataColumn(label: Text('Bed Number')),
                  DataColumn(label: Text('Patient ID')),
                  DataColumn(label: Text('Patient Name')),
                  DataColumn(label: Text('Admission Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: section.occupiedBeds.map((bed) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: HospitalTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: HospitalTheme.error),
                          ),
                          child: Text(
                            'Bed ${bed.bedNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.error,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(bed.patientId)),
                      DataCell(Text(bed.patientName)),
                      DataCell(Text(
                        '${bed.admissionDate.day}/${bed.admissionDate.month}/${bed.admissionDate.year}',
                      )),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility,
                                  color: HospitalTheme.primary),
                              onPressed: () {
                                // View patient details
                              },
                              tooltip: 'View Patient',
                              iconSize: 20,
                            ),
                            IconButton(
                              icon: Icon(Icons.output,
                                  color: HospitalTheme.warning),
                              onPressed: () {
                                // Discharge patient
                              },
                              tooltip: 'Discharge',
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: HospitalTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBedItem({
    required int bedNumber,
    required bool isAvailable,
    required String type,
    OccupiedBed? patientInfo,
  }) {
    IconData icon = type == 'Icu' ? Icons.local_hospital : Icons.bed;
    Color color = isAvailable ? HospitalTheme.success : HospitalTheme.error;

    return Tooltip(
      message: isAvailable
          ? 'Bed $bedNumber (Available)'
          : patientInfo != null
              ? 'Bed $bedNumber - ${patientInfo.patientName} (${patientInfo.patientId})'
              : 'Bed $bedNumber (Occupied)',
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (!isAvailable && patientInfo != null) {
                // Show patient details or actions
                showDialog(
                  context: context,
                  builder: (context) =>
                      _buildPatientDetailsDialog(patientInfo, context),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                SizedBox(height: 4),
                Text(
                  'Bed $bedNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (!isAvailable && patientInfo != null)
                  Text(
                    patientInfo.patientId,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDetailsDialog(
      OccupiedBed patientInfo, BuildContext dialogContext) {
    return AlertDialog(
      title: Text('Patient Details'),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientDetailRow(
                'Bed Number', patientInfo.bedNumber.toString()),
            _buildPatientDetailRow('Patient ID', patientInfo.patientId),
            _buildPatientDetailRow('Patient Name', patientInfo.patientName),
            _buildPatientDetailRow('Admission Date',
                '${patientInfo.admissionDate.day}/${patientInfo.admissionDate.month}/${patientInfo.admissionDate.year}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Use the passed dialogContext
            Navigator.of(dialogContext).pop();
          },
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Discharge patient
            Navigator.of(dialogContext).pop();
            // Implement discharge functionality
          },
          child: Text('Discharge Patient'),
          style: ElevatedButton.styleFrom(
            backgroundColor: HospitalTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: HospitalTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionFormDialog({
    required bool isEditing,
    required BuildContext dialogContext,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Section' : 'Add New Section',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Section Name',
                hintText: 'e.g., General Ward, ICU',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: typeController,
              decoration: InputDecoration(
                labelText: 'Section Type',
                hintText: 'e.g., Ward, Icu',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: bedsController,
              decoration: InputDecoration(
                labelText: 'Total Beds',
                hintText: 'e.g., 20',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    clearSectionForm();
                  },
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isEditingSection || isCreatingSection
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          if (isEditing) {
                            updateSection();
                          } else {
                            createSection();
                          }
                        },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSectionColor(String type) {
    switch (type) {
      case 'Icu':
        return HospitalTheme.medical;
      case 'Ward':
        return HospitalTheme.laboratory;
      default:
        return HospitalTheme.pharmacy;
    }
  }

  IconData _getSectionIcon(String type) {
    switch (type) {
      case 'Icu':
        return Icons.medical_services;
      case 'Ward':
        return Icons.local_hospital;
      default:
        return Icons.bed;
    }
  }
}
