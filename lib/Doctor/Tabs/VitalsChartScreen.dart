import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';

class VitalsChartScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;
  final List<Vitals> vitals;

  const VitalsChartScreen({
    required this.patientId,
    required this.admissionId,
    required this.vitals,
    Key? key,
  }) : super(key: key);

  @override
  _VitalsChartScreenState createState() => _VitalsChartScreenState();
}

class _VitalsChartScreenState extends ConsumerState<VitalsChartScreen> {
  // Key colors from HospitalTheme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF8FBFD);
  final Color cardBackground = Colors.white;
  final Color textDark = const Color(0xFF2D3748);
  final Color textMedium = const Color(0xFF5A6B7F);
  final Color success = const Color(0xFF43A047);
  final Color error = const Color(0xFFE53935);
  final Color warning = const Color(0xFFFFA000);

  // Chart control properties
  String selectedVitalType = 'temperature';
  String selectedTimeRange = '7days';
  bool showNormalRange = true;
  bool showTrendline = true;

  // Define normal ranges for vitals
  final Map<String, Map<String, double>> normalRanges = {
    'temperature': {'min': 36.0, 'max': 37.8},
    'pulse': {'min': 60.0, 'max': 100.0},
    'bloodSugar': {'min': 70.0, 'max': 180.0},
    'systolic': {'min': 90.0, 'max': 140.0},
    'diastolic': {'min': 60.0, 'max': 90.0},
  };

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final processedData = _processVitalsData();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/bb1.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
            colorFilter: ColorFilter.mode(
              primaryColor.withOpacity(0.05),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // Controls Section
              _buildControlsSection(),
              const SizedBox(height: 24),

              // Chart Section
              Expanded(
                child: _buildChartSection(processedData),
              ),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Title with Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(FontAwesomeIcons.chartLine,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vitals Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                Text(
                  'Analyze patient vital trends over time',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Export and Print Buttons
          Row(
            children: [
              _buildActionButton(
                icon: Icons.print,
                label: 'Print Report',
                color: textMedium,
                onPressed: () {
                  // Implement print functionality
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.save_alt,
                label: 'Export Data',
                color: accentColor,
                onPressed: () {
                  // Implement export functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chart Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Vital Type Selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vital Sign',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedVitalType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: const Color(0xFFDFEAF4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: const Color(0xFFDFEAF4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'temperature', child: Text('Temperature')),
                        DropdownMenuItem(
                            value: 'pulse', child: Text('Pulse Rate')),
                        DropdownMenuItem(
                            value: 'bloodPressure',
                            child: Text('Blood Pressure')),
                        DropdownMenuItem(
                            value: 'bloodSugar', child: Text('Blood Sugar')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedVitalType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Time Range Selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Range',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTimeRange,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: const Color(0xFFDFEAF4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: const Color(0xFFDFEAF4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: '7days', child: Text('Last 7 Days')),
                        DropdownMenuItem(
                            value: '14days', child: Text('Last 14 Days')),
                        DropdownMenuItem(
                            value: '30days', child: Text('Last 30 Days')),
                        DropdownMenuItem(
                            value: 'all', child: Text('All Records')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedTimeRange = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Toggle Options
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chart Options',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: showNormalRange,
                            onChanged: (value) {
                              setState(() {
                                showNormalRange = value!;
                              });
                            },
                            title: Text(
                              'Show Normal Range',
                              style: TextStyle(
                                fontSize: 12,
                                color: textDark,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            value: showTrendline,
                            onChanged: (value) {
                              setState(() {
                                showTrendline = value!;
                              });
                            },
                            title: Text(
                              'Show Trendline',
                              style: TextStyle(
                                fontSize: 12,
                                color: textDark,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleValueChart(List<dynamic> chartData, double minValue,
      double maxValue, String vitalUnit, Map<int, String> dateLabels) {
    // Calculate padding for y-axis
    final double yPadding = (maxValue - minValue) * 0.2;
    final double adjustedMinValue =
        minValue - yPadding < 0 ? 0 : minValue - yPadding;
    final double adjustedMaxValue = maxValue + yPadding;

    // Get normal range for the selected vital type
    final Map<String, double>? range = normalRanges[selectedVitalType];
    final double normalMin = range?['min'] ?? adjustedMinValue;
    final double normalMax = range?['max'] ?? adjustedMaxValue;

    // Pre-process the spots to avoid conversion issues
    final List<FlSpot> dataSpots = [];

    for (int i = 0; i < chartData.length; i++) {
      try {
        final value = chartData[i];
        double doubleValue;
        if (value is int) {
          doubleValue = value.toDouble();
        } else if (value is String) {
          doubleValue = double.tryParse(value) ?? 0.0;
        } else {
          doubleValue = value is double ? value : 0.0;
        }
        dataSpots.add(FlSpot(i.toDouble(), doubleValue));
      } catch (e) {
        print('Error converting value to double: $e');
        dataSpots.add(FlSpot(i.toDouble(), 0.0));
      }
    }

    return LineChart(
      LineChartData(
        minY: adjustedMinValue,
        maxY: adjustedMaxValue,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20 > 0 ? 20 : 1.0,
          getDrawingHorizontalLine: (value) {
            // Highlight normal range lines
            if (showNormalRange && (value == normalMin || value == normalMax)) {
              return FlLine(
                color: success.withOpacity(0.7),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            }
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: chartData.length > 7 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    dateLabels[index] ?? '',
                    style: TextStyle(
                      color: textMedium,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: textMedium,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Only show unit on the right side at the middle
                if (value == (adjustedMinValue + adjustedMaxValue) / 2) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      vitalUnit,
                      style: TextStyle(
                        color: textMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final int index = spot.x.toInt();
                final dateLabel = dateLabels[index] ?? '';

                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} $vitalUnit\n$dateLabel',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // Normal range area if enabled
          if (showNormalRange)
            LineChartBarData(
              spots: List.generate(chartData.length,
                  (index) => FlSpot(index.toDouble(), normalMax)),
              isCurved: false,
              color: success.withOpacity(0.2),
              barWidth: 0,
              isStrokeCapRound: false,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: success.withOpacity(0.1),
                cutOffY: normalMin,
                applyCutOffY: true,
              ),
            ),

          // Main data line - use pre-processed spots
          LineChartBarData(
            spots: dataSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Safe way to get the value
                double doubleValue = 0.0;
                try {
                  if (index < chartData.length) {
                    final value = chartData[index];
                    if (value is int) {
                      doubleValue = value.toDouble();
                    } else if (value is double) {
                      doubleValue = value;
                    } else if (value is String) {
                      doubleValue = double.tryParse(value) ?? 0.0;
                    }
                  }
                } catch (e) {
                  print('Error in dot painter: $e');
                }

                Color dotColor = Colors.blue;

                // Color dots based on normal range
                if (range != null) {
                  if (doubleValue < range['min']!) {
                    dotColor = Colors.blue;
                  } else if (doubleValue > range['max']!) {
                    dotColor = error;
                  } else {
                    dotColor = success;
                  }
                }

                return FlDotCirclePainter(
                  radius: 5,
                  color: dotColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),

          // Trend line if enabled
          if (showTrendline && chartData.length > 1)
            _buildSafeTrendLine(chartData),
        ],
      ),
    );
  }

  Map<String, dynamic> _processVitalsData() {
    // 1. Filter vitals based on selected time range
    final now = DateTime.now();
    final filteredVitals = widget.vitals.where((vital) {
      if (selectedTimeRange == 'all') return true;

      DateTime? recordTime;
      try {
        // Try to extract date from recordedAt field
        if (vital.recordedAt != null && vital.recordedAt!.isNotEmpty) {
          recordTime = DateTime.parse(vital.recordedAt!);
        } else if (vital.other.contains('Date:')) {
          // Try to extract date from "other" field
          final dateStr = vital.other.split('Date:').last.trim();
          recordTime = DateTime.parse(dateStr);
        }
      } catch (e) {
        // Use current time if date parsing fails
        recordTime = now;
      }

      if (recordTime == null) return true;

      final diff = now.difference(recordTime).inDays;

      switch (selectedTimeRange) {
        case '7days':
          return diff <= 7;
        case '14days':
          return diff <= 14;
        case '30days':
          return diff <= 30;
        default:
          return true;
      }
    }).toList();

    // Sort by date
    filteredVitals.sort((a, b) {
      DateTime? dateA, dateB;

      try {
        if (a.recordedAt != null && a.recordedAt!.isNotEmpty) {
          dateA = DateTime.parse(a.recordedAt!);
        }
      } catch (_) {}

      try {
        if (b.recordedAt != null && b.recordedAt!.isNotEmpty) {
          dateB = DateTime.parse(b.recordedAt!);
        }
      } catch (_) {}

      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    // 2. Extract and process data based on vital type
    if (selectedVitalType == 'bloodPressure') {
      return _processBloodPressureData(filteredVitals);
    } else {
      return _processSingleValueData(filteredVitals, selectedVitalType);
    }
  }

  Map<String, dynamic> _processSingleValueData(
      List<Vitals> vitals, String vitalType) {
    final List<dynamic> chartData = [];
    final Map<int, String> dateLabels = {};

    // Collect non-null values and create date labels
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    double sum = 0;
    int count = 0;

    for (int i = 0; i < vitals.length; i++) {
      final vital = vitals[i];

      // Extract value based on vital type
      double? extractedValue;

      try {
        switch (vitalType) {
          case 'temperature':
            final value = vital.temperature;
            // Try multiple parsing approaches
            extractedValue = double.tryParse(value);
            if (extractedValue == null) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                extractedValue = intValue.toDouble();
              }
            }
            break;
          case 'pulse':
            final value = vital.pulse;
            extractedValue = double.tryParse(value);
            if (extractedValue == null) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                extractedValue = intValue.toDouble();
              }
            }
            break;
          case 'bloodSugar':
            final value = vital.bloodSugarLevel;
            extractedValue = double.tryParse(value);
            if (extractedValue == null) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                extractedValue = intValue.toDouble();
              }
            }
            break;
        }
      } catch (e) {
        print('Error parsing ${vitalType} value: ${e}');
        extractedValue = null;
      }

      if (extractedValue != null) {
        // Add to chart data - using the double value
        chartData.add(extractedValue);

        // Create date label
        String dateLabel = 'N/A';
        try {
          if (vital.recordedAt != null && vital.recordedAt!.isNotEmpty) {
            final date = DateTime.parse(vital.recordedAt!);
            dateLabel = DateFormat('MM/dd').format(date);
          }
        } catch (_) {}

        dateLabels[count] = dateLabel;

        // Update statistics
        if (extractedValue < minValue) minValue = extractedValue;
        if (extractedValue > maxValue) maxValue = extractedValue;
        sum += extractedValue;
        count++;
      }
    }

    // Default values if no data
    if (chartData.isEmpty) {
      minValue = 0;
      maxValue = 100; // Default to 100 for better visualization
      sum = 0;
      count = 0;
    }

    // Set unit based on vital type
    String unit = '';
    switch (vitalType) {
      case 'temperature':
        unit = '°C';
        break;
      case 'pulse':
        unit = 'bpm';
        break;
      case 'bloodSugar':
        unit = 'mg/dL';
        break;
      default:
        unit = '';
    }

    return {
      'chartData': chartData,
      'dateLabels': dateLabels,
      'minValue': minValue == double.infinity ? 0 : minValue,
      'maxValue': maxValue == double.negativeInfinity ? 100 : maxValue,
      'unit': unit,
      'stats': {
        'min': minValue == double.infinity ? 0 : minValue,
        'max': maxValue == double.negativeInfinity ? 0 : maxValue,
        'avg': count > 0 ? sum / count : 0,
      }
    };
  }

  Map<String, dynamic> _processBloodPressureData(List<Vitals> vitals) {
    final List<dynamic> systolicData = [];
    final List<dynamic> diastolicData = [];
    final Map<int, String> dateLabels = {};

    double minSystolic = double.infinity;
    double maxSystolic = double.negativeInfinity;
    double minDiastolic = double.infinity;
    double maxDiastolic = double.negativeInfinity;
    double sumSystolic = 0;
    double sumDiastolic = 0;
    int count = 0;

    for (int i = 0; i < vitals.length; i++) {
      final vital = vitals[i];

      // Parse blood pressure (expected format: "120/80")
      try {
        if (vital.bloodPressure.isNotEmpty &&
            vital.bloodPressure.contains('/')) {
          final parts = vital.bloodPressure.split('/');
          if (parts.length == 2) {
            // Try multiple parsing approaches
            double? systolic;
            double? diastolic;

            // First try double parse
            systolic = double.tryParse(parts[0].trim());
            diastolic = double.tryParse(parts[1].trim());

            // If that fails, try int parse and convert
            if (systolic == null) {
              final intValue = int.tryParse(parts[0].trim());
              if (intValue != null) {
                systolic = intValue.toDouble();
              }
            }

            if (diastolic == null) {
              final intValue = int.tryParse(parts[1].trim());
              if (intValue != null) {
                diastolic = intValue.toDouble();
              }
            }

            if (systolic != null && diastolic != null) {
              systolicData.add(systolic);
              diastolicData.add(diastolic);

              // Create date label
              String dateLabel = 'N/A';
              try {
                if (vital.recordedAt != null && vital.recordedAt!.isNotEmpty) {
                  final date = DateTime.parse(vital.recordedAt!);
                  dateLabel = DateFormat('MM/dd').format(date);
                }
              } catch (_) {}

              dateLabels[count] = dateLabel;

              // Update statistics
              if (systolic < minSystolic) minSystolic = systolic;
              if (systolic > maxSystolic) maxSystolic = systolic;
              if (diastolic < minDiastolic) minDiastolic = diastolic;
              if (diastolic > maxDiastolic) maxDiastolic = diastolic;

              sumSystolic += systolic;
              sumDiastolic += diastolic;
              count++;
            }
          }
        }
      } catch (e) {
        print('Error parsing blood pressure value: $e');
      }
    }

    // Default values if no data
    if (systolicData.isEmpty || diastolicData.isEmpty) {
      minSystolic = 0;
      maxSystolic = 180; // Default max for systolic
      minDiastolic = 0;
      maxDiastolic = 100; // Default max for diastolic
      sumSystolic = 0;
      sumDiastolic = 0;
      count = 0;
    }

    return {
      'systolicData': systolicData,
      'diastolicData': diastolicData,
      'dateLabels': dateLabels,
      'minValue': 0.0, // Explicitly use doubles for min/max
      'maxValue': systolicData.isEmpty ? 180.0 : maxSystolic,
      'unit': 'mmHg',
      'stats': {
        'minSystolic': minSystolic == double.infinity ? 0 : minSystolic,
        'maxSystolic': maxSystolic == double.negativeInfinity ? 0 : maxSystolic,
        'avgSystolic': count > 0 ? sumSystolic / count : 0,
        'minDiastolic': minDiastolic == double.infinity ? 0 : minDiastolic,
        'maxDiastolic':
            maxDiastolic == double.negativeInfinity ? 0 : maxDiastolic,
        'avgDiastolic': count > 0 ? sumDiastolic / count : 0,
      }
    };
  }

  Widget _buildChartSection(Map<String, dynamic> processedData) {
    // Safely extract data with null checks
    final List<dynamic> chartData = processedData['chartData'] ?? [];
    final double minValue = processedData['minValue'] ?? 0.0;
    final double maxValue = processedData['maxValue'] ?? 100.0;
    final String vitalUnit = processedData['unit'] ?? '';
    final Map<int, String> dateLabels = processedData['dateLabels'] ?? {};

    // If no data is available
    if (chartData.isEmpty) {
      return _buildEmptyDataView();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title and stats
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getVitalTypeTitle(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  Text(
                    'Showing ${chartData.length} records ${_getTimeRangeText()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textMedium,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Stats summary
              _buildStatsSummary(processedData),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Measurements', Colors.blue),
              if (showTrendline) _buildLegendItem('Trend', Colors.purple),
              if (showNormalRange)
                _buildLegendItem('Normal Range', Colors.green.withOpacity(0.2)),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: selectedVitalType == 'bloodPressure'
                ? _buildBloodPressureChart(processedData)
                : _buildSingleValueChart(
                    chartData, minValue, maxValue, vitalUnit, dateLabels),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart(Map<String, dynamic> processedData) {
    final List<dynamic> systolicData = processedData['systolicData'] ?? [];
    final List<dynamic> diastolicData = processedData['diastolicData'] ?? [];
    final Map<int, String> dateLabels = processedData['dateLabels'] ?? {};

    // If both data arrays are empty, show empty state
    if (systolicData.isEmpty && diastolicData.isEmpty) {
      return _buildEmptyChartState();
    }

    // Set min and max values for BP chart
    final double minValue = 40.0; // Lower than any normal diastolic
    final double maxValue = 180.0; // Higher than any normal systolic

    // Get normal ranges
    final Map<String, double>? systolicRange = normalRanges['systolic'];
    final Map<String, double>? diastolicRange = normalRanges['diastolic'];

    // Create properly converted spot lists ahead of time to avoid conversion issues
    final List<FlSpot> systolicSpots = [];
    final List<FlSpot> diastolicSpots = [];

    // Pre-process systolic spots
    for (int i = 0; i < systolicData.length; i++) {
      try {
        final value = systolicData[i];
        double doubleValue;
        if (value is int) {
          doubleValue = value.toDouble();
        } else if (value is String) {
          doubleValue = double.tryParse(value) ?? 0.0;
        } else {
          doubleValue = value is double ? value : 0.0;
        }
        systolicSpots.add(FlSpot(i.toDouble(), doubleValue));
      } catch (e) {
        print('Error converting systolic value to double: $e');
        systolicSpots.add(FlSpot(i.toDouble(), 0.0));
      }
    }

    // Pre-process diastolic spots
    for (int i = 0; i < diastolicData.length; i++) {
      try {
        final value = diastolicData[i];
        double doubleValue;
        if (value is int) {
          doubleValue = value.toDouble();
        } else if (value is String) {
          doubleValue = double.tryParse(value) ?? 0.0;
        } else {
          doubleValue = value is double ? value : 0.0;
        }
        diastolicSpots.add(FlSpot(i.toDouble(), doubleValue));
      } catch (e) {
        print('Error converting diastolic value to double: $e');
        diastolicSpots.add(FlSpot(i.toDouble(), 0.0));
      }
    }

    return LineChart(
      LineChartData(
        minY: minValue,
        maxY: maxValue,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            // Highlight normal range lines
            if (showNormalRange &&
                ((systolicRange != null &&
                        (value == systolicRange['min'] ||
                            value == systolicRange['max'])) ||
                    (diastolicRange != null &&
                        (value == diastolicRange['min'] ||
                            value == diastolicRange['max'])))) {
              return FlLine(
                color: success.withOpacity(0.7),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            }
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: systolicData.length > 7 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    dateLabels[index] ?? '',
                    style: TextStyle(
                      color: textMedium,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: textMedium,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Only show unit on the right side at the middle
                if (value == (minValue + maxValue) / 2) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      'mmHg',
                      style: TextStyle(
                        color: textMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final int index = spot.x.toInt();
                final dateLabel = dateLabels[index] ?? '';
                final String label =
                    spot.barIndex == 0 ? 'Systolic' : 'Diastolic';

                return LineTooltipItem(
                  '$label: ${spot.y.toInt()} mmHg\n$dateLabel',
                  TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // Normal range areas if enabled
          if (showNormalRange && systolicRange != null)
            LineChartBarData(
              spots: List.generate(
                  systolicData.length,
                  (index) => FlSpot(
                      index.toDouble(), systolicRange['max']!.toDouble())),
              isCurved: false,
              color: success.withOpacity(0.1),
              barWidth: 0,
              isStrokeCapRound: false,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: success.withOpacity(0.1),
                cutOffY: systolicRange['min']!.toDouble(),
                applyCutOffY: true,
              ),
            ),

          if (showNormalRange && diastolicRange != null)
            LineChartBarData(
              spots: List.generate(
                  diastolicData.length,
                  (index) => FlSpot(
                      index.toDouble(), diastolicRange['max']!.toDouble())),
              isCurved: false,
              color: success.withOpacity(0.1),
              barWidth: 0,
              isStrokeCapRound: false,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: success.withOpacity(0.1),
                cutOffY: diastolicRange['min']!.toDouble(),
                applyCutOffY: true,
              ),
            ),

          // Systolic data line - Use pre-processed spots
          LineChartBarData(
            spots: systolicSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: error.withOpacity(0.8),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Safe way to get the value
                double doubleValue = 0.0;
                try {
                  if (index < systolicData.length) {
                    final value = systolicData[index];
                    if (value is int) {
                      doubleValue = value.toDouble();
                    } else if (value is double) {
                      doubleValue = value;
                    } else if (value is String) {
                      doubleValue = double.tryParse(value) ?? 0.0;
                    }
                  }
                } catch (e) {
                  print('Error in systolic dot painter: $e');
                }

                Color dotColor = error;

                // Color dots based on normal range
                if (systolicRange != null) {
                  if (doubleValue < systolicRange['min']!) {
                    dotColor = Colors.blue;
                  } else if (doubleValue > systolicRange['max']!) {
                    dotColor = error;
                  } else {
                    dotColor = success;
                  }
                }

                return FlDotCirclePainter(
                  radius: 5,
                  color: dotColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),

          // Diastolic data line - Use pre-processed spots
          LineChartBarData(
            spots: diastolicSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: accentColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Safe way to get the value
                double doubleValue = 0.0;
                try {
                  if (index < diastolicData.length) {
                    final value = diastolicData[index];
                    if (value is int) {
                      doubleValue = value.toDouble();
                    } else if (value is double) {
                      doubleValue = value;
                    } else if (value is String) {
                      doubleValue = double.tryParse(value) ?? 0.0;
                    }
                  }
                } catch (e) {
                  print('Error in diastolic dot painter: $e');
                }

                Color dotColor = accentColor;

                // Color dots based on normal range
                if (diastolicRange != null) {
                  if (doubleValue < diastolicRange['min']!) {
                    dotColor = Colors.blue;
                  } else if (doubleValue > diastolicRange['max']!) {
                    dotColor = error;
                  } else {
                    dotColor = success;
                  }
                }

                return FlDotCirclePainter(
                  radius: 5,
                  color: dotColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),

          // Trend lines if enabled
          if (showTrendline && systolicData.length > 1)
            _buildSafeTrendLine(systolicData, color: error.withOpacity(0.5)),

          if (showTrendline && diastolicData.length > 1)
            _buildSafeTrendLine(diastolicData,
                color: accentColor.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: textMedium.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No data to display',
            style: TextStyle(
              fontSize: 16,
              color: textMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add measurements to see a chart',
            style: TextStyle(
              fontSize: 14,
              color: textMedium,
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildSafeTrendLine(List<dynamic> data, {Color? color}) {
    // If we have less than 2 data points, we can't create a meaningful trend line
    if (data.length < 2) {
      // Return a dummy transparent line
      return LineChartBarData(
        spots: [FlSpot(0, 0), FlSpot(1, 0)],
        color: Colors.transparent,
        barWidth: 0,
        dotData: FlDotData(show: false),
      );
    }

    // Otherwise use the normal trend line calculation with proper type handling
    return _buildTrendLine(data, color: color);
  }

  LineChartBarData _buildTrendLine(List<dynamic> data, {Color? color}) {
    try {
      // Calculate linear regression with safe conversion to double
      final xValues = List.generate(data.length, (i) => i.toDouble());
      final yValues = data.map((value) {
        if (value is int) {
          return value.toDouble();
        } else if (value is String) {
          return double.tryParse(value) ?? 0.0;
        } else {
          return value is double ? value : 0.0;
        }
      }).toList();

      double sumX = 0;
      double sumY = 0;
      double sumXY = 0;
      double sumX2 = 0;

      for (int i = 0; i < data.length; i++) {
        sumX += xValues[i];
        sumY += yValues[i];
        sumXY += xValues[i] * yValues[i];
        sumX2 += xValues[i] * xValues[i];
      }

      final n = data.length.toDouble();

      // Avoid division by zero
      if (n * sumX2 - sumX * sumX == 0) {
        // Calculate average line instead
        final avgY = sumY / n;
        final trendSpots = xValues.map((x) {
          return FlSpot(x, avgY);
        }).toList();

        return LineChartBarData(
          spots: trendSpots,
          isCurved: false,
          color: color ?? Colors.purple.withOpacity(0.7),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          dashArray: [4, 4],
        );
      }

      // Calculate slope and intercept
      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;

      // Create trend line points
      final trendSpots = xValues.map((x) {
        return FlSpot(x, slope * x + intercept);
      }).toList();

      return LineChartBarData(
        spots: trendSpots,
        isCurved: false,
        color: color ?? Colors.purple.withOpacity(0.7),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
        dashArray: [4, 4],
      );
    } catch (e) {
      print('Error building trend line: $e');
      // Return an empty transparent line in case of any error
      return LineChartBarData(
        spots: [FlSpot(0, 0), FlSpot(1, 0)],
        color: Colors.transparent,
        barWidth: 0,
        dotData: FlDotData(show: false),
      );
    }
  }

  Widget _buildStatsSummary(Map<String, dynamic> processedData) {
    final stats = processedData['stats'];
    final String unit = processedData['unit'];

    // For blood pressure, we need different handling
    if (selectedVitalType == 'bloodPressure') {
      return Row(
        children: [
          _buildStatBox(
            title: 'Avg Systolic',
            value: '${stats['avgSystolic'].toStringAsFixed(1)} mmHg',
            icon: Icons.arrow_upward,
            color: error.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          _buildStatBox(
            title: 'Avg Diastolic',
            value: '${stats['avgDiastolic'].toStringAsFixed(1)} mmHg',
            icon: Icons.arrow_downward,
            color: accentColor,
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildStatBox(
          title: 'Average',
          value: '${stats['avg'].toStringAsFixed(1)} $unit',
          icon: Icons.bar_chart,
          color: primaryColor,
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          title: 'Min/Max',
          value:
              '${stats['min'].toStringAsFixed(1)} - ${stats['max'].toStringAsFixed(1)} $unit',
          icon: Icons.show_chart,
          color: accentColor,
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: textMedium,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.chartLine,
              size: 64,
              color: textMedium.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'There is no data available for ${_getVitalTypeTitle().toLowerCase()} ${_getTimeRangeText()}',
              style: TextStyle(
                fontSize: 16,
                color: textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add New Measurements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Vitals'),
            style: ElevatedButton.styleFrom(
              backgroundColor: textMedium,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Implementation to add new vitals and return
              Navigator.of(context)
                  .pop(true); // Return true to refresh the parent screen
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Reading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getVitalTypeTitle() {
    switch (selectedVitalType) {
      case 'temperature':
        return 'Body Temperature';
      case 'pulse':
        return 'Pulse Rate';
      case 'bloodPressure':
        return 'Blood Pressure';
      case 'bloodSugar':
        return 'Blood Sugar Level';
      default:
        return 'Vital Sign';
    }
  }

  String _getTimeRangeText() {
    switch (selectedTimeRange) {
      case '7days':
        return 'for the last 7 days';
      case '14days':
        return 'for the last 14 days';
      case '30days':
        return 'for the last 30 days';
      case 'all':
        return 'for all time';
      default:
        return '';
    }
  }
}
