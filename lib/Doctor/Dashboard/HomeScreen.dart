import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HospitalDashboardApp extends StatelessWidget {
  const HospitalDashboardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.light,
      home: const HospitalDashboard(),
    );
  }
}

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({Key? key}) : super(key: key);

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  int _selectedIndex = 0;
  String _selectedDateRange = 'This Week';
  final String _todayDate =
      DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

  // Sample data for charts
  final List<double> admissionsData = [23, 34, 67, 45, 39, 48, 29];
  final List<double> dischargesData = [19, 31, 52, 43, 30, 45, 25];
  final Map<String, double> conditionData = {
    'Recovered': 75.0,
    'Transferred': 15.0,
    'AMA': 5.0,
    'Other': 5.0,
  };
  final Map<String, double> symptomsData = {
    'Fever': 35.0,
    'Cough': 25.0,
    'Headache': 15.0,
    'Body Pain': 10.0,
    'Others': 15.0,
  };
  final List<Map<String, dynamic>> medicationsData = [
    {'name': 'Paracetamol', 'count': 245},
    {'name': 'Amoxicillin', 'count': 187},
    {'name': 'Ibuprofen', 'count': 156},
    {'name': 'Azithromycin', 'count': 124},
    {'name': 'Aspirin', 'count': 98},
  ];
  final List<Map<String, dynamic>> criticalAlerts = [
    {
      'patient': 'John Doe',
      'issue': 'High BP',
      'room': '203A',
      'priority': 'High'
    },
    {
      'patient': 'Mary Smith',
      'issue': 'Post-Op Fever',
      'room': '105B',
      'priority': 'Medium'
    },
    {
      'patient': 'Robert Johnson',
      'issue': 'Abnormal ECG',
      'room': '310C',
      'priority': 'High'
    },
    {
      'patient': 'Emily Wilson',
      'issue': 'Low O2 Levels',
      'room': '402D',
      'priority': 'Critical'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1️⃣ Sidebar (Navigation)
          // _buildSidebar(),

          // 2️⃣ Main Dashboard Panel
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Header and Search Bar
                  _buildHeader(),

                  // Dashboard Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Overview Cards
                            _buildStatsOverview(),

                            const SizedBox(height: 24),

                            // 3️⃣ Key Analytics Sections

                            // 📊 Patient & Admission Stats
                            _buildSectionTitle('Patient & Admission Stats'),
                            _buildAdmissionStats(),

                            const SizedBox(height: 24),

                            // 🏥 Symptom Trends & 💊 Medication Analytics
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildSymptomTrends()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMedicationAnalytics()),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ❤️ Vital Signs Monitoring & 🚨 Critical Alerts
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildVitalSigns()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildCriticalAlerts()),
                              ],
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1️⃣ Sidebar Widget
  Widget _buildSidebar() {
    const List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.people, 'label': 'Patients'},
      {'icon': Icons.analytics, 'label': 'Analytics'},
      {'icon': Icons.description, 'label': 'Reports'},
      {'icon': Icons.settings, 'label': 'Settings'},
    ];

    return Container(
      width: 240,
      color: Colors.blue[800],
      child: Column(
        children: [
          // App Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'MediDash',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.blue, height: 1),

          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(
                    menuItems[index]['icon'],
                    color:
                        _selectedIndex == index ? Colors.white : Colors.white70,
                  ),
                  title: Text(
                    menuItems[index]['label'],
                    style: TextStyle(
                      color: _selectedIndex == index
                          ? Colors.white
                          : Colors.white70,
                      fontWeight: _selectedIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: _selectedIndex == index,
                  selectedTileColor: Colors.blue[700],
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),

          // User Profile at Bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[900],
              border: const Border(
                top: BorderSide(color: Colors.blue, width: 1),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      NetworkImage('https://via.placeholder.com/150'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Dr. Jane Smith',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cardiologist',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
  }

  // 2️⃣ Header Widget
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hospital Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _todayDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          // Container(
          //   width: 300,
          //   height: 40,
          //   decoration: BoxDecoration(
          //     color: Colors.grey[100],
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: TextField(
          //     decoration: InputDecoration(
          //       hintText: 'Search patients, diagnoses...',
          //       prefixIcon: const Icon(Icons.search),
          //       border: InputBorder.none,
          //       contentPadding: const EdgeInsets.symmetric(vertical: 10),
          //       hintStyle: TextStyle(color: Colors.grey[500]),
          //     ),
          //   ),
          // ),

          const SizedBox(width: 16),

          // Date Range Selector
          DropdownButton<String>(
            value: _selectedDateRange,
            items: <String>['Today', 'This Week', 'This Month', 'Last 3 Months']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDateRange = newValue;
                });
              }
            },
          ),

          const SizedBox(width: 8),

          // Notifications Icon
          Badge(
            backgroundColor: Colors.red,
            label: const Text('3', style: TextStyle(color: Colors.white)),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  // Stats Overview Cards
  Widget _buildStatsOverview() {
    final List<Map<String, dynamic>> statsCards = [
      {
        'title': 'Total Patients',
        'value': '1,245',
        'trend': '+2.3%',
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Discharges Today',
        'value': '37',
        'trend': '+5.1%',
        'icon': Icons.exit_to_app,
        'color': Colors.green,
      },
      {
        'title': 'Avg. Stay Duration',
        'value': '4.2 days',
        'trend': '-0.5 days',
        'icon': Icons.access_time,
        'color': Colors.orange,
      },
      {
        'title': 'Revenue Collected',
        'value': '\$142,589',
        'trend': '+12.7%',
        'icon': Icons.attach_money,
        'color': Colors.purple,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1200, // Increased width to ensure text fits
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3.0, // Increased aspect ratio to make cards wider
          ),
          itemCount: statsCards.length,
          itemBuilder: (context, index) {
            final card = statsCards[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: card['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      card['icon'],
                      color: card['color'],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card['title'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                card['value'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              card['trend'],
                              style: TextStyle(
                                color: card['trend'].startsWith('+')
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
    );
  }

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Patient & Admission Stats
  Widget _buildAdmissionStats() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar Chart: Admissions & Discharges
        Expanded(
          flex: 3,
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admissions & Discharges (Last Week)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 70,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              return SideTitleWidget(
                                meta: meta,
                                // axisSide: meta.axisSide,
                                child: Text(
                                  days[value.toInt() % days.length],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                // axisSide: meta.axisSide,
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: List.generate(
                        7,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: admissionsData[index],
                              color: Colors.blue,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: dischargesData[index],
                              color: Colors.green,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Admissions', Colors.blue),
                    const SizedBox(width: 16),
                    _buildLegendItem('Discharges', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Pie Chart: Condition at Discharge
        Expanded(
          flex: 2,
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Condition at Discharge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16), // Reduced height from 46 to 16
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: conditionData['Recovered'],
                          title: '75%',
                          radius: 60, // Reduced radius from 80 to 60
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: conditionData['Transferred'],
                          title: '15%',
                          radius: 60, // Reduced radius from 80 to 60
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: conditionData['AMA'],
                          title: '5%',
                          radius: 60, // Reduced radius from 80 to 60
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.grey,
                          value: conditionData['Other'],
                          title: '5%',
                          radius: 60, // Reduced radius from 80 to 60
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend with proper spacing
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Recovered', Colors.green),
                          const SizedBox(width: 16),
                          _buildLegendItem('Transferred', Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('AMA', Colors.red),
                          const SizedBox(width: 16),
                          _buildLegendItem('Other', Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Symptom Trends
  Widget _buildSymptomTrends() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptom Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.blue[400],
                    value: symptomsData['Fever'],
                    title: '35%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.green[400],
                    value: symptomsData['Cough'],
                    title: '25%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.purple[400],
                    value: symptomsData['Headache'],
                    title: '15%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange[400],
                    value: symptomsData['Body Pain'],
                    title: '10%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.grey[400],
                    value: symptomsData['Others'],
                    title: '15%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Fever', Colors.blue[400]!),
                  const SizedBox(width: 16),
                  _buildLegendItem('Cough', Colors.green[400]!),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Headache', Colors.purple[400]!),
                  const SizedBox(width: 16),
                  _buildLegendItem('Body Pain', Colors.orange[400]!),
                ],
              ),
              const SizedBox(height: 8),
              _buildLegendItem('Others', Colors.grey[400]!),
            ],
          ),
        ],
      ),
    );
  }

  // Medication Analytics
  Widget _buildMedicationAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Analytics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medicationsData.length,
            itemBuilder: (context, index) {
              final medication = medicationsData[index];
              final double percentage = medication['count'] / 245 * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          medication['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${medication['count']} prescriptions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: medication['count'] / 245,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(percentage),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('View All Medications'),
          ),
        ],
      ),
    );
  }

  // Vital Signs Monitoring
  Widget _buildVitalSigns() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vital Signs Monitoring',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              DropdownButton<String>(
                value: 'Last 24 Hours',
                items: <String>['Last 24 Hours', 'Last Week', 'Last Month']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildVitalCard('Temperature', '36.8°C', Colors.orange,
                      Icons.thermostat)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildVitalCard(
                      'Blood Pressure', '120/80', Colors.red, Icons.favorite)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildVitalCard('Heart Rate', '72 bpm', Colors.pink,
                      Icons.monitor_heart)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _buildVitalCard('SpO2', '98%', Colors.blue, Icons.air)),
            ],
          ),
          const SizedBox(height: 16),
          // Simple line chart for temperature over time
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const times = [
                          '6AM',
                          '10AM',
                          '2PM',
                          '6PM',
                          '10PM',
                          '2AM'
                        ];
                        final index = value.toInt();
                        if (index >= 0 && index < times.length) {
                          return SideTitleWidget(
                            meta: meta,
                            // axisSide: meta.axisSide,
                            child: Text(
                              times[index],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                minX: 0,
                maxX: 5,
                minY: 36,
                maxY: 38,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 36.7),
                      FlSpot(1, 36.8),
                      FlSpot(2, 37.1),
                      FlSpot(3, 37.3),
                      FlSpot(4, 37.0),
                      FlSpot(5, 36.6),
                    ],
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('View Detailed Vitals'),
          ),
        ],
      ),
    );
  }

  // Vital Card Widget
  Widget _buildVitalCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Critical Alerts
  Widget _buildCriticalAlerts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Critical Alerts & Follow-ups',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Badge(
                backgroundColor: Colors.red,
                label: const Text('4', style: TextStyle(color: Colors.white)),
                child: const Icon(Icons.warning, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: criticalAlerts.length,
            itemBuilder: (context, index) {
              final alert = criticalAlerts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAlertColor(alert['priority']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getAlertColor(alert['priority']).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getAlertColor(alert['priority']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                alert['patient'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Room ${alert['room']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            alert['issue'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {},
                      color: Colors.grey[600],
                      iconSize: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('View All Alerts'),
          ),
        ],
      ),
    );
  }

  // Helper method for Legend
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Helper method for progress color
  Color _getProgressColor(double percentage) {
    if (percentage > 80) return Colors.blue;
    if (percentage > 50) return Colors.green;
    if (percentage > 30) return Colors.orange;
    return Colors.red;
  }

  // Helper method for alert color
  Color _getAlertColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }
}

// Badge widget implementation for Flutter versions without it
class Badge extends StatelessWidget {
  final Widget child;
  final Widget? label;
  final Color backgroundColor;

  const Badge({
    Key? key,
    required this.child,
    this.label,
    this.backgroundColor = Colors.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (label != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(child: label),
            ),
          ),
      ],
    );
  }
}
