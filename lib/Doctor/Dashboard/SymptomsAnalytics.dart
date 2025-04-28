import 'dart:async';
import 'dart:convert';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SymptomAnalyticsDashboard extends StatefulWidget {
  const SymptomAnalyticsDashboard({Key? key}) : super(key: key);

  @override
  _SymptomAnalyticsDashboardState createState() =>
      _SymptomAnalyticsDashboardState();
}

class _SymptomAnalyticsDashboardState extends State<SymptomAnalyticsDashboard> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _seasonalData = {};
  Map<String, dynamic> _coOccurringData = {};
  Map<String, dynamic> _demographicsData = {};
  Map<String, dynamic> _locationData = {};
  Map<String, dynamic> _outbreakData = {};

  @override
  void initState() {
    super.initState();
    _fetchAllData();

    // Set up periodic refresh every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchSymptomAnalytics(),
        _fetchSeasonalSymptoms(),
        _fetchCoOccurringSymptoms(),
        _fetchSymptomDemographics(),
        _fetchSymptomsByLocation(),
        _fetchOutbreakDetection(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSymptomAnalytics() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/doctors/getSymptomAnalytics'));
    if (response.statusCode == 200) {
      setState(() {
        _analyticsData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load symptom analytics data');
    }
  }

  Future<void> _fetchSeasonalSymptoms() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/doctors/getSeasonalSymptoms'));
    if (response.statusCode == 200) {
      setState(() {
        _seasonalData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load seasonal symptoms data');
    }
  }

  Future<void> _fetchCoOccurringSymptoms() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/doctors/getCoOccurringSymptoms'));
    if (response.statusCode == 200) {
      setState(() {
        _coOccurringData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load co-occurring symptoms data');
    }
  }

  Future<void> _fetchSymptomDemographics() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/doctors/getSymptomDemographics'));
    if (response.statusCode == 200) {
      setState(() {
        _demographicsData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load symptom demographics data');
    }
  }

  Future<void> _fetchSymptomsByLocation() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/doctors/getSymptomsByLocation'));
    if (response.statusCode == 200) {
      setState(() {
        _locationData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load symptoms by location data');
    }
  }

  Future<void> _fetchOutbreakDetection() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/doctors/getOutbreakDetection'));
    if (response.statusCode == 200) {
      setState(() {
        _outbreakData = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load outbreak detection data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Symptom Analytics',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _fetchAllData,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Exit Dashboard',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: false,
        showBackButton: true,
        onBackPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildDashboard(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Symptom Analytics...',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: HospitalTheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchAllData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      decoration: BoxDecoration(
        color: HospitalTheme.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(),
                  const SizedBox(height: 24),
                  _buildSymptomsDataSection(),
                  const SizedBox(height: 24),
                  _buildDemographicSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildOutbreakSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [HospitalTheme.primaryDark, HospitalTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primaryDark.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Symptom Analytics Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Comprehensive analysis of patient symptoms and trends ',
                        ),
                        TextSpan(
                          text: '• Powered by DocNex AI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildLastUpdatedInfo(),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _fetchAllData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: HospitalTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  elevation: 3,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// You'll also need to update the last updated info to match the new color scheme
  Widget _buildLastUpdatedInfo() {
    String lastUpdateText = 'Last updated: ';

    if (_outbreakData.isNotEmpty && _outbreakData['success'] == true) {
      final lastUpdated = DateTime.parse(_outbreakData['data']['lastUpdated']);
      final formattedDate =
          DateFormat('MMM d, yyyy • h:mm a').format(lastUpdated);
      lastUpdateText += formattedDate;
    } else {
      lastUpdateText +=
          DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            lastUpdateText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildLastUpdatedInfo() {
  //   String lastUpdateText = 'Last updated: ';

  //   if (_outbreakData.isNotEmpty && _outbreakData['success'] == true) {
  //     final lastUpdated = DateTime.parse(_outbreakData['data']['lastUpdated']);
  //     final formattedDate =
  //         DateFormat('MMM d, yyyy • h:mm a').format(lastUpdated);
  //     lastUpdateText += formattedDate;
  //   } else {
  //     lastUpdateText +=
  //         DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now());
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: HospitalTheme.surfaceLight,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           Icons.update,
  //           size: 16,
  //           color: HospitalTheme.primary,
  //         ),
  //         const SizedBox(width: 8),
  //         Text(
  //           lastUpdateText,
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: HospitalTheme.textMedium,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildOverviewSection() {
    // Extract data from analytics response
    final data =
        _analyticsData['success'] == true ? _analyticsData['data'] : null;

    final totalPatients = data != null ? data['totalPatients'] : 0;
    final totalSymptomRecords = data != null ? data['totalSymptomRecords'] : 0;
    final mostUsedSymptoms = data != null ? data['mostUsedSymptoms'] : [];

    // Alert count from outbreak data
    final alertCount = _outbreakData['success'] == true
        ? _outbreakData['data']['alertCount']
        : 0;

    // Calculate data for season with most symptoms
    String topSeason = 'N/A';
    int topSeasonCount = 0;

    if (_seasonalData['success'] == true && _seasonalData['data'] != null) {
      for (var month in _seasonalData['data']) {
        if (month['totalSymptomCount'] > topSeasonCount) {
          topSeasonCount = month['totalSymptomCount'];
          topSeason = month['monthName'];
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Total Patients',
                value: totalPatients.toString(),
                icon: Icons.people,
                iconColor: HospitalTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Symptom Records',
                value: totalSymptomRecords.toString(),
                icon: Icons.medical_information,
                iconColor: HospitalTheme.medical,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Peak Season',
                value: topSeason,
                subtitle: '$topSeasonCount symptoms recorded',
                icon: Icons.calendar_today,
                iconColor: HospitalTheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Outbreak Alerts',
                value: alertCount.toString(),
                icon: Icons.warning_amber,
                iconColor: alertCount > 0
                    ? HospitalTheme.error
                    : HospitalTheme.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        mostUsedSymptoms.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: HospitalTheme.shadowSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Top Reported Symptoms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: HospitalTheme.medical.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Top ${mostUsedSymptoms.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.medical,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Bar chart for top symptoms
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 240,
                            padding: const EdgeInsets.only(right: 24),
                            child: _buildTopSymptomsChart(mostUsedSymptoms),
                          ),
                        ),
                        // List of top symptoms with count
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(
                                mostUsedSymptoms.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildSymptomListItem(
                                    mostUsedSymptoms[index]['name'],
                                    mostUsedSymptoms[index]['count'],
                                    index,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : _buildNoDataDisplay('No symptom data available'),
      ],
    );
  }

  Widget _buildTopSymptomsChart(List<dynamic> symptoms) {
    if (symptoms.isEmpty) {
      return Center(
        child: Text(
          'No symptom data available',
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 14,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: symptoms
                .map<int>((e) => e['count'] as int)
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // ignore: deprecated_member_use
            // tooltipBackgroundColor: HospitalTheme.textDark.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${symptoms[groupIndex]['name']}: ${symptoms[groupIndex]['count']}',
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < symptoms.length) {
                  String name = symptoms[value.toInt()]['name'];
                  if (name.length > 7) {
                    name = name.substring(0, 7) + '...';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: HospitalTheme.border,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          drawVerticalLine: false,
        ),
        barGroups: List.generate(
          symptoms.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: symptoms[index]['count'].toDouble(),
                color: _getChartColor(index),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      HospitalTheme.primary,
      HospitalTheme.medical,
      HospitalTheme.success,
      HospitalTheme.secondary,
      HospitalTheme.emergency,
      HospitalTheme.laboratory,
      HospitalTheme.pharmacy,
    ];
    return colors[index % colors.length];
  }

  Widget _buildSymptomListItem(String name, int count, int index) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: _getChartColor(index),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: HospitalTheme.textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomsDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Symptom Trends & Patterns',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seasonal chart
            Expanded(
              child: HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader(
                      'Seasonal Distribution',
                      trailing: Icon(
                        Icons.calendar_month,
                        color: HospitalTheme.primary,
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: _buildSeasonalChart(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Co-occurring symptoms
            Expanded(
              child: HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader(
                      'Co-occurring Symptoms',
                      trailing: Icon(
                        Icons.bubble_chart,
                        color: HospitalTheme.laboratory,
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: _buildCoOccurringChart(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonalChart() {
    if (_seasonalData.isEmpty || _seasonalData['success'] != true) {
      return _buildNoDataDisplay('No seasonal data available');
    }

    final months = _seasonalData['data'] as List;
    if (months.isEmpty) {
      return _buildNoDataDisplay('No seasonal data available');
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: HospitalTheme.border,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final monthIndex = value.toInt();
                if (monthIndex >= 0 && monthIndex < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[monthIndex]['monthName'].substring(0, 3),
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: months.length - 1.0,
        minY: 0,
        maxY: months
                    .map<int>((m) => m['totalSymptomCount'] as int)
                    .reduce((a, b) => a > b ? a : b) *
                1.2 +
            1,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              months.length,
              (index) => FlSpot(
                index.toDouble(),
                months[index]['totalSymptomCount'].toDouble(),
              ),
            ),
            isCurved: true,
            color: HospitalTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Highlight the month with the most symptoms
                final isHighestPoint = spot.y ==
                    months
                        .map<double>((m) => m['totalSymptomCount'].toDouble())
                        .reduce((a, b) => a > b ? a : b);
                return FlDotCirclePainter(
                  radius: isHighestPoint ? 6 : 4,
                  color: isHighestPoint ? HospitalTheme.accent : barData.color!,
                  strokeWidth: isHighestPoint ? 2 : 0,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: HospitalTheme.primary.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // tooltipBgColor: HospitalTheme.textDark.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final monthIndex = spot.x.toInt();
                final monthName = months[monthIndex]['monthName'];
                final count = spot.y.toInt();
                final symptomList = months[monthIndex]['symptoms'] as List;

                String tooltipText = '$monthName: $count symptoms';
                if (symptomList.isNotEmpty) {
                  tooltipText += '\n\nTop symptoms:';
                  for (int i = 0; i < Math.min(3, symptomList.length); i++) {
                    tooltipText +=
                        '\n• ${symptomList[i]['name']}: ${symptomList[i]['count']}';
                  }
                }

                return LineTooltipItem(
                  tooltipText,
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCoOccurringChart() {
    if (_coOccurringData.isEmpty || _coOccurringData['success'] != true) {
      return _buildNoDataDisplay('No co-occurring symptoms data available');
    }

    final coOccurrences = _coOccurringData['data']['coOccurrences'] as List;
    if (coOccurrences.isEmpty) {
      return _buildNoDataDisplay('No co-occurring symptoms data available');
    }

    // Filter out self-pairs for visualization
    final filteredOccurrences = coOccurrences.where((item) {
      final pair = item['pair'] as List;
      return pair[0] != pair[1]; // Filter out pairs like [cough, cough]
    }).toList();

    if (filteredOccurrences.isEmpty) {
      return _buildNoDataDisplay(
          'No significant co-occurring symptoms detected');
    }

    return ListView.builder(
      itemCount: filteredOccurrences.length,
      itemBuilder: (context, index) {
        final item = filteredOccurrences[index];
        final pair = item['pair'] as List;
        final count = item['count'] as int;

        // Calculate percentage based on total
        final totalPairs = _coOccurringData['data']['totalPairs'] as int;
        final percentage = totalPairs > 0 ? (count / totalPairs) * 100 : 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pair[0]} & ${pair[1]}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ),
                  HospitalTheme.buildStatusBadge(
                    '${count.toInt()} occurrences',
                    color: HospitalTheme.laboratory,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: HospitalTheme.border,
                valueColor:
                    AlwaysStoppedAnimation<Color>(HospitalTheme.laboratory),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 2),
              Text(
                '${percentage.toStringAsFixed(1)}% of all co-occurrences',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemographicSection() {
    if (_demographicsData.isEmpty || _demographicsData['success'] != true) {
      return _buildNoDataDisplay('No demographic data available',
          asSection: true);
    }

    final byGender = _demographicsData['data']['byGender'] as List;
    final byAgeRange = _demographicsData['data']['byAgeRange'] as List;

    if (byGender.isEmpty && byAgeRange.isEmpty) {
      return _buildNoDataDisplay('No demographic data available',
          asSection: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Demographic Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gender distribution
            Expanded(
              child: HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader(
                      'Symptoms by Gender',
                      trailing: Icon(
                        Icons.wc,
                        color: HospitalTheme.primary,
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: _buildGenderDistributionChart(byGender),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Age distribution
            Expanded(
              child: HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader(
                      'Symptoms by Age Group',
                      trailing: Icon(
                        Icons.people_outline,
                        color: HospitalTheme.medical,
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: _buildAgeDistributionChart(byAgeRange),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderDistributionChart(List<dynamic> genderData) {
    // Check if there's any data with symptoms
    bool hasData = genderData.any((item) => (item['totalCount'] as int) > 0);

    if (!hasData) {
      return _buildNoDataDisplay('No gender distribution data available');
    }

    // Create pie chart data
    final sections = <PieChartSectionData>[];
    final legends = <Widget>[];

    final colors = [
      HospitalTheme.primary,
      HospitalTheme.emergency,
      HospitalTheme.pharmacy,
    ];

    for (int i = 0; i < genderData.length; i++) {
      final item = genderData[i];
      final category = item['category'] as String;
      final count = item['totalCount'] as int;
      final color = colors[i % colors.length];

      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: color,
            value: count.toDouble(),
            title: '$category\n$count',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

        legends.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legends,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeDistributionChart(List<dynamic> ageData) {
    // Check if there's any data with symptoms
    bool hasData = ageData.any((item) => (item['totalCount'] as int) > 0);

    if (!hasData) {
      return _buildNoDataDisplay('No age distribution data available');
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ageData
                .map<int>((e) => e['totalCount'] as int)
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: HospitalTheme.textDark.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = ageData[groupIndex];
              final category = item['category'] as String;
              final count = item['totalCount'] as int;
              final symptoms = item['symptoms'] as List;

              String tooltipText = '$category: $count symptoms';
              if (symptoms.isNotEmpty) {
                tooltipText += '\n\nTop symptoms:';
                for (int i = 0; i < Math.min(3, symptoms.length); i++) {
                  tooltipText +=
                      '\n• ${symptoms[i]['name']}: ${symptoms[i]['count']}';
                }
              }

              return BarTooltipItem(
                tooltipText,
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < ageData.length) {
                  String category =
                      ageData[value.toInt()]['category'] as String;
                  if (category.length > 10) {
                    category = category.substring(0, 10) + '...';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: HospitalTheme.border,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          drawVerticalLine: false,
        ),
        barGroups: List.generate(
          ageData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: ageData[index]['totalCount'].toDouble(),
                color: HospitalTheme.medical,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    if (_locationData.isEmpty || _locationData['success'] != true) {
      return _buildNoDataDisplay('No location data available', asSection: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geographical Distribution',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HospitalTheme.buildSectionHeader(
                'Symptoms by Location',
                trailing: Icon(
                  Icons.location_on_outlined,
                  color: HospitalTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: HospitalTheme.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location data collection is pending',
                      style: TextStyle(
                        fontSize: 16,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Geographic symptom distribution will be available once location data is collected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: HospitalTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutbreakSection() {
    if (_outbreakData.isEmpty || _outbreakData['success'] != true) {
      return _buildNoDataDisplay('No outbreak data available', asSection: true);
    }

    final outbreakAlerts = _outbreakData['data']['outbreakAlerts'] as List;
    final alertCount = _outbreakData['data']['alertCount'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outbreak Monitoring',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HospitalTheme.buildSectionHeader(
                'Potential Outbreaks',
                trailing: alertCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: HospitalTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: HospitalTheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$alertCount Alerts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.error,
                              ),
                            ),
                          ],
                        ),
                      )
                    : HospitalTheme.buildStatusBadge(
                        'No Alerts',
                        color: HospitalTheme.success,
                      ),
              ),
              const SizedBox(height: 16),
              outbreakAlerts.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: outbreakAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = outbreakAlerts[index];
                        return ListTile(
                          leading: Icon(
                            Icons.warning_amber,
                            color: HospitalTheme.error,
                          ),
                          title: Text(alert['symptom']),
                          subtitle: Text(alert['details']),
                          trailing: HospitalTheme.buildStatusBadge(
                            alert['severity'],
                            color: alert['severity'] == 'High'
                                ? HospitalTheme.error
                                : alert['severity'] == 'Medium'
                                    ? HospitalTheme.warning
                                    : HospitalTheme.info,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: HospitalTheme.success,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No outbreak alerts detected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The system is continuously monitoring symptom patterns for potential outbreaks',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataDisplay(String message, {bool asSection = false}) {
    return asSection
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.split(' ')[0],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              HospitalTheme.buildCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 64,
                          color: HospitalTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 16,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: HospitalTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

// Helper class for basic math operations
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
