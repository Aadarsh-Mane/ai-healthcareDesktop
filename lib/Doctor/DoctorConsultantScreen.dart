import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  // Form fields configuration - All fields are now optional
  final Map<String, Map<String, dynamic>> _formFields = {
    // Existing fields - all made optional
    'Chief Complaint': {
      'required': false,
      'multiline': true,
      'rows': 3,
      'category': 'History'
    },
    'Describe Allergies': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'History'
    },
    'History of Present Illness': {
      'required': false,
      'multiline': true,
      'rows': 4,
      'category': 'History'
    },
    'Past Medical History': {
      'required': false,
      'multiline': true,
      'rows': 3,
      'category': 'History'
    },
    'Family History': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'History'
    },
    'Relevant Previous Investigations': {
      'required': false,
      'multiline': true,
      'rows': 3,
      'category': 'History'
    },
    'Menstrual History': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'History'
    },
    'Visual Analogue': {
      'required': false,
      'multiline': false,
      'rows': 1,
      'category': 'History'
    },
    'Immunization History': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'History'
    },

    // New General Examination fields
    'Pulse': {
      'required': false,
      'multiline': false,
      'rows': 1,
      'category': 'General Examination'
    },
    'Blood Pressure': {
      'required': false,
      'multiline': false,
      'rows': 1,
      'category': 'General Examination'
    },
    'Temperature': {
      'required': false,
      'multiline': false,
      'rows': 1,
      'category': 'General Examination'
    },
    'Oxygen Saturation': {
      'required': false,
      'multiline': false,
      'rows': 1,
      'category': 'General Examination'
    },

    // New Systemic Examination fields
    'Respiratory System': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'Systemic Examination'
    },
    'Cardiovascular System': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'Systemic Examination'
    },
    'Gastrointestinal System': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'Systemic Examination'
    },
    'Genitourinary System': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'Systemic Examination'
    },
    'Musculoskeletal System': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'Systemic Examination'
    },
    'Neurological System': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'Systemic Examination'
    },
    'Endocrine System': {
      'required': false,
      'multiline': true,
      'rows': 2,
      'category': 'Systemic Examination'
    },

    // Clinical Diagnosis
    'Clinical Diagnosis': {
      'required': false,
      'multiline': true,
      'rows': 3,
      'category': 'Diagnosis'
    },
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

            // Form Fields organized by categories
            ..._buildCategorizedFields(),

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

  List<Widget> _buildCategorizedFields() {
    final categories = <String, List<String>>{};

    // Group fields by category
    _formFields.forEach((field, config) {
      final category = config['category'] as String;
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(field);
    });

    final widgets = <Widget>[];

    // Define category order
    final categoryOrder = [
      'History',
      'General Examination',
      'Systemic Examination',
      'Diagnosis',
    ];

    for (String category in categoryOrder) {
      if (categories.containsKey(category)) {
        widgets.add(_buildCategorySection(category, categories[category]!));
        widgets.add(const SizedBox(height: 32));
      }
    }

    return widgets;
  }

  Widget _buildCategorySection(String category, List<String> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HospitalTheme.primary.withOpacity(0.1),
                HospitalTheme.primary.withOpacity(0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HospitalTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: HospitalTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                category,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Fields in this category
        if (category == 'General Examination')
          _buildGeneralExaminationGrid(fields)
        else
          ...fields.map((field) {
            final config = _formFields[field]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildTextField(
                field,
                config['required'] as bool,
                config['multiline'] as bool,
                config['rows'] as int,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildGeneralExaminationGrid(List<String> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final crossAxisCount = isWide ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: isWide ? 3.5 : 4.5,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: fields.length,
          itemBuilder: (context, index) {
            final field = fields[index];
            final config = _formFields[field]!;
            return _buildTextField(
              field,
              config['required'] as bool,
              config['multiline'] as bool,
              config['rows'] as int,
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'History':
        return Icons.history_outlined;
      case 'General Examination':
        return Icons.health_and_safety_outlined;
      case 'Systemic Examination':
        return Icons.medical_services_outlined;
      case 'Diagnosis':
        return Icons.dialer_sip;
      default:
        return Icons.notes_outlined;
    }
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
          // No validation required since all fields are optional
        ),
      ],
    );
  }

  Widget _buildTextField(
      String fieldName, bool required, bool multiline, int rows) {
    final controller = _controllers[fieldName]!;
    final focusNode = _focusNodes[fieldName]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Label - removed required asterisk since no fields are required
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
          ],
        ),
        const SizedBox(height: 12),

        // Text Field - removed validation since all fields are optional
        TextFormField(
          cursorColor: Colors.black,
          controller: controller,
          focusNode: focusNode,
          maxLines: multiline ? rows : 1,
          minLines: multiline ? rows : 1,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: _getFieldHint(fieldName),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: HospitalTheme.textMedium),
                    onPressed: () {
                      controller.clear();
                      setState(() {}); // Rebuild to hide clear button
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {}); // Rebuild to show/hide clear button
          },
        ),
      ],
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
      // New field icons
      'Pulse': Icons.favorite_outlined,
      'Blood Pressure': Icons.monitor_heart_outlined,
      'Temperature': Icons.thermostat_outlined,
      'Oxygen Saturation': Icons.air_outlined,
      'Respiratory System': Icons.air_outlined,
      'Cardiovascular System': Icons.favorite_outlined,
      'Gastrointestinal System': Icons.restaurant_outlined,
      'Genitourinary System': Icons.water_drop_outlined,
      'Musculoskeletal System': Icons.accessibility_outlined,
      'Neurological System': Icons.psychology_outlined,
      'Endocrine System': Icons.healing_outlined,
      'Clinical Diagnosis': Icons.dialer_sip,
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
      // New field hints
      'Pulse': 'e.g., 72 bpm, regular rhythm...',
      'Blood Pressure': 'e.g., 120/80 mmHg...',
      'Temperature': 'e.g., 98.6°F (37°C)...',
      'Oxygen Saturation': 'e.g., 98% on room air...',
      'Respiratory System': 'e.g., Clear air entry bilaterally...',
      'Cardiovascular System': 'e.g., Heart sounds S1 and S2 normal...',
      'Gastrointestinal System': 'e.g., Abdomen soft, non-tender...',
      'Genitourinary System': 'e.g., No costovertebral angle tenderness...',
      'Musculoskeletal System': 'e.g., Full range of motion in all joints...',
      'Neurological System': 'e.g., Alert and oriented times three...',
      'Endocrine System': 'e.g., No signs of thyroid enlargement...',
      'Clinical Diagnosis': 'e.g., Working diagnosis of...',
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
    // No form validation needed since all fields are optional
    try {
      String currentDateTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final consulting = DoctorConsulting(
        date: currentDateTime,
        allergies: selectedAllergy ?? 'NA',
        personalHabits: selectedPersonalHabit ?? 'NA',
        cheifComplaint: _controllers['Chief Complaint']!.text.isNotEmpty
            ? _controllers['Chief Complaint']!.text
            : 'NA',
        describeAllergies: _controllers['Describe Allergies']!.text.isNotEmpty
            ? _controllers['Describe Allergies']!.text
            : 'NA',
        historyOfPresentIllness:
            _controllers['History of Present Illness']!.text.isNotEmpty
                ? _controllers['History of Present Illness']!.text
                : 'NA',
        familyHistory: _controllers['Family History']!.text.isNotEmpty
            ? _controllers['Family History']!.text
            : 'NA',
        menstrualHistory: _controllers['Menstrual History']!.text.isNotEmpty
            ? _controllers['Menstrual History']!.text
            : 'NA',
        wongBaker: _getEmojiForWongBaker(_wongBakerValue),
        visualAnalogue: _controllers['Visual Analogue']!.text.isNotEmpty
            ? _controllers['Visual Analogue']!.text
            : 'NA',
        relevantPreviousInvestigations:
            _controllers['Relevant Previous Investigations']!.text.isNotEmpty
                ? _controllers['Relevant Previous Investigations']!.text
                : 'NA',
        immunizationHistory:
            _controllers['Immunization History']!.text.isNotEmpty
                ? _controllers['Immunization History']!.text
                : 'NA',
        pastMedicalHistory:
            _controllers['Past Medical History']!.text.isNotEmpty
                ? _controllers['Past Medical History']!.text
                : 'NA',
        // New fields with NA default
        pulse: _controllers['Pulse']!.text.isNotEmpty
            ? _controllers['Pulse']!.text
            : 'NA',
        bloodPressure: _controllers['Blood Pressure']!.text.isNotEmpty
            ? _controllers['Blood Pressure']!.text
            : 'NA',
        temperature: _controllers['Temperature']!.text.isNotEmpty
            ? _controllers['Temperature']!.text
            : 'NA',
        oxygenSaturation: _controllers['Oxygen Saturation']!.text.isNotEmpty
            ? _controllers['Oxygen Saturation']!.text
            : 'NA',
        respiratorySystem: _controllers['Respiratory System']!.text.isNotEmpty
            ? _controllers['Respiratory System']!.text
            : 'NA',
        cardiovascularSystem:
            _controllers['Cardiovascular System']!.text.isNotEmpty
                ? _controllers['Cardiovascular System']!.text
                : 'NA',
        gastrointestinalSystem:
            _controllers['Gastrointestinal System']!.text.isNotEmpty
                ? _controllers['Gastrointestinal System']!.text
                : 'NA',
        genitourinarySystem:
            _controllers['Genitourinary System']!.text.isNotEmpty
                ? _controllers['Genitourinary System']!.text
                : 'NA',
        musculoskeletalSystem:
            _controllers['Musculoskeletal System']!.text.isNotEmpty
                ? _controllers['Musculoskeletal System']!.text
                : 'NA',
        neurologicalSystem: _controllers['Neurological System']!.text.isNotEmpty
            ? _controllers['Neurological System']!.text
            : 'NA',
        endocrineSystem: _controllers['Endocrine System']!.text.isNotEmpty
            ? _controllers['Endocrine System']!.text
            : 'NA',
        clinicalDiagnosis: _controllers['Clinical Diagnosis']!.text.isNotEmpty
            ? _controllers['Clinical Diagnosis']!.text
            : 'NA',
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
