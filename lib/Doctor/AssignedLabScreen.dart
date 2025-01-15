import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/getLabPatient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assignedLabsProvider =
    StateNotifierProvider<AssignedLabsNotifier, List<AssignedLab>>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AssignedLabsNotifier(authRepository);
});

class AssignedLabsScreen extends ConsumerWidget {
  const AssignedLabsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the assigned labs data
    final assignedLabs = ref.watch(assignedLabsProvider);

    // Trigger a refresh of assigned labs when the screen is first built
    Future.delayed(Duration.zero, () {
      ref.read(assignedLabsProvider.notifier).fetchAssignedLabs();
    });

    return Scaffold(
      appBar: AppBar(
        actions: [
          // Manual refresh icon
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(assignedLabsProvider.notifier).fetchAssignedLabs();
            },
          ),
        ],
        backgroundColor: Colors.blue,
        title: const Text(
          'Assigned Labs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: assignedLabs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: assignedLabs.length,
              itemBuilder: (context, index) {
                final assignment = assignedLabs[index];

                // Collect all reports for the patient
                final reports = assignment.reports;

                return Card(
                  margin: const EdgeInsets.all(10.0),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        tileColor: Colors.deepPurple[50],
                        title: Text(
                          '${assignment.patient.name} Lab Test Name ${assignment.labTestNameGivenByDoctor}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        subtitle: Text(
                          'Age: ${assignment.patient.age}, Gender: ${assignment.patient.gender}\n'
                          'Assigned by: Dr. ${assignment.doctor.doctorName}\n'
                          'Contact: ${assignment.patient.contact}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: Icon(
                          Icons.assignment_outlined,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const Divider(),
                      ExpansionTile(
                        title: Text(
                          'Lab Reports (${reports.length})',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        children: [
                          if (reports.isNotEmpty)
                            ...reports.map((report) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: Card(
                                  color: Colors.deepPurple[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12.0),
                                    title: Text(
                                      report.labTestName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Uploaded At: ${report.uploadedAt}',
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                        ),
                                        Text(
                                          'Lab Type: ${report.labType}',
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Report URL:',
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Methods().openPdf(report.reportUrl);
                                            // Optionally, open the report URL
                                          },
                                          child: Text(
                                            report.reportUrl,
                                            style: TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          if (reports.isEmpty)
                            const ListTile(
                              title: Text('No reports available.',
                                  style:
                                      TextStyle(fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
