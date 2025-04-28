// lib/Doctor/CreateInvestigationScreen.dart

import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/model/getInvestigationModel.dart';
import 'package:doctordesktop/repositories/investigation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';

class CreateInvestigationScreen extends StatefulWidget {
  final String? patientId; // Optional - if coming from patient profile
  final String? admissionId; // Optional - if coming from admission screen

  const CreateInvestigationScreen({
    Key? key,
    this.patientId,
    this.admissionId,
  }) : super(key: key);

  @override
  _CreateInvestigationScreenState createState() =>
      _CreateInvestigationScreenState();
}

class _CreateInvestigationScreenState extends State<CreateInvestigationScreen> {
  final InvestigationRepository _repository = InvestigationRepository();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _admissionIdController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _clinicalHistoryController =
      TextEditingController();
  final TextEditingController _investigationDetailsController =
      TextEditingController();
  final TextEditingController _otherTypeController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  // Form values
  String _selectedInvestigationType = 'CT Scan';
  String _selectedPriority = 'Routine';
  DateTime _scheduledDateTime = DateTime.now().add(Duration(days: 1));
  List<String> _tags = [];

  // State variables
  bool _isSubmitting = false;
  bool _isOtherType = false;
  String? _errorMessage;

  // Investigation type options from schema
  final List<String> _investigationTypes = [
    'X-Ray',
    'MRI',
    'CT Scan',
    'Ultrasound',
    'CT PNS',
    'Nasal Endoscopy',
    'Laryngoscopy',
    'Glucose Tolerance Test',
    'DEXA Scan',
    'VEP',
    'SSEP',
    'BAER',
    'Breath Test',
    'Blood Test',
    'Urine Test',
    'Other',
  ];

  // Priority options from schema
  final List<String> _priorityOptions = [
    'Routine',
    'Urgent',
    'STAT',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with patientId and admissionId if provided
    if (widget.patientId != null) {
      _patientIdController.text = widget.patientId!;
    }
    if (widget.admissionId != null) {
      _admissionIdController.text = widget.admissionId!;
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _admissionIdController.dispose();
    _reasonController.dispose();
    _clinicalHistoryController.dispose();
    _investigationDetailsController.dispose();
    _otherTypeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _updateTags(String value) {
    setState(() {
      // Split by commas and remove any empty strings
      _tags = value
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final request = CreateInvestigationRequest(
        patientId: _patientIdController.text,
        admissionId: _admissionIdController.text,
        investigationType: _selectedInvestigationType,
        reasonForInvestigation: _reasonController.text,
        priority: _selectedPriority,
        scheduledDate: _scheduledDateTime.toUtc().toIso8601String(),
        clinicalHistory: _clinicalHistoryController.text,
        investigationDetails: _investigationDetailsController.text,
        tags: _tags,
        otherInvestigationType: _isOtherType ? _otherTypeController.text : null,
      );

      final response = await _repository.createInvestigation(request);

      // Show success message and close screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Investigation created successfully'),
          backgroundColor: HospitalTheme.success,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create investigation: ${e.toString()}'),
          backgroundColor: HospitalTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Create New Investigation',
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: HospitalTheme.background,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and description
                      Text(
                        'New Investigation Request',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fill in the details below to create a new investigation request',
                        style: TextStyle(
                          color: HospitalTheme.textMedium,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Patient and Admission IDs
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _patientIdController,
                              label: 'Patient ID',
                              hint: 'Enter patient ID',
                              prefixIcon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Patient ID is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _admissionIdController,
                              label: 'Admission ID',
                              hint: 'Enter admission ID',
                              prefixIcon: Icons.assignment_ind,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Admission ID is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Investigation Type and Priority
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Investigation Type',
                              value: _selectedInvestigationType,
                              items: _investigationTypes,
                              onChanged: (value) {
                                setState(() {
                                  _selectedInvestigationType =
                                      value ?? 'CT Scan';
                                  _isOtherType =
                                      _selectedInvestigationType == 'Other';
                                });
                              },
                              prefixIcon: Icons.science,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Priority',
                              value: _selectedPriority,
                              items: _priorityOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value ?? 'Routine';
                                });
                              },
                              prefixIcon: Icons.priority_high,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Other investigation type field (conditional)
                      if (_isOtherType) ...[
                        _buildTextField(
                          controller: _otherTypeController,
                          label: 'Specify Investigation Type',
                          hint: 'Enter custom investigation type',
                          prefixIcon: Icons.science,
                          validator: (value) {
                            if (_isOtherType &&
                                (value == null || value.isEmpty)) {
                              return 'Please specify the investigation type';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                      ],

                      // Scheduled Date and Time
                      _buildDateTimeField(
                        label: 'Scheduled Date & Time',
                        value: _scheduledDateTime,
                        onChanged: (dateTime) {
                          setState(() {
                            _scheduledDateTime = dateTime;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Reason for Investigation
                      _buildTextField(
                        controller: _reasonController,
                        label: 'Reason for Investigation',
                        hint: 'Why is this investigation needed?',
                        prefixIcon: Icons.help_outline,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Reason is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Clinical History
                      _buildTextField(
                        controller: _clinicalHistoryController,
                        label: 'Clinical History',
                        hint: 'Enter relevant clinical history',
                        prefixIcon: Icons.history,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Clinical history is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Investigation Details
                      _buildTextField(
                        controller: _investigationDetailsController,
                        label: 'Investigation Details',
                        hint: 'Specific details (e.g., CBC, CRP, ESR)',
                        prefixIcon: Icons.description,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Investigation details are required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Tags
                      _buildTextField(
                        controller: _tagsController,
                        label: 'Tags (comma separated)',
                        hint: 'e.g., cancer, blood, infection',
                        prefixIcon: Icons.tag,
                        onChanged: _updateTags,
                      ),
                      SizedBox(height: 8),

                      // Tags preview
                      if (_tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: HospitalTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: HospitalTheme.border),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: HospitalTheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Error message (if any)
                      if (_errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HospitalTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: HospitalTheme.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: HospitalTheme.error),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: HospitalTheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ],

                      // Submit and Cancel buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              side: BorderSide(color: HospitalTheme.primary),
                            ),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 24),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HospitalTheme.primary,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                            ),
                            child: _isSubmitting
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Creating...'),
                                    ],
                                  )
                                : Text('Create Investigation'),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: HospitalTheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: HospitalTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: HospitalTheme.error),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
            color: Colors.white,
          ),
          child: Row(
            children: [
              SizedBox(width: 12),
              Icon(prefixIcon, color: HospitalTheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down,
                        color: HospitalTheme.primary),
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Show date picker
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: HospitalTheme.primary,
                      onPrimary: HospitalTheme.textOnPrimary,
                      onSurface: HospitalTheme.textDark,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null) {
              // Show time picker after date is selected
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(value),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: HospitalTheme.primary,
                        onPrimary: HospitalTheme.textOnPrimary,
                        onSurface: HospitalTheme.textDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedTime != null) {
                // Combine date and time into a single DateTime
                final newDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );

                onChanged(newDateTime);
              }
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.border),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: HospitalTheme.primary),
                SizedBox(width: 12),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(value),
                  style: TextStyle(
                    fontSize: 16,
                    color: HospitalTheme.textDark,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down, color: HospitalTheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
