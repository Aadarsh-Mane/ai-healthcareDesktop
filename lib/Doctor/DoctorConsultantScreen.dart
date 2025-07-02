import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// AI Suggestion Service
// AI Suggestion Service - UPDATED
class AIConsultingService {
  static const String _apiKey = 'AIzaSyBzHQvf_-z28gTf0poC2s8bvt83mingpHc';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<List<String>> getSuggestions(String fieldType,
      String currentInput, Map<String, String> context) async {
    try {
      final prompt = _buildMedicalPrompt(fieldType, currentInput, context);

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 3,
            'topP': 0.8,
            'maxOutputTokens': 500,
          }
        }),
      );

      print('AI Suggestion Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        return _parseSuggestions(content);
      } else {
        print('AI Suggestion Error: ${response.body}');
      }
    } catch (e) {
      print('AI Suggestion Error: $e');
    }
    return _getFallbackSuggestions(fieldType);
  }

  static String _buildMedicalPrompt(
      String fieldType, String currentInput, Map<String, String> context) {
    // Extract relevant context
    String allergyContext = context['allergies'] ?? '';
    String habitsContext = context['personalHabits'] ?? '';
    String chiefComplaint = context['Chief Complaint'] ?? '';

    String basePrompt = '''
You are a medical AI assistant helping doctors with clinical documentation. 
Based on the field "${fieldType}" and current input "${currentInput}", provide exactly 3-5 medically accurate suggestions.

Patient Context:
- Known Allergies: ${allergyContext.isNotEmpty ? allergyContext : 'Not specified'}
- Personal Habits: ${habitsContext.isNotEmpty ? habitsContext : 'Not specified'}
- Chief Complaint: ${chiefComplaint.isNotEmpty ? chiefComplaint : 'Not specified'}

Instructions:
- Provide complete, professional medical phrases
- Use appropriate medical terminology
- Each suggestion should be 1-2 sentences maximum
- Format each suggestion on a new line
- No numbering, bullets, or formatting
- Focus on common clinical scenarios
- Make suggestions contextually relevant

Field: ${fieldType}
Current input: "${currentInput}"

Medical suggestions:''';

    return basePrompt;
  }

  static List<String> _parseSuggestions(String content) {
    return content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .take(5)
        .toList();
  }

  static List<String> _getFallbackSuggestions(String fieldType) {
    final fallbacks = {
      'Chief Complaint': [
        'Patient presents with acute onset chest pain radiating to left arm',
        'Patient complains of persistent cough with productive sputum for 2 weeks',
        'Patient reports severe headache with associated nausea and photophobia',
        'Patient experiencing progressive shortness of breath on exertion',
        'Patient presents with abdominal pain localized to right lower quadrant'
      ],
      'Describe Allergies': [
        'Patient reports rash and urticaria when exposed to penicillin',
        'Patient experiences respiratory distress with shellfish consumption',
        'Patient develops contact dermatitis with latex exposure',
        'Patient reports gastrointestinal upset with NSAIDs',
        'No known drug allergies or food intolerances reported'
      ],
      'History of Present Illness': [
        'Symptoms began gradually over the past 3-4 days without precipitating factors',
        'Pain described as sharp, stabbing, and intermittent in nature',
        'No associated fever, chills, night sweats, or weight loss',
        'Symptoms worsen with physical activity and improve with rest',
        'Patient denies any recent trauma, travel, or sick contacts'
      ],
      'Past Medical History': [
        'No significant past medical history, no previous hospitalizations',
        'History of hypertension well controlled on ACE inhibitors',
        'Previous appendectomy in childhood without complications',
        'Type 2 diabetes mellitus managed with metformin',
        'History of seasonal allergies managed with antihistamines'
      ],
      'Family History': [
        'No significant family history of cardiovascular or malignant diseases',
        'Father deceased from myocardial infarction at age 65',
        'Mother alive with history of breast cancer and diabetes',
        'Paternal grandfather with history of stroke and hypertension',
        'No known genetic disorders or hereditary conditions in family'
      ],
      'Relevant Previous Investigations': [
        'Recent CBC shows mild anemia with normal white cell count',
        'Chest X-ray from last month showed clear lung fields',
        'ECG performed shows normal sinus rhythm without abnormalities',
        'Basic metabolic panel within normal limits',
        'Urinalysis negative for protein, glucose, and blood'
      ],
      'Menstrual History': [
        'Regular menstrual cycles, 28-day cycle with 5-day duration',
        'Last menstrual period 2 weeks ago, normal flow and duration',
        'History of dysmenorrhea managed with NSAIDs',
        'Menopause at age 52, no hormone replacement therapy',
        'Gravida 2, Para 2, no history of pregnancy complications'
      ],
      'Visual Analogue': [
        'Pain scale 7/10, described as throbbing and constant',
        'Mobility limited due to pain, requires assistance with ambulation',
        'Pain partially relieved with rest and elevation',
        'Visual analog scale 4/10 with current pain medication',
        'Pain intensity varies from 3-8/10 throughout the day'
      ],
      'Immunization History': [
        'Up to date with routine adult vaccinations including tetanus',
        'COVID-19 vaccination completed with booster received',
        'Annual influenza vaccination received last season',
        'Childhood immunizations completed per schedule',
        'Hepatitis B vaccination series completed for occupational exposure'
      ],
    };

    return fallbacks[fieldType] ??
        [
          'No specific suggestions available for this field',
          'Please consult medical guidelines for appropriate content',
          'Consider patient-specific factors when documenting'
        ];
  }
}

