import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

// ==================== MODELS ====================

class SurgicalNote {
  final String id;
  final DateTime surgeryDate;
  final String surgeryTime;
  final String surgeonId;
  final String surgeonName;
  final List<AssistantSurgeon> assistantSurgeons;
  final String preOperativeDiagnosis;
  final String indicationForSurgery;
  final String surgicalProcedure;
  final String plannedProcedure;
  final String anesthesiaType;
  final String anesthesiaStart;
  final String anesthesiaEnd;
  final String surgicalApproach;
  final String incisionType;
  final String incisionLocation;
  final String surgicalFindings;
  final String procedureDescription;
  final String intraOperativeComplications;
  final String estimatedBloodLoss;
  final FluidBalance fluidBalance;
  final List<String> implants;
  final String sutureMaterials;
  final String drains;
  final String postOperativeDiagnosis;
  final String procedureOutcome;
  final String postOperativeInstructions;
  final String recoveryNotes;
  final VitalSigns vitalSigns;
  final String expectedRecoveryTime;
  final String followUpInstructions;
  final String dischargePlanning;
  final String operatingRoom;
  final String surgeryDuration;
  final String urgency;
  final bool photographicDocumentation;
  final bool videoDocumentation;
  final String pathologySpecimens;
  final String surgeonNotes;
  final String nursingNotes;
  final String additionalObservations;
  final bool pdfGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SurgicalNote({
    required this.id,
    required this.surgeryDate,
    required this.surgeryTime,
    required this.surgeonId,
    required this.surgeonName,
    required this.assistantSurgeons,
    required this.preOperativeDiagnosis,
    required this.indicationForSurgery,
    required this.surgicalProcedure,
    required this.plannedProcedure,
    required this.anesthesiaType,
    required this.anesthesiaStart,
    required this.anesthesiaEnd,
    required this.surgicalApproach,
    required this.incisionType,
    required this.incisionLocation,
    required this.surgicalFindings,
    required this.procedureDescription,
    required this.intraOperativeComplications,
    required this.estimatedBloodLoss,
    required this.fluidBalance,
    required this.implants,
    required this.sutureMaterials,
    required this.drains,
    required this.postOperativeDiagnosis,
    required this.procedureOutcome,
    required this.postOperativeInstructions,
    required this.recoveryNotes,
    required this.vitalSigns,
    required this.expectedRecoveryTime,
    required this.followUpInstructions,
    required this.dischargePlanning,
    required this.operatingRoom,
    required this.surgeryDuration,
    required this.urgency,
    required this.photographicDocumentation,
    required this.videoDocumentation,
    required this.pathologySpecimens,
    required this.surgeonNotes,
    required this.nursingNotes,
    required this.additionalObservations,
    required this.pdfGenerated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SurgicalNote.fromJson(Map<String, dynamic> json) {
    return SurgicalNote(
      id: json['_id'] ?? '',
      surgeryDate:
          DateTime.tryParse(json['surgeryDate'] ?? '') ?? DateTime.now(),
      surgeryTime: json['surgeryTime'] ?? '',
      surgeonId: json['surgeonId']?['_id'] ?? json['surgeonId'] ?? '',
      surgeonName: json['surgeonName'] ?? '',
      assistantSurgeons: (json['assistantSurgeons'] as List<dynamic>?)
              ?.map((e) => AssistantSurgeon.fromJson(e))
              .toList() ??
          [],
      preOperativeDiagnosis: json['preOperativeDiagnosis'] ?? '',
      indicationForSurgery: json['indicationForSurgery'] ?? '',
      surgicalProcedure: json['surgicalProcedure'] ?? '',
      plannedProcedure: json['plannedProcedure'] ?? '',
      anesthesiaType: json['anesthesiaType'] ?? '',
      anesthesiaStart: json['anesthesiaStart'] ?? '',
      anesthesiaEnd: json['anesthesiaEnd'] ?? '',
      surgicalApproach: json['surgicalApproach'] ?? '',
      incisionType: json['incisionType'] ?? '',
      incisionLocation: json['incisionLocation'] ?? '',
      surgicalFindings: json['surgicalFindings'] ?? '',
      procedureDescription: json['procedureDescription'] ?? '',
      intraOperativeComplications: json['intraOperativeComplications'] ?? '',
      estimatedBloodLoss: json['estimatedBloodLoss'] ?? '',
      fluidBalance: FluidBalance.fromJson(json['fluidBalance'] ?? {}),
      implants: List<String>.from(json['implants'] ?? []),
      sutureMaterials: json['sutureMaterials'] ?? '',
      drains: json['drains'] ?? '',
      postOperativeDiagnosis: json['postOperativeDiagnosis'] ?? '',
      procedureOutcome: json['procedureOutcome'] ?? '',
      postOperativeInstructions: json['postOperativeInstructions'] ?? '',
      recoveryNotes: json['recoveryNotes'] ?? '',
      vitalSigns: VitalSigns.fromJson(json['vitalSigns'] ?? {}),
      expectedRecoveryTime: json['expectedRecoveryTime'] ?? '',
      followUpInstructions: json['followUpInstructions'] ?? '',
      dischargePlanning: json['dischargePlanning'] ?? '',
      operatingRoom: json['operatingRoom'] ?? '',
      surgeryDuration: json['surgeryDuration'] ?? '',
      urgency: json['urgency'] ?? '',
      photographicDocumentation: json['photographicDocumentation'] ?? false,
      videoDocumentation: json['videoDocumentation'] ?? false,
      pathologySpecimens: json['pathologySpecimens'] ?? '',
      surgeonNotes: json['surgeonNotes'] ?? '',
      nursingNotes: json['nursingNotes'] ?? '',
      additionalObservations: json['additionalObservations'] ?? '',
      pdfGenerated: json['pdfGenerated'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surgeryDate': surgeryDate.toIso8601String(),
      'surgeryTime': surgeryTime,
      'preOperativeDiagnosis': preOperativeDiagnosis,
      'indicationForSurgery': indicationForSurgery,
      'surgicalProcedure': surgicalProcedure,
      'plannedProcedure': plannedProcedure,
      'anesthesiaType': anesthesiaType,
      'anesthesiaStart': anesthesiaStart,
      'anesthesiaEnd': anesthesiaEnd,
      'surgicalApproach': surgicalApproach,
      'incisionType': incisionType,
      'incisionLocation': incisionLocation,
      'surgicalFindings': surgicalFindings,
      'procedureDescription': procedureDescription,
      'intraOperativeComplications': intraOperativeComplications,
      'estimatedBloodLoss': estimatedBloodLoss,
      'fluidBalance': fluidBalance.toJson(),
      'implants': implants,
      'sutureMaterials': sutureMaterials,
      'drains': drains,
      'postOperativeDiagnosis': postOperativeDiagnosis,
      'procedureOutcome': procedureOutcome,
      'postOperativeInstructions': postOperativeInstructions,
      'recoveryNotes': recoveryNotes,
      'vitalSigns': vitalSigns.toJson(),
      'expectedRecoveryTime': expectedRecoveryTime,
      'followUpInstructions': followUpInstructions,
      'dischargePlanning': dischargePlanning,
      'operatingRoom': operatingRoom,
      'surgeryDuration': surgeryDuration,
      'urgency': urgency,
      'photographicDocumentation': photographicDocumentation,
      'videoDocumentation': videoDocumentation,
      'pathologySpecimens': pathologySpecimens,
      'surgeonNotes': surgeonNotes,
      'nursingNotes': nursingNotes,
      'additionalObservations': additionalObservations,
      'assistantSurgeons': assistantSurgeons.map((e) => e.toJson()).toList(),
    };
  }
}

class AssistantSurgeon {
  final String name;
  final String? id;

  const AssistantSurgeon({
    required this.name,
    this.id,
  });

  factory AssistantSurgeon.fromJson(Map<String, dynamic> json) {
    return AssistantSurgeon(
      name: json['name'] ?? '',
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

class FluidBalance {
  final String inputFluids;
  final String outputFluids;
  final String bloodTransfusion;

  const FluidBalance({
    required this.inputFluids,
    required this.outputFluids,
    required this.bloodTransfusion,
  });

  factory FluidBalance.fromJson(Map<String, dynamic> json) {
    return FluidBalance(
      inputFluids: json['inputFluids'] ?? '',
      outputFluids: json['outputFluids'] ?? '',
      bloodTransfusion: json['bloodTransfusion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inputFluids': inputFluids,
      'outputFluids': outputFluids,
      'bloodTransfusion': bloodTransfusion,
    };
  }
}

class VitalSigns {
  final String bloodPressure;
  final String heartRate;
  final String oxygenSaturation;
  final String temperature;

  const VitalSigns({
    required this.bloodPressure,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.temperature,
  });

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      bloodPressure: json['bloodPressure'] ?? '',
      heartRate: json['heartRate'] ?? '',
      oxygenSaturation: json['oxygenSaturation'] ?? '',
      temperature: json['temperature'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bloodPressure': bloodPressure,
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'temperature': temperature,
    };
  }
}

// ==================== PROVIDERS ====================

class SurgicalNotesState {
  final List<SurgicalNote> notes;
  final bool isLoading;
  final String? error;
  final SurgicalNote? selectedNote;
  final bool isDeleting;

  const SurgicalNotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.selectedNote,
    this.isDeleting = false,
  });

  SurgicalNotesState copyWith({
    List<SurgicalNote>? notes,
    bool? isLoading,
    String? error,
    SurgicalNote? selectedNote,
    bool? isDeleting,
    bool clearSelectedNote = false,
  }) {
    return SurgicalNotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedNote:
          clearSelectedNote ? null : (selectedNote ?? this.selectedNote),
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

class SurgicalNotesNotifier extends StateNotifier<SurgicalNotesState> {
  final String patientId;
  final String admissionId;

  SurgicalNotesNotifier({
    required this.patientId,
    required this.admissionId,
  }) : super(const SurgicalNotesState()) {
    loadSurgicalNotes();
  }

  Future<void> loadSurgicalNotes() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.get(
        Uri.parse(
            '${BASE_URL}/doctors/getSurgicalNotes/$patientId/$admissionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<SurgicalNote> notes = (data['data'] as List)
              .map((noteJson) => SurgicalNote.fromJson(noteJson))
              .toList();

          state = state.copyWith(
            notes: notes,
            isLoading: false,
            selectedNote: notes.isNotEmpty ? notes.first : null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: data['message'] ?? 'Failed to load surgical notes',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<void> createSurgicalNote(Map<String, dynamic> noteData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(
            '${BASE_URL}/doctors/createSurgicalNotes/$patientId/$admissionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(noteData),
      );
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await loadSurgicalNotes(); // Refresh the list
        } else {
          state = state.copyWith(
              error: data['message'] ?? 'Failed to create surgical note');
        }
      } else {
        state = state.copyWith(error: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(error: 'Network error: ${e.toString()}');
    }
  }

  Future<void> deleteSurgicalNote(String noteId) async {
    state = state.copyWith(isDeleting: true, error: null);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse(
            '${BASE_URL}/doctors/deleteSurgicalNotes/$patientId/$admissionId/$noteId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Remove the deleted note from the list
          final updatedNotes =
              state.notes.where((note) => note.id != noteId).toList();

          state = state.copyWith(
            notes: updatedNotes,
            isDeleting: false,
            selectedNote: updatedNotes.isNotEmpty ? updatedNotes.first : null,
            clearSelectedNote: updatedNotes.isEmpty,
          );
        } else {
          state = state.copyWith(
            isDeleting: false,
            error: data['message'] ?? 'Failed to delete surgical note',
          );
        }
      } else {
        state = state.copyWith(
          isDeleting: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  void selectNote(SurgicalNote note) {
    state = state.copyWith(selectedNote: note);
  }

  void clearSelectedNote() {
    state = state.copyWith(clearSelectedNote: true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final surgicalNotesProvider = StateNotifierProvider.family<
    SurgicalNotesNotifier,
    SurgicalNotesState,
    Map<String, String>>((ref, params) {
  return SurgicalNotesNotifier(
    patientId: params['patientId']!,
    admissionId: params['admissionId']!,
  );
});

// ==================== MAIN SCREEN ====================

class SurgicalNotesScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const SurgicalNotesScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  ConsumerState<SurgicalNotesScreen> createState() =>
      _SurgicalNotesScreenState();
}

class _SurgicalNotesScreenState extends ConsumerState<SurgicalNotesScreen> {
  late final Map<String, String> _providerParams;

  @override
  void initState() {
    super.initState();
    _providerParams = {
      'patientId': widget.patientId,
      'admissionId': widget.admissionId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final state = ref.watch(surgicalNotesProvider(_providerParams));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Surgical Notes',
        actions: [
          IconButton(
            onPressed: () => _showAddNoteDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add New Surgical Note',
          ),
          IconButton(
            onPressed: () => ref
                .read(surgicalNotesProvider(_providerParams).notifier)
                .loadSurgicalNotes(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: Row(
          children: [
            // Master Panel
            SizedBox(
              width: size.width * 0.35,
              child: _MasterPanel(
                state: state,
                onNoteSelected: (note) => ref
                    .read(surgicalNotesProvider(_providerParams).notifier)
                    .selectNote(note),
                onAddNote: () => _showAddNoteDialog(context),
                onRefresh: () => ref
                    .read(surgicalNotesProvider(_providerParams).notifier)
                    .loadSurgicalNotes(),
                onDeleteNote: (noteId) =>
                    _showDeleteConfirmation(context, noteId),
              ),
            ),

            // Divider
            Container(
              width: 1,
              color: HospitalTheme.border,
            ),

            // Detail Panel
            Expanded(
              child: _DetailPanel(
                selectedNote: state.selectedNote,
                isLoading: state.isLoading,
                onClose: () => ref
                    .read(surgicalNotesProvider(_providerParams).notifier)
                    .clearSelectedNote(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyN) {
        _showAddNoteDialog(context);
      } else if (isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyR) {
        ref
            .read(surgicalNotesProvider(_providerParams).notifier)
            .loadSurgicalNotes();
      }
    }
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddSurgicalNoteDialog(
        patientId: widget.patientId,
        admissionId: widget.admissionId,
        onSave: (data) => ref
            .read(surgicalNotesProvider(_providerParams).notifier)
            .createSurgicalNote(data),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: HospitalTheme.error),
            const SizedBox(width: 8),
            const Text('Delete Surgical Note'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this surgical note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(surgicalNotesProvider(_providerParams).notifier)
                  .deleteSurgicalNote(noteId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ==================== MASTER PANEL ====================

class _MasterPanel extends StatelessWidget {
  final SurgicalNotesState state;
  final Function(SurgicalNote) onNoteSelected;
  final VoidCallback onAddNote;
  final VoidCallback onRefresh;
  final Function(String) onDeleteNote;

  const _MasterPanel({
    required this.state,
    required this.onNoteSelected,
    required this.onAddNote,
    required this.onRefresh,
    required this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Surgical Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onAddNote,
                  icon: Icon(Icons.add, color: HospitalTheme.primary),
                  tooltip: 'Add Note (Ctrl+N)',
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh, color: HospitalTheme.primary),
                  tooltip: 'Refresh (Ctrl+R)',
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading surgical notes...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: HospitalTheme.error),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: HospitalTheme.textMedium),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_alt_outlined,
                  size: 48, color: HospitalTheme.textLight),
              const SizedBox(height: 16),
              Text(
                'No Surgical Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first surgical note to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: HospitalTheme.textLight),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddNote,
                icon: const Icon(Icons.add),
                label: const Text('Add Note'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.notes.length,
      itemBuilder: (context, index) {
        final note = state.notes[index];
        final isSelected = state.selectedNote?.id == note.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _SurgicalNoteCard(
            note: note,
            isSelected: isSelected,
            onTap: () => onNoteSelected(note),
            onDelete: () => onDeleteNote(note.id),
            isDeleting: state.isDeleting,
          ),
        );
      },
    );
  }
}

// ==================== SURGICAL NOTE CARD ====================

class _SurgicalNoteCard extends StatelessWidget {
  final SurgicalNote note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _SurgicalNoteCard({
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HospitalTheme.radiusMedium,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
            borderRadius: HospitalTheme.radiusMedium,
            border: Border.all(
              color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? HospitalTheme.shadowSmall : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.surgicalProcedure.isNotEmpty
                          ? note.surgicalProcedure
                          : 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? HospitalTheme.primary
                            : HospitalTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  HospitalTheme.buildStatusBadge(
                    note.procedureOutcome.isNotEmpty
                        ? note.procedureOutcome
                        : 'N/A',
                    color: note.procedureOutcome.toLowerCase() == 'successful'
                        ? HospitalTheme.success
                        : HospitalTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isDeleting ? null : onDelete,
                    icon: isDeleting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HospitalTheme.error,
                            ),
                          )
                        : Icon(
                            Icons.delete_outline,
                            color: HospitalTheme.error,
                            size: 20,
                          ),
                    tooltip: 'Delete Note',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note.surgeonName.isNotEmpty
                          ? 'Dr. ${note.surgeonName}'
                          : 'N/A',
                      style: TextStyle(
                        fontSize: 13,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(note.surgeryDate)} • ${note.surgeryTime.isNotEmpty ? note.surgeryTime : 'N/A'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4),
                  Text(
                    note.operatingRoom.isNotEmpty ? note.operatingRoom : 'N/A',
                    style: TextStyle(
                      fontSize: 13,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    note.surgeryDuration.isNotEmpty
                        ? note.surgeryDuration
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ==================== DETAIL PANEL ====================

class _DetailPanel extends StatelessWidget {
  final SurgicalNote? selectedNote;
  final bool isLoading;
  final VoidCallback onClose;

  const _DetailPanel({
    required this.selectedNote,
    required this.isLoading,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (selectedNote == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined,
                size: 64, color: HospitalTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'Select a Surgical Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a surgical note from the list to view details',
              style: TextStyle(color: HospitalTheme.textLight),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with close button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: HospitalTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Surgical Note Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, color: HospitalTheme.textMedium),
                tooltip: 'Close Details',
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _SurgicalNoteDetails(note: selectedNote!),
          ),
        ),
      ],
    );
  }
}

// ==================== SURGICAL NOTE DETAILS ====================

class _SurgicalNoteDetails extends StatelessWidget {
  final SurgicalNote note;

  const _SurgicalNoteDetails({required this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.surgicalProcedure.isNotEmpty
                        ? note.surgicalProcedure
                        : 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Surgery Date: ${_formatDate(note.surgeryDate)} at ${note.surgeryTime.isNotEmpty ? note.surgeryTime : 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            HospitalTheme.buildStatusBadge(
              note.procedureOutcome.isNotEmpty ? note.procedureOutcome : 'N/A',
              color: note.procedureOutcome.toLowerCase() == 'successful'
                  ? HospitalTheme.success
                  : HospitalTheme.warning,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Basic Information
        _buildSection(
          'Basic Information',
          [
            _buildInfoRow(
                'Surgeon',
                note.surgeonName.isNotEmpty
                    ? 'Dr. ${note.surgeonName}'
                    : 'N/A'),
            _buildInfoRow('Operating Room',
                note.operatingRoom.isNotEmpty ? note.operatingRoom : 'N/A'),
            _buildInfoRow('Surgery Duration',
                note.surgeryDuration.isNotEmpty ? note.surgeryDuration : 'N/A'),
            _buildInfoRow(
                'Urgency', note.urgency.isNotEmpty ? note.urgency : 'N/A'),
            _buildInfoRow(
                'Surgical Approach',
                note.surgicalApproach.isNotEmpty
                    ? note.surgicalApproach
                    : 'N/A'),
          ],
        ),

        // Assistant Surgeons
        if (note.assistantSurgeons.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSection(
            'Assistant Surgeons',
            [
              for (int i = 0; i < note.assistantSurgeons.length; i++)
                _buildInfoRow(
                    'Assistant ${i + 1}',
                    note.assistantSurgeons[i].name.isNotEmpty
                        ? note.assistantSurgeons[i].name
                        : 'N/A'),
            ],
          ),
        ],

        // Diagnosis and Procedure
        const SizedBox(height: 24),
        _buildSection(
          'Diagnosis and Procedure',
          [
            _buildInfoRow(
                'Pre-operative Diagnosis',
                note.preOperativeDiagnosis.isNotEmpty
                    ? note.preOperativeDiagnosis
                    : 'N/A'),
            _buildInfoRow(
                'Post-operative Diagnosis',
                note.postOperativeDiagnosis.isNotEmpty
                    ? note.postOperativeDiagnosis
                    : 'N/A'),
            _buildInfoRow(
                'Indication for Surgery',
                note.indicationForSurgery.isNotEmpty
                    ? note.indicationForSurgery
                    : 'N/A'),
            _buildInfoRow(
                'Planned Procedure',
                note.plannedProcedure.isNotEmpty
                    ? note.plannedProcedure
                    : 'N/A'),
          ],
        ),

        // Anesthesia
        const SizedBox(height: 24),
        _buildSection(
          'Anesthesia',
          [
            _buildInfoRow('Type',
                note.anesthesiaType.isNotEmpty ? note.anesthesiaType : 'N/A'),
            _buildInfoRow('Start Time',
                note.anesthesiaStart.isNotEmpty ? note.anesthesiaStart : 'N/A'),
            _buildInfoRow('End Time',
                note.anesthesiaEnd.isNotEmpty ? note.anesthesiaEnd : 'N/A'),
          ],
        ),

        // Surgical Details
        const SizedBox(height: 24),
        _buildSection(
          'Surgical Details',
          [
            _buildInfoRow('Incision Type',
                note.incisionType.isNotEmpty ? note.incisionType : 'N/A'),
            _buildInfoRow(
                'Incision Location',
                note.incisionLocation.isNotEmpty
                    ? note.incisionLocation
                    : 'N/A'),
            _buildInfoRow(
                'Estimated Blood Loss',
                note.estimatedBloodLoss.isNotEmpty
                    ? note.estimatedBloodLoss
                    : 'N/A'),
            _buildInfoRow('Suture Materials',
                note.sutureMaterials.isNotEmpty ? note.sutureMaterials : 'N/A'),
            _buildInfoRow(
                'Drains', note.drains.isNotEmpty ? note.drains : 'N/A'),
          ],
        ),

        // Findings and Description
        const SizedBox(height: 24),
        _buildTextSection('Surgical Findings',
            note.surgicalFindings.isNotEmpty ? note.surgicalFindings : 'N/A'),

        const SizedBox(height: 16),
        _buildTextSection(
            'Procedure Description',
            note.procedureDescription.isNotEmpty
                ? note.procedureDescription
                : 'N/A'),

        const SizedBox(height: 16),
        _buildTextSection(
            'Intra-operative Complications',
            note.intraOperativeComplications.isNotEmpty
                ? note.intraOperativeComplications
                : 'N/A'),

        // Fluid Balance
        const SizedBox(height: 24),
        _buildSection(
          'Fluid Balance',
          [
            _buildInfoRow(
                'Input Fluids',
                note.fluidBalance.inputFluids.isNotEmpty
                    ? note.fluidBalance.inputFluids
                    : 'N/A'),
            _buildInfoRow(
                'Output Fluids',
                note.fluidBalance.outputFluids.isNotEmpty
                    ? note.fluidBalance.outputFluids
                    : 'N/A'),
            _buildInfoRow(
                'Blood Transfusion',
                note.fluidBalance.bloodTransfusion.isNotEmpty
                    ? note.fluidBalance.bloodTransfusion
                    : 'N/A'),
          ],
        ),

        // Vital Signs
        const SizedBox(height: 24),
        _buildSection(
          'Vital Signs',
          [
            _buildInfoRow(
                'Blood Pressure',
                note.vitalSigns.bloodPressure.isNotEmpty
                    ? note.vitalSigns.bloodPressure
                    : 'N/A'),
            _buildInfoRow(
                'Heart Rate',
                note.vitalSigns.heartRate.isNotEmpty
                    ? note.vitalSigns.heartRate
                    : 'N/A'),
            _buildInfoRow(
                'Oxygen Saturation',
                note.vitalSigns.oxygenSaturation.isNotEmpty
                    ? note.vitalSigns.oxygenSaturation
                    : 'N/A'),
            _buildInfoRow(
                'Temperature',
                note.vitalSigns.temperature.isNotEmpty
                    ? note.vitalSigns.temperature
                    : 'N/A'),
          ],
        ),

        // Post-operative Care
        const SizedBox(height: 24),
        _buildTextSection(
            'Post-operative Instructions',
            note.postOperativeInstructions.isNotEmpty
                ? note.postOperativeInstructions
                : 'N/A'),

        const SizedBox(height: 16),
        _buildTextSection('Recovery Notes',
            note.recoveryNotes.isNotEmpty ? note.recoveryNotes : 'N/A'),

        const SizedBox(height: 16),
        _buildSection(
          'Recovery Information',
          [
            _buildInfoRow(
                'Expected Recovery Time',
                note.expectedRecoveryTime.isNotEmpty
                    ? note.expectedRecoveryTime
                    : 'N/A'),
            _buildInfoRow(
                'Follow-up Instructions',
                note.followUpInstructions.isNotEmpty
                    ? note.followUpInstructions
                    : 'N/A'),
            _buildInfoRow(
                'Discharge Planning',
                note.dischargePlanning.isNotEmpty
                    ? note.dischargePlanning
                    : 'N/A'),
          ],
        ),

        // Documentation
        const SizedBox(height: 24),
        _buildSection(
          'Documentation',
          [
            _buildInfoRow('Photographic Documentation',
                note.photographicDocumentation ? 'Yes' : 'No'),
            _buildInfoRow(
                'Video Documentation', note.videoDocumentation ? 'Yes' : 'No'),
            _buildInfoRow(
                'Pathology Specimens',
                note.pathologySpecimens.isNotEmpty
                    ? note.pathologySpecimens
                    : 'N/A'),
            _buildInfoRow('PDF Generated', note.pdfGenerated ? 'Yes' : 'No'),
          ],
        ),

        // Notes
        const SizedBox(height: 24),
        _buildTextSection('Surgeon Notes',
            note.surgeonNotes.isNotEmpty ? note.surgeonNotes : 'N/A'),

        const SizedBox(height: 16),
        _buildTextSection('Nursing Notes',
            note.nursingNotes.isNotEmpty ? note.nursingNotes : 'N/A'),

        const SizedBox(height: 16),
        _buildTextSection(
            'Additional Observations',
            note.additionalObservations.isNotEmpty
                ? note.additionalObservations
                : 'N/A'),

        const SizedBox(height: 32),

        // Timestamps
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            borderRadius: HospitalTheme.radiusMedium,
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                        'Created', _formatDateTime(note.createdAt)),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                        'Last Updated', _formatDateTime(note.updatedAt)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextSection(String title, String content) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: content != 'N/A'
                  ? HospitalTheme.textDark
                  : HospitalTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: HospitalTheme.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: value != 'N/A'
                    ? HospitalTheme.textDark
                    : HospitalTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== ADD SURGICAL NOTE DIALOG ====================

class _AddSurgicalNoteDialog extends StatefulWidget {
  final String patientId;
  final String admissionId;
  final Function(Map<String, dynamic>) onSave;

  const _AddSurgicalNoteDialog({
    required this.patientId,
    required this.admissionId,
    required this.onSave,
  });

  @override
  State<_AddSurgicalNoteDialog> createState() => _AddSurgicalNoteDialogState();
}

class _AddSurgicalNoteDialogState extends State<_AddSurgicalNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Date and Time controllers
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay? _anesthesiaStartTime;
  TimeOfDay? _anesthesiaEndTime;

  // Form controllers for text fields
  final _preOpDiagnosisController = TextEditingController();
  final _indicationController = TextEditingController();
  final _surgicalProcedureController = TextEditingController();
  final _plannedProcedureController = TextEditingController();
  final _anesthesiaTypeController = TextEditingController();
  final _surgicalApproachController = TextEditingController();
  final _incisionTypeController = TextEditingController();
  final _incisionLocationController = TextEditingController();
  final _surgicalFindingsController = TextEditingController();
  final _procedureDescriptionController = TextEditingController();
  final _complicationsController = TextEditingController();
  final _bloodLossController = TextEditingController();
  final _inputFluidsController = TextEditingController();
  final _outputFluidsController = TextEditingController();
  final _bloodTransfusionController = TextEditingController();
  final _sutureMaterialsController = TextEditingController();
  final _drainsController = TextEditingController();
  final _postOpDiagnosisController = TextEditingController();
  final _procedureOutcomeController = TextEditingController();
  final _postOpInstructionsController = TextEditingController();
  final _recoveryNotesController = TextEditingController();
  final _bpController = TextEditingController();
  final _hrController = TextEditingController();
  final _o2SatController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _recoveryTimeController = TextEditingController();
  final _followUpController = TextEditingController();
  final _dischargePlanningController = TextEditingController();
  final _operatingRoomController = TextEditingController();
  final _surgeryDurationController = TextEditingController();
  final _urgencyController = TextEditingController();
  final _pathologyController = TextEditingController();
  final _surgeonNotesController = TextEditingController();
  final _nursingNotesController = TextEditingController();
  final _additionalObservationsController = TextEditingController();

  bool _photographicDoc = false;
  bool _videoDoc = false;
  final List<String> _assistantSurgeons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  void _initializeDefaults() {
    _procedureOutcomeController.text = 'Successful';
    _urgencyController.text = 'Elective';
    _complicationsController.text = 'None';
    _drainsController.text = 'None';
    _bloodTransfusionController.text = 'None';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Dispose all controllers
    _preOpDiagnosisController.dispose();
    _indicationController.dispose();
    _surgicalProcedureController.dispose();
    _plannedProcedureController.dispose();
    _anesthesiaTypeController.dispose();
    _surgicalApproachController.dispose();
    _incisionTypeController.dispose();
    _incisionLocationController.dispose();
    _surgicalFindingsController.dispose();
    _procedureDescriptionController.dispose();
    _complicationsController.dispose();
    _bloodLossController.dispose();
    _inputFluidsController.dispose();
    _outputFluidsController.dispose();
    _bloodTransfusionController.dispose();
    _sutureMaterialsController.dispose();
    _drainsController.dispose();
    _postOpDiagnosisController.dispose();
    _procedureOutcomeController.dispose();
    _postOpInstructionsController.dispose();
    _recoveryNotesController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    _o2SatController.dispose();
    _temperatureController.dispose();
    _recoveryTimeController.dispose();
    _followUpController.dispose();
    _dischargePlanningController.dispose();
    _operatingRoomController.dispose();
    _surgeryDurationController.dispose();
    _urgencyController.dispose();
    _pathologyController.dispose();
    _surgeonNotesController.dispose();
    _nursingNotesController.dispose();
    _additionalObservationsController.dispose();
    super.dispose();
  }

  // Helper method to get value or "N/A"
  String _getValueOrNA(String value) {
    return value.trim().isEmpty ? 'N/A' : value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: HospitalTheme.radiusSmall,
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: HospitalTheme.radiusSmall,
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: HospitalTheme.radiusSmall,
            borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: HospitalTheme.radiusSmall,
            borderSide: BorderSide(color: HospitalTheme.error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: TextStyle(
            color: HospitalTheme.textLight,
            fontSize: 14,
          ),
          labelStyle: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 14,
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: HospitalTheme.primary.withOpacity(0.3),
          selectionHandleColor: HospitalTheme.primary,
        ),
      ),
      child: Dialog(
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.note_add, color: HospitalTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New Surgical Note',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormSection('Basic Information', [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDatePickerField(
                                    label: 'Surgery Date',
                                    selectedDate: _selectedDate,
                                    onDateSelected: (date) {
                                      setState(() {
                                        _selectedDate = date;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTimePickerField(
                                    label: 'Surgery Time',
                                    selectedTime: _selectedTime,
                                    onTimeSelected: (time) {
                                      setState(() {
                                        _selectedTime = time;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _operatingRoomController,
                                    decoration: const InputDecoration(
                                      labelText: 'Operating Room',
                                      hintText: 'OR-1',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _surgeryDurationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Surgery Duration',
                                      hintText: '45 minutes',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _urgencyController.text.isNotEmpty
                                        ? _urgencyController.text
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Urgency',
                                    ),
                                    items: ['Elective', 'Urgent', 'Emergency']
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (value) =>
                                        _urgencyController.text = value ?? '',
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Diagnosis and Procedure', [
                            TextFormField(
                              controller: _surgicalProcedureController,
                              decoration: const InputDecoration(
                                labelText: 'Surgical Procedure',
                                hintText: 'Laparoscopic Appendectomy',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _preOpDiagnosisController,
                              decoration: const InputDecoration(
                                labelText: 'Pre-operative Diagnosis',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _postOpDiagnosisController,
                              decoration: const InputDecoration(
                                labelText: 'Post-operative Diagnosis',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _indicationController,
                              decoration: const InputDecoration(
                                labelText: 'Indication for Surgery',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _plannedProcedureController,
                              decoration: const InputDecoration(
                                labelText: 'Planned Procedure',
                              ),
                              maxLines: 2,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Anesthesia', [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _anesthesiaTypeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Anesthesia Type',
                                      hintText: 'General',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTimePickerField(
                                    label: 'Anesthesia Start',
                                    selectedTime: _anesthesiaStartTime,
                                    onTimeSelected: (time) {
                                      setState(() {
                                        _anesthesiaStartTime = time;
                                      });
                                    },
                                    isRequired: false,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTimePickerField(
                                    label: 'Anesthesia End',
                                    selectedTime: _anesthesiaEndTime,
                                    onTimeSelected: (time) {
                                      setState(() {
                                        _anesthesiaEndTime = time;
                                      });
                                    },
                                    isRequired: false,
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Surgical Details', [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _surgicalApproachController,
                                    decoration: const InputDecoration(
                                      labelText: 'Surgical Approach',
                                      hintText: 'Laparoscopic',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _incisionTypeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Incision Type',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _incisionLocationController,
                              decoration: const InputDecoration(
                                labelText: 'Incision Location',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bloodLossController,
                                    decoration: const InputDecoration(
                                      labelText: 'Estimated Blood Loss',
                                      hintText: 'Minimal (<50ml)',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sutureMaterialsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Suture Materials',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _drainsController,
                              decoration: const InputDecoration(
                                labelText: 'Drains',
                                hintText: 'None',
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Findings and Description', [
                            TextFormField(
                              controller: _surgicalFindingsController,
                              decoration: const InputDecoration(
                                labelText: 'Surgical Findings',
                              ),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _procedureDescriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Procedure Description',
                              ),
                              maxLines: 5,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _complicationsController,
                              decoration: const InputDecoration(
                                labelText: 'Intra-operative Complications',
                                hintText: 'None',
                              ),
                              maxLines: 2,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Fluid Balance', [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _inputFluidsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Input Fluids',
                                      hintText: '1500ml Lactated Ringers',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _outputFluidsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Output Fluids',
                                      hintText: '200ml urine',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _bloodTransfusionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Blood Transfusion',
                                      hintText: 'None',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Vital Signs', [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bpController,
                                    decoration: const InputDecoration(
                                      labelText: 'Blood Pressure',
                                      hintText: '120/80 mmHg',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _hrController,
                                    decoration: const InputDecoration(
                                      labelText: 'Heart Rate',
                                      hintText: '72 bpm',
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
                                    controller: _o2SatController,
                                    decoration: const InputDecoration(
                                      labelText: 'Oxygen Saturation',
                                      hintText: '98% on room air',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _temperatureController,
                                    decoration: const InputDecoration(
                                      labelText: 'Temperature',
                                      hintText: '98.6°F',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Post-operative Care', [
                            TextFormField(
                              controller: _postOpInstructionsController,
                              decoration: const InputDecoration(
                                labelText: 'Post-operative Instructions',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _recoveryNotesController,
                              decoration: const InputDecoration(
                                labelText: 'Recovery Notes',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _recoveryTimeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Expected Recovery Time',
                                      hintText: '2-3 days for full recovery',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _procedureOutcomeController
                                            .text.isNotEmpty
                                        ? _procedureOutcomeController.text
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Procedure Outcome',
                                    ),
                                    items: [
                                      'Successful',
                                      'Complicated',
                                      'Failed'
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (value) =>
                                        _procedureOutcomeController.text =
                                            value ?? '',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _followUpController,
                              decoration: const InputDecoration(
                                labelText: 'Follow-up Instructions',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dischargePlanningController,
                              decoration: const InputDecoration(
                                labelText: 'Discharge Planning',
                              ),
                              maxLines: 2,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Documentation', [
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text(
                                        'Photographic Documentation'),
                                    value: _photographicDoc,
                                    onChanged: (value) => setState(() =>
                                        _photographicDoc = value ?? false),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Video Documentation'),
                                    value: _videoDoc,
                                    onChanged: (value) => setState(
                                        () => _videoDoc = value ?? false),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pathologyController,
                              decoration: const InputDecoration(
                                labelText: 'Pathology Specimens',
                                hintText:
                                    'Appendix sent for routine histopathology',
                              ),
                              maxLines: 2,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Assistant Surgeons', [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Assistant Surgeons',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _addAssistantSurgeon,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Assistant'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: HospitalTheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_assistantSurgeons.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: HospitalTheme.surfaceLight,
                                      borderRadius: HospitalTheme.radiusSmall,
                                      border: Border.all(
                                          color: HospitalTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: HospitalTheme.textMedium,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'No assistant surgeons added',
                                          style: TextStyle(
                                            color: HospitalTheme.textMedium,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    children: _assistantSurgeons
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final surgeon = entry.value;

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              HospitalTheme.radiusSmall,
                                          border: Border.all(
                                              color: HospitalTheme.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.person,
                                                color: HospitalTheme.primary,
                                                size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                surgeon,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _removeAssistantSurgeon(
                                                      index),
                                              icon: Icon(
                                                  Icons.remove_circle_outline,
                                                  color: HospitalTheme.error,
                                                  size: 20),
                                              tooltip: 'Remove',
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildFormSection('Additional Notes', [
                            TextFormField(
                              controller: _surgeonNotesController,
                              decoration: const InputDecoration(
                                labelText: 'Surgeon Notes',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nursingNotesController,
                              decoration: const InputDecoration(
                                labelText: 'Nursing Notes',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _additionalObservationsController,
                              decoration: const InputDecoration(
                                labelText: 'Additional Observations',
                              ),
                              maxLines: 3,
                            ),
                          ]),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveSurgicalNote,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label:
                        Text(_isLoading ? 'Saving...' : 'Save Surgical Note'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HospitalTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: HospitalTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
    bool isRequired = false,
  }) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select date',
        suffixIcon: Icon(Icons.calendar_today, color: HospitalTheme.primary),
      ),
      controller: TextEditingController(
        text:
            '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: HospitalTheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: HospitalTheme.textDark,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onTimeSelected,
    bool isRequired = false,
  }) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select time',
        suffixIcon: Icon(Icons.access_time, color: HospitalTheme.primary),
      ),
      controller: TextEditingController(
        text: selectedTime != null ? selectedTime!.format(context) : '',
      ),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: HospitalTheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: HospitalTheme.textDark,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
    );
  }

  void _addAssistantSurgeon() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();

        return Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: Colors.black,
              selectionColor: HospitalTheme.primary.withOpacity(0.3),
              selectionHandleColor: HospitalTheme.primary,
            ),
          ),
          child: AlertDialog(
            title: const Text('Add Assistant Surgeon'),
            content: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Surgeon Name',
                hintText: 'Dr. John Smith',
                border: OutlineInputBorder(
                  borderRadius: HospitalTheme.radiusSmall,
                  borderSide: BorderSide(color: HospitalTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: HospitalTheme.radiusSmall,
                  borderSide: BorderSide(color: HospitalTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: HospitalTheme.radiusSmall,
                  borderSide:
                      BorderSide(color: HospitalTheme.primary, width: 2),
                ),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    setState(() {
                      _assistantSurgeons.add(controller.text.trim());
                    });
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeAssistantSurgeon(int index) {
    setState(() {
      _assistantSurgeons.removeAt(index);
    });
  }

  Future<void> _saveSurgicalNote() async {
    setState(() => _isLoading = true);

    try {
      final noteData = {
        'surgeryDate':
            '${_selectedDate.toIso8601String().split('T')[0]}T10:00:00.000Z',
        'surgeryTime': _selectedTime.format(context),
        'preOperativeDiagnosis': _getValueOrNA(_preOpDiagnosisController.text),
        'indicationForSurgery': _getValueOrNA(_indicationController.text),
        'surgicalProcedure': _getValueOrNA(_surgicalProcedureController.text),
        'plannedProcedure': _getValueOrNA(_plannedProcedureController.text),
        'anesthesiaType': _getValueOrNA(_anesthesiaTypeController.text),
        'anesthesiaStart': _anesthesiaStartTime?.format(context) ?? 'N/A',
        'anesthesiaEnd': _anesthesiaEndTime?.format(context) ?? 'N/A',
        'surgicalApproach': _getValueOrNA(_surgicalApproachController.text),
        'incisionType': _getValueOrNA(_incisionTypeController.text),
        'incisionLocation': _getValueOrNA(_incisionLocationController.text),
        'surgicalFindings': _getValueOrNA(_surgicalFindingsController.text),
        'procedureDescription':
            _getValueOrNA(_procedureDescriptionController.text),
        'intraOperativeComplications':
            _getValueOrNA(_complicationsController.text),
        'estimatedBloodLoss': _getValueOrNA(_bloodLossController.text),
        'fluidBalance': {
          'inputFluids': _getValueOrNA(_inputFluidsController.text),
          'outputFluids': _getValueOrNA(_outputFluidsController.text),
          'bloodTransfusion': _getValueOrNA(_bloodTransfusionController.text),
        },
        'implants': [],
        'sutureMaterials': _getValueOrNA(_sutureMaterialsController.text),
        'drains': _getValueOrNA(_drainsController.text),
        'postOperativeDiagnosis':
            _getValueOrNA(_postOpDiagnosisController.text),
        'procedureOutcome': _getValueOrNA(_procedureOutcomeController.text),
        'postOperativeInstructions':
            _getValueOrNA(_postOpInstructionsController.text),
        'recoveryNotes': _getValueOrNA(_recoveryNotesController.text),
        'vitalSigns': {
          'bloodPressure': _getValueOrNA(_bpController.text),
          'heartRate': _getValueOrNA(_hrController.text),
          'oxygenSaturation': _getValueOrNA(_o2SatController.text),
          'temperature': _getValueOrNA(_temperatureController.text),
        },
        'expectedRecoveryTime': _getValueOrNA(_recoveryTimeController.text),
        'followUpInstructions': _getValueOrNA(_followUpController.text),
        'dischargePlanning': _getValueOrNA(_dischargePlanningController.text),
        'operatingRoom': _getValueOrNA(_operatingRoomController.text),
        'surgeryDuration': _getValueOrNA(_surgeryDurationController.text),
        'urgency': _getValueOrNA(_urgencyController.text),
        'photographicDocumentation': _photographicDoc,
        'videoDocumentation': _videoDoc,
        'pathologySpecimens': _getValueOrNA(_pathologyController.text),
        'surgeonNotes': _getValueOrNA(_surgeonNotesController.text),
        'nursingNotes': _getValueOrNA(_nursingNotesController.text),
        'additionalObservations':
            _getValueOrNA(_additionalObservationsController.text),
        'assistantSurgeons':
            _assistantSurgeons.map((name) => {'name': name}).toList(),
      };

      await widget.onSave(noteData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Surgical note saved successfully'),
              ],
            ),
            backgroundColor: HospitalTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to save: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: HospitalTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
