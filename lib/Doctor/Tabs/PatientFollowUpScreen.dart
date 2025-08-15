import 'package:doctordesktop/Doctor/Tabs/FollowUpsAnalytics.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// ==================== MODELS ====================

class PatientInfo {
  final String patientId;
  final String name;
  final int age;
  final String gender;

  const PatientInfo({
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      patientId: json['patientId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      age: _safeInt(json['age']) ?? 0,
      gender: json['gender']?.toString() ?? 'Unknown',
    );
  }
}

class TwoHourFollowUp {
  final String id;
  final String nurseEmail;
  final DateTime date;
  final String notes;
  final String observations;
  final String temperature;
  final String pulse;
  final String respirationRate;
  final String bloodPressure;
  final String oxygenSaturation;
  final String bloodSugarLevel;
  final String otherVitals;
  final String ivFluid;
  final String nasogastric;
  final String rtFeedOral;
  final String totalIntake;
  final String cvp;
  final String urine;
  final String stool;
  final String rtAspirate;
  final String otherOutput;
  final String ventyMode;
  final String setRate;
  final String fiO2;
  final String pip;
  final String peepCpap;
  final String ieRatio;
  final String otherVentilator;

  const TwoHourFollowUp({
    required this.id,
    required this.nurseEmail,
    required this.date,
    required this.notes,
    required this.observations,
    required this.temperature,
    required this.pulse,
    required this.respirationRate,
    required this.bloodPressure,
    required this.oxygenSaturation,
    required this.bloodSugarLevel,
    required this.otherVitals,
    required this.ivFluid,
    required this.nasogastric,
    required this.rtFeedOral,
    required this.totalIntake,
    required this.cvp,
    required this.urine,
    required this.stool,
    required this.rtAspirate,
    required this.otherOutput,
    required this.ventyMode,
    required this.setRate,
    required this.fiO2,
    required this.pip,
    required this.peepCpap,
    required this.ieRatio,
    required this.otherVentilator,
  });

  factory TwoHourFollowUp.fromJson(Map<String, dynamic> json) {
    return TwoHourFollowUp(
      id: json['_id']?.toString() ?? '',
      nurseEmail: json['nurseId']?['email']?.toString() ?? 'Unknown',
      date: _safeDateTime(json['date']) ?? DateTime.now(),
      notes: json['notes']?.toString() ?? '',
      observations: json['observations']?.toString() ?? '',
      temperature: _safeString(json['temperature']),
      pulse: _safeString(json['pulse']),
      respirationRate: _safeString(json['respirationRate']),
      bloodPressure: _safeString(json['bloodPressure']),
      oxygenSaturation: _safeString(json['oxygenSaturation']),
      bloodSugarLevel: _safeString(json['bloodSugarLevel']),
      otherVitals: _safeString(json['otherVitals']),
      ivFluid: _safeString(json['ivFluid']),
      nasogastric: _safeString(json['nasogastric']),
      rtFeedOral: _safeString(json['rtFeedOral']),
      totalIntake: _safeString(json['totalIntake']),
      cvp: _safeString(json['cvp']),
      urine: _safeString(json['urine']),
      stool: _safeString(json['stool']),
      rtAspirate: _safeString(json['rtAspirate']),
      otherOutput: _safeString(json['otherOutput']),
      ventyMode: _safeString(json['ventyMode']),
      setRate: _safeString(json['setRate']),
      fiO2: _safeString(json['fiO2']),
      pip: _safeString(json['pip']),
      peepCpap: _safeString(json['peepCpap']),
      ieRatio: _safeString(json['ieRatio']),
      otherVentilator: _safeString(json['otherVentilator']),
    );
  }
}

class FourHourFollowUp {
  final String id;
  final String nurseEmail;
  final DateTime date;
  final String notes;
  final String observations;
  final String pulse;
  final String bloodPressure;
  final String oxygenSaturation;
  final String temperature;
  final String bloodSugarLevel;
  final String otherVitals;
  final String ivFluid;
  final String urine;

  const FourHourFollowUp({
    required this.id,
    required this.nurseEmail,
    required this.date,
    required this.notes,
    required this.observations,
    required this.pulse,
    required this.bloodPressure,
    required this.oxygenSaturation,
    required this.temperature,
    required this.bloodSugarLevel,
    required this.otherVitals,
    required this.ivFluid,
    required this.urine,
  });

