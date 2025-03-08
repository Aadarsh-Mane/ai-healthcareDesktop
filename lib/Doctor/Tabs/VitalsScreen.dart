// import 'package:doctordesktop/constants/colors.dart';
// import 'package:doctordesktop/model/getNewPatientModel.dart';
// import 'package:doctordesktop/repositories/doctor_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class VitalsScreen extends StatelessWidget {
//   final String patientId;
//   final String admissionId;

//   const VitalsScreen({
//     required this.patientId,
//     required this.admissionId,
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Color(0xffE3F2FD), // Background color
//                 image: DecorationImage(
//                   image: AssetImage('assets/vii.png'),
//                   fit: BoxFit.cover,
//                   opacity: 0.3, // Adjust opacity to blend with background color
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: _buildVitalsSection(patientId, admissionId),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVitalsSection(String patientId, String admissionId) {
//     final doctor = DoctorRepository();

//     return FutureBuilder<List<Vitals>>(
//       future: doctor.fetchVitals(patientId, admissionId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildShimmerEffect();
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: \${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('No vitals data available'));
//         } else {
//           List<Vitals> vitalsList = snapshot.data!;
//           return ListView.builder(
//             itemCount: vitalsList.length,
//             itemBuilder: (context, index) {
//               Vitals vitals = vitalsList[index];
//               return Card(
//                 margin:
//                     const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(30),
//                     bottomRight: Radius.circular(30),
//                   ),
//                 ),
//                 elevation: 17,
//                 color: Colors.white.withOpacity(0.8),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildVitalsRow(FontAwesomeIcons.thermometerHalf,
//                           'Temperature', "\${vitals.temperature}°C"),
//                       _buildVitalsRow(FontAwesomeIcons.heart, 'Pulse',
//                           "\${vitals.pulse} bpm"),
//                       _buildVitalsRow(
//                           FontAwesomeIcons.tint, 'BP', vitals.bloodPressure),
//                       _buildVitalsRow(FontAwesomeIcons.prescription, 'BSL',
//                           vitals.bloodSugarLevel),
//                       _buildVitalsRow(
//                           FontAwesomeIcons.notesMedical, 'Other', vitals.other),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         }
//       },
//     );
//   }

//   Widget _buildVitalsRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blueGrey, size: 20),
//           const SizedBox(width: 10),
//           Text('$label: ',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//           Expanded(
//             child: Text(value, style: TextStyle(fontSize: 16)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildShimmerEffect() {
//     return ListView.builder(
//       shrinkWrap: true,
//       itemCount: 3, // Show 3 shimmer items for loading
//       itemBuilder: (context, index) {
//         return Shimmer.fromColors(
//           baseColor: Colors.grey[300]!,
//           highlightColor: Colors.grey[100]!,
//           child: Card(
//             margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30.0),
//             ),
//             elevation: 6,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 16.0,
//                     width: 150.0,
//                     color: Colors.grey[300],
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     height: 16.0,
//                     width: 100.0,
//                     color: Colors.grey[300],
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     height: 16.0,
//                     width: 200.0,
//                     color: Colors.grey[300],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/Doctor/Tabs/Chart.dart';
import 'package:doctordesktop/constants/colors.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:doctordesktop/constants/colors.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class VitalsScreen extends StatelessWidget {
//   final String patientId;
//   final String admissionId;

//   const VitalsScreen({
//     required this.patientId,
//     required this.admissionId,
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.asset(
//               'assets/images/bb1.png',
//               fit: BoxFit.cover,
//               opacity: AlwaysStoppedAnimation(0.3),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: _buildVitalsSection(patientId, admissionId),
//           ),
//         ],
//       ),
//     );
//   }

//   String formatToIST(String utcDate) {
//     DateTime utcDateTime = DateTime.parse(utcDate).toUtc();
//     DateTime istDateTime = utcDateTime.add(Duration(hours: 5, minutes: 30));
//     return DateFormat('dd MMM yyyy, hh:mm a').format(istDateTime);
//   }

//   Widget _buildVitalsSection(String patientId, String admissionId) {
//     final doctor = DoctorRepository();

//     return FutureBuilder<List<Vitals>>(
//       future: doctor.fetchVitals(patientId, admissionId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildShimmerEffect();
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: \${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('No vitals data available'));
//         } else {
//           List<Vitals> vitalsList = snapshot.data!;
//           return ListView.builder(
//             itemCount: vitalsList.length,
//             itemBuilder: (context, index) {
//               Vitals vitals = vitalsList[index];
//               return Card(
//                 margin:
//                     const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     bottomRight: Radius.circular(20),
//                   ),
//                 ),
//                 elevation: 20,
//                 color: Colors.white.withOpacity(0.9),
//                 shadowColor: Colors.grey,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                       vertical: 12.0, horizontal: 16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Recorded On: ' +
//                                 (vitals.recordedAt != null
//                                     ? formatToIST(vitals.recordedAt!)
//                                     : 'N/A'),
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           IconButton(
//                             icon: Icon(FontAwesomeIcons.trash,
//                                 color: Color(0xff1565C0)),
//                             onPressed: () {
//                               // TODO: Implement delete function
//                             },
//                           ),
//                         ],
//                       ),
//                       _buildVitalsRow(FontAwesomeIcons.thermometerHalf,
//                           'Temperature', "${vitals.temperature}°C"),
//                       _buildVitalsRow(FontAwesomeIcons.heart, 'Pulse',
//                           "${vitals.pulse} bpm"),
//                       _buildVitalsRow(
//                           FontAwesomeIcons.tint, 'BP', vitals.bloodPressure),
//                       _buildVitalsRow(FontAwesomeIcons.prescription, 'BSL',
//                           vitals.bloodSugarLevel),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         }
//       },
//     );
//   }

//   Widget _buildVitalsRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blueGrey, size: 18),
//           const SizedBox(width: 8),
//           Text('$label: ',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//                 fontFamily: 'Poppins',
//               )),
//           Expanded(
//             child: Text(value,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontFamily: 'Poppins',
//                   fontWeight: FontWeight.normal,
//                 )),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildShimmerEffect() {
//     return ListView.builder(
//       shrinkWrap: true,
//       itemCount: 3,
//       itemBuilder: (context, index) {
//         return Shimmer.fromColors(
//           baseColor: Colors.grey[300]!,
//           highlightColor: Colors.grey[100]!,
//           child: Card(
//             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20.0),
//             ),
//             elevation: 4,
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 14.0,
//                     width: 150.0,
//                     color: Colors.grey[300],
//                   ),
//                   const SizedBox(height: 6),
//                   Container(
//                     height: 14.0,
//                     width: 100.0,
//                     color: Colors.grey[300],
//                   ),
//                   const SizedBox(height: 6),
//                   Container(
//                     height: 14.0,
//                     width: 200.0,
//                     color: Colors.grey[300],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:doctordesktop/constants/colors.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final vitalsProvider =
    StateNotifierProvider<VitalsNotifier, List<Vitals>>((ref) {
  return VitalsNotifier();
});

final doctor = DoctorRepository();

class VitalsNotifier extends StateNotifier<List<Vitals>> {
  VitalsNotifier() : super([]);

  Future<void> fetchVitals(String patientId, String admissionId) async {
    final vitals = await doctor.fetchVitals(patientId, admissionId);
    state = vitals;
  }

  Future<void> deleteVital(
      String patientId, String admissionId, String vitalsId) async {
    try {
      // Call the deleteVitals API method from doctor repository
      await doctor.deleteVitals(patientId, admissionId, vitalsId);

      // If the deletion was successful, update the state
      state = state.where((vital) => vital.id != vitalsId).toList();

      print("Vital deleted successfully");
    } catch (e) {
      print("Error deleting vital: $e");
      // Handle the error as needed (you can show a message to the user or log it)
    }
  }
}

class VitalsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const VitalsScreen({
    required this.patientId,
    required this.admissionId,
    Key? key,
  }) : super(key: key);

  @override
  _VitalsScreenState createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  @override
  void initState() {
    super.initState();
    // Call fetchVitals once when the screen is initialized
    ref
        .read(vitalsProvider.notifier)
        .fetchVitals(widget.patientId, widget.admissionId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref
        .read(vitalsProvider.notifier)
        .fetchVitals(widget.patientId, widget.admissionId);
  }

  @override
  Widget build(BuildContext context) {
    final vitalsList = ref.watch(vitalsProvider);
    final gradientColors = [const Color(0xFF005F9E), const Color(0xFF00B8D4)];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background with gradient overlay
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
            child: vitalsList.isEmpty
                ? Center(
                    child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2A79B4),
                      elevation: 0,
                    ),
                    onPressed: () => openAddVitalsDialog(
                        widget.patientId, widget.admissionId),
                    child: Text(
                      'No vitals available Click to add',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with gradient
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Patient Vitals History',
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
                      // Vitals List
                      Expanded(
                        child: ListView.builder(
                          itemCount: vitalsList.length,
                          itemBuilder: (context, index) {
                            final vitals = vitalsList[index];
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
                                  // Gradient Border
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
                                              'Recorded On: ${vitals.recordedAt != null ? formatToIST(vitals.recordedAt!) : 'N/A'}',
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
                                                  .read(vitalsProvider.notifier)
                                                  .deleteVital(
                                                      widget.patientId,
                                                      widget.admissionId,
                                                      vitals.id!),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVitalsRow(
                                          FontAwesomeIcons.thermometerHalf,
                                          'Temperature',
                                          "${vitals.temperature}°C",
                                          gradientColors[0],
                                        ),
                                        _buildVitalsRow(
                                          FontAwesomeIcons.heart,
                                          'Pulse',
                                          "${vitals.pulse} bpm",
                                          gradientColors[1],
                                        ),
                                        _buildVitalsRow(
                                          FontAwesomeIcons.tint,
                                          'BP',
                                          vitals.bloodPressure,
                                          gradientColors[0],
                                        ),
                                        _buildVitalsRow(
                                          FontAwesomeIcons.prescription,
                                          'BSL',
                                          vitals.bloodSugarLevel,
                                          gradientColors[1],
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

  Widget _buildVitalsRow(
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

  void openAddVitalsDialog(String patientId, String admissionId) {
    final temperature = TextEditingController();
    final pulse = TextEditingController();
    final bloodPressure = TextEditingController();
    final bloodSugarLevel = TextEditingController();
    final other = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Vitals'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: temperature,
                decoration: const InputDecoration(labelText: 'Temperature '),
              ),
              TextField(
                controller: pulse,
                decoration: const InputDecoration(labelText: 'Pulse'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bloodPressure,
                decoration: const InputDecoration(labelText: 'Blood Pressure'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bloodSugarLevel,
                decoration: const InputDecoration(labelText: 'Sugar Level'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: other,
                decoration: const InputDecoration(labelText: 'Others'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final String currentDateTime =
                    DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

                // Append the current date and time to the 'other' field, placing it on a new line
                final String otherWithDateTime =
                    '${other.text}\nDate: $currentDateTime';
                final vitals = Vitals(
                  temperature: temperature.text,
                  pulse: pulse.text,
                  bloodPressure: bloodPressure.text,
                  bloodSugarLevel: bloodSugarLevel.text,
                  other: otherWithDateTime,
                );

                try {
                  // print("vital are ${vitals.}");
                  await doctor.addVitals(patientId, admissionId, vitals);

                  // Refresh the data after adding the prescription
                  await ref
                      .read(vitalsProvider.notifier)
                      .fetchVitals(patientId, admissionId);

                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  print('Error adding prescription: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Add Vitals'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitalsRow1(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 18),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Poppins',
              )),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.normal,
                )),
          ),
        ],
      ),
    );
  }
}
