// File: lib/screens/followup_analytics_screen.dart

import 'package:doctordesktop/Doctor/Tabs/PatientFollowUpScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FollowUpAnalyticsScreen extends StatefulWidget {
  final PatientInfo patientInfo;
  final List<TwoHourFollowUp> twoHrFollowUps;
  final List<FourHourFollowUp> fourHrFollowUps;

  const FollowUpAnalyticsScreen({
    Key? key,
    required this.patientInfo,
    required this.twoHrFollowUps,
    required this.fourHrFollowUps,
  }) : super(key: key);

  @override
  State<FollowUpAnalyticsScreen> createState() =>
      _FollowUpAnalyticsScreenState();
}

class _FollowUpAnalyticsScreenState extends State<FollowUpAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedVital = 'temperature';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
        LogicalKeySet(LogicalKeyboardKey.keyF, LogicalKeyboardKey.control):
            _toggleFullscreen,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: HospitalTheme.buildAppBar(
            context: context,
            title: 'Follow-up Analytics - ${widget.patientInfo.name}',
            actions: [
              IconButton(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                tooltip: 'Export Data',
              ),
              IconButton(
                onPressed: _toggleFullscreen,
                icon: const Icon(Icons.fullscreen),
                tooltip: 'Fullscreen (Ctrl+F)',
              ),
              const SizedBox(width: 16),
            ],
            bottom: TabBar(
              unselectedLabelColor: Colors.white,
              overlayColor:
                  MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
              controller: _tabController,
              tabs: const [
                // Tab(icon: Icon(Icons.analytics), text: 'Vitals Trends'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Intake/Output'),
                Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                Tab(icon: Icon(Icons.assessment), text: 'Summary'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildVitalsTrendsTab(),
              _buildIntakeOutputTab(),
              _buildTimelineTab(),
              _buildSummaryTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFullscreen() {
    // This would typically implement fullscreen functionality
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fullscreen toggle (implementation needed)'),
        backgroundColor: HospitalTheme.info,
      ),
    );
  }

  void _exportData() {
    // This would typically implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export functionality (implementation needed)'),
        backgroundColor: HospitalTheme.success,
      ),
    );
  }

  // ==================== VITALS TRENDS TAB ====================
