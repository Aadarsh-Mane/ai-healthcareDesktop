import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

final prescriptionsProvider =
    StateNotifierProvider<PrescriptionsNotifier, List<DoctorPrescription>>(
        (ref) {
  return PrescriptionsNotifier();
});

class PrescriptionsNotifier extends StateNotifier<List<DoctorPrescription>> {
  PrescriptionsNotifier() : super([]);

  final doctor = DoctorRepository();

  Future<void> fetchPrescriptions(String patientId, String admissionId) async {
    final prescriptions =
        await doctor.fetchPrescriptions(patientId, admissionId);
    state = prescriptions;
  }

  Future<void> deletePrescription(
      String patientId, String admissionId, String prescriptionId) async {
    try {
      await doctor.deletePrescription(patientId, admissionId, prescriptionId);
      state = state
          .where((prescription) => prescription.medicine.id != prescriptionId)
          .toList();
    } catch (e) {
      print("Error deleting prescription: $e");
    }
  }
}

class DoctorPrescriptionsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const DoctorPrescriptionsScreen({
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  _DoctorPrescriptionsScreenState createState() =>
      _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState
    extends ConsumerState<DoctorPrescriptionsScreen> {
  @override
  void initState() {
    super.initState();
    ref
        .read(prescriptionsProvider.notifier)
        .fetchPrescriptions(widget.patientId, widget.admissionId);
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionsList = ref.watch(prescriptionsProvider);
    final gradientColors = [const Color(0xFF005F9E), const Color(0xFF00B8D4)];

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
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: prescriptionsList.isEmpty
                ? const Center(child: CustomLoadingAnimation())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Patient Prescriptions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: gradientColors,
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 20)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: prescriptionsList.length,
                          itemBuilder: (context, index) {
                            final prescription = prescriptionsList[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientColors[0].withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(20),
                                      ),
                                      border: Border.all(
                                        width: 2,
                                        color:
                                            gradientColors[1].withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Prescribed On: ${prescription.medicine.date}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: gradientColors[0],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                      colors: gradientColors),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(
                                                  FontAwesomeIcons.trash,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              onPressed: () => ref
                                                  .read(prescriptionsProvider
                                                      .notifier)
                                                  .deletePrescription(
                                                      widget.patientId,
                                                      widget.admissionId,
                                                      prescription
                                                          .medicine.id!),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _buildPrescriptionRow(
                                          FontAwesomeIcons.pills,
                                          'Medicine',
                                          prescription.medicine.name ?? 'N/A',
                                          gradientColors[0],
                                        ),
                                        _buildPrescriptionRow(
                                          Icons.sunny,
                                          'Morning Dose',
                                          prescription.medicine.morning ??
                                              'N/A',
                                          gradientColors[1],
                                        ),
                                        _buildPrescriptionRow(
                                          Icons.wb_twilight,
                                          'Afternoon Dose',
                                          prescription.medicine.afternoon ??
                                              'N/A',
                                          gradientColors[0],
                                        ),
                                        _buildPrescriptionRow(
                                          FontAwesomeIcons.moon,
                                          'Night Dose',
                                          prescription.medicine.night ?? 'N/A',
                                          gradientColors[1],
                                        ),
                                        _buildPrescriptionRow(
                                          Icons.comment,
                                          'Comments',
                                          prescription.medicine.comment ??
                                              'No comments',
                                          gradientColors[0],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
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

  Widget _buildPrescriptionRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String formatToIST(String utcDate) {
    DateTime utcDateTime = DateTime.parse(utcDate).toUtc();
    DateTime istDateTime = utcDateTime.add(Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM yyyy, hh:mm a').format(istDateTime);
  }
}
