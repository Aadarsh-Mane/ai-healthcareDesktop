import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isLoading = false;

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
          // ElevatedButton(
          //   onPressed: () async {
          //     setState(() => _isLoading = true);
          //     await ref
          //         .read(prescriptionsProvider.notifier)
          //         .fetchPrescriptions(widget.patientId, widget.admissionId);
          //     setState(() => _isLoading = false);
          //   },
          //   child: _isLoading
          //       ? const CustomLoadingAnimation()
          //       : const Text('Generate Prescription'),
          // ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: prescriptionsList.isEmpty
                ? const Center(child: Text('No prescriptions found.'))
                : ListView.builder(
                    itemCount: prescriptionsList.length,
                    itemBuilder: (context, index) {
                      final prescription = prescriptionsList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        elevation: 6,
                        color: Colors.white.withOpacity(0.9),
                        shadowColor: Colors.black26,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Medicines: ' +
                                        (prescription.medicine.name!),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(FontAwesomeIcons.trash,
                                        color: Color(0xff1565C0)),
                                    onPressed: () => ref
                                        .read(prescriptionsProvider.notifier)
                                        .deletePrescription(
                                            widget.patientId,
                                            widget.admissionId,
                                            prescription.medicine.id!),
                                  ),
                                ],
                              ),
                              _buildVitalsRow(Icons.sunny, 'Morning',
                                  "${prescription.medicine.morning}"),
                              _buildVitalsRow(Icons.wb_twilight, 'Afternoon',
                                  prescription.medicine.night.toString()),
                              _buildVitalsRow(FontAwesomeIcons.moon, 'Night',
                                  prescription.medicine.night.toString()),
                              _buildVitalsRow(Icons.comment, 'Comment',
                                  prescription.medicine.comment.toString()),
                              // _buildVitalsRow(FontAwesomeIcons.calendar, 'Date',
                              //     prescription.medicine.date.toString()),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 18),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                fontWeight: GoogleFonts.italiana().fontWeight,
                fontSize: 14,
                fontFamily: 'Poppins',
              )),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
    );
  }
}
