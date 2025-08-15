import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddDiagnosisDoctorScreen extends StatefulWidget {
  final String admissionId;
  final String patientId;
  final Future<void> Function(
          String admissionId, String symptomWithDateTime, String patientId)
      addDoctorDiagnosis;
  final void Function(String patientId, String admissionId)
      fetchDoctorDiagnosis;

  const AddDiagnosisDoctorScreen({
    Key? key,
    required this.admissionId,
    required this.patientId,
    required this.addDoctorDiagnosis,
    required this.fetchDoctorDiagnosis,
  }) : super(key: key);

  @override
  _AddDiagnosisDoctorScreenState createState() =>
      _AddDiagnosisDoctorScreenState();
}

class _AddDiagnosisDoctorScreenState extends State<AddDiagnosisDoctorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _symptomsController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<String> diagnosisSuggestions = [];
  List<String> selectedDiagnoses = [];
  bool isLoadingSuggestions = false;
  bool isSubmitting = false;
  String? errorMessage;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
    _fetchDiagnosisSuggestions();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchDiagnosisSuggestions() async {
    setState(() {
      isLoadingSuggestions = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
          Uri.parse('${KVM_URL}/doctors/getDiagnosis/${widget.patientId}'));
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          diagnosisSuggestions = List<String>.from(data['diagnosis'] ?? []);
        });
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() {
        diagnosisSuggestions = [];
        errorMessage = 'Failed to load AI suggestions. Please try again.';
      });
    } finally {
      setState(() {
        isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _addDiagnosis() async {
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      // Add manually typed diagnosis if it's not empty
      if (_symptomsController.text.trim().isNotEmpty) {
        final manualDiagnosis = _symptomsController.text.trim();
        if (!selectedDiagnoses.contains(manualDiagnosis)) {
          selectedDiagnoses.add(manualDiagnosis);
        }
      }

      if (selectedDiagnoses.isNotEmpty) {
        final String currentDateTime =
            DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());
        final String symptomWithDateTime =
            '${selectedDiagnoses.join(', ')} - Date: $currentDateTime';

        await widget.addDoctorDiagnosis(
          widget.admissionId,
          symptomWithDateTime,
          widget.patientId,
        );

        widget.fetchDoctorDiagnosis(widget.patientId, widget.admissionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text('Diagnosis added successfully!'),
                ],
              ),
              backgroundColor: HospitalTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: HospitalTheme.radiusSmall,
              ),
            ),
          );

          setState(() {
            selectedDiagnoses.clear();
            _symptomsController.clear();
          });
        }
      } else {
        setState(() {
          errorMessage = 'Please select or enter a diagnosis!';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to add diagnosis. Please try again.';
      });
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if ((event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _addDiagnosis();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(true);
      } else if (event.logicalKey == LogicalKeyboardKey.keyF &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _textFieldFocusNode.requestFocus();
      }
    }
  }

  Widget _buildSelectedDiagnosesSection() {
    if (selectedDiagnoses.isEmpty) return const SizedBox.shrink();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Icon(
                  Icons.checklist_rtl,
                  color: HospitalTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Selected Diagnoses (${selectedDiagnoses.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: selectedDiagnoses.map((diagnosis) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Chip(
                  label: Text(
                    diagnosis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: HospitalTheme.primary,
                  deleteIcon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.8),
                    size: 18,
                  ),
                  onDeleted: () {
                    setState(() {
                      selectedDiagnoses.remove(diagnosis);
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HospitalTheme.medical.withOpacity(0.1),
                      borderRadius: HospitalTheme.radiusSmall,
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: HospitalTheme.medical,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Diagnosis Suggestions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              HospitalTheme.buildGradientButton(
                label: 'Refresh',
                icon: Icons.refresh,
                onPressed: _fetchDiagnosisSuggestions,
                width: 120,
                isLoading: isLoadingSuggestions,
                startColor: HospitalTheme.medical,
                endColor: HospitalTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingSuggestions)
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: HospitalTheme.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing patient data...',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (errorMessage != null && diagnosisSuggestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: HospitalTheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HospitalTheme.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (diagnosisSuggestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    color: HospitalTheme.textLight,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No AI suggestions available for this patient',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: diagnosisSuggestions.length,
                  separatorBuilder: (context, index) => Divider(
                    color: HospitalTheme.border,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final diagnosis = diagnosisSuggestions[index];
                    final isSelected = selectedDiagnoses.contains(diagnosis);

                    return HospitalTheme.buildListTile(
                      title: diagnosis,
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDiagnoses.add(diagnosis);
                            } else {
                              selectedDiagnoses.remove(diagnosis);
                            }
                          });
                        },
                        activeColor: HospitalTheme.primary,
                      ),
                      isSelected: isSelected,
                      showBorder: false,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedDiagnoses.remove(diagnosis);
                          } else {
                            selectedDiagnoses.add(diagnosis);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualEntrySection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HospitalTheme.secondary.withOpacity(0.1),
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Icon(
                  Icons.edit_note,
                  color: HospitalTheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Manual Diagnosis Entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            cursorColor: Colors.black,
            controller: _symptomsController,
            focusNode: _textFieldFocusNode,
            maxLines: 3,
            decoration: InputDecoration(
              labelStyle: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
              labelText: 'Enter diagnosis manually',
              hintText: 'Type your diagnosis here... (Ctrl+F to focus)',
              prefixIcon: Icon(
                Icons.medical_information_outlined,
                color: HospitalTheme.primary,
              ),
              suffixIcon: _symptomsController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: HospitalTheme.textMedium),
                      onPressed: () {
                        _symptomsController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Press Ctrl+Enter to add diagnosis',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.error.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: HospitalTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: HospitalTheme.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: HospitalTheme.error, size: 18),
            onPressed: () => setState(() => errorMessage = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Add Diagnosis',
        actions: [
          Tooltip(
            message: 'Keyboard Shortcuts',
            child: IconButton(
              icon: Icon(Icons.keyboard, color: HospitalTheme.primary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Keyboard Shortcuts'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShortcutItem('Ctrl + Enter', 'Add diagnosis'),
                        _buildShortcutItem('Ctrl + F', 'Focus input field'),
                        _buildShortcutItem('Escape', 'Close screen'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyPress,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1000 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HospitalTheme.primary.withOpacity(0.1),
                          HospitalTheme.primaryLight.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: HospitalTheme.radiusMedium,
                      border: Border.all(
                        color: HospitalTheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: HospitalTheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient ID: ${widget.patientId}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            Text(
                              'Admission ID: ${widget.admissionId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Section
                  _buildErrorSection(),

                  // Selected Diagnoses
                  _buildSelectedDiagnosesSection(),
                  if (selectedDiagnoses.isNotEmpty) const SizedBox(height: 24),

                  // Layout based on screen size
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildAISuggestionsSection(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildManualEntrySection(),
                              const SizedBox(height: 24),
                              _buildActionButtons(context),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildAISuggestionsSection(),
                        const SizedBox(height: 24),
                        _buildManualEntrySection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(context),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: HospitalTheme.buildGradientButton(
              label: isSubmitting ? 'Adding...' : 'Add Diagnosis',
              icon: isSubmitting ? Icons.hourglass_empty : Icons.add_circle,
              onPressed: isSubmitting ? () {} : _addDiagnosis,
              width: double.infinity,
              height: 48,
              isLoading: isSubmitting,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Patient'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: HospitalTheme.textMedium),
                foregroundColor: HospitalTheme.textMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: HospitalTheme.radiusSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
