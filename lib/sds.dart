import 'package:flutter/material.dart';

class AssignedPatientsScreen2 extends StatelessWidget {
  final List<Patient> patients = [
    Patient('John Doe', '9876543210', 'Admitted', '9876543210', '2025-05-01'),
    Patient(
        'Jane Smith', '9123456789', 'Discharged', '9123456789', '2025-04-20'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assigned Patients'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Patient Name')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Contact')),
            DataColumn(label: Text('Admission Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: patients.map((patient) {
            return DataRow(cells: [
              DataCell(Text(patient.name)),
              DataCell(Text(patient.phone)),
              DataCell(Text(patient.status)),
              DataCell(Text(patient.contact)),
              DataCell(Text(patient.admissionDate)),
              DataCell(Row(
                children: [
                  TextButton(
                    onPressed: () {
                      // View patient details
                    },
                    child: Text("View"),
                  ),
                  SizedBox(width: 8),
                  if (patient.status == "Admitted")
                    TextButton(
                      onPressed: () {
                        // Discharge action
                      },
                      child: Text("Discharge"),
                    ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class Patient {
  final String name;
  final String phone;
  final String status;
  final String contact;
  final String admissionDate;

  Patient(this.name, this.phone, this.status, this.contact, this.admissionDate);
}
