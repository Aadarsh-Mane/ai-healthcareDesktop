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

class AssignedLabsScreen extends ConsumerStatefulWidget {
  const AssignedLabsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AssignedLabsScreen> createState() => _AssignedLabsScreenState();
}

class _AssignedLabsScreenState extends ConsumerState<AssignedLabsScreen> {
  final gradientColors = [const Color(0xFF005F9E), const Color(0xFF00B8D4)];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    ref.read(assignedLabsProvider.notifier).fetchAssignedLabs();
  }

  @override
  Widget build(BuildContext context) {
    final assignedLabs = ref.watch(assignedLabsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Assigned Laboratory Tests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: gradientColors,
              ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.refresh, color: Colors.white, size: 24),
            ),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientColors[0].withOpacity(0.15),
              gradientColors[1].withOpacity(0.15)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/bb1.png'),
            opacity: 0.2,
            fit: BoxFit.cover,
          ),
        ),
        child: assignedLabs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: gradientColors[0].withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Laboratory Assignments Found',
                      style: TextStyle(
                        fontSize: 18,
                        color: gradientColors[0].withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: assignedLabs.length,
                  itemBuilder: (context, index) {
                    final assignment = assignedLabs[index];
                    final reports = assignment.reports;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
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
                                color: gradientColors[1].withOpacity(0.3),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            gradientColors[0].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 24,
                                        color: gradientColors[0],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        assignment.patient.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: gradientColors[0],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 12,
                                  children: [
                                    _buildDetailItem(
                                      Icons.calendar_today,
                                      '${assignment.patient.age} years',
                                      gradientColors[0],
                                    ),
                                    _buildDetailItem(
                                      Icons.transgender,
                                      assignment.patient.gender,
                                      gradientColors[1],
                                    ),
                                    _buildDetailItem(
                                      Icons.medical_services,
                                      'Test: ${assignment.labTestNameGivenByDoctor}',
                                      gradientColors[0],
                                    ),
                                    _buildDetailItem(
                                      Icons.contact_page,
                                      assignment.patient.contact,
                                      gradientColors[1],
                                    ),
                                    _buildDetailItem(
                                      Icons.badge,
                                      'Dr. ${assignment.doctor.doctorName}',
                                      gradientColors[0],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: gradientColors[0].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.library_books,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                  title: Text(
                                    'Laboratory Reports (${reports.length})',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: gradientColors[0],
                                    ),
                                  ),
                                  children: reports.isNotEmpty
                                      ? reports
                                          .map((report) => _buildReportCard(
                                              report, gradientColors))
                                          .toList()
                                      : [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              'No reports available',
                                              style: TextStyle(
                                                  color: gradientColors[0]
                                                      .withOpacity(0.7),
                                                  fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                        ],
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
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(LabReport report, List<Color> gradientColors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: gradientColors[1].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: gradientColors[1].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.picture_as_pdf,
            color: gradientColors[1],
          ),
        ),
        title: Text(report.labTestName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Uploaded: ${report.uploadedAt}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text('Type: ${report.labType}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
            onPressed: () => Methods().openPdf(report.reportUrl),
          ),
        ),
      ),
    );
  }
}
