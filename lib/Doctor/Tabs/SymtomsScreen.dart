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
  @override
  void initState() {
    super.initState();
    // Fetch symptoms when the screen is first loaded
    ref
        .read(symptomsProvider.notifier)
        .fetchSymptoms(widget.patientId, widget.admissionId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/bb1.png',
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(0.3),
            ),
          ),
          Center(
            child: SizedBox(
              width: mediaQuery.width * 0.7, // Adjusts width for desktop
              child: SymptomsContent(
                symptomsList: symptomsList,
                patientId: widget.patientId,
                admissionId: widget.admissionId,
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

  const SymptomsContent({
    required this.symptomsList,
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: symptomsList.isEmpty
          ? Center(child: CustomLoadingAnimation())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FontAwesomeIcons.heartbeat,
                        color: Colors.red, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Symptoms by Doctor',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
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
                                // Centering the table
                                child: DataTable(
                                  columnSpacing: 40,
                                  horizontalMargin: 16,
                                  columns: const [
                                    DataColumn(
                                      label: Row(
                                        children: [
                                          Icon(FontAwesomeIcons.hashtag,
                                              color: Colors.teal, size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            'No.',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataColumn(
                                      label: Row(
                                        children: [
                                          Icon(FontAwesomeIcons.notesMedical,
                                              color: Colors.teal, size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            'Symptom',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataColumn(
                                      label: Row(
                                        children: [
                                          Icon(FontAwesomeIcons.calendarAlt,
                                              color: Colors.teal, size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            'Date',
                                            style: TextStyle(
                                              color: Colors.teal,
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataColumn(
                                      label: Row(
                                        children: [
                                          Icon(FontAwesomeIcons.deleteLeft,
                                              color: Colors.teal, size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.teal,
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                            DataCell(Row(
                                              children: [
                                                const Icon(
                                                    FontAwesomeIcons.disease,
                                                    color: Colors.red,
                                                    size: 16),
                                                const SizedBox(width: 6),
                                                Text(symptomText),
                                              ],
                                            )),
                                            DataCell(Row(
                                              children: [
                                                const Icon(
                                                    FontAwesomeIcons.clock,
                                                    color: Colors.blue,
                                                    size: 16),
                                                const SizedBox(width: 6),
                                                Text(dateText),
                                              ],
                                            )),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  ref
                                                      .read(symptomsProvider
                                                          .notifier)
                                                      .deleteSymptoms(patientId,
                                                          admissionId, symptom);
                                                },
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
                ElevatedButton.icon(
                  onPressed: () =>
                      _openAddSymptomsScreen(context, patientId, admissionId),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Symptom',
                      style: TextStyle(
                          color: Colors.white, fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                  ),
                )
              ],
            ),
    );
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
      BuildContext context, String patientId, String admissionId) {
    // Implement navigation to add symptoms screen
    // Example:
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddSymptomScreen(
                patientId: patientId, admissionId: admissionId)));
  }
}
