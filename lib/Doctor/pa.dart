import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PatientDashboardApp1 extends StatelessWidget {
  const PatientDashboardApp1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const PatientDashboard(),
    );
  }
}

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String _selectedTimeFilter = '7 Days';
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Added DefaultTabController
      length: 6, // Number of tabs
      child: Scaffold(
        body: Row(
          children: [
            // Left Navigation Sidebar
            Container(
              width: 60,
              color: const Color(0xFF2A3F54),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Back to Dashboard',
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Home',
                  ),
                  IconButton(
                    icon: const Icon(Icons.people, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Patients',
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Appointments',
                  ),
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Analytics',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Settings',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Help',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Patient Quick Access List
            Container(
              width: 250,
              color: const Color(0xFFF5F5F5),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search patients...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final isSelected = index == 0;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: Colors.blue, width: 1)
                                : null,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                [
                                  'JD',
                                  'SM',
                                  'RW',
                                  'MT',
                                  'KL',
                                  'CP',
                                  'AB',
                                  'NN',
                                  'DS',
                                  'TJ'
                                ][index],
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                            title: Text(
                              [
                                'John Doe',
                                'Sarah Miller',
                                'Robert Wilson',
                                'Maria Thompson',
                                'Kevin Lee',
                                'Claire Parker',
                                'Alex Brown',
                                'Nina Novak',
                                'David Smith',
                                'Tom Jones'
                              ][index],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text([
                              '#A${10230 + index}',
                              '#A${10340 + index}',
                              '#A${10450 + index}',
                              '#A${10560 + index}',
                              '#A${10670 + index}',
                              '#A${10780 + index}',
                              '#A${10890 + index}',
                              '#A${10900 + index}',
                              '#A${11010 + index}',
                              '#A${11120 + index}'
                            ][index]),
                            selected: isSelected,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Patient Summary Panel (Left Sidebar)
            Container(
              width: 280,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person,
                                  size: 40, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'John Doe',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '42 y/o, Male',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Admitted: 10 Mar 2025',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Patient ID',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    '#A10230',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    '304-B',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vitals Overview
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Vitals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildVitalCard(
                                'Heart Rate',
                                '78',
                                'bpm',
                                Colors.green,
                                Icons.favorite,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildVitalCard(
                                'BP',
                                '126/82',
                                'mmHg',
                                Colors.green,
                                Icons.speed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildVitalCard(
                                'Temperature',
                                '99.1',
                                '°F',
                                Colors.yellow.shade800,
                                Icons.thermostat,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildVitalCard(
                                'O2 Saturation',
                                '97',
                                '%',
                                Colors.green,
                                Icons.air,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Current Diagnosis
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Diagnosis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Type 2 Diabetes',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Spacer(),
                                  Text(
                                    'Primary',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hypertension',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hyperlipidemia',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Medications
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Medications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildMedicationCard(
                                  'Metformin',
                                  '500mg',
                                  'Twice daily with meals',
                                  '30 days (20 remaining)',
                                ),
                                const SizedBox(height: 8),
                                _buildMedicationCard(
                                  'Lisinopril',
                                  '10mg',
                                  'Once daily in the morning',
                                  '30 days (20 remaining)',
                                ),
                                const SizedBox(height: 8),
                                _buildMedicationCard(
                                  'Atorvastatin',
                                  '20mg',
                                  'Once daily at bedtime',
                                  '30 days (20 remaining)',
                                ),
                                const SizedBox(height: 8),
                                _buildMedicationCard(
                                  'Aspirin',
                                  '81mg',
                                  'Once daily with breakfast',
                                  '30 days (20 remaining)',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Analytics Panel
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header and Filters
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Patient Analytics',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              FilterChip(
                                label: const Text('24 Hours'),
                                selected: _selectedTimeFilter == '24 Hours',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeFilter = '24 Hours';
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('7 Days'),
                                selected: _selectedTimeFilter == '7 Days',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeFilter = '7 Days';
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('30 Days'),
                                selected: _selectedTimeFilter == '30 Days',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeFilter = '30 Days';
                                  });
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.download),
                                tooltip: 'Download Report',
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.print),
                                tooltip: 'Print',
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab Navigation
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        tabs: const [
                          Tab(text: 'Vitals Trend'),
                          Tab(text: 'Medication History'),
                          Tab(text: 'Visit History'),
                          Tab(text: 'Lab Reports'),
                          Tab(text: 'Alerts'),
                          Tab(text: 'Documents'),
                        ],
                        onTap: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        isScrollable: true,
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        indicator: const UnderlineTabIndicator(
                          borderSide: BorderSide(width: 3, color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        // Added TabBarView
                        children: [
                          // Vitals Trend
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildTabContent(),
                          ),
                          // Medication History
                          Center(child: Text('Medication History')),
                          // Visit History
                          Center(child: Text('Visit History')),
                          // Lab Reports
                          Center(child: Text('Lab Reports')),
                          // Alerts
                          Center(child: Text('Alerts')),
                          // Documents
                          Center(child: Text('Documents')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard(
      String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
      String name, String dosage, String schedule, String duration) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                dosage,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                schedule,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildVitalsTrendTab();
      case 1:
        return _buildMedicationHistoryTab();
      case 2:
        return _buildVisitHistoryTab();
      case 3:
        return _buildLabReportsTab();
      case 4:
        return _buildAlertsTab();
      case 5:
        return _buildDocumentsTab();
      default:
        return _buildVitalsTrendTab();
    }
  }

  Widget _buildDocumentsTab() {
    return Container();
    // return Container(
    //   padding: EdgeInsets.all(16.0),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(
    //         'Patient Documents',
    //         style: TextStyle(
    //           fontSize: 20,
    //           fontWeight: FontWeight.bold,
    //         ),
    //       ),
    //       SizedBox(height: 16.0),
    //       Expanded(
    //         child: ListView.builder(
    //           itemCount: patientDocuments.length,
    //           itemBuilder: (context, index) {
    //             final document = patientDocuments[index];
    //             return Card(
    //               margin: EdgeInsets.only(bottom: 8.0),
    //               child: ListTile(
    //                 leading: Icon(Icons.description),
    //                 title: Text(document.title),
    //                 subtitle: Text(document.date),
    //                 trailing: IconButton(
    //                   icon: Icon(Icons.download),
    //                   onPressed: () {
    //                     // Implement document download functionality
    //                     // _downloadDocument(document.id);
    //                   },
    //                 ),
    //                 onTap: () {
    //                   // Implement document viewing functionality
    //                   // _viewDocument(document.id);
    //                 },
    //               ),
    //             );
    //           },
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildVitalsTrendTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vitals Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              // Temperature Chart
              Expanded(
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Temperature (°F)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current: 99.1°F',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 98.6),
                                    FlSpot(1, 98.8),
                                    FlSpot(2, 99.0),
                                    FlSpot(3, 99.2),
                                    FlSpot(4, 99.1),
                                    FlSpot(5, 98.9),
                                    FlSpot(6, 99.1),
                                  ],
                                  isCurved: true,
                                  color: Colors.orange,
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.orange.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Heart Rate Chart
              Expanded(
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Heart Rate (bpm)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current: 78 bpm',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 82),
                                    FlSpot(1, 79),
                                    FlSpot(2, 75),
                                    FlSpot(3, 80),
                                    FlSpot(4, 83),
                                    FlSpot(5, 76),
                                    FlSpot(6, 78),
                                  ],
                                  isCurved: true,
                                  color: Colors.red,
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.red.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              // Blood Pressure Chart
              Expanded(
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Blood Pressure (mmHg)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current: 126/82 mmHg',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              lineBarsData: [
                                // Systolic
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 128),
                                    FlSpot(1, 130),
                                    FlSpot(2, 125),
                                    FlSpot(3, 132),
                                    FlSpot(4, 129),
                                    FlSpot(5, 127),
                                    FlSpot(6, 126),
                                  ],
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                ),
                                // Diastolic
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 85),
                                    FlSpot(1, 84),
                                    FlSpot(2, 80),
                                    FlSpot(3, 83),
                                    FlSpot(0, 85),
                                    FlSpot(1, 84),
                                    FlSpot(2, 80),
                                    FlSpot(3, 83),
                                    FlSpot(4, 81),
                                    FlSpot(5, 83),
                                    FlSpot(6, 82),
                                  ],
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Oxygen Level Chart
              Expanded(
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Oxygen Saturation (%)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Current: 97%',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 96),
                                    FlSpot(1, 98),
                                    FlSpot(2, 97),
                                    FlSpot(3, 95),
                                    FlSpot(4, 97),
                                    FlSpot(5, 98),
                                    FlSpot(6, 97),
                                  ],
                                  isCurved: true,
                                  color: Colors.purple,
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.purple.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationHistoryTab() {
    final medicationData = [
      {
        'name': 'Metformin',
        'dosage': '500mg',
        'startDate': '10 Jan 2025',
        'endDate': 'Ongoing',
        'adherence': 0.95,
        'status': 'Active',
      },
      {
        'name': 'Lisinopril',
        'dosage': '10mg',
        'startDate': '10 Jan 2025',
        'endDate': 'Ongoing',
        'adherence': 0.92,
        'status': 'Active',
      },
      {
        'name': 'Atorvastatin',
        'dosage': '20mg',
        'startDate': '10 Jan 2025',
        'endDate': 'Ongoing',
        'adherence': 0.98,
        'status': 'Active',
      },
      {
        'name': 'Acetaminophen',
        'dosage': '500mg',
        'startDate': '15 Feb 2025',
        'endDate': '22 Feb 2025',
        'adherence': 0.85,
        'status': 'Completed',
      },
      {
        'name': 'Amoxicillin',
        'dosage': '500mg',
        'startDate': '05 Feb 2025',
        'endDate': '15 Feb 2025',
        'adherence': 1.0,
        'status': 'Completed',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medication History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication Timeline & Adherence',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      for (int i = 0; i < 30; i++)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: i % 7 == 0
                                          ? Colors.grey.shade400
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (i % 3 == 0)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: i % 6 == 0
                                              ? Colors.yellow
                                              : Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    if (i % 4 == 0)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    if (i % 5 == 0)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.purple,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegendItem(Colors.green, 'Taken on time'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.yellow, 'Delayed'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.red, 'Missed'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medication List',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: medicationData.length,
                      itemBuilder: (context, index) {
                        final medication = medicationData[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: medication['status'] == 'Active'
                                      ? Colors.green
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medication['name'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      medication['dosage'].toString(),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From: ${medication['startDate']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      'To: ${medication['endDate']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Adherence',
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: medication['adherence'] as double,
                                      backgroundColor: Colors.grey.shade200,
                                      color: _getAdherenceColor(
                                          medication['adherence'] as double),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${((medication['adherence'] as double) * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Chip(
                                  label: Text(
                                    medication['status'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: medication['status'] == 'Active'
                                          ? Colors.green
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  backgroundColor:
                                      medication['status'] == 'Active'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.shade100,
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
          ),
        ),
      ],
    );
  }

  Color _getAdherenceColor(double adherence) {
    if (adherence >= 0.9) {
      return Colors.green;
    } else if (adherence >= 0.75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVisitHistoryTab() {
    final visitData = [
      {
        'date': '10 Mar 2025',
        'doctor': 'Dr. Sarah Johnson',
        'department': 'Endocrinology',
        'diagnosis': 'Type 2 Diabetes, Hypertension',
        'notes':
            'Patient reports fatigue and increased thirst. Blood glucose levels consistently above target range. Adjusted insulin dosage and recommended dietary changes.',
      },
      {
        'date': '15 Feb 2025',
        'doctor': 'Dr. Michael Wong',
        'department': 'Internal Medicine',
        'diagnosis': 'Upper Respiratory Infection',
        'notes':
            'Patient presented with cough, sore throat and low-grade fever. Prescribed amoxicillin for 10 days. Advised rest and increased fluid intake.',
      },
      {
        'date': '05 Jan 2025',
        'doctor': 'Dr. Sarah Johnson',
        'department': 'Endocrinology',
        'diagnosis': 'Type 2 Diabetes, Hypertension',
        'notes':
            'Routine follow-up. Blood glucose levels improved but still above target. Blood pressure well-controlled. Continue current medications with minor adjustments.',
      },
      {
        'date': '10 Dec 2024',
        'doctor': 'Dr. James Wilson',
        'department': 'Cardiology',
        'diagnosis': 'Hypertension, Hyperlipidemia',
        'notes':
            'Annual cardiac evaluation. EKG normal. Cholesterol levels improved with statin therapy. Continue current medication regimen.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visit & Treatment History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: visitData.length,
                itemBuilder: (context, index) {
                  final visit = visitData[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        '${visit['date']} - ${visit['doctor']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${visit['department']} | ${visit['diagnosis']}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Doctor Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                visit['notes'].toString(),
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.description),
                                    label: const Text('Full Report'),
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.print),
                                    label: const Text('Print'),
                                    onPressed: () {},
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
        ),
      ],
    );
  }

  Widget _buildLabReportsTab() {
    final labData = [
      {
        'date': '15 Mar 2025',
        'name': 'Complete Blood Count (CBC)',
        'status': 'Completed',
        'results': 'Normal',
        'doctor': 'Dr. Sarah Johnson',
      },
      {
        'date': '15 Mar 2025',
        'name': 'Comprehensive Metabolic Panel',
        'status': 'Completed',
        'results': 'Abnormal',
        'doctor': 'Dr. Sarah Johnson',
      },
      {
        'date': '15 Mar 2025',
        'name': 'Hemoglobin A1C',
        'status': 'Completed',
        'results': 'Abnormal',
        'doctor': 'Dr. Sarah Johnson',
      },
      {
        'date': '15 Mar 2025',
        'name': 'Lipid Panel',
        'status': 'Completed',
        'results': 'Normal',
        'doctor': 'Dr. Sarah Johnson',
      },
      {
        'date': '20 Mar 2025',
        'name': 'Thyroid Function Test',
        'status': 'Pending',
        'results': 'N/A',
        'doctor': 'Dr. Sarah Johnson',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lab Test Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Laboratory Results',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text('1 Pending'),
                        backgroundColor: Color(0xFFFFF3E0),
                        labelStyle: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: labData.length,
                      itemBuilder: (context, index) {
                        final lab = labData[index];
                        final bool isPending = lab['status'] == 'Pending';
                        final bool isAbnormal = lab['results'] == 'Abnormal';

                        Color statusColor;
                        if (isPending) {
                          statusColor = Colors.orange;
                        } else if (isAbnormal) {
                          statusColor = Colors.red;
                        } else {
                          statusColor = Colors.green;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lab['name'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Ordered by: ${lab['doctor']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  lab['date'].toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Chip(
                                  label: Text(
                                    lab['status'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPending
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                  backgroundColor: isPending
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: lab['results'] != 'N/A'
                                    ? Chip(
                                        label: Text(
                                          lab['results'].toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isAbnormal
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                        backgroundColor: isAbnormal
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                      )
                                    : const Text('--'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                tooltip: 'View Report',
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                tooltip: 'Download Report',
                                onPressed: () {},
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
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    final alertsData = [
      {
        'date': '22 Mar 2025',
        'type': 'Critical',
        'message': 'Blood glucose level 245 mg/dL (Target: 70-130 mg/dL)',
        'source': 'Glucose Monitor',
      },
      {
        'date': '20 Mar 2025',
        'type': 'Warning',
        'message':
            'Elevated blood pressure: 145/95 mmHg (Target: <130/80 mmHg)',
        'source': 'Regular Checkup',
      },
      {
        'date': '18 Mar 2025',
        'type': 'Warning',
        'message': 'Medication adherence below 80% for Metformin',
        'source': 'Medication Tracking',
      },
      {
        'date': '15 Mar 2025',
        'type': 'Info',
        'message':
            'Follow-up appointment with Dr. Sarah Johnson scheduled for April 15, 2025',
        'source': 'Appointment System',
      },
      {
        'date': '12 Mar 2025',
        'type': 'Info',
        'message':
            'Lab test results for Hemoglobin A1C received: 7.8% (Target: <7.0%)',
        'source': 'Laboratory System',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alerts & Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Critical Alerts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: alertsData.length,
                          itemBuilder: (context, index) {
                            final alert = alertsData[index];

                            IconData iconData;
                            Color iconColor;

                            switch (alert['type']) {
                              case 'Critical':
                                iconData = Icons.warning_amber;
                                iconColor = Colors.red;
                                break;
                              case 'Warning':
                                iconData = Icons.warning;
                                iconColor = Colors.orange;
                                break;
                              default:
                                iconData = Icons.info;
                                iconColor = Colors.blue;
                            }

                            if (alert['type'] == 'Info') {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: alert['type'] == 'Critical'
                                    ? Colors.red.withOpacity(0.05)
                                    : Colors.orange.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: alert['type'] == 'Critical'
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    iconData,
                                    color: iconColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert['message'].toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              alert['date'].toString(),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '| ${alert['source']}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {},
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
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Events',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildEventCard(
                              'Doctor Appointment',
                              'Dr. Sarah Johnson (Endocrinology)',
                              'Apr 15, 2025 | 10:30 AM',
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            _buildEventCard(
                              'Laboratory Test',
                              'Comprehensive Metabolic Panel',
                              'Apr 10, 2025 | 09:00 AM',
                              Icons.science,
                              Colors.purple,
                            ),
                            const SizedBox(height: 8),
                            _buildEventCard(
                              'Medication Refill',
                              'Metformin, Lisinopril, Atorvastatin',
                              'Apr 5, 2025',
                              Icons.medication,
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventCard(
      String title, String subtitle, String date, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
