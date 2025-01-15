// import 'package:doctordesktop/model/getNewPatientModel.dart';
// import 'package:flutter/material.dart';

// class PatientDetailScreen4 extends StatelessWidget {
//   final Patient1 patient;

//   const PatientDetailScreen4({Key? key, required this.patient})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(patient.name),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             Text(
//               'Patient Details',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text('Name: ${patient.name}'),
//             Text('Age: ${patient.age}'),
//             Text('Gender: ${patient.gender}'),
//             Text('Contact: ${patient.contact}'),
//             Text('Address: ${patient.address}'),
//             const SizedBox(height: 20),
//             Text(
//               'Admission Records (${patient.admissionRecords.length})',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ...patient.admissionRecords.map(
//               (record) => Card(
//                 margin: const EdgeInsets.symmetric(vertical: 8),
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Admission Date: ${record.admissionDate}',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                           'Reason for Admission: ${record.reasonForAdmission}'),
//                       Text('Symptoms: ${record.symptoms}'),
//                       Text('Initial Diagnosis: ${record.initialDiagnosis}'),
//                       const SizedBox(height: 10),
//                       Text(
//                         'Reports (${record.reports.length}):',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       if (record.reports.isNotEmpty)
//                         ...record.reports.map((report) => Text('• $report'))
//                       else
//                         Text('No reports available'),
//                       const SizedBox(height: 10),
//                       Text(
//                         'Follow-Ups (${record.followUps.length}):',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       if (record.followUps.isNotEmpty)
//                         ...record.followUps.map(
//                           (followUp) => Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('• Date: ${followUp.date}'),
//                               Text('  Notes: ${followUp.notes}'),
//                               Text('  Observations: ${followUp.observations}'),
//                               Text('  Nurse ID: ${followUp.nurseId}'),
//                             ],
//                           ),
//                         )
//                       else
//                         Text('No follow-ups available'),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