// ==================== VITALS TRENDS TAB - CLEAN & PROFESSIONAL ====================

  Widget _buildVitalsTrendsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isWideScreen = screenWidth > 1200;

        return Container(
          height: screenHeight,
          child: Column(
            children: [
              // Fixed Vital Selection Controls - Clean horizontal layout
              Container(
                padding: const EdgeInsets.all(16),
                child: _buildVitalSelectionControls(),
              ),

              // Main content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isWideScreen
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chart takes most space
                            Expanded(
                              flex: 7,
                              child: Container(
                                height: screenHeight - 200,
                                child: _buildVitalsChart(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Stats sidebar
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: screenHeight - 200,
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _buildVitalsStatistics(),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      flex: 2,
                                      child: _buildVitalsOverview(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            // Chart takes 60% on smaller screens
                            Container(
                              height: (screenHeight - 200) * 0.6,
                              child: _buildVitalsChart(),
                            ),
                            const SizedBox(height: 16),
                            // Stats and overview split remaining space
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildVitalsStatistics()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildVitalsOverview()),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalSelectionControls() {
    final vitals = [
      {'key': 'temperature', 'label': 'Temperature', 'icon': Icons.thermostat},
      {'key': 'pulse', 'label': 'Pulse', 'icon': Icons.monitor_heart},
      {
        'key': 'bloodPressure',
        'label': 'Blood Pressure',
        'icon': Icons.favorite
      },
      {'key': 'oxygenSaturation', 'label': 'SpO2', 'icon': Icons.air},
      {'key': 'bloodSugar', 'label': 'Blood Sugar', 'icon': Icons.bloodtype},
    ];

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Vital Sign to Analyze',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Clean horizontal layout with proper spacing
          Row(
            children: vitals.asMap().entries.map((entry) {
              final index = entry.key;
              final vital = entry.value;
              final isSelected = _selectedVital == vital['key'];

              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: index < vitals.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedVital = vital['key'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? HospitalTheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? HospitalTheme.primary
                              : HospitalTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            vital['icon'] as IconData,
                            size: 20,
                            color: isSelected
                                ? HospitalTheme.primary
                                : HospitalTheme.textMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vital['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? HospitalTheme.primary
                                  : HospitalTheme.textDark,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsChart() {
    final data = _getVitalData(_selectedVital);

    return HospitalTheme.buildCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean header with vital info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getVitalColor(_selectedVital).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getVitalIcon(_selectedVital),
                    color: _getVitalColor(_selectedVital),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getVitalLabel(_selectedVital)} Trends',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data.isNotEmpty)
                        Text(
                          '${data.length} data points over time',
                          style: TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                if (data.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getVitalColor(_selectedVital).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getVitalColor(_selectedVital).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Latest: ${data.last.y.toStringAsFixed(1)}${_getVitalUnit(_selectedVital)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getVitalColor(_selectedVital),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: data.isEmpty
                  ? _buildEmptyState()
                  : Container(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine:
                                false, // Remove vertical grid lines
                            drawHorizontalLine: true,
                            horizontalInterval:
                                _getHorizontalInterval(_selectedVital),
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: HospitalTheme.border.withOpacity(0.5),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: data.length > 6
                                    ? (data.length / 6).ceil().toDouble()
                                    : 1,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < data.length) {
                                    final time = data[value.toInt()].x;
                                    final date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            time.toInt());
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('MMM dd\nHH:mm')
                                            .format(date),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: HospitalTheme.textMedium,
                                          height: 1.2,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval:
                                    _getHorizontalInterval(_selectedVital),
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '${value.toStringAsFixed(0)}${_getVitalUnit(_selectedVital)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: HospitalTheme.textMedium,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(
                                  color: HospitalTheme.border, width: 1),
                              bottom: BorderSide(
                                  color: HospitalTheme.border, width: 1),
                              right: BorderSide.none,
                              top: BorderSide.none,
                            ),
                          ),
                          minX: 0,
                          maxX: (data.length - 1).toDouble(),
                          minY: _getMinY(_selectedVital, data),
                          maxY: _getMaxY(_selectedVital, data),
                          lineBarsData: [
                            LineChartBarData(
                              spots: data.asMap().entries.map((entry) {
                                return FlSpot(
                                    entry.key.toDouble(), entry.value.y);
                              }).toList(),
                              isCurved: true,
                              curveSmoothness: 0.2,
                              color: _getVitalColor(_selectedVital),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                  radius: 4,
                                  color: _getVitalColor(_selectedVital),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _getVitalColor(_selectedVital)
                                        .withOpacity(0.3),
                                    _getVitalColor(_selectedVital)
                                        .withOpacity(0.05),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HospitalTheme.textLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getVitalIcon(_selectedVital),
              size: 48,
              color: HospitalTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_getVitalLabel(_selectedVital).toLowerCase()} data available',
            style: const TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data will appear here once follow-ups are recorded',
            style: TextStyle(
              color: HospitalTheme.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsStatistics() {
    final data = _getVitalData(_selectedVital);

    return HospitalTheme.buildCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getVitalLabel(_selectedVital)} Statistics',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No statistics available',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: _buildStatisticsContent(data),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(List<FlSpot> data) {
    final values = data.map((e) => e.y).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final latest = values.last;

    return Column(
      children: [
        _buildStatItem(
          'Current',
          '${latest.toStringAsFixed(1)}${_getVitalUnit(_selectedVital)}',
          _getVitalColor(_selectedVital),
          Icons.fiber_manual_record,
        ),
        const SizedBox(height: 12),
        _buildStatItem(
          'Average',
          '${avg.toStringAsFixed(1)}${_getVitalUnit(_selectedVital)}',
          HospitalTheme.info,
          Icons.analytics,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactStatItem(
                'Min',
                '${min.toStringAsFixed(1)}${_getVitalUnit(_selectedVital)}',
                HospitalTheme.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactStatItem(
                'Max',
                '${max.toStringAsFixed(1)}${_getVitalUnit(_selectedVital)}',
                HospitalTheme.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildVitalRangeIndicator(_selectedVital, latest),
      ],
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: HospitalTheme.textDark,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalRangeIndicator(String vital, double value) {
    final ranges = _getNormalRanges(vital);
    final isNormal = value >= ranges['min']! && value <= ranges['max']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNormal
            ? HospitalTheme.success.withOpacity(0.08)
            : HospitalTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNormal
              ? HospitalTheme.success.withOpacity(0.3)
              : HospitalTheme.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isNormal ? Icons.check_circle : Icons.warning,
                color: isNormal ? HospitalTheme.success : HospitalTheme.warning,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNormal ? 'Within Normal Range' : 'Outside Normal Range',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isNormal
                        ? HospitalTheme.success
                        : HospitalTheme.warning,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Normal Range: ${ranges['min']!.toStringAsFixed(0)} - ${ranges['max']!.toStringAsFixed(0)}${_getVitalUnit(vital)}',
            style: const TextStyle(
              fontSize: 11,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsOverview() {
    return HospitalTheme.buildCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Vitals Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _getAllVitalsStatus()
                    .map((status) => Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: (status['color'] as Color).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  (status['color'] as Color).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                status['icon'] as IconData,
                                size: 16,
                                color: status['color'] as Color,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  status['label'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: status['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ==================== HELPER METHODS FOR VITALS ====================

  IconData _getVitalIcon(String vital) {
    switch (vital) {
      case 'temperature':
        return Icons.thermostat;
      case 'pulse':
        return Icons.monitor_heart;
      case 'bloodPressure':
        return Icons.favorite;
      case 'oxygenSaturation':
        return Icons.air;
      case 'bloodSugar':
        return Icons.bloodtype;
      default:
        return Icons.analytics;
    }
  }

  String _getVitalUnit(String vital) {
    switch (vital) {
      case 'temperature':
        return '°F';
      case 'pulse':
        return ' bpm';
      case 'bloodPressure':
        return ' mmHg';
      case 'oxygenSaturation':
        return '%';
      case 'bloodSugar':
        return ' mg/dL';
      default:
        return '';
    }
  }

  // ==================== INTAKE/OUTPUT TAB ====================

  Widget _buildIntakeOutputTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 1000;

          return isWideScreen
              ? Row(
                  children: [
                    Expanded(child: _buildIntakeChart()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildOutputChart()),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildIntakeChart()),
                    const SizedBox(height: 16),
                    Expanded(child: _buildOutputChart()),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildIntakeChart() {
    final intakeData = _getIntakeData();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fluid Intake Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: intakeData.isEmpty
                ? const Center(child: Text('No intake data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxIntake(intakeData) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < intakeData.length) {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    DateFormat('HH:mm')
                                        .format(intakeData[value.toInt()].date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}ml',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: HospitalTheme.border),
                      ),
                      barGroups: intakeData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.amount,
                              color: HospitalTheme.info,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputChart() {
    final outputData = _getOutputData();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Urine Output Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: outputData.isEmpty
                ? const Center(child: Text('No output data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxOutput(outputData) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < outputData.length) {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    DateFormat('HH:mm')
                                        .format(outputData[value.toInt()].date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}ml',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: HospitalTheme.border),
                      ),
                      barGroups: outputData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.amount,
                              color: HospitalTheme.warning,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== TIMELINE TAB ====================

  Widget _buildTimelineTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 1200;

          return isWideScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _build2HourTimelineSection()),
                    const SizedBox(width: 16),
                    Expanded(child: _build4HourTimelineSection()),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _build2HourTimelineSection()),
                    const SizedBox(height: 16),
                    Expanded(child: _build4HourTimelineSection()),
                  ],
                );
        },
      ),
    );
  }

  Widget _build2HourTimelineSection() {
    final twoHrEvents = _get2HourTimelineEvents();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: HospitalTheme.medical.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: HospitalTheme.medical,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '2-Hour Follow-up Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HospitalTheme.medical,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${twoHrEvents.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: twoHrEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 48,
                            color: HospitalTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No 2-hour follow-ups available',
                            style: TextStyle(
                              color: HospitalTheme.textMedium,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: twoHrEvents.length,
                      itemBuilder: (context, index) {
                        final event = twoHrEvents[index];
                        final isLast = index == twoHrEvents.length - 1;
                        return _buildTimelineItem(event, isLast);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build4HourTimelineSection() {
    final fourHrEvents = _get4HourTimelineEvents();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: HospitalTheme.pharmacy.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: HospitalTheme.pharmacy,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '4-Hour Follow-up Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HospitalTheme.pharmacy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${fourHrEvents.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: fourHrEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 48,
                            color: HospitalTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No 4-hour follow-ups available',
                            style: TextStyle(
                              color: HospitalTheme.textMedium,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: fourHrEvents.length,
                      itemBuilder: (context, index) {
                        final event = fourHrEvents[index];
                        final isLast = index == fourHrEvents.length - 1;
                        return _buildTimelineItem(event, isLast);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: event.color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                event.icon,
                size: 12,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: event.color.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Event content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: event.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: event.color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('MMM dd, HH:mm').format(event.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: event.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                      height: 1.3,
                    ),
                  ),
                ],
                if (event.vitals.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: event.vitals.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: event.color.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SUMMARY TAB ====================

  Widget _buildSummaryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 1000;

          return isWideScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(child: _buildSummaryCards()),
                          const SizedBox(height: 16),
                          Expanded(child: _buildTrendsAnalysis()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildRecommendations(),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      _buildTrendsAnalysis(),
                      const SizedBox(height: 16),
                      _buildRecommendations(),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard(
                  'Total Follow-ups',
                  '${widget.twoHrFollowUps.length + widget.fourHrFollowUps.length}',
                  Icons.assignment,
                  HospitalTheme.primary,
                ),
                _buildSummaryCard(
                  '2Hr Records',
                  '${widget.twoHrFollowUps.length}',
                  Icons.access_time,
                  HospitalTheme.medical,
                ),
                _buildSummaryCard(
                  '4Hr Records',
                  '${widget.fourHrFollowUps.length}',
                  Icons.schedule,
                  HospitalTheme.pharmacy,
                ),
                _buildSummaryCard(
                  'Monitoring Days',
                  _getMonitoringDays().toString(),
                  Icons.calendar_today,
                  HospitalTheme.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsAnalysis() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trends Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                _buildTrendItem('Temperature', _analyzeTrend('temperature')),
                _buildTrendItem('Pulse', _analyzeTrend('pulse')),
                _buildTrendItem(
                    'Blood Pressure', _analyzeTrend('bloodPressure')),
                _buildTrendItem('SpO2', _analyzeTrend('oxygenSaturation')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String vital, Map<String, dynamic> analysis) {
    final trendIcon = analysis['trend'] == 'increasing'
        ? Icons.trending_up
        : analysis['trend'] == 'decreasing'
            ? Icons.trending_down
            : Icons.trending_flat;

    final trendColor = analysis['trend'] == 'increasing'
        ? HospitalTheme.warning
        : analysis['trend'] == 'decreasing'
            ? HospitalTheme.info
            : HospitalTheme.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              vital,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(trendIcon, color: trendColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  analysis['change'],
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: analysis['status'] == 'Normal'
                    ? HospitalTheme.success.withOpacity(0.1)
                    : HospitalTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                analysis['status'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: analysis['status'] == 'Normal'
                      ? HospitalTheme.success
                      : HospitalTheme.warning,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinical Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: recommendation['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: recommendation['color'].withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        recommendation['icon'],
                        color: recommendation['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recommendation['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: HospitalTheme.textMedium,
                              ),
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
    );
  }

  // ==================== HELPER METHODS ====================

  List<FlSpot> _getVitalData(String vital) {
    final List<FlSpot> data = [];

    // Combine data from both 2hr and 4hr follow-ups
    final allData = <Map<String, dynamic>>[];

    for (final followUp in widget.twoHrFollowUps) {
      allData.add({
        'date': followUp.date,
        'temperature': _parseDouble(followUp.temperature),
        'pulse': _parseDouble(followUp.pulse),
        'bloodPressure': _parseBloodPressure(followUp.bloodPressure),
        'oxygenSaturation': _parseDouble(followUp.oxygenSaturation),
        'bloodSugar': _parseDouble(followUp.bloodSugarLevel),
      });
    }

    for (final followUp in widget.fourHrFollowUps) {
      allData.add({
        'date': followUp.date,
        'temperature': _parseDouble(followUp.temperature),
        'pulse': _parseDouble(followUp.pulse),
        'bloodPressure': _parseBloodPressure(followUp.bloodPressure),
        'oxygenSaturation': _parseDouble(followUp.oxygenSaturation),
        'bloodSugar': _parseDouble(followUp.bloodSugarLevel),
      });
    }

    // Sort by date
    allData.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    for (int i = 0; i < allData.length; i++) {
      final value = allData[i][vital];
      if (value != null && value > 0) {
        data.add(FlSpot(
          (allData[i]['date'] as DateTime).millisecondsSinceEpoch.toDouble(),
          value.toDouble(),
        ));
      }
    }

    return data;
  }

  double? _parseDouble(String value) {
    if (value == 'N/A' || value == '--' || value.isEmpty) return null;
    return double.tryParse(value);
  }

  double? _parseBloodPressure(String value) {
    if (value == 'N/A' || value == '--' || value.isEmpty) return null;
    // Take systolic pressure (first number)
    final parts = value.split('/');
    if (parts.isNotEmpty) {
      return double.tryParse(parts[0]);
    }
    return null;
  }

  String _getVitalLabel(String vital) {
    switch (vital) {
      case 'temperature':
        return 'Temperature';
      case 'pulse':
        return 'Pulse';
      case 'bloodPressure':
        return 'Blood Pressure (Systolic)';
      case 'oxygenSaturation':
        return 'Oxygen Saturation';
      case 'bloodSugar':
        return 'Blood Sugar';
      default:
        return vital;
    }
  }

  Color _getVitalColor(String vital) {
    switch (vital) {
      case 'temperature':
        return HospitalTheme.warning;
      case 'pulse':
        return HospitalTheme.error;
      case 'bloodPressure':
        return HospitalTheme.primary;
      case 'oxygenSaturation':
        return HospitalTheme.info;
      case 'bloodSugar':
        return HospitalTheme.secondary;
      default:
        return HospitalTheme.primary;
    }
  }

  double _getHorizontalInterval(String vital) {
    switch (vital) {
      case 'temperature':
        return 10;
      case 'pulse':
        return 20;
      case 'bloodPressure':
        return 20;
      case 'oxygenSaturation':
        return 5;
      case 'bloodSugar':
        return 50;
      default:
        return 10;
    }
  }

  double _getMinY(String vital, List<FlSpot> data) {
    if (data.isEmpty) return 0;
    final values = data.map((e) => e.y).toList();
    final min = values.reduce((a, b) => a < b ? a : b);

    switch (vital) {
      case 'temperature':
        return (min - 5).clamp(90, double.infinity);
      case 'pulse':
        return (min - 10).clamp(40, double.infinity);
      case 'bloodPressure':
        return (min - 20).clamp(80, double.infinity);
      case 'oxygenSaturation':
        return (min - 5).clamp(85, double.infinity);
      case 'bloodSugar':
        return (min - 20).clamp(60, double.infinity);
      default:
        return min - (min * 0.1);
    }
  }

  double _getMaxY(String vital, List<FlSpot> data) {
    if (data.isEmpty) return 100;
    final values = data.map((e) => e.y).toList();
    final max = values.reduce((a, b) => a > b ? a : b);

    switch (vital) {
      case 'temperature':
        return max + 5;
      case 'pulse':
        return max + 20;
      case 'bloodPressure':
        return max + 20;
      case 'oxygenSaturation':
        return (max + 2).clamp(0, 100);
      case 'bloodSugar':
        return max + 50;
      default:
        return max + (max * 0.1);
    }
  }

  Map<String, double> _getNormalRanges(String vital) {
    switch (vital) {
      case 'temperature':
        return {'min': 97.0, 'max': 99.0};
      case 'pulse':
        return {'min': 60.0, 'max': 100.0};
      case 'bloodPressure':
        return {'min': 90.0, 'max': 140.0};
      case 'oxygenSaturation':
        return {'min': 95.0, 'max': 100.0};
      case 'bloodSugar':
        return {'min': 70.0, 'max': 140.0};
      default:
        return {'min': 0.0, 'max': 100.0};
    }
  }

  List<Map<String, dynamic>> _getAllVitalsStatus() {
    // This would analyze all vitals and return their status
    return [
      {
        'label': 'Temperature: Normal',
        'icon': Icons.thermostat,
        'color': HospitalTheme.success,
      },
      {
        'label': 'Pulse: Elevated',
        'icon': Icons.monitor_heart,
        'color': HospitalTheme.warning,
      },
      {
        'label': 'BP: Normal',
        'icon': Icons.favorite,
        'color': HospitalTheme.success,
      },
      {
        'label': 'SpO2: Normal',
        'icon': Icons.air,
        'color': HospitalTheme.success,
      },
    ];
  }

  List<IntakeData> _getIntakeData() {
    final List<IntakeData> data = [];

    for (final followUp in widget.twoHrFollowUps) {
      final amount = _parseDouble(followUp.totalIntake.replaceAll('ml', ''));
      if (amount != null) {
        data.add(IntakeData(followUp.date, amount));
      }
    }

    return data..sort((a, b) => a.date.compareTo(b.date));
  }

  List<OutputData> _getOutputData() {
    final List<OutputData> data = [];

    for (final followUp in widget.twoHrFollowUps) {
      final amount = _parseDouble(followUp.urine.replaceAll('ml', ''));
      if (amount != null) {
        data.add(OutputData(followUp.date, amount));
      }
    }

    for (final followUp in widget.fourHrFollowUps) {
      final amount = _parseDouble(followUp.urine.replaceAll('ml', ''));
      if (amount != null) {
        data.add(OutputData(followUp.date, amount));
      }
    }

    return data..sort((a, b) => a.date.compareTo(b.date));
  }

  double _getMaxIntake(List<IntakeData> data) {
    if (data.isEmpty) return 1000;
    return data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  double _getMaxOutput(List<OutputData> data) {
    if (data.isEmpty) return 500;
    return data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  List<TimelineEvent> _get2HourTimelineEvents() {
    final List<TimelineEvent> events = [];

    // Add 2hr follow-up events only
    for (final followUp in widget.twoHrFollowUps) {
      events.add(TimelineEvent(
        date: followUp.date,
        title: 'Nursing Assessment',
        description:
            followUp.observations.isNotEmpty && followUp.observations != 'N/A'
                ? followUp.observations
                : 'Regular 2-hour monitoring completed',
        icon: Icons.medical_services,
        color: HospitalTheme.medical,
        vitals: {
          if (followUp.temperature != 'N/A' && followUp.temperature.isNotEmpty)
            'Temp': '${followUp.temperature}°F',
          if (followUp.pulse != 'N/A' && followUp.pulse.isNotEmpty)
            'HR': '${followUp.pulse}bpm',
          if (followUp.bloodPressure != 'N/A' &&
              followUp.bloodPressure.isNotEmpty)
            'BP': followUp.bloodPressure,
          if (followUp.oxygenSaturation != 'N/A' &&
              followUp.oxygenSaturation.isNotEmpty)
            'SpO2': '${followUp.oxygenSaturation}%',
        },
      ));
    }

    return events..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TimelineEvent> _get4HourTimelineEvents() {
    final List<TimelineEvent> events = [];

    // Add 4hr follow-up events only
    for (final followUp in widget.fourHrFollowUps) {
      events.add(TimelineEvent(
        date: followUp.date,
        title: 'Extended Assessment',
        description:
            followUp.observations.isNotEmpty && followUp.observations != 'N/A'
                ? followUp.observations
                : 'Comprehensive 4-hour evaluation completed',
        icon: Icons.assignment_outlined,
        color: HospitalTheme.pharmacy,
        vitals: {
          if (followUp.temperature != 'N/A' && followUp.temperature.isNotEmpty)
            'Temp': '${followUp.temperature}°F',
          if (followUp.pulse != 'N/A' && followUp.pulse.isNotEmpty)
            'HR': '${followUp.pulse}bpm',
          if (followUp.bloodPressure != 'N/A' &&
              followUp.bloodPressure.isNotEmpty)
            'BP': followUp.bloodPressure,
          if (followUp.oxygenSaturation != 'N/A' &&
              followUp.oxygenSaturation.isNotEmpty)
            'SpO2': '${followUp.oxygenSaturation}%',
        },
      ));
    }

    return events..sort((a, b) => b.date.compareTo(a.date));
  }

  int _getMonitoringDays() {
    final allDates = <DateTime>[];

    for (final followUp in widget.twoHrFollowUps) {
      allDates.add(DateTime(
        followUp.date.year,
        followUp.date.month,
        followUp.date.day,
      ));
    }

    for (final followUp in widget.fourHrFollowUps) {
      allDates.add(DateTime(
        followUp.date.year,
        followUp.date.month,
        followUp.date.day,
      ));
    }

    final uniqueDates = allDates.toSet();
    return uniqueDates.length;
  }

  Map<String, dynamic> _analyzeTrend(String vital) {
    final data = _getVitalData(vital);

    if (data.length < 2) {
      return {
        'trend': 'stable',
        'change': 'N/A',
        'status': 'Normal',
      };
    }

    final first = data.first.y;
    final last = data.last.y;
    final change = last - first;
    final percentChange = (change / first * 100).abs();

    String trend = 'stable';
    if (change > 0 && percentChange > 5) {
      trend = 'increasing';
    } else if (change < 0 && percentChange > 5) {
      trend = 'decreasing';
    }

    final ranges = _getNormalRanges(vital);
    final isNormal = last >= ranges['min']! && last <= ranges['max']!;

    return {
      'trend': trend,
      'change': '${percentChange.toStringAsFixed(1)}%',
      'status': isNormal ? 'Normal' : 'Alert',
    };
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    // Analyze vitals and generate recommendations
    final tempData = _getVitalData('temperature');
    if (tempData.isNotEmpty) {
      final latestTemp = tempData.last.y;
      if (latestTemp > 99.5) {
        recommendations.add({
          'title': 'Monitor Temperature',
          'description':
              'Patient shows elevated temperature. Consider fever management protocols.',
          'icon': Icons.thermostat,
          'color': HospitalTheme.warning,
        });
      }
    }

    final pulseData = _getVitalData('pulse');
    if (pulseData.isNotEmpty) {
      final latestPulse = pulseData.last.y;
      if (latestPulse > 100) {
        recommendations.add({
          'title': 'Pulse Monitoring',
          'description':
              'Elevated heart rate detected. Monitor for signs of distress.',
          'icon': Icons.monitor_heart,
          'color': HospitalTheme.error,
        });
      }
    }

    // Default recommendations if no alerts
    if (recommendations.isEmpty) {
      recommendations.addAll([
        {
          'title': 'Continue Monitoring',
          'description':
              'All vitals are within normal ranges. Continue regular follow-ups.',
          'icon': Icons.check_circle,
          'color': HospitalTheme.success,
        },
        {
          'title': 'Hydration Status',
          'description': 'Monitor fluid intake and output balance.',
          'icon': Icons.water_drop,
          'color': HospitalTheme.info,
        },
      ]);
    }

    return recommendations;
  }
}

// ==================== DATA MODELS FOR CHARTS ====================

class IntakeData {
  final DateTime date;
  final double amount;

  IntakeData(this.date, this.amount);
}

class OutputData {
  final DateTime date;
  final double amount;

  OutputData(this.date, this.amount);
}

class TimelineEvent {
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Map<String, String> vitals;

  TimelineEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.vitals,
  });
}

// ==================== HELPER FUNCTIONS ====================

String _safeString(dynamic value) {
  if (value == null) return 'N/A';
  if (value is String) return value.isEmpty ? 'N/A' : value;
  return value.toString();
}

int? _safeInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _safeDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
