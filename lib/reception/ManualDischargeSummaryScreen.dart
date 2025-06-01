import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import your theme
// import 'hospitalTheme.dart';

class ManualDischargeSummaryScreen extends ConsumerStatefulWidget {
  final String patientId;

  const ManualDischargeSummaryScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<ManualDischargeSummaryScreen> createState() =>
      _ManualDischargeSummaryScreenState();
}

class _ManualDischargeSummaryScreenState
    extends ConsumerState<ManualDischargeSummaryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Controllers for mandatory fields
  final TextEditingController _finalDiagnosisController =
      TextEditingController();
  final TextEditingController _conditionOnDischargeController =
      TextEditingController();

  // Controllers for optional fields
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _operationTypeController =
      TextEditingController();
  final TextEditingController _operationDateController =
      TextEditingController();
  final TextEditingController _surgeonController = TextEditingController();
  final TextEditingController _anaesthetistController = TextEditingController();
  final TextEditingController _anaesthesiaTypeController =
      TextEditingController();

  // Lists for dynamic fields
  List<TextEditingController> _complaintsControllers = [
    TextEditingController()
  ];
  List<TextEditingController> _pastHistoryControllers = [
    TextEditingController()
  ];
  List<TextEditingController> _examFindingsControllers = [
    TextEditingController()
  ];
  List<TextEditingController> _radiologyControllers = [TextEditingController()];
  List<TextEditingController> _pathologyControllers = [TextEditingController()];
  List<TextEditingController> _procedureControllers = [TextEditingController()];
  List<TextEditingController> _treatmentControllers = [TextEditingController()];

  bool _uploadToDrive = true;
  bool _isLoading = false;
  Map<String, dynamic>? _generatedResponse;

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl/Cmd + S to save
      if (event.logicalKey == LogicalKeyboardKey.keyS &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _generateDischargeSummary();
        return true;
      }
      // Ctrl/Cmd + N to add new complaint
      if (event.logicalKey == LogicalKeyboardKey.keyN &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _addComplaint();
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _scrollController.dispose();
    _finalDiagnosisController.dispose();
    _conditionOnDischargeController.dispose();
    _tempController.dispose();
    _pulseController.dispose();
    _bpController.dispose();
    _spo2Controller.dispose();
    _operationTypeController.dispose();
    _operationDateController.dispose();
    _surgeonController.dispose();
    _anaesthetistController.dispose();
    _anaesthesiaTypeController.dispose();

    // Dispose dynamic controllers
    for (var controller in _complaintsControllers) {
      controller.dispose();
    }
    for (var controller in _pastHistoryControllers) {
      controller.dispose();
    }
    for (var controller in _examFindingsControllers) {
      controller.dispose();
    }
    for (var controller in _radiologyControllers) {
      controller.dispose();
    }
    for (var controller in _pathologyControllers) {
      controller.dispose();
    }
    for (var controller in _procedureControllers) {
      controller.dispose();
    }
    for (var controller in _treatmentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addComplaint() {
    setState(() {
      _complaintsControllers.add(TextEditingController());
    });
  }

  void _removeComplaint(int index) {
    if (_complaintsControllers.length > 1) {
      setState(() {
        _complaintsControllers[index].dispose();
        _complaintsControllers.removeAt(index);
      });
    }
  }

  void _addPastHistory() {
    setState(() {
      _pastHistoryControllers.add(TextEditingController());
    });
  }

  void _removePastHistory(int index) {
    if (_pastHistoryControllers.length > 1) {
      setState(() {
        _pastHistoryControllers[index].dispose();
        _pastHistoryControllers.removeAt(index);
      });
    }
  }

  void _addExamFinding() {
    setState(() {
      _examFindingsControllers.add(TextEditingController());
    });
  }

  void _removeExamFinding(int index) {
    if (_examFindingsControllers.length > 1) {
      setState(() {
        _examFindingsControllers[index].dispose();
        _examFindingsControllers.removeAt(index);
      });
    }
  }

  void _addRadiology() {
    setState(() {
      _radiologyControllers.add(TextEditingController());
    });
  }

  void _removeRadiology(int index) {
    setState(() {
      _radiologyControllers[index].dispose();
      _radiologyControllers.removeAt(index);
    });
  }

  void _addPathology() {
    setState(() {
      _pathologyControllers.add(TextEditingController());
    });
  }

  void _removePathology(int index) {
    setState(() {
      _pathologyControllers[index].dispose();
      _pathologyControllers.removeAt(index);
    });
  }

  void _addProcedure() {
    setState(() {
      _procedureControllers.add(TextEditingController());
    });
  }

  void _removeProcedure(int index) {
    setState(() {
      _procedureControllers[index].dispose();
      _procedureControllers.removeAt(index);
    });
  }

  void _addTreatment() {
    setState(() {
      _treatmentControllers.add(TextEditingController());
    });
  }

  void _removeTreatment(int index) {
    setState(() {
      _treatmentControllers[index].dispose();
      _treatmentControllers.removeAt(index);
    });
  }

  Future<void> _generateDischargeSummary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = _buildRequestBody();
      final response = await http.post(
        Uri.parse(
            '${KVM_URL}/reception/generateManualDischargeSummary/${widget.patientId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _generatedResponse = responseData;
        });
        _showSuccessDialog(responseData);
      } else {
        _showErrorDialog('Failed to generate discharge summary');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _buildRequestBody() {
    return {
      "Final Diagnosis": _finalDiagnosisController.text.trim(),
      "Complaints": _complaintsControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      "Past History": _pastHistoryControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      "Exam Findings": _examFindingsControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      "General Exam": {
        if (_tempController.text.isNotEmpty) "Temp": _tempController.text,
        if (_pulseController.text.isNotEmpty) "Pulse": _pulseController.text,
        if (_bpController.text.isNotEmpty) "BP": _bpController.text,
        if (_spo2Controller.text.isNotEmpty) "SPO2": _spo2Controller.text,
      },
      "Radiology": _radiologyControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      "Pathology": _pathologyControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      if (_operationTypeController.text.isNotEmpty)
        "Operation": {
          "Type": _operationTypeController.text,
          if (_operationDateController.text.isNotEmpty)
            "Date": _operationDateController.text,
          if (_surgeonController.text.isNotEmpty)
            "Surgeon": _surgeonController.text,
          if (_anaesthetistController.text.isNotEmpty)
            "Anaesthetist": _anaesthetistController.text,
          if (_anaesthesiaTypeController.text.isNotEmpty)
            "Anaesthesia Type": _anaesthesiaTypeController.text,
          "Procedure": _procedureControllers
              .map((controller) => controller.text.trim())
              .where((text) => text.isNotEmpty)
              .toList(),
        },
      "Treatment Given": _treatmentControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(),
      "Condition on Discharge": _conditionOnDischargeController.text.trim(),
      "uploadToDriveFlag": _uploadToDrive,
    };
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(response['message'] ?? 'Discharge summary generated'),
              const SizedBox(height: 16),
              if (response['data'] != null) ...[
                Text('File: ${response['data']['fileName']}'),
                const SizedBox(height: 8),
                if (response['data']['driveLink'] != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Use Methods().pdfUrl(response['data']['driveLink'])
                      Methods().openPdf(response['data']['driveLink']);
                      // For now, just copying to clipboard
                      Clipboard.setData(
                          ClipboardData(text: response['data']['driveLink']));
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open PDF'),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200;

    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Manual Discharge Summary - ${widget.patientId}',
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _generateDischargeSummary,
                icon: const Icon(Icons.generating_tokens),
                label: const Text('Generate'),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Row(
          children: [
            // Main form area
            Expanded(
              flex: isTablet ? 1 : 2,
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMandatorySection(),
                      const SizedBox(height: 24),
                      _buildComplaintsSection(),
                      const SizedBox(height: 24),
                      _buildPastHistorySection(),
                      const SizedBox(height: 24),
                      _buildExamFindingsSection(),
                      const SizedBox(height: 24),
                      _buildGeneralExamSection(),
                      const SizedBox(height: 24),
                      _buildRadiologySection(),
                      const SizedBox(height: 24),
                      _buildPathologySection(),
                      const SizedBox(height: 24),
                      _buildOperationSection(),
                      const SizedBox(height: 24),
                      _buildTreatmentSection(),
                      const SizedBox(height: 24),
                      _buildUploadOptionsSection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                      const SizedBox(
                          height: 120), // Extra space for better scrolling
                    ],
                  ),
                ),
              ),
            ),

            // Right sidebar - always show on desktop
            if (!isTablet)
              Expanded(
                flex: 1,
                child: _buildRightSidebar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandatorySection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Mandatory Information *'),
          TextFormField(
            controller: _finalDiagnosisController,
            decoration: const InputDecoration(
              labelText: 'Final Diagnosis *',
              hintText: 'Enter the final diagnosis',
            ),
            validator: (value) =>
                value?.isEmpty == true ? 'Final diagnosis is required' : null,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conditionOnDischargeController,
            decoration: const InputDecoration(
              labelText: 'Condition on Discharge *',
              hintText: 'e.g., STABLE, IMPROVED, etc.',
            ),
            validator: (value) => value?.isEmpty == true
                ? 'Condition on discharge is required'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Complaints *',
            trailing: IconButton(
              onPressed: _addComplaint,
              icon: const Icon(Icons.add),
              tooltip: 'Add Complaint (Ctrl+N)',
            ),
          ),
          ..._complaintsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Complaint ${index + 1}',
                        hintText: 'Enter patient complaint',
                      ),
                      validator: index == 0
                          ? (value) => value?.isEmpty == true
                              ? 'At least one complaint is required'
                              : null
                          : null,
                      maxLines: 2,
                    ),
                  ),
                  if (_complaintsControllers.length > 1)
                    IconButton(
                      onPressed: () => _removeComplaint(index),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPastHistorySection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Past History',
            trailing: IconButton(
              onPressed: _addPastHistory,
              icon: const Icon(Icons.add),
            ),
          ),
          ..._pastHistoryControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Past History ${index + 1}',
                        hintText: 'Enter past medical history',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  if (_pastHistoryControllers.length > 1)
                    IconButton(
                      onPressed: () => _removePastHistory(index),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildExamFindingsSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Exam Findings *',
            trailing: IconButton(
              onPressed: _addExamFinding,
              icon: const Icon(Icons.add),
            ),
          ),
          ..._examFindingsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Exam Finding ${index + 1}',
                        hintText: 'Enter examination findings',
                      ),
                      validator: index == 0
                          ? (value) => value?.isEmpty == true
                              ? 'At least one exam finding is required'
                              : null
                          : null,
                      maxLines: 2,
                    ),
                  ),
                  if (_examFindingsControllers.length > 1)
                    IconButton(
                      onPressed: () => _removeExamFinding(index),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGeneralExamSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('General Examination'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tempController,
                  decoration: const InputDecoration(
                    labelText: 'Temperature',
                    hintText: 'e.g., 96F',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _pulseController,
                  decoration: const InputDecoration(
                    labelText: 'Pulse',
                    hintText: 'e.g., 94',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bpController,
                  decoration: const InputDecoration(
                    labelText: 'Blood Pressure',
                    hintText: 'e.g., 120/80',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _spo2Controller,
                  decoration: const InputDecoration(
                    labelText: 'SPO2',
                    hintText: 'e.g., 99%',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadiologySection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Radiology',
            trailing: IconButton(
              onPressed: _addRadiology,
              icon: const Icon(Icons.add),
            ),
          ),
          ..._radiologyControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Radiology ${index + 1}',
                        hintText: 'Enter radiology findings',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeRadiology(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPathologySection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Pathology',
            trailing: IconButton(
              onPressed: _addPathology,
              icon: const Icon(Icons.add),
            ),
          ),
          ..._pathologyControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Pathology ${index + 1}',
                        hintText: 'Enter pathology results',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removePathology(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOperationSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Operation Details'),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _operationTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Operation Type',
                    hintText: 'e.g., LAPAROSCOPIC APPENDECTOMY',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _operationDateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    hintText: 'DD.MM.YYYY',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _surgeonController,
                  decoration: const InputDecoration(
                    labelText: 'Surgeon',
                    hintText: 'Dr. Name',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _anaesthetistController,
                  decoration: const InputDecoration(
                    labelText: 'Anaesthetist',
                    hintText: 'Dr. Name',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _anaesthesiaTypeController,
            decoration: const InputDecoration(
              labelText: 'Anaesthesia Type',
              hintText: 'e.g., SA, GA',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Procedure Steps:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: _addProcedure,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          ..._procedureControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Step ${index + 1}',
                        hintText: 'Enter procedure step',
                      ),
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeProcedure(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTreatmentSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Treatment Given',
            trailing: IconButton(
              onPressed: _addTreatment,
              icon: const Icon(Icons.add),
            ),
          ),
          ..._treatmentControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Treatment ${index + 1}',
                        hintText: 'Enter treatment details',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeTreatment(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUploadOptionsSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Upload Options'),
          CheckboxListTile(
            title: const Text('Upload to Google Drive'),
            subtitle: const Text('Automatically upload generated PDF to Drive'),
            value: _uploadToDrive,
            onChanged: (value) =>
                setState(() => _uploadToDrive = value ?? true),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _showPreviewDialog,
          icon: const Icon(Icons.preview),
          label: const Text('Preview'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _generateDischargeSummary,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(_isLoading ? 'Generating...' : 'Generate Summary'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showPreviewDialog() {
    final requestBody = _buildRequestBody();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.preview, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Discharge Summary Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildPreviewContent(requestBody),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateDischargeSummary();
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: HospitalTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'DISCHARGE SUMMARY',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Patient ID: ${widget.patientId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Final Diagnosis
          _buildPreviewSection('FINAL DIAGNOSIS', [data['Final Diagnosis']]),

          // Complaints
          if (data['Complaints'] != null &&
              (data['Complaints'] as List).isNotEmpty)
            _buildPreviewSection('COMPLAINTS', data['Complaints']),

          // Past History
          if (data['Past History'] != null &&
              (data['Past History'] as List).isNotEmpty)
            _buildPreviewSection('PAST HISTORY', data['Past History']),

          // Exam Findings
          if (data['Exam Findings'] != null &&
              (data['Exam Findings'] as List).isNotEmpty)
            _buildPreviewSection('EXAMINATION FINDINGS', data['Exam Findings']),

          // General Exam
          if (data['General Exam'] != null &&
              (data['General Exam'] as Map).isNotEmpty)
            _buildPreviewGeneralExam(data['General Exam']),

          // Radiology
          if (data['Radiology'] != null &&
              (data['Radiology'] as List).isNotEmpty)
            _buildPreviewSection('RADIOLOGY', data['Radiology']),

          // Pathology
          if (data['Pathology'] != null &&
              (data['Pathology'] as List).isNotEmpty)
            _buildPreviewSection('PATHOLOGY', data['Pathology']),

          // Operation
          if (data['Operation'] != null)
            _buildPreviewOperation(data['Operation']),

          // Treatment
          if (data['Treatment Given'] != null &&
              (data['Treatment Given'] as List).isNotEmpty)
            _buildPreviewSection('TREATMENT GIVEN', data['Treatment Given']),

          // Condition on Discharge
          _buildPreviewSection(
              'CONDITION ON DISCHARGE', [data['Condition on Discharge']]),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(String title, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $item',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPreviewGeneralExam(Map<String, dynamic> generalExam) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GENERAL EXAMINATION',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: generalExam.entries
                .map((entry) => Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 14),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewOperation(Map<String, dynamic> operation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPERATION DETAILS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (operation['Type'] != null)
            Text('Type: ${operation['Type']}',
                style: const TextStyle(fontSize: 14)),
          if (operation['Date'] != null)
            Text('Date: ${operation['Date']}',
                style: const TextStyle(fontSize: 14)),
          if (operation['Surgeon'] != null)
            Text('Surgeon: ${operation['Surgeon']}',
                style: const TextStyle(fontSize: 14)),
          if (operation['Anaesthetist'] != null)
            Text('Anaesthetist: ${operation['Anaesthetist']}',
                style: const TextStyle(fontSize: 14)),
          if (operation['Anaesthesia Type'] != null)
            Text('Anaesthesia: ${operation['Anaesthesia Type']}',
                style: const TextStyle(fontSize: 14)),
          if (operation['Procedure'] != null &&
              (operation['Procedure'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Procedure:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            ...(operation['Procedure'] as List)
                .map((step) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 2),
                      child:
                          Text('• $step', style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_generatedResponse != null)
            Expanded(child: _buildResponsePreview())
          else
            Expanded(child: _buildNurseAssistantPanel()),
        ],
      ),
    );
  }

  Widget _buildNurseAssistantPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions Card
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: HospitalTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuickActionTile(
                  icon: Icons.preview,
                  title: 'Preview Summary',
                  subtitle: 'Review before generating',
                  onTap: _showPreviewDialog,
                ),
                _buildQuickActionTile(
                  icon: Icons.content_copy,
                  title: 'Copy Template',
                  subtitle: 'Load common templates',
                  onTap: _showTemplateDialog,
                ),
                _buildQuickActionTile(
                  icon: Icons.save_outlined,
                  title: 'Save Draft',
                  subtitle: 'Save current progress',
                  onTap: _saveDraft,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Medical Guidelines Card
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: HospitalTheme.info),
                    const SizedBox(width: 8),
                    const Text(
                      'Medical Guidelines',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuidelineItem(
                    'Final Diagnosis', 'Must be specific and complete'),
                _buildGuidelineItem(
                    'Complaints', 'List in chronological order'),
                _buildGuidelineItem(
                    'Exam Findings', 'Include all relevant observations'),
                _buildGuidelineItem(
                    'Condition', 'STABLE, IMPROVED, or specific status'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Common Templates Card
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.library_books, color: HospitalTheme.medical),
                    const SizedBox(width: 8),
                    const Text(
                      'Common Templates',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTemplateItem('Appendectomy', Icons.medical_services),
                _buildTemplateItem('General Surgery', Icons.healing),
                _buildTemplateItem('Emergency Care', Icons.emergency),
                _buildTemplateItem('Pediatric Care', Icons.child_care),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress Tracker Card
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: HospitalTheme.success),
                    const SizedBox(width: 8),
                    const Text(
                      'Completion Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProgressItem('Final Diagnosis',
                    _finalDiagnosisController.text.isNotEmpty),
                _buildProgressItem('Complaints',
                    _complaintsControllers.any((c) => c.text.isNotEmpty)),
                _buildProgressItem('Exam Findings',
                    _examFindingsControllers.any((c) => c.text.isNotEmpty)),
                _buildProgressItem('Condition on Discharge',
                    _conditionOnDischargeController.text.isNotEmpty),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _getCompletionProgress(),
                  backgroundColor: HospitalTheme.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(HospitalTheme.success),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_getCompletionProgress() * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tips Card
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: HospitalTheme.warning),
                    const SizedBox(width: 8),
                    const Text(
                      'Tips & Shortcuts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTipItem('💡', 'Use Ctrl+S to generate summary'),
                _buildTipItem('⚡', 'Use Ctrl+N to add new complaint'),
                _buildTipItem('📝', 'Preview before generating PDF'),
                _buildTipItem('📋', 'Save drafts for later completion'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: HospitalTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: HospitalTheme.textMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: HospitalTheme.info,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
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
  }

  Widget _buildTemplateItem(String name, IconData icon) {
    return InkWell(
      onTap: () => _loadTemplate(name),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: HospitalTheme.medical),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Icon(Icons.download, size: 16, color: HospitalTheme.textMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color:
                isCompleted ? HospitalTheme.success : HospitalTheme.textMedium,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isCompleted
                    ? HospitalTheme.textDark
                    : HospitalTheme.textMedium,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  double _getCompletionProgress() {
    int completed = 0;
    int total = 4; // Mandatory fields

    if (_finalDiagnosisController.text.isNotEmpty) completed++;
    if (_complaintsControllers.any((c) => c.text.isNotEmpty)) completed++;
    if (_examFindingsControllers.any((c) => c.text.isNotEmpty)) completed++;
    if (_conditionOnDischargeController.text.isNotEmpty) completed++;

    return completed / total;
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Template'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('Appendectomy Template'),
                onTap: () {
                  Navigator.pop(context);
                  _loadTemplate('Appendectomy');
                },
              ),
              ListTile(
                leading: const Icon(Icons.healing),
                title: const Text('General Surgery Template'),
                onTap: () {
                  Navigator.pop(context);
                  _loadTemplate('General Surgery');
                },
              ),
              ListTile(
                leading: const Icon(Icons.emergency),
                title: const Text('Emergency Care Template'),
                onTap: () {
                  Navigator.pop(context);
                  _loadTemplate('Emergency Care');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _loadTemplate(String templateName) {
    // Implement template loading logic here
    switch (templateName) {
      case 'Appendectomy':
        _finalDiagnosisController.text = 'ACUTE APPENDICITIS';
        _complaintsControllers[0].text = 'Pain in abdomen';
        if (_complaintsControllers.length > 1) {
          _complaintsControllers[1].text = 'Vomiting';
        } else {
          _addComplaint();
          _complaintsControllers[1].text = 'Vomiting';
        }
        _conditionOnDischargeController.text = 'STABLE';
        break;
      // Add more templates as needed
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$templateName template loaded'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveDraft() {
    // Implement draft saving logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildResponsePreview() {
    if (_generatedResponse == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.cardBackground,
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: HospitalTheme.success,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Generated Successfully',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildResponseContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseContent() {
    final data = _generatedResponse!['data'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File Information
        _buildInfoCard(
          title: 'File Information',
          icon: Icons.description,
          children: [
            _buildInfoRow('File Name', data['fileName'] ?? 'N/A'),
            _buildInfoRow('Generated At', _formatDateTime(data['generatedAt'])),
            _buildInfoRow('Size', _formatFileSize(data['pdfSize'])),
            _buildInfoRow('Type',
                data['isManuallyGenerated'] == true ? 'Manual' : 'Auto'),
          ],
        ),

        const SizedBox(height: 16),

        // Patient Information
        if (data['patientInfo'] != null)
          _buildInfoCard(
            title: 'Patient Information',
            icon: Icons.person,
            children: [
              _buildInfoRow('Patient ID', data['patientInfo']['patientId']),
              _buildInfoRow('Name', data['patientInfo']['name']),
              _buildInfoRow('Age', '${data['patientInfo']['age']} years'),
              _buildInfoRow('Gender', data['patientInfo']['gender']),
            ],
          ),

        const SizedBox(height: 16),

        // Summary Data
        if (data['summaryData'] != null)
          _buildInfoCard(
            title: 'Summary Information',
            icon: Icons.medical_information,
            children: [
              _buildInfoRow('Consultant', data['summaryData']['consultant']),
              _buildInfoRow(
                  'Admission Date', data['summaryData']['admissionDate']),
              _buildInfoRow(
                  'Discharge Date', data['summaryData']['dischargeDate']),
              _buildInfoRow(
                  'Final Diagnosis', data['summaryData']['finalDiagnosis']),
              _buildInfoRow(
                  'Condition', data['summaryData']['conditionOnDischarge']),
            ],
          ),

        const SizedBox(height: 16),

        // Action Buttons
        if (data['driveLink'] != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Methods().openPdf(data['driveLink']);
                // For now, copy to clipboard
                Clipboard.setData(ClipboardData(text: data['driveLink']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Drive link copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data['driveLink']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Drive link copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Link'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: HospitalTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return 'N/A';
    final sizeInBytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024)
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Provider for managing discharge summary state (if needed for global state)
final dischargeSummaryProvider = StateNotifierProvider.family<
    DischargeSummaryNotifier, DischargeSummaryState, String>(
  (ref, patientId) => DischargeSummaryNotifier(patientId),
);

class DischargeSummaryState {
  final bool isLoading;
  final Map<String, dynamic>? response;
  final String? error;

  const DischargeSummaryState({
    this.isLoading = false,
    this.response,
    this.error,
  });

  DischargeSummaryState copyWith({
    bool? isLoading,
    Map<String, dynamic>? response,
    String? error,
  }) {
    return DischargeSummaryState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      error: error ?? this.error,
    );
  }
}

class DischargeSummaryNotifier extends StateNotifier<DischargeSummaryState> {
  final String patientId;

  DischargeSummaryNotifier(this.patientId)
      : super(const DischargeSummaryState());

  Future<void> generateSummary(Map<String, dynamic> requestBody) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.post(
        Uri.parse(
            '${KVM_URL}/reception/generateManualDischargeSummary/$patientId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        state = state.copyWith(
          isLoading: false,
          response: responseData,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to generate discharge summary',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
    }
  }

  void clearState() {
    state = const DischargeSummaryState();
  }
}
