import 'dart:convert';
import 'package:doctordesktop/Doctor/MedicalRecordScreen.dart';
import 'package:doctordesktop/Doctor/speech.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Models for parsed medical data (keep existing models)
// Enhanced Medical Data Models for Speech-to-Text

class ParsedMedicalData {
  final String patientId;
  final String admissionId;
  final ParsedVitals vitals;
  final List<String> symptoms;
  final List<String> diagnosis;
  final List<ParsedPrescription> prescriptions;

  const ParsedMedicalData({
    required this.patientId,
    required this.admissionId,
    required this.vitals,
    required this.symptoms,
    required this.diagnosis,
    required this.prescriptions,
  });

  factory ParsedMedicalData.fromJson(Map<String, dynamic> json) {
    return ParsedMedicalData(
      patientId: json['patientId']?.toString() ?? '',
      admissionId: json['admissionId']?.toString() ?? '',
      vitals: ParsedVitals.fromJson(json['vitals'] ?? {}),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      diagnosis: List<String>.from(json['diagnosis'] ?? []),
      prescriptions: (json['prescriptions'] as List<dynamic>? ?? [])
          .map((p) => ParsedPrescription.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'admissionId': admissionId,
      'vitals': vitals.toJson(),
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'prescriptions': prescriptions.map((p) => p.toJson()).toList(),
    };
  }

  ParsedMedicalData copyWith({
    String? patientId,
    String? admissionId,
    ParsedVitals? vitals,
    List<String>? symptoms,
    List<String>? diagnosis,
    List<ParsedPrescription>? prescriptions,
  }) {
    return ParsedMedicalData(
      patientId: patientId ?? this.patientId,
      admissionId: admissionId ?? this.admissionId,
      vitals: vitals ?? this.vitals,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      prescriptions: prescriptions ?? this.prescriptions,
    );
  }
}

class ParsedVitals {
  final String temperature;
  final String pulse;
  final String bloodPressure;
  final String bloodSugarLevel;
  final String other;

  const ParsedVitals({
    required this.temperature,
    required this.pulse,
    required this.bloodPressure,
    required this.bloodSugarLevel,
    required this.other,
  });

  factory ParsedVitals.fromJson(Map<String, dynamic> json) {
    return ParsedVitals(
      temperature: json['temperature']?.toString() ?? 'N/A',
      pulse: json['pulse']?.toString() ?? 'N/A',
      bloodPressure: json['bloodPressure']?.toString() ?? 'N/A',
      bloodSugarLevel: json['bloodSugarLevel']?.toString() ?? 'N/A',
      other: json['other']?.toString() ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'pulse': pulse,
      'bloodPressure': bloodPressure,
      'bloodSugarLevel': bloodSugarLevel,
      'other': other,
    };
  }

  ParsedVitals copyWith({
    String? temperature,
    String? pulse,
    String? bloodPressure,
    String? bloodSugarLevel,
    String? other,
  }) {
    return ParsedVitals(
      temperature: temperature ?? this.temperature,
      pulse: pulse ?? this.pulse,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      bloodSugarLevel: bloodSugarLevel ?? this.bloodSugarLevel,
      other: other ?? this.other,
    );
  }
}

class ParsedPrescription {
  final ParsedMedicine medicine;

  const ParsedPrescription({required this.medicine});