  factory FourHourFollowUp.fromJson(Map<String, dynamic> json) {
    return FourHourFollowUp(
      id: json['_id']?.toString() ?? '',
      nurseEmail: json['nurseId']?['email']?.toString() ?? 'Unknown',
      date: _safeDateTime(json['date']) ?? DateTime.now(),
      notes: json['notes']?.toString() ?? '',
      observations: json['observations']?.toString() ?? '',
      pulse: _safeString(json['fourhrpulse']),
      bloodPressure: _safeString(json['fourhrbloodPressure']),
      oxygenSaturation: _safeString(json['fourhroxygenSaturation']),
      temperature: _safeString(json['fourhrTemperature']),
      bloodSugarLevel: _safeString(json['fourhrbloodSugarLevel']),
      otherVitals: _safeString(json['fourhrotherVitals']),
      ivFluid: _safeString(json['fourhrivFluid']),
      urine: _safeString(json['fourhrurine']),
    );
  }
}

class FollowUpsData {
  final PatientInfo patientInfo;
  final String admissionId;
  final int opdNumber;
  final List<TwoHourFollowUp> twoHourFollowUps;
  final List<FourHourFollowUp> fourHourFollowUps;
  final bool isLoading;
  final String? error;

  const FollowUpsData({
    required this.patientInfo,
    required this.admissionId,
    required this.opdNumber,
    required this.twoHourFollowUps,
    required this.fourHourFollowUps,
    this.isLoading = false,
    this.error,
  });

  FollowUpsData copyWith({
    PatientInfo? patientInfo,
    String? admissionId,
    int? opdNumber,
    List<TwoHourFollowUp>? twoHourFollowUps,
    List<FourHourFollowUp>? fourHourFollowUps,
    bool? isLoading,
    String? error,
  }) {
    return FollowUpsData(
      patientInfo: patientInfo ?? this.patientInfo,
      admissionId: admissionId ?? this.admissionId,
      opdNumber: opdNumber ?? this.opdNumber,
      twoHourFollowUps: twoHourFollowUps ?? this.twoHourFollowUps,
      fourHourFollowUps: fourHourFollowUps ?? this.fourHourFollowUps,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ==================== PDF GENERATION MODEL ====================

class PdfGenerationResult {
  final bool success;
  final String message;
  final String fileName;
  final String driveLink;
  final String patientName;
  final int? followUpCount;
  final int? twoHrFollowUpCount;
  final int? fourHrFollowUpCount;

  const PdfGenerationResult({
    required this.success,
    required this.message,
    required this.fileName,
    required this.driveLink,
    required this.patientName,
    this.followUpCount,
    this.twoHrFollowUpCount,
    this.fourHrFollowUpCount,
  });

  factory PdfGenerationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return PdfGenerationResult(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      fileName: data['fileName'] ?? '',
      driveLink: data['driveLink'] ?? '',
      patientName: data['patientName'] ?? '',
      followUpCount: data['followUpCount'],
      twoHrFollowUpCount: data['twoHrFollowUpCount'],
      fourHrFollowUpCount: data['fourHrFollowUpCount'],
    );
  }
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

String _formatDateTime(DateTime dateTime) {
  final istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30));
  return DateFormat('dd MMM yyyy, hh:mm a').format(istDateTime);
}

// ==================== STATE MANAGEMENT ====================

class FollowUpsNotifier extends StateNotifier<FollowUpsData> {
  FollowUpsNotifier()
      : super(FollowUpsData(
          patientInfo: const PatientInfo(
            patientId: '',
            name: '',
            age: 0,
            gender: '',
          ),
          admissionId: '',
          opdNumber: 0,
          twoHourFollowUps: [],
          fourHourFollowUps: [],
        ));

  Future<void> fetchFollowUps(String patientId, String admissionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _fetchTwoHourFollowUps(patientId, admissionId),
        _fetchFourHourFollowUps(patientId, admissionId),
      ]);

      final twoHourData = results[0] as Map<String, dynamic>;
      final fourHourData = results[1] as Map<String, dynamic>;

