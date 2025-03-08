import 'package:doctordesktop/Doctor/AddSymptomsScreen.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/constants/colors.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import 'package:doctordesktop/constants/colors.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

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

      print("Symptom deleted successfully");
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
  final gradientColors = [const Color(0xFF005F9E), const Color(0xFF00B8D4)];

  @override
  void initState() {
    super.initState();
    ref
        .read(symptomsProvider.notifier)
        .fetchSymptoms(widget.patientId, widget.admissionId);
  }

  @override
  Widget build(BuildContext context) {
    final symptomsList = ref.watch(symptomsProvider);
    final mediaQuery = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Updated background with gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors[0].withOpacity(0.15),
                    gradientColors[1].withOpacity(0.15)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Image.asset(
                'assets/images/bb1.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.2),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: mediaQuery.width * 0.7,
              child: SymptomsContent(
                symptomsList: symptomsList,
                patientId: widget.patientId,
                admissionId: widget.admissionId,
                gradientColors: gradientColors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SymptomsContent extends ConsumerWidget {
  final List<String> symptomsList;
  final String patientId;
  final String admissionId;
  final List<Color> gradientColors;

  const SymptomsContent({
    required this.symptomsList,
    required this.patientId,
    required this.admissionId,
    required this.gradientColors,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: symptomsList.isEmpty
          // ? const Center(child: CustomLoadingAnimation())
          ? Center(
              child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2A79B4),
                elevation: 0,
              ),
              onPressed: () => {
                _openAddSymptomsScreen(ref, context, patientId, admissionId)
              },
              child: Text(
                'No symptoms available Click to add',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Updated header with gradient
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Symptoms by Doctor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: gradientColors,
                        ).createShader(const Rect.fromLTWH(0, 0, 250, 20)),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                    border: Border.all(
                      color: gradientColors[1].withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Column(
                        children: [
                          SizedBox(
                            height: symptomsList.length > 6 ? 300 : null,
                            child: SingleChildScrollView(
                              child: Center(
                                child: DataTable(
                                  columnSpacing: 40,
                                  horizontalMargin: 16,
                                  columns: [
                                    _buildDataColumn(
                                      'No.',
                                      FontAwesomeIcons.hashtag,
                                      gradientColors[0],
                                    ),
                                    _buildDataColumn(
                                      'Symptom',
                                      FontAwesomeIcons.notesMedical,
                                      gradientColors[1],
                                    ),
                                    _buildDataColumn(
                                      'Date',
                                      FontAwesomeIcons.calendarAlt,
                                      gradientColors[0],
                                    ),
                                    _buildDataColumn(
                                      'Delete',
                                      FontAwesomeIcons.deleteLeft,
                                      gradientColors[1],
                                    ),
                                  ],
                                  rows: symptomsList
                                      .asMap()
                                      .map((index, symptom) {
                                        final parts = symptom.split(' - ');
                                        final symptomText = parts.length > 1
                                            ? parts[0]
                                            : symptom;
                                        final dateText =
                                            parts.length > 1 ? parts[1] : '';
                                        return MapEntry(
                                          index,
                                          DataRow(cells: [
                                            DataCell(Text('${index + 1}')),
                                            DataCell(
                                                _buildSymptomCell(symptomText)),
                                            DataCell(_buildDateCell(dateText)),
                                            DataCell(
                                              IconButton(
                                                icon: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        colors: gradientColors),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: const Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                      size: 18),
                                                ),
                                                onPressed: () => ref
                                                    .read(symptomsProvider
                                                        .notifier)
                                                    .deleteSymptoms(patientId,
                                                        admissionId, symptom),
                                              ),
                                            )
                                          ]),
                                        );
                                      })
                                      .values
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Updated button with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _openAddSymptomsScreen(
                        ref, context, patientId, admissionId),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Symptom',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                )
              ],
            ),
    );
  }

  DataColumn _buildDataColumn(String label, IconData icon, Color color) {
    return DataColumn(
      label: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomCell(String text) {
    return Row(
      children: [
        Icon(FontAwesomeIcons.disease, color: gradientColors[0], size: 16),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  Widget _buildDateCell(String text) {
    return Row(
      children: [
        Icon(FontAwesomeIcons.clock, color: gradientColors[1], size: 16),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  // ... keep existing _openAddSymptomsScreen and _buildShimmerEffect methods
}

Widget _buildShimmerEffect() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            height: 20,
            width: double.infinity,
            color: Colors.grey[300],
          ),
        ),
      ),
    ),
  );
}

void _openAddSymptomsScreen(
    ref, BuildContext context, String patientId, String admissionId) {
  // Implement navigation to add symptoms screen
  // Example:
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddSymptomScreen(
              patientId: patientId, admissionId: admissionId))).then((value) {
    if (value != null && value) {
      // Refresh data after returning from the screen
      ref.read(symptomsProvider.notifier).fetchSymptoms(patientId, admissionId);
    }
  });
}