  factory ParsedPrescription.fromJson(Map<String, dynamic> json) {
    return ParsedPrescription(
      medicine: ParsedMedicine.fromJson(json['medicine'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicine.toJson(),
    };
  }

  ParsedPrescription copyWith({
    ParsedMedicine? medicine,
  }) {
    return ParsedPrescription(
      medicine: medicine ?? this.medicine,
    );
  }
}

class ParsedMedicine {
  final String name;
  final String morning;
  final String afternoon;
  final String night;
  final String comment;

  const ParsedMedicine({
    required this.name,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.comment,
  });

  factory ParsedMedicine.fromJson(Map<String, dynamic> json) {
    return ParsedMedicine(
      name: json['name']?.toString() ?? '',
      morning: json['morning']?.toString() ?? '',
      afternoon: json['afternoon']?.toString() ?? '',
      night: json['night']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'morning': morning,
      'afternoon': afternoon,
      'night': night,
      'comment': comment,
    };
  }

  ParsedMedicine copyWith({
    String? name,
    String? morning,
    String? afternoon,
    String? night,
    String? comment,
  }) {
    return ParsedMedicine(
      name: name ?? this.name,
      morning: morning ?? this.morning,
      afternoon: afternoon ?? this.afternoon,
      night: night ?? this.night,
      comment: comment ?? this.comment,
    );
  }
}

// Enhanced State management for Google Speech-to-Text
class GoogleSpeechToTextState {
  final bool isListening;
  final bool isProcessing;
  final bool isUpdating;
  final bool isInitializing;
  final bool isEditing;
  final String transcriptText;
  final ParsedMedicalData? parsedData;
  final String? error;
  final bool hasProcessedData;
  final double? confidence;

  const GoogleSpeechToTextState({
    this.isListening = false,
    this.isProcessing = false,
    this.isUpdating = false,
    this.isInitializing = false,
    this.isEditing = false,
    this.transcriptText = '',
    this.parsedData,
    this.error,
    this.hasProcessedData = false,
    this.confidence,
  });

  GoogleSpeechToTextState copyWith({
    bool? isListening,
    bool? isProcessing,
    bool? isUpdating,
    bool? isInitializing,
    bool? isEditing,
    String? transcriptText,
    ParsedMedicalData? parsedData,
    String? error,
    bool? hasProcessedData,
    double? confidence,
  }) {
    return GoogleSpeechToTextState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      isUpdating: isUpdating ?? this.isUpdating,
      isInitializing: isInitializing ?? this.isInitializing,
      isEditing: isEditing ?? this.isEditing,
      transcriptText: transcriptText ?? this.transcriptText,
      parsedData: parsedData ?? this.parsedData,
      error: error,
      hasProcessedData: hasProcessedData ?? this.hasProcessedData,
      confidence: confidence ?? this.confidence,
    );
  }
}

class GoogleSpeechToTextNotifier
    extends StateNotifier<GoogleSpeechToTextState> {
  final Ref ref;
  final GoogleSpeechToTextService _speechService = GoogleSpeechToTextService();
  static const String geminiApiKey = 'AIzaSyBzHQvf_-z28gTf0poC2s8bvt83mingpHc';

  GoogleSpeechToTextNotifier(this.ref) : super(const GoogleSpeechToTextState());

  // Map<String, String> get _authHeaders {
  //   try {
  //     return ref.read(authHeadersProvider);
  //   } catch (e) {
  //     return {'Content-Type': 'application/json'};
  //   }
  // }

  Future<void> initializeSpeech() async {
    state = state.copyWith(isInitializing: true, error: null);

    try {
      final initialized = await _speechService.initialize();
      if (initialized) {
        state = state.copyWith(isInitializing: false);
        debugPrint('Google Speech-to-Text initialized successfully');
      } else {
        state = state.copyWith(
          isInitializing: false,
          error: 'Failed to initialize Google Speech-to-Text',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: 'Speech initialization error: $e',
      );
    }
  }

  Future<void> startListening() async {
    if (state.isInitializing) return;

    state = state.copyWith(
      isListening: false,
      error: null,
      transcriptText: '',
      parsedData: null,
      hasProcessedData: false,
      confidence: null,
      isEditing: false,
    );

    try {
      final started = await _speechService.startRecording();
      if (started) {
        state = state.copyWith(isListening: true);
        debugPrint('Recording started with Google Speech API');
      } else {
        state = state.copyWith(
          error:
              'Failed to start recording. Please check microphone permissions.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start listening: $e',
      );
    }
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;

    state = state.copyWith(isListening: false, isProcessing: true);

    try {
      final transcript = await _speechService.stopRecording();

      if (transcript != null && transcript.trim().isNotEmpty) {
        state = state.copyWith(
          transcriptText: transcript,
          isProcessing: false,
        );

        // Automatically process with Gemini after successful transcription
        await _processTranscriptWithGemini(transcript);
      } else {
        state = state.copyWith(
          isProcessing: false,
          error:
              'No speech detected or transcription failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to process recording: $e',
      );
    }
  }

  Future<void> _processTranscriptWithGemini(String transcript) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final prompt = _buildGeminiPrompt(transcript);

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 2048,
          }
        }),
      );

