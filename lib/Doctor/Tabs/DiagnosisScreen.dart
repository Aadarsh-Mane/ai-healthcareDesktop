import 'package:doctordesktop/Doctor/AddDiagnosisScreen.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final doctor = DoctorRepository();
final diagnosisProvider =
    StateNotifierProvider<DiagnosisNotifier, List<String>>((ref) {
  return DiagnosisNotifier();
});

class DiagnosisNotifier extends StateNotifier<List<String>> {
  DiagnosisNotifier() : super([]);

  Future<void> fetchDiagnosis(String patientId, String admissionId) async {
    final diagnosis = await doctor.fetchDoctorDiagnosis(admissionId, patientId);
    state = diagnosis;
  }

  Future<void> deleteDiagnosis(
      String patientId, String admissionId, String diagnosis) async {
    try {
      await doctor.deleteDiagnosis(patientId, admissionId, diagnosis);
      state = state.where((d) => d != diagnosis).toList();
    } catch (e) {
      print("Error deleting diagnosis: $e");
    }
  }
}

class DiagnosisScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const DiagnosisScreen({
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  _DiagnosisScreenState createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  final gradientColors = [const Color(0xFF005F9E), const Color(0xFF00B8D4)];

  @override
  void initState() {
    super.initState();
    ref
        .read(diagnosisProvider.notifier)
        .fetchDiagnosis(widget.patientId, widget.admissionId);
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisList = ref.watch(diagnosisProvider);
    final mediaQuery = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
              child: DiagnosisContent(
                diagnosisList: diagnosisList,
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

class DiagnosisContent extends ConsumerWidget {
  final List<String> diagnosisList;
  final String patientId;
  final String admissionId;
  final List<Color> gradientColors;

  const DiagnosisContent({
    required this.diagnosisList,
    required this.patientId,
    required this.admissionId,
    required this.gradientColors,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: diagnosisList.isEmpty
          ? const Center(child: CustomLoadingAnimation())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Diagnosis by Doctor',
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
                            height: diagnosisList.length > 6 ? 300 : null,
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
                                      'Diagnosis',
                                      FontAwesomeIcons.clipboardCheck,
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
                                  // In your DataTable rows construction
                                  rows: diagnosisList
                                      .asMap()
                                      .map((index, diagnosis) {
                                        // Updated splitting logic for date extraction
                                        final dateSplit =
                                            diagnosis.split(RegExp(r' Date: '));
                                        final diagnosisText = dateSplit[0];
                                        final dateText = dateSplit.length > 1
                                            ? dateSplit[1]
                                            : '';

                                        return MapEntry(
                                          index,
                                          DataRow(cells: [
                                            DataCell(Text('${index + 1}')),
                                            DataCell(_buildDiagnosisCell(
                                                diagnosisText)),
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
                                                    .read(diagnosisProvider
                                                        .notifier)
                                                    .deleteDiagnosis(patientId,
                                                        admissionId, diagnosis),
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
                    onPressed: () => {
                      openAddDiagnosisScreen(
                          ref, context, patientId, admissionId),
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Diagnosis',
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

  void openAddDiagnosisScreen(
      ref, BuildContext context, patientId, String admissionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDiagnosisDoctorScreen(
          patientId: patientId,
          admissionId: admissionId,
          addDoctorDiagnosis: doctor.addDoctorDiagnosis,
          fetchDoctorDiagnosis: doctor.fetchDoctorDiagnosis,
        ),
      ),
    ).then((value) {
      if (value != null && value) {
        ref
            .read(diagnosisProvider.notifier)
            .fetchDiagnosis(patientId, admissionId); // Refresh state
      }
    });
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

  // Widget _buildDiagnosisCell(String text) {
  //   return Row(
  //     children: [
  //       Icon(FontAwesomeIcons.stethoscope, color: gradientColors[0], size: 16),
  //       const SizedBox(width: 6),
  //       Text(text),
  //     ],
  //   );
  // }
  Widget _buildDiagnosisCell(String text) {
    final scrollController = ScrollController(); // <-- Add controller

    return Row(
      children: [
        Icon(FontAwesomeIcons.stethoscope, color: gradientColors[0], size: 16),
        const SizedBox(width: 6),
        Container(
          constraints: BoxConstraints(maxWidth: 300),
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true, // Always show scrollbar for desktop
            trackVisibility: true,
            thickness: 0.6,
            radius: Radius.circular(4),
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: scrollController,
              physics:
                  const AlwaysScrollableScrollPhysics(), // <-- Important for mouse
              scrollDirection: Axis.horizontal,
              child: MouseRegion(
                cursor: SystemMouseCursors.click, // <-- Show click cursor
                child: SelectableText(
                  // <-- Make text selectable
                  text,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ),
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
}