// Suggestion Provider
final suggestionProvider =
    StateNotifierProvider.family<SuggestionNotifier, List<String>, String>(
  (ref, fieldType) => SuggestionNotifier(fieldType),
);

class SuggestionNotifier extends StateNotifier<List<String>> {
  final String fieldType;

  SuggestionNotifier(this.fieldType) : super([]);

  Future<void> getSuggestions(
      String currentInput, Map<String, String> context) async {
    if (currentInput.trim().isEmpty) {
      state = [];
      return;
    }

    final suggestions = await AIConsultingService.getSuggestions(
        fieldType, currentInput, context);
    state = suggestions;
  }

  void clearSuggestions() {
    state = [];
  }
}

class EnhancedDoctorConsultingScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const EnhancedDoctorConsultingScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedDoctorConsultingScreen> createState() =>
      _EnhancedDoctorConsultingScreenState();
}

class _EnhancedDoctorConsultingScreenState
    extends ConsumerState<EnhancedDoctorConsultingScreen> {
  final doctor = DoctorRepository();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _controllers = <String, TextEditingController>{};

  // Focus nodes
  final _focusNodes = <String, FocusNode>{};

  // Dropdown values
  String? selectedAllergy;
  String? selectedPersonalHabit;
  double _wongBakerValue = 5;

  // Form fields configuration
  final Map<String, Map<String, dynamic>> _formFields = {
    'Chief Complaint': {'required': true, 'multiline': true, 'rows': 3},
    'Describe Allergies': {'required': false, 'multiline': true, 'rows': 2},
    'History of Present Illness': {
      'required': true,
      'multiline': true,
      'rows': 4
    },
    'Past Medical History': {'required': true, 'multiline': true, 'rows': 3},
    'Family History': {'required': true, 'multiline': true, 'rows': 2},
    'Relevant Previous Investigations': {
      'required': false,
      'multiline': true,
      'rows': 3
    },
    'Menstrual History': {'required': false, 'multiline': true, 'rows': 2},
    'Visual Analogue': {'required': false, 'multiline': false, 'rows': 1},
    'Immunization History': {'required': false, 'multiline': true, 'rows': 2},
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (String field in _formFields.keys) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _contextData => {
        'allergies': selectedAllergy ?? '',
        'personalHabits': selectedPersonalHabit ?? '',
        'patientId': widget.patientId,
        'admissionId': widget.admissionId,
        ..._controllers
            .map((key, controller) => MapEntry(key, controller.text)),
      };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Doctor Consultation',
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveDraft,
            tooltip: 'Save Draft',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Row(
          children: [
            // Main Form Area
            Expanded(
              flex: isWideScreen ? 3 : 4,
              child: _buildFormSection(),
            ),
            // Right Panel for Quick Actions (only on wide screens)
            if (isWideScreen)
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: HospitalTheme.cardBackground,
                  border: Border(
                    left: BorderSide(color: HospitalTheme.border),
                  ),
                ),
                child: _buildQuickActionsPanel(),
              ),
          ],
        ),
      ),
      floatingActionButton: HospitalTheme.buildFloatingActionButton(
        icon: Icons.check,
        onPressed: _submitForm,
        tooltip: 'Submit Consultation',
      ),
    );
  }

  Widget _buildFormSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HospitalTheme.buildSectionHeader('Patient Consultation Form'),
            const SizedBox(height: 24),

            // Patient Info Summary
            _buildPatientSummaryCard(),
            const SizedBox(height: 32),

            // Dropdown Fields Row
            _buildDropdownSection(),
            const SizedBox(height: 32),

            // Form Fields
            ..._formFields.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildEnhancedTextField(
                  entry.key,
                  entry.value['required'] as bool,
                  entry.value['multiline'] as bool,
                  entry.value['rows'] as int,
                ),
              );
            }).toList(),

            // Wong Baker Scale
            _buildWongBakerSection(),
            const SizedBox(height: 40),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSummaryCard() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: HospitalTheme.primary),
              const SizedBox(width: 12),
              Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                    Text(
                      widget.patientId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admission ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                    Text(
                      widget.admissionId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
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

  Widget _buildDropdownSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            'Known Allergies',
            selectedAllergy,
            ['Drugs', 'Food', 'Latex', 'Dye', 'Contrast', 'Other', 'None'],
            (value) => setState(() => selectedAllergy = value),
            Icons.warning_amber_outlined,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildDropdownField(
            'Personal Habits',
            selectedPersonalHabit,
            ['Smoking', 'Alcohol', 'Chewing Tobacco', 'Multiple', 'None'],
            (value) => setState(() => selectedPersonalHabit = value),
            Icons.psychology_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: HospitalTheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          decoration: InputDecoration(
            hintText: 'Select $label',
            prefixIcon: Icon(icon, color: HospitalTheme.primary),
          ),
          validator: (val) => val == null ? 'Please select $label' : null,
        ),
      ],
    );
  }

  Widget _buildEnhancedTextField(
      String fieldName, bool required, bool multiline, int rows) {
    final controller = _controllers[fieldName]!;
    final focusNode = _focusNodes[fieldName]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Label
        Row(
          children: [
            Icon(
              _getFieldIcon(fieldName),
              size: 20,
              color: HospitalTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              fieldName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textDark,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  color: HospitalTheme.error,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Enhanced Text Field with AI Suggestions
        _buildAIEnhancedTextField(
          controller: controller,
          focusNode: focusNode,
          fieldName: fieldName,
          multiline: multiline,
          rows: rows,
          required: required,
        ),
      ],
    );
  }

  Widget _buildAIEnhancedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String fieldName,
    required bool multiline,
    required int rows,
    required bool required,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final suggestions = ref.watch(suggestionProvider(fieldName));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Field
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.tab) {
                  if (suggestions.isNotEmpty) {
                    controller.text = suggestions.first;
                    ref
                        .read(suggestionProvider(fieldName).notifier)
                        .clearSuggestions();
                  }
                }
              },
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                maxLines: multiline ? rows : 1,
                minLines: multiline ? rows : 1,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: _getFieldHint(fieldName),
                  suffixIcon: controller.text.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.auto_awesome,
                                  color: HospitalTheme.accent),
                              onPressed: () => _triggerAISuggestions(fieldName),
                              tooltip: 'Get AI Suggestions',
                            ),
                            IconButton(
                              icon: Icon(Icons.clear,
                                  color: HospitalTheme.textMedium),
                              onPressed: () {
                                controller.clear();
                                ref
                                    .read(
                                        suggestionProvider(fieldName).notifier)
                                    .clearSuggestions();
                              },
                            ),
                          ],
                        )
                      : IconButton(
                          icon: Icon(Icons.auto_awesome,
                              color: HospitalTheme.accent),
                          onPressed: () => _triggerAISuggestions(fieldName),
                          tooltip: 'Get AI Suggestions',
                        ),
                ),
                onChanged: (value) {
                  if (value.length > 3) {
                    _triggerAISuggestions(fieldName);
                  } else {
                    ref
                        .read(suggestionProvider(fieldName).notifier)
                        .clearSuggestions();
                  }
                },
                validator: (value) {
                  if (required && (value == null || value.trim().isEmpty)) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
            ),

            // AI Suggestions
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: HospitalTheme.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 16, color: HospitalTheme.accent),
                          const SizedBox(width: 8),
                          Text(
                            'AI Suggestions (Press Tab to use first)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HospitalTheme.accent,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 16),
                            onPressed: () => ref
                                .read(suggestionProvider(fieldName).notifier)
                                .clearSuggestions(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          return _buildSuggestionItem(
                            suggestions[index],
                            index == 0,
                            () {
                              controller.text = suggestions[index];
                              ref
                                  .read(suggestionProvider(fieldName).notifier)
                                  .clearSuggestions();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSuggestionItem(
      String suggestion, bool isFirst, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isFirst ? HospitalTheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
          border: isFirst
              ? Border.all(color: HospitalTheme.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            if (isFirst) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'TAB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textDark,
                  fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              size: 16,
              color: HospitalTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _triggerAISuggestions(String fieldName) {
    ref.read(suggestionProvider(fieldName).notifier).getSuggestions(
          _controllers[fieldName]!.text,
          _contextData,
        );
  }

  Widget _buildWongBakerSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sentiment_satisfied_outlined,
                  color: HospitalTheme.primary),
              const SizedBox(width: 12),
              Text(
                'Wong Baker Faces Scale',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: HospitalTheme.primary,
              inactiveTrackColor: HospitalTheme.border,
              thumbColor: HospitalTheme.primary,
              overlayColor: HospitalTheme.primary.withOpacity(0.2),
              valueIndicatorColor: HospitalTheme.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: _wongBakerValue,
              min: 1,
              max: 10,
              divisions: 9,
              label: _wongBakerValue.round().toString(),
              onChanged: (value) => setState(() => _wongBakerValue = value),
            ),
          ),

          // Emoji Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _getEmojiForWongBaker(_wongBakerValue),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pain Level: ${_wongBakerValue.round()}/10',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                Text(
                  _getPainDescription(_wongBakerValue),
                  style: TextStyle(
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

  Widget _buildQuickActionsPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),

          // Common Templates
          _buildQuickActionCard(
            'Common Templates',
            Icons.library_books_outlined,
            [
              'Load routine checkup template',
              'Load emergency template',
              'Load follow-up template',
            ],
          ),
          const SizedBox(height: 16),

          // Medical References
          _buildQuickActionCard(
            'Medical References',
            Icons.book_outlined,
            [
              'ICD-10 codes',
              'Drug interactions',
              'Normal ranges',
            ],
          ),
          const SizedBox(height: 16),

          // Voice Commands
          _buildQuickActionCard(
            'Voice Commands',
            Icons.mic_outlined,
            [
              'Start voice dictation',
              'Voice to text',
              'Audio notes',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, List<String> actions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: HospitalTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actions
              .map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _handleQuickAction(action),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_forward_ios,
                              size: 12, color: HospitalTheme.textMedium),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action,
                              style: TextStyle(
                                fontSize: 13,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: HospitalTheme.primary),
              foregroundColor: HospitalTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Submit Consultation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  IconData _getFieldIcon(String fieldName) {
    final icons = {
      'Chief Complaint': Icons.medical_information_outlined,
      'Describe Allergies': Icons.warning_amber_outlined,
      'History of Present Illness': Icons.history_outlined,
      'Past Medical History': Icons.folder_outlined,
      'Family History': Icons.family_restroom_outlined,
      'Relevant Previous Investigations': Icons.science_outlined,
      'Menstrual History': Icons.calendar_month_outlined,
      'Visual Analogue': Icons.visibility_outlined,
      'Immunization History': Icons.vaccines_outlined,
    };
    return icons[fieldName] ?? Icons.notes_outlined;
  }

  String _getFieldHint(String fieldName) {
    final hints = {
      'Chief Complaint': 'Enter the main reason for the visit...',
      'Describe Allergies': 'Describe any allergic reactions...',
      'History of Present Illness': 'Describe the current illness timeline...',
      'Past Medical History': 'List previous medical conditions...',
      'Family History': 'Describe relevant family medical history...',
      'Relevant Previous Investigations': 'List relevant tests and results...',
      'Menstrual History': 'Enter menstrual cycle details if applicable...',
      'Visual Analogue': 'Enter visual assessment details...',
      'Immunization History': 'List vaccination history...',
    };
    return hints[fieldName] ?? 'Enter details...';
  }

  String _getEmojiForWongBaker(double value) {
    if (value <= 2) return '😭';
    if (value <= 4) return '😢';
    if (value <= 6) return '😐';
    if (value <= 8) return '🙂';
    return '😊';
  }

  String _getPainDescription(double value) {
    if (value <= 2) return 'Severe Pain';
    if (value <= 4) return 'Moderate Pain';
    if (value <= 6) return 'Mild Pain';
    if (value <= 8) return 'Slight Discomfort';
    return 'No Pain';
  }

  void _handleQuickAction(String action) {
    // Implement quick action functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quick Action: $action')),
    );
  }

  void _saveDraft() {
    // Implement save draft functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: HospitalTheme.success,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String currentDateTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        final consulting = DoctorConsulting(
          date: currentDateTime,
          allergies: selectedAllergy ?? '',
          personalHabits: selectedPersonalHabit ?? '',
          cheifComplaint: _controllers['Chief Complaint']!.text,
          describeAllergies: _controllers['Describe Allergies']!.text,
          historyOfPresentIllness:
              _controllers['History of Present Illness']!.text,
          familyHistory: _controllers['Family History']!.text,
          menstrualHistory: _controllers['Menstrual History']!.text,
          wongBaker: _getEmojiForWongBaker(_wongBakerValue),
          visualAnalogue: _controllers['Visual Analogue']!.text,
          relevantPreviousInvestigations:
              _controllers['Relevant Previous Investigations']!.text,
          immunizationHistory: _controllers['Immunization History']!.text,
          pastMedicalHistory: _controllers['Past Medical History']!.text,
        );

        await doctor.addDoctorConsultant(
            widget.patientId, widget.admissionId, consulting);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consultation submitted successfully'),
              backgroundColor: HospitalTheme.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: HospitalTheme.error,
            ),
          );
        }
      }
    }
  }
}