      debugPrint('Gemini response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (generatedText != null) {
          final cleanedJson = _cleanJsonString(generatedText);
          final parsedJson = jsonDecode(cleanedJson);
          final parsedData = ParsedMedicalData.fromJson(parsedJson);

          state = state.copyWith(
            parsedData: parsedData,
            isProcessing: false,
            hasProcessedData: true,
          );
        } else {
          throw Exception('No generated text in Gemini response');
        }
      } else {
        throw Exception(
            'Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error processing with Gemini: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to process transcript: $e',
      );
    }
  }

  String _buildGeminiPrompt(String transcript) {
    return '''
You are a reliable and intelligent medical data extractor with strong reasoning skills.
You will be given a doctor's spoken or written transcript containing patient details.
The transcript may be unstructured, contain spelling mistakes, informal language, and mixed ordering of information.
Your tasks:
1. Carefully read and interpret the entire transcript.
2. Ignore spelling and grammar errors — understand the intended meaning.
3. Logically identify and group details into:
   - patientId (string)
   - admissionId (string)
   - vitals (temperature, pulse, bloodPressure, bloodSugarLevel, other)
   - symptoms (array of strings)
   - diagnosis (array of strings)
   - prescriptions (array of objects: { medicine: { name, morning, afternoon, night, comment } })
4. Normalize medicine names and ensure dosage, frequency, and instructions are clear and consistent. Make sure to add quantity of dosage in morning afternoon and night in number form of string like "1", "2", "3".
5. If any required field is missing, set its value to "N/A".
6. Output **only** a single valid JSON object in the exact format below, without any explanations, extra text, or markdown.

Doctor's transcript: "$transcript"

JSON format:
{
  "patientId": "string",
  "admissionId": "string",
  "vitals": {
    "temperature": "string",
    "pulse": "string",
    "bloodPressure": "string",
    "bloodSugarLevel": "string",
    "other": "string"
  },
  "symptoms": ["string", "string"],
  "diagnosis": ["string", "string"],
  "prescriptions": [
    {
      "medicine": {
        "name": "string",
        "morning": "string",
        "afternoon": "string",
        "night": "string",
        "comment": "string"
      }
    }
  ]
}
''';
  }

  String _cleanJsonString(String jsonString) {
    String cleaned = jsonString.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  // Method to toggle editing mode
  void toggleEditing() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  // Method to update parsed data when editing
  void updateParsedData(ParsedMedicalData updatedData) {
    state = state.copyWith(parsedData: updatedData);
  }

  Future<void> updatePatientMedicalInfo(
      String patientId, String admissionId) async {
    if (state.parsedData == null) return;

    state = state.copyWith(isUpdating: true, error: null, isEditing: false);

    try {
      final requestBody = {
        'patientId': patientId,
        'admissionId': admissionId,
        'vitals': state.parsedData!.vitals.toJson(),
        'symptoms': state.parsedData!.symptoms,
        'diagnosis': state.parsedData!.diagnosis,
        'prescriptions':
            state.parsedData!.prescriptions.map((p) => p.toJson()).toList(),
      };

      debugPrint('Updating medical info with: ${jsonEncode(requestBody)}');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      final response = await http.post(
        Uri.parse('${BASE_URL}/doctors/updatePatientMedicalInfo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}'
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Update response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isUpdating: false);

        // Refresh medical records data
        ref
            .read(medicalRecordsProvider.notifier)
            .fetchAllMedicalRecords(patientId, admissionId);
      } else {
        throw Exception(
            'Failed to update medical info: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating medical info: $e');
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update medical records: $e',
      );
    }
  }

  void clearData() {
    state = const GoogleSpeechToTextState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}

final googleSpeechToTextProvider =
    StateNotifierProvider<GoogleSpeechToTextNotifier, GoogleSpeechToTextState>(
        (ref) {
  return GoogleSpeechToTextNotifier(ref);
});

class GoogleSpeechToTextMedicalScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const GoogleSpeechToTextMedicalScreen({
    super.key,
    required this.patientId,
    required this.admissionId,
  });

  @override
  ConsumerState<GoogleSpeechToTextMedicalScreen> createState() =>
      _GoogleSpeechToTextMedicalScreenState();
}

