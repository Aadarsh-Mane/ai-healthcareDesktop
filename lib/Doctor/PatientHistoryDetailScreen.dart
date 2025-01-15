import 'package:doctordesktop/model/getNewPatientHistoryModel.dart';
import 'package:doctordesktop/repositories/history_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PatientHistoryDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientHistoryDetailScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientHistoryDetailScreen> {
  late Future<PatientHistory> _patientHistoryFuture;
  final history = HistoryRepository();
  @override
  void initState() {
    super.initState();
    _patientHistoryFuture = history.fetchPatientHistory(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
      ),
      body: FutureBuilder<PatientHistory>(
        future: _patientHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            final patientHistory = snapshot.data!;
            return _buildPatientDetails(patientHistory);
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }

  Widget _buildPatientDetails(PatientHistory patientHistory) {
    final history = patientHistory.history!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Basic Details'),
          _buildDetail('Name', history.name),
          _buildDetail('Gender', history.gender),
          _buildDetail('Contact', history.contact),
          const SizedBox(height: 16),
          _buildHeader('Admission History'),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.history?.length ?? 0,
            itemBuilder: (context, index) {
              final admission = history.history![index];
              return _buildAdmissionCard(admission);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisList(List<String> diagnosis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: diagnosis.map((item) => Text(item)).toList(),
    );
  }

  Widget _buildSymptomsList(List<String> symptoms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: symptoms.map((symptom) => Text(symptom)).toList(),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$label: ${value ?? "N/A"}',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildAdmissionCard(AdmissionRecord admission) {
    print("checking $admission");
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Admission Details'),
            _buildDetail('Admission ID', admission.admissionId),
            _buildDetail('Reason for Admission', admission.reasonForAdmission),
            _buildDetail('Initial  Diagnosis', admission.initialDiagnosis),
            _buildDetail('Previous Remaining Amount',
                admission.previousRemainingAmount.toString()),
            _buildDetail('Weight  ', admission.weight.toString()),
            _buildDetail('Symptoms', admission.symptoms),
            _buildDetail('Admission Date', admission.admissionDate?.toString()),
            _buildDetail('Discharge Date', admission.dischargeDate?.toString()),
            _buildDetail(
                'Condition at Discharge', admission.conditionAtDischarge),
            _buildHeader('Doctor Details'),
            _buildDetail('Doctor Name', admission.doctor?.name),
            _buildDetail('Doctor ID', admission.doctor?.id),
            const SizedBox(height: 8),
            _buildHeader('Vitals'),
            admission.vitals != null && admission.vitals!.isNotEmpty
                ? _buildVitalsList(admission.vitals!)
                : const Text('No vitals available'),
            const SizedBox(height: 8),
            _buildHeader('Lab Reports'),
            admission.labReports != null && admission.labReports!.isNotEmpty
                ? _buildLabReportsList(admission.labReports!)
                : const Text('No lab reports available'),
            _buildHeader('Doctor Prescriptions'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: admission.doctorPrescriptions?.length ?? 0,
              itemBuilder: (context, index) {
                final prescription = admission.doctorPrescriptions![index];

                // Assuming you want to display the medicine's name and dosage information
                return ListTile(
                  title:
                      Text(prescription.medicine?.name ?? 'No Medicine Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Morning: ${prescription.medicine?.morning ?? 'N/A'}'),
                      Text(
                          'Afternoon: ${prescription.medicine?.afternoon ?? 'N/A'}'),
                      Text('Night: ${prescription.medicine?.night ?? 'N/A'}'),
                      if (prescription.medicine?.comment != null)
                        Text('Comment: ${prescription.medicine?.comment}'),
                      Text('Date: ${prescription.medicine?.date}'),
                    ],
                  ),
                );
              },
            ),
            // Symptoms by Doctor
            _buildHeader('Symptoms by Doctor'),
            admission.symptomsByDoctor != null &&
                    admission.symptomsByDoctor!.isNotEmpty
                ? _buildSymptomsList(admission.symptomsByDoctor!.cast<String>())
                : const Text('No symptoms by doctor available'),

            // Diagnosis by Doctor
            _buildHeader('Diagnosis by Doctor'),
            admission.diagnosisByDoctor != null &&
                    admission.diagnosisByDoctor!.isNotEmpty
                ? _buildDiagnosisList(admission.diagnosisByDoctor!)
                : const Text('No diagnosis by doctor available'),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsList(List<Vital> vitals) {
    return Column(
      children: vitals.map((vital) {
        return Card(
          child: ListTile(
            title: Text('Temperature: ${vital.temperature ?? "N/A"}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pulse: ${vital.pulse ?? "N/A"}'),
                Text('Other: ${vital.other ?? "N/A"}'),
                Text('Recorded At: ${vital.recordedAt ?? "N/A"}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

// Widget for building the list of lab reports
  Widget _buildLabReportsList(List<LabReport> labReports) {
    return Column(
      children: labReports.map((labReport) {
        return Card(
          child: ListTile(
            title: Text(
                'Lab Test: ${labReport.labTestNameGivenByDoctor ?? "N/A"}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: labReport.reports!.map((report) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Report: ${report.labTestName} | ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: 'URL: ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: report.reportUrl ?? "N/A",
                          style: TextStyle(
                            color: Colors.blue, // Make it look like a link
                            decoration:
                                TextDecoration.underline, // Underline it
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              if (report.reportUrl != null) {
                                final Uri url = Uri.parse(report.reportUrl!);
                                // if (await canLaunch(url.toString())) {
                                //   await launch(url.toString(),
                                //       forceSafariVC: false,
                                //       forceWebView: false);
                                // } else {
                                //   ScaffoldMessenger.of(context).showSnackBar(
                                //     SnackBar(
                                //         content: Text(
                                //             'Could not open the report URL')),
                                //   );
                                // }
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}