      final patientInfo = PatientInfo.fromJson(twoHourData['patientInfo']);
      final twoHourFollowUps = (twoHourData['followUps'] as List)
          .map((json) => TwoHourFollowUp.fromJson(json))
          .toList();
      final fourHourFollowUps = (fourHourData['fourHrFollowUps'] as List)
          .map((json) => FourHourFollowUp.fromJson(json))
          .toList();

      state = FollowUpsData(
        patientInfo: patientInfo,
        admissionId: twoHourData['admissionId']?.toString() ?? '',
        opdNumber: _safeInt(twoHourData['opdNumber']) ?? 0,
        twoHourFollowUps: twoHourFollowUps,
        fourHourFollowUps: fourHourFollowUps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load follow-ups: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> _fetchTwoHourFollowUps(
      String patientId, String admissionId) async {
    final response = await http.get(
      Uri.parse('${BASE_URL}/nurse/getTwoHrFollowUps/$patientId/$admissionId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch 2-hour follow-ups');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _fetchFourHourFollowUps(
      String patientId, String admissionId) async {
    final response = await http.get(
      Uri.parse('${BASE_URL}/nurse/getFourHrFollowUps/$patientId/$admissionId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch 4-hour follow-ups');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ==================== PDF GENERATION STATE ====================

class PdfGenerationNotifier extends StateNotifier<Map<String, bool>> {
  PdfGenerationNotifier() : super({});

  void setLoading(String type, bool loading) {
    state = {...state, type: loading};
  }

  Future<PdfGenerationResult?> generatePdf(
    String type,
    String patientId,
    String admissionId,
  ) async {
    setLoading(type, true);

    try {
      String endpoint;
      switch (type) {
        case '2hr':
          endpoint = '/nurse/generate2HrFollowUpPDF';
          break;
        case '4hr':
          endpoint = '/nurse/generate4HrFollowUpPDF';
          break;
        case 'combined':
          endpoint = '/nurse/generateCombinedFollowUpPDF';
          break;
        default:
          throw Exception('Invalid PDF type');
      }

      final response = await http.post(
        Uri.parse('$BASE_URL$endpoint/$patientId/$admissionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PdfGenerationResult.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate PDF: ${e.toString()}');
    } finally {
      setLoading(type, false);
    }
  }
}

final followUpsProvider =
    StateNotifierProvider.autoDispose<FollowUpsNotifier, FollowUpsData>((ref) {
  return FollowUpsNotifier();
});

final pdfGenerationProvider =
    StateNotifierProvider.autoDispose<PdfGenerationNotifier, Map<String, bool>>(
        (ref) {
  return PdfGenerationNotifier();
});

// ==================== MAIN SCREEN ====================

class FollowUpsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const FollowUpsScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> {
  final Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    ref
        .read(followUpsProvider.notifier)
        .fetchFollowUps(widget.patientId, widget.admissionId);
  }

  bool _isExpanded(String id) => _expandedStates[id] ?? false;

  void _toggleExpanded(String id) {
    setState(() {
      _expandedStates[id] = !_isExpanded(id);
    });
  }

  Future<void> _generateAndViewPdf(String type) async {
    try {
      final result = await ref
          .read(pdfGenerationProvider.notifier)
          .generatePdf(type, widget.patientId, widget.admissionId);

      if (result != null && result.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: HospitalTheme.success,
              duration: const Duration(seconds: 3),
            ),
          );

          // Open PDF viewer
          await ref
              .read(pdfViewerProvider.notifier)
              .loadAndShowPdf(result.driveLink, title: result.fileName);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: HospitalTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showPdfGenerationMenu() {
    final followUpsData = ref.read(followUpsProvider);

    showDialog(
      context: context,
      builder: (context) => _PdfGenerationDialog(
        onGenerate: _generateAndViewPdf,
        twoHourCount: followUpsData.twoHourFollowUps.length,
        fourHourCount: followUpsData.fourHourFollowUps.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final followUpsData = ref.watch(followUpsProvider);
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 768;

    return PdfViewerWidget(
      primaryColor: HospitalTheme.primary,
      appBarTitle: 'Follow-up Reports',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f5): _refreshData,
          const SingleActivator(LogicalKeyboardKey.keyR, control: true):
              _refreshData,
          const SingleActivator(LogicalKeyboardKey.keyP, control: true):
              _showPdfGenerationMenu,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: HospitalTheme.primaryDark,
              automaticallyImplyLeading: false,
              elevation: 2,
              title: const Text(
                'Follow-ups Management',
                style: TextStyle(
                  color: HospitalTheme.surfaceLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                // PDF Generation Menu
                Consumer(
                  builder: (context, ref, child) {
                    final pdfStates = ref.watch(pdfGenerationProvider);
                    final isAnyPdfLoading =
                        pdfStates.values.any((loading) => loading);

                    return Tooltip(
                      message: 'Generate PDF Reports (Ctrl+P)',
                      child: IconButton(
                        onPressed:
                            isAnyPdfLoading ? null : _showPdfGenerationMenu,
                        icon: isAnyPdfLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf,
                                color: Colors.white),
                      ),
                    );
                  },
                ),
                // Analytics Button
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      _createFallingPageRoute(
                        FollowUpAnalyticsScreen(
                          patientInfo: followUpsData.patientInfo,
                          twoHrFollowUps: followUpsData.twoHourFollowUps,
                          fourHrFollowUps: followUpsData.fourHourFollowUps,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics, color: Colors.white),
                  tooltip: 'View Analytics',
                ),
                // Refresh Button
                IconButton(
                  onPressed: followUpsData.isLoading ? null : _refreshData,
                  icon: followUpsData.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh Data (F5 or Ctrl+R)',
                ),
                const SizedBox(width: 16),
              ],
            ),
            backgroundColor: HospitalTheme.background,
            body: Column(
              children: [
                if (followUpsData.patientInfo.name.isNotEmpty)
                  _PatientInfoHeader(patientInfo: followUpsData.patientInfo),
                if (followUpsData.error != null)
                  _ErrorBanner(
                    error: followUpsData.error!,
                    onRetry: _refreshData,
                    onDismiss: () =>
                        ref.read(followUpsProvider.notifier).clearError(),
                  ),
                Expanded(
                  child: followUpsData.isLoading &&
                          followUpsData.twoHourFollowUps.isEmpty &&
                          followUpsData.fourHourFollowUps.isEmpty
                      ? const _LoadingWidget()
                      : Padding(
                          padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
                          child: isMediumScreen
                              ? _TwoColumnLayout(
                                  followUpsData: followUpsData,
                                  isExpanded: _isExpanded,
                                  toggleExpanded: _toggleExpanded,
                                )
                              : _SingleColumnLayout(
                                  followUpsData: followUpsData,
                                  isExpanded: _isExpanded,
                                  toggleExpanded: _toggleExpanded,
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PDF GENERATION DIALOG ====================

class _PdfGenerationDialog extends ConsumerWidget {
  final Function(String) onGenerate;
  final int twoHourCount;
  final int fourHourCount;

  const _PdfGenerationDialog({
    required this.onGenerate,
    required this.twoHourCount,
    required this.fourHourCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfStates = ref.watch(pdfGenerationProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: HospitalTheme.radiusMedium,
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  color: HospitalTheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Generate PDF Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose the type of report to generate:',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24),

            // 2-Hour Follow-ups PDF
            _PdfOptionCard(
              title: '2-Hour Follow-ups',
              subtitle: '$twoHourCount follow-ups available',
              icon: Icons.schedule,
              color: HospitalTheme.medical,
              isLoading: pdfStates['2hr'] ?? false,
              enabled: twoHourCount > 0,
              onTap: () {
                onGenerate('2hr');
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 12),

            // 4-Hour Follow-ups PDF
            _PdfOptionCard(
              title: '4-Hour Follow-ups',
              subtitle: '$fourHourCount follow-ups available',
              icon: Icons.schedule_outlined,
              color: HospitalTheme.pharmacy,
              isLoading: pdfStates['4hr'] ?? false,
              enabled: fourHourCount > 0,
              onTap: () {
                onGenerate('4hr');
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 12),

            // Combined PDF
            _PdfOptionCard(
              title: 'Combined Report',
              subtitle: 'Both 2hr and 4hr follow-ups',
              icon: Icons.merge_type,
              color: HospitalTheme.primary,
              isLoading: pdfStates['combined'] ?? false,
              enabled: (twoHourCount + fourHourCount) > 0,
              onTap: () {
                onGenerate('combined');
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _PdfOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled && !isLoading ? onTap : null,
      borderRadius: HospitalTheme.radiusSmall,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.05) : HospitalTheme.surfaceLight,
          borderRadius: HospitalTheme.radiusSmall,
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : HospitalTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: enabled
                    ? color.withOpacity(0.1)
                    : HospitalTheme.textLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: enabled ? color : HospitalTheme.textLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled
                          ? HospitalTheme.textDark
                          : HospitalTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled
                          ? HospitalTheme.textMedium
                          : HospitalTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (enabled)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

PageRouteBuilder _createFallingPageRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: const Offset(0, 0),
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: child,
      );
    },
  );
}

// ==================== LAYOUT WIDGETS ====================

class _TwoColumnLayout extends StatelessWidget {
  final FollowUpsData followUpsData;
  final bool Function(String) isExpanded;
  final void Function(String) toggleExpanded;

  const _TwoColumnLayout({
    required this.followUpsData,
    required this.isExpanded,
    required this.toggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FollowUpColumn(
            title: '2-Hour Follow-ups',
            count: followUpsData.twoHourFollowUps.length,
            color: HospitalTheme.medical,
            children: followUpsData.twoHourFollowUps
                .map((followUp) => _TwoHourFollowUpCard(
                      followUp: followUp,
                      isExpanded: isExpanded(followUp.id),
                      onToggleExpanded: () => toggleExpanded(followUp.id),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _FollowUpColumn(
            title: '4-Hour Follow-ups',
            count: followUpsData.fourHourFollowUps.length,
            color: HospitalTheme.pharmacy,
            children: followUpsData.fourHourFollowUps
                .map((followUp) => _FourHourFollowUpCard(
                      followUp: followUp,
                      isExpanded: isExpanded(followUp.id),
                      onToggleExpanded: () => toggleExpanded(followUp.id),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SingleColumnLayout extends StatelessWidget {
  final FollowUpsData followUpsData;
  final bool Function(String) isExpanded;
  final void Function(String) toggleExpanded;

  const _SingleColumnLayout({
    required this.followUpsData,
    required this.isExpanded,
    required this.toggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return _ScrollableSingleChild(
      child: Column(
        children: [
          _FollowUpSection(
            title: '2-Hour Follow-ups',
            count: followUpsData.twoHourFollowUps.length,
            color: HospitalTheme.medical,
            children: followUpsData.twoHourFollowUps
                .map((followUp) => _TwoHourFollowUpCard(
                      followUp: followUp,
                      isExpanded: isExpanded(followUp.id),
                      onToggleExpanded: () => toggleExpanded(followUp.id),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          _FollowUpSection(
            title: '4-Hour Follow-ups',
            count: followUpsData.fourHourFollowUps.length,
            color: HospitalTheme.pharmacy,
            children: followUpsData.fourHourFollowUps
                .map((followUp) => _FourHourFollowUpCard(
                      followUp: followUp,
                      isExpanded: isExpanded(followUp.id),
                      onToggleExpanded: () => toggleExpanded(followUp.id),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ==================== COMPONENT WIDGETS ====================

class _PatientInfoHeader extends StatelessWidget {
  final PatientInfo patientInfo;

  const _PatientInfoHeader({required this.patientInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: HospitalTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: HospitalTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientInfo.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${patientInfo.patientId} | Age: ${patientInfo.age} | Gender: ${patientInfo.gender}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _ErrorBanner({
    required this.error,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: HospitalTheme.error.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: HospitalTheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: HospitalTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading follow-ups...',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpColumn extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final List<Widget> children;

  const _FollowUpColumn({
    required this.title,
    required this.count,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: HospitalTheme.radiusSmall,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.medical_services,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              HospitalTheme.buildStatusBadge(
                '$count',
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: HospitalTheme.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${title.toLowerCase()} available',
                        style: const TextStyle(
                          color: HospitalTheme.textMedium,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : _ScrollableListView(
                  children: children,
                ),
        ),
      ],
    );
  }
}

class _FollowUpSection extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final List<Widget> children;

  const _FollowUpSection({
    required this.title,
    required this.count,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSectionHeight = (screenHeight * 0.4).clamp(300.0, 500.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: HospitalTheme.radiusSmall,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.medical_services,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              HospitalTheme.buildStatusBadge(
                '$count',
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (children.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: HospitalTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${title.toLowerCase()} available',
                    style: const TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: children.length > 3 ? maxSectionHeight : null,
            child: children.length > 3
                ? _ScrollableListView(children: children)
                : Column(
                    children: children.asMap().entries.map((entry) {
                      final index = entry.key;
                      final child = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < children.length - 1 ? 12.0 : 0,
                        ),
                        child: child,
                      );
                    }).toList(),
                  ),
          ),
      ],
    );
  }
}

// ==================== FOLLOW-UP CARDS ====================

class _TwoHourFollowUpCard extends StatelessWidget {
  final TwoHourFollowUp followUp;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const _TwoHourFollowUpCard({
    required this.followUp,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: isExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  )
                : HospitalTheme.radiusMedium,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.medical.withOpacity(0.1),
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : HospitalTheme.radiusMedium,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(followUp.date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.medical,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By: ${followUp.nurseEmail}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: HospitalTheme.medical,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            _TwoHourExpandedContent(
              followUp: followUp,
              onCollapse: onToggleExpanded,
            ),
        ],
      ),
    );
  }
}

class _TwoHourExpandedContent extends StatelessWidget {
  final TwoHourFollowUp followUp;
  final VoidCallback onCollapse;

  const _TwoHourExpandedContent({
    required this.followUp,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 350,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: _ScrollableSingleChild(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (followUp.notes.isNotEmpty && followUp.notes != 'N/A')
              _InfoSection(
                title: 'Notes',
                content: followUp.notes,
                icon: Icons.note_alt_outlined,
              ),
            if (followUp.observations.isNotEmpty &&
                followUp.observations != 'N/A')
              _InfoSection(
                title: 'Observations',
                content: followUp.observations,
                icon: Icons.visibility_outlined,
              ),
            const Text(
              'Vital Signs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _VitalSignsTable(
              vitals: [
                ['Temperature', followUp.temperature, '°F'],
                ['Pulse', followUp.pulse, 'bpm'],
                ['Respiration Rate', followUp.respirationRate, '/min'],
                ['Blood Pressure', followUp.bloodPressure, 'mmHg'],
                ['Oxygen Saturation', followUp.oxygenSaturation, '%'],
                ['Blood Sugar', followUp.bloodSugarLevel, 'mg/dL'],
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Intake & Output',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _DetailTable(
              data: [
                ['IV Fluid', followUp.ivFluid],
                ['Nasogastric', followUp.nasogastric],
                ['RT Feed Oral', followUp.rtFeedOral],
                ['Total Intake', followUp.totalIntake],
                ['CVP', followUp.cvp],
                ['Urine', followUp.urine],
                ['Stool', followUp.stool],
                ['RT Aspirate', followUp.rtAspirate],
                ['Other Output', followUp.otherOutput],
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ventilator Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _DetailTable(
              data: [
                ['Mode', followUp.ventyMode],
                ['Set Rate', followUp.setRate],
                ['FiO2', followUp.fiO2],
                ['PIP', followUp.pip],
                ['PEEP/CPAP', followUp.peepCpap],
                ['I:E Ratio', followUp.ieRatio],
                ['Other', followUp.otherVentilator],
              ],
            ),
            if (followUp.otherVitals.isNotEmpty &&
                followUp.otherVitals != 'N/A')
              _InfoSection(
                title: 'Other Vitals',
                content: followUp.otherVitals,
                icon: Icons.favorite_outline,
              ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: onCollapse,
                icon: const Icon(
                  Icons.keyboard_arrow_up,
                  color: HospitalTheme.medical,
                ),
                label: const Text(
                  'Collapse',
                  style: TextStyle(
                    color: HospitalTheme.medical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FourHourFollowUpCard extends StatelessWidget {
  final FourHourFollowUp followUp;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const _FourHourFollowUpCard({
    required this.followUp,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: isExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  )
                : HospitalTheme.radiusMedium,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.pharmacy.withOpacity(0.1),
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : HospitalTheme.radiusMedium,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(followUp.date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.pharmacy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By: ${followUp.nurseEmail}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: HospitalTheme.pharmacy,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            _FourHourExpandedContent(
              followUp: followUp,
              onCollapse: onToggleExpanded,
            ),
        ],
      ),
    );
  }
}

class _FourHourExpandedContent extends StatelessWidget {
  final FourHourFollowUp followUp;
  final VoidCallback onCollapse;

  const _FourHourExpandedContent({
    required this.followUp,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 350,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (followUp.notes.isNotEmpty && followUp.notes != 'N/A')
                _InfoSection(
                  title: 'Notes',
                  content: followUp.notes,
                  icon: Icons.note_alt_outlined,
                ),
              if (followUp.observations.isNotEmpty &&
                  followUp.observations != 'N/A')
                _InfoSection(
                  title: 'Observations',
                  content: followUp.observations,
                  icon: Icons.visibility_outlined,
                ),
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _VitalSignsTable(
                vitals: [
                  ['Temperature', followUp.temperature, '°F'],
                  ['Pulse', followUp.pulse, 'bpm'],
                  ['Blood Pressure', followUp.bloodPressure, 'mmHg'],
                  ['Oxygen Saturation', followUp.oxygenSaturation, '%'],
                  ['Blood Sugar', followUp.bloodSugarLevel, 'mg/dL'],
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Intake & Output',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _DetailTable(
                data: [
                  ['IV Fluid', followUp.ivFluid],
                  ['Urine', followUp.urine],
                ],
              ),
              if (followUp.otherVitals.isNotEmpty &&
                  followUp.otherVitals != 'N/A')
                _InfoSection(
                  title: 'Other Vitals',
                  content: followUp.otherVitals,
                  icon: Icons.favorite_outline,
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: onCollapse,
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    color: HospitalTheme.pharmacy,
                  ),
                  label: const Text(
                    'Collapse',
                    style: TextStyle(
                      color: HospitalTheme.pharmacy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== UTILITY WIDGETS ====================

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: HospitalTheme.textMedium,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: HospitalTheme.radiusSmall,
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalSignsTable extends StatelessWidget {
  final List<List<String>> vitals;

  const _VitalSignsTable({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: HospitalTheme.border),
        borderRadius: HospitalTheme.radiusSmall,
      ),
      child: Column(
        children: vitals.asMap().entries.map((entry) {
          final index = entry.key;
          final vital = entry.value;
          final isLast = index == vitals.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? HospitalTheme.surfaceLight : Colors.white,
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: HospitalTheme.border),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    vital[0],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    vital[1],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    vital[2],
                    style: const TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailTable extends StatelessWidget {
  final List<List<String>> data;

  const _DetailTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final filteredData =
        data.where((row) => row[1].isNotEmpty && row[1] != 'N/A').toList();

    if (filteredData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HospitalTheme.surfaceLight,
          borderRadius: HospitalTheme.radiusSmall,
          border: Border.all(color: HospitalTheme.border),
        ),
        child: const Text(
          'No data available',
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: HospitalTheme.border),
        borderRadius: HospitalTheme.radiusSmall,
      ),
      child: Column(
        children: filteredData.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isLast = index == filteredData.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? HospitalTheme.surfaceLight : Colors.white,
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: HospitalTheme.border),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row[0],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    row[1],
                    style: const TextStyle(
                      fontSize: 14,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==================== CUSTOM SCROLLABLE WIDGETS ====================

class _ScrollableListView extends StatefulWidget {
  final List<Widget> children;

  const _ScrollableListView({
    required this.children,
  });

  @override
  _ScrollableListViewState createState() => _ScrollableListViewState();
}

class _ScrollableListViewState extends State<_ScrollableListView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent pointerSignal) {
    if (pointerSignal is PointerScrollEvent) {
      final double scrollDelta = pointerSignal.scrollDelta.dy;
      const double scrollSensitivity = 50.0;

      _scrollController.animateTo(
        _scrollController.offset + scrollDelta * scrollSensitivity / 120,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView.separated(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.children.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => widget.children[index],
        ),
      ),
    );
  }
}

class _ScrollableSingleChild extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _ScrollableSingleChild({
    required this.child,
    this.padding,
  });

  @override
  _ScrollableSingleChildState createState() => _ScrollableSingleChildState();
}

class _ScrollableSingleChildState extends State<_ScrollableSingleChild> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent pointerSignal) {
    if (pointerSignal is PointerScrollEvent) {
      final double scrollDelta = pointerSignal.scrollDelta.dy;
      const double scrollSensitivity = 50.0;

      _scrollController.animateTo(
        _scrollController.offset + scrollDelta * scrollSensitivity / 120,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}