class _GoogleSpeechToTextMedicalScreenState
    extends ConsumerState<GoogleSpeechToTextMedicalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(googleSpeechToTextProvider.notifier).initializeSpeech();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(googleSpeechToTextProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          children: [
            // Show extracted data at the top when available
            if (state.hasProcessedData && state.parsedData != null) ...[
              _buildParsedDataSection(context, state, isTablet),
              SizedBox(height: isTablet ? 24 : 16),
            ],

            // Speech Recognition Section
            _buildSpeechSection(context, state, isTablet),

            if (state.transcriptText.isNotEmpty) ...[
              SizedBox(height: isTablet ? 24 : 16),
              _buildTranscriptSection(context, state, isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechSection(
      BuildContext context, GoogleSpeechToTextState state, bool isTablet) {
    return HospitalTheme.buildCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: HospitalTheme.primary,
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  'Google Voice Medical Records',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HospitalTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HospitalTheme.success),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        color: HospitalTheme.success, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Medical AI',
                      style: TextStyle(
                        color: HospitalTheme.success,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            state.isInitializing
                ? 'Initializing Google Speech API...'
                : state.isListening
                    ? 'Listening... Speak clearly'
                    : state.isProcessing
                        ? 'Processing with medical AI...'
                        : 'Tap the microphone to start recording',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!state.isProcessing &&
                  !state.isUpdating &&
                  !state.isInitializing) ...[
                _buildMicButton(context, state, isTablet),
              ],
              if (state.isProcessing || state.isInitializing)
                Container(
                  width: isTablet ? 80 : 60,
                  height: isTablet ? 80 : 60,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
                    strokeWidth: 4,
                  ),
                ),
            ],
          ),
          if (state.confidence != null) ...[
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HospitalTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Confidence: ${(state.confidence! * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: HospitalTheme.info,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (state.error != null) ...[
            SizedBox(height: isTablet ? 20 : 16),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusSmall,
                border: Border.all(color: HospitalTheme.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: HospitalTheme.error),
                  SizedBox(width: isTablet ? 12 : 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: HospitalTheme.error),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: HospitalTheme.error),
                    onPressed: () => ref
                        .read(googleSpeechToTextProvider.notifier)
                        .clearError(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicButton(
      BuildContext context, GoogleSpeechToTextState state, bool isTablet) {
    return GestureDetector(
      onTap: state.isListening
          ? () => ref.read(googleSpeechToTextProvider.notifier).stopListening()
          : () =>
              ref.read(googleSpeechToTextProvider.notifier).startListening(),
      child: Container(
        width: isTablet ? 80 : 60,
        height: isTablet ? 80 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              state.isListening ? HospitalTheme.error : HospitalTheme.primary,
          boxShadow: HospitalTheme.shadow,
        ),
        child: Icon(
          state.isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: isTablet ? 36 : 28,
        ),
      ),
    );
  }

  Widget _buildTranscriptSection(
      BuildContext context, GoogleSpeechToTextState state, bool isTablet) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Medical Transcript',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HospitalTheme.medical.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology,
                        color: HospitalTheme.medical, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Google AI',
                      style: TextStyle(
                        color: HospitalTheme.medical,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: HospitalTheme.radiusSmall,
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Text(
              state.transcriptText.isEmpty
                  ? 'No speech detected yet...'
                  : state.transcriptText,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: HospitalTheme.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedDataSection(
      BuildContext context, GoogleSpeechToTextState state, bool isTablet) {
    final data = state.parsedData!;

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Extracted Medical Data',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ),
              if (!state.isEditing) ...[
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(googleSpeechToTextProvider.notifier)
                      .toggleEditing(),
                  icon: Icon(Icons.edit, size: isTablet ? 18 : 16),
                  label: Text(
                    'Edit',
                    style: TextStyle(fontSize: isTablet ? 14 : 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.info,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
              ],
              if (state.isEditing) ...[
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(googleSpeechToTextProvider.notifier)
                      .toggleEditing(),
                  icon: Icon(Icons.close, size: isTablet ? 18 : 16),
                  label: Text(
                    'Cancel',
                    style: TextStyle(fontSize: isTablet ? 14 : 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: state.isUpdating
                    ? null
                    : () {
                        ref
                            .read(googleSpeechToTextProvider.notifier)
                            .updatePatientMedicalInfo(
                                widget.patientId, widget.admissionId);
                      },
                icon: state.isUpdating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.save, size: isTablet ? 18 : 16),
                label: Text(
                  state.isUpdating ? 'Updating...' : 'Apply',
                  style: TextStyle(fontSize: isTablet ? 14 : 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vitals
              _buildEditableVitalsSection(data, isTablet),
              SizedBox(height: isTablet ? 20 : 16),

              // Symptoms
              _buildEditableListSection(
                'Symptoms',
                Icons.sick,
                data.symptoms,
                (updatedList) {
                  final updatedData = data.copyWith(symptoms: updatedList);
                  ref
                      .read(googleSpeechToTextProvider.notifier)
                      .updateParsedData(updatedData);
                },
                isTablet,
              ),
              SizedBox(height: isTablet ? 20 : 16),

              // Diagnosis
              _buildEditableListSection(
                'Diagnosis',
                Icons.medical_services,
                data.diagnosis,
                (updatedList) {
                  final updatedData = data.copyWith(diagnosis: updatedList);
                  ref
                      .read(googleSpeechToTextProvider.notifier)
                      .updateParsedData(updatedData);
                },
                isTablet,
              ),
              SizedBox(height: isTablet ? 20 : 16),

              // Prescriptions
              _buildEditablePrescriptionsSection(data.prescriptions, isTablet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableVitalsSection(ParsedMedicalData data, bool isTablet) {
    final state = ref.watch(googleSpeechToTextProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_border,
                size: isTablet ? 24 : 20, color: HospitalTheme.primary),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Vitals',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            borderRadius: HospitalTheme.radiusSmall,
            border: Border.all(color: HospitalTheme.border),
          ),
          child: state.isEditing
              ? Column(
                  children: [
                    _buildEditableField(
                      'Temperature',
                      data.vitals.temperature,
                      (value) {
                        final updatedVitals =
                            data.vitals.copyWith(temperature: value);
                        final updatedData =
                            data.copyWith(vitals: updatedVitals);
                        ref
                            .read(googleSpeechToTextProvider.notifier)
                            .updateParsedData(updatedData);
                      },
                      isTablet,
                    ),
                    SizedBox(height: 8),
                    _buildEditableField(
                      'Pulse',
                      data.vitals.pulse,
                      (value) {
                        final updatedVitals =
                            data.vitals.copyWith(pulse: value);
                        final updatedData =
                            data.copyWith(vitals: updatedVitals);
                        ref
                            .read(googleSpeechToTextProvider.notifier)
                            .updateParsedData(updatedData);
                      },
                      isTablet,
                    ),
                    SizedBox(height: 8),
                    _buildEditableField(
                      'Blood Pressure',
                      data.vitals.bloodPressure,
                      (value) {
                        final updatedVitals =
                            data.vitals.copyWith(bloodPressure: value);
                        final updatedData =
                            data.copyWith(vitals: updatedVitals);
                        ref
                            .read(googleSpeechToTextProvider.notifier)
                            .updateParsedData(updatedData);
                      },
                      isTablet,
                    ),
                    SizedBox(height: 8),
                    _buildEditableField(
                      'Blood Sugar',
                      data.vitals.bloodSugarLevel,
                      (value) {
                        final updatedVitals =
                            data.vitals.copyWith(bloodSugarLevel: value);
                        final updatedData =
                            data.copyWith(vitals: updatedVitals);
                        ref
                            .read(googleSpeechToTextProvider.notifier)
                            .updateParsedData(updatedData);
                      },
                      isTablet,
                    ),
                    SizedBox(height: 8),
                    _buildEditableField(
                      'Other',
                      data.vitals.other,
                      (value) {
                        final updatedVitals =
                            data.vitals.copyWith(other: value);
                        final updatedData =
                            data.copyWith(vitals: updatedVitals);
                        ref
                            .read(googleSpeechToTextProvider.notifier)
                            .updateParsedData(updatedData);
                      },
                      isTablet,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Temperature: ${data.vitals.temperature}',
                        style: TextStyle(fontSize: isTablet ? 14 : 12)),
                    SizedBox(height: 4),
                    Text('• Pulse: ${data.vitals.pulse}',
                        style: TextStyle(fontSize: isTablet ? 14 : 12)),
                    SizedBox(height: 4),
                    Text('• Blood Pressure: ${data.vitals.bloodPressure}',
                        style: TextStyle(fontSize: isTablet ? 14 : 12)),
                    SizedBox(height: 4),
                    Text('• Blood Sugar: ${data.vitals.bloodSugarLevel}',
                        style: TextStyle(fontSize: isTablet ? 14 : 12)),
                    SizedBox(height: 4),
                    Text('• Other: ${data.vitals.other}',
                        style: TextStyle(fontSize: isTablet ? 14 : 12)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEditableListSection(
    String title,
    IconData icon,
    List<String> items,
    Function(List<String>) onUpdate,
    bool isTablet,
  ) {
    final state = ref.watch(googleSpeechToTextProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: isTablet ? 24 : 20, color: HospitalTheme.primary),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            borderRadius: HospitalTheme.radiusSmall,
            border: Border.all(color: HospitalTheme.border),
          ),
          child: state.isEditing
              ? Column(
                  children: [
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                style: TextStyle(fontSize: isTablet ? 14 : 12),
                                onChanged: (value) {
                                  final updatedItems = List<String>.from(items);
                                  updatedItems[index] = value;
                                  onUpdate(updatedItems);
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: HospitalTheme.error, size: 20),
                              onPressed: () {
                                final updatedItems = List<String>.from(items);
                                updatedItems.removeAt(index);
                                onUpdate(updatedItems);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    ElevatedButton.icon(
                      onPressed: () {
                        final updatedItems = List<String>.from(items);
                        updatedItems.add('New item');
                        onUpdate(updatedItems);
                      },
                      icon: Icon(Icons.add, size: 16),
                      label: Text('Add Item',
                          style: TextStyle(fontSize: isTablet ? 14 : 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HospitalTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.isNotEmpty
                      ? items
                          .map((item) => Padding(
                                padding:
                                    EdgeInsets.only(bottom: isTablet ? 8 : 4),
                                child: Text(
                                  '• $item',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: HospitalTheme.textDark,
                                  ),
                                ),
                              ))
                          .toList()
                      : [
                          Text(
                            'No $title recorded',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: HospitalTheme.textMedium,
                            ),
                          ),
                        ],
                ),
        ),
      ],
    );
  }

  Widget _buildEditablePrescriptionsSection(
      List<ParsedPrescription> prescriptions, bool isTablet) {
    final state = ref.watch(googleSpeechToTextProvider);
    final data = state.parsedData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medication,
                size: isTablet ? 24 : 20, color: HospitalTheme.primary),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Prescriptions',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        if (state.isEditing && prescriptions.isNotEmpty)
          ...prescriptions.asMap().entries.map((entry) {
            final index = entry.key;
            final prescription = entry.value;
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: HospitalTheme.radiusSmall,
                border: Border.all(color: HospitalTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: prescription.medicine.name,
                          decoration: InputDecoration(
                            labelText: 'Medicine Name',
                            isDense: true,
                          ),
                          style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold),
                          onChanged: (value) {
                            final updatedMedicine =
                                prescription.medicine.copyWith(name: value);
                            final updatedPrescription = prescription.copyWith(
                                medicine: updatedMedicine);
                            final updatedPrescriptions =
                                List<ParsedPrescription>.from(prescriptions);
                            updatedPrescriptions[index] = updatedPrescription;
                            final updatedData = data.copyWith(
                                prescriptions: updatedPrescriptions);
                            ref
                                .read(googleSpeechToTextProvider.notifier)
                                .updateParsedData(updatedData);
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: HospitalTheme.error),
                        onPressed: () {
                          final updatedPrescriptions =
                              List<ParsedPrescription>.from(prescriptions);
                          updatedPrescriptions.removeAt(index);
                          final updatedData = data.copyWith(
                              prescriptions: updatedPrescriptions);
                          ref
                              .read(googleSpeechToTextProvider.notifier)
                              .updateParsedData(updatedData);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: prescription.medicine.morning,
                          decoration: InputDecoration(
                            labelText: 'Morning',
                            isDense: true,
                          ),
                          style: TextStyle(fontSize: isTablet ? 14 : 12),
                          onChanged: (value) {
                            final updatedMedicine =
                                prescription.medicine.copyWith(morning: value);
                            final updatedPrescription = prescription.copyWith(
                                medicine: updatedMedicine);
                            final updatedPrescriptions =
                                List<ParsedPrescription>.from(prescriptions);
                            updatedPrescriptions[index] = updatedPrescription;
                            final updatedData = data.copyWith(
                                prescriptions: updatedPrescriptions);
                            ref
                                .read(googleSpeechToTextProvider.notifier)
                                .updateParsedData(updatedData);
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: prescription.medicine.afternoon,
                          decoration: InputDecoration(
                            labelText: 'Afternoon',
                            isDense: true,
                          ),
                          style: TextStyle(fontSize: isTablet ? 14 : 12),
                          onChanged: (value) {
                            final updatedMedicine = prescription.medicine
                                .copyWith(afternoon: value);
                            final updatedPrescription = prescription.copyWith(
                                medicine: updatedMedicine);
                            final updatedPrescriptions =
                                List<ParsedPrescription>.from(prescriptions);
                            updatedPrescriptions[index] = updatedPrescription;
                            final updatedData = data.copyWith(
                                prescriptions: updatedPrescriptions);
                            ref
                                .read(googleSpeechToTextProvider.notifier)
                                .updateParsedData(updatedData);
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: prescription.medicine.night,
                          decoration: InputDecoration(
                            labelText: 'Night',
                            isDense: true,
                          ),
                          style: TextStyle(fontSize: isTablet ? 14 : 12),
                          onChanged: (value) {
                            final updatedMedicine =
                                prescription.medicine.copyWith(night: value);
                            final updatedPrescription = prescription.copyWith(
                                medicine: updatedMedicine);
                            final updatedPrescriptions =
                                List<ParsedPrescription>.from(prescriptions);
                            updatedPrescriptions[index] = updatedPrescription;
                            final updatedData = data.copyWith(
                                prescriptions: updatedPrescriptions);
                            ref
                                .read(googleSpeechToTextProvider.notifier)
                                .updateParsedData(updatedData);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    initialValue: prescription.medicine.comment,
                    decoration: InputDecoration(
                      labelText: 'Comment',
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: isTablet ? 14 : 12),
                    maxLines: 2,
                    onChanged: (value) {
                      final updatedMedicine =
                          prescription.medicine.copyWith(comment: value);
                      final updatedPrescription =
                          prescription.copyWith(medicine: updatedMedicine);
                      final updatedPrescriptions =
                          List<ParsedPrescription>.from(prescriptions);
                      updatedPrescriptions[index] = updatedPrescription;
                      final updatedData =
                          data.copyWith(prescriptions: updatedPrescriptions);
                      ref
                          .read(googleSpeechToTextProvider.notifier)
                          .updateParsedData(updatedData);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        if (state.isEditing)
          ElevatedButton.icon(
            onPressed: () {
              final newPrescription = ParsedPrescription(
                medicine: ParsedMedicine(
                  name: 'New Medicine',
                  morning: '',
                  afternoon: '',
                  night: '',
                  comment: '',
                ),
              );
              final updatedPrescriptions =
                  List<ParsedPrescription>.from(prescriptions);
              updatedPrescriptions.add(newPrescription);
              final updatedData =
                  data.copyWith(prescriptions: updatedPrescriptions);
              ref
                  .read(googleSpeechToTextProvider.notifier)
                  .updateParsedData(updatedData);
            },
            icon: Icon(Icons.add, size: 16),
            label: Text('Add Prescription',
                style: TextStyle(fontSize: isTablet ? 14 : 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        if (!state.isEditing)
          prescriptions.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: HospitalTheme.surfaceLight,
                    borderRadius: HospitalTheme.radiusSmall,
                    border: Border.all(color: HospitalTheme.border),
                  ),
                  child: Text(
                    'No prescriptions recorded',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                )
              : Column(
                  children: prescriptions
                      .map((prescription) => Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: HospitalTheme.surfaceLight,
                              borderRadius: HospitalTheme.radiusSmall,
                              border: Border.all(color: HospitalTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prescription.medicine.name,
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: HospitalTheme.textDark,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 8 : 4),
                                if (prescription.medicine.morning.isNotEmpty)
                                  Text(
                                      'Morning: ${prescription.medicine.morning}',
                                      style: TextStyle(
                                          fontSize: isTablet ? 14 : 12)),
                                if (prescription.medicine.afternoon.isNotEmpty)
                                  Text(
                                      'Afternoon: ${prescription.medicine.afternoon}',
                                      style: TextStyle(
                                          fontSize: isTablet ? 14 : 12)),
                                if (prescription.medicine.night.isNotEmpty)
                                  Text('Night: ${prescription.medicine.night}',
                                      style: TextStyle(
                                          fontSize: isTablet ? 14 : 12)),
                                if (prescription
                                    .medicine.comment.isNotEmpty) ...[
                                  SizedBox(height: isTablet ? 8 : 4),
                                  Text(
                                    'Comment: ${prescription.medicine.comment}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      fontStyle: FontStyle.italic,
                                      color: HospitalTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ))
                      .toList(),
                ),
      ],
    );
  }

  Widget _buildEditableField(
    String label,
    String value,
    Function(String) onChanged,
    bool isTablet,
  ) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: TextStyle(fontSize: isTablet ? 14 : 12),
      onChanged: onChanged,
    );
  }
}
