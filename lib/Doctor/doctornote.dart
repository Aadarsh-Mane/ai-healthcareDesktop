import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Model for Doctor Notes
class DoctorNote {
  final String id;
  final String text;
  final String date;
  final String doctor;

  DoctorNote({
    required this.id,
    required this.text,
    required this.date,
    required this.doctor,
  });

  factory DoctorNote.fromJson(Map<String, dynamic> json) {
    return DoctorNote(
      id: json['_id'] ?? '',
      text: json['text'] ?? '',
      date: json['date'] ?? '',
      doctor: json['doctor'] ?? '',
    );
  }
}

// API Service for Doctor Notes
class DoctorNotesService {
  final String baseUrl = '${KVM_URL}/doctors';

  // Fetch notes for a patient admission
  Future<List<DoctorNote>> fetchNotes(
      String patientId, String admissionId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/getNotes?patientId=$patientId&admissionId=$admissionId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DoctorNote.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notes: $e');
      return [];
    }
  }

  // Add a new note
  Future<bool> addNote(String patientId, String admissionId, String text,
      String doctorName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addNotes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': patientId,
          'admissionId': admissionId,
          'text': text,
          'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
          'doctor': doctorName,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding note: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(
      String patientId, String admissionId, String noteId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deleteNote'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': patientId,
          'admissionId': admissionId,
          'noteId': noteId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
}

// Updated UI Components for Doctor Notes
class DoctorNotesSection extends StatefulWidget {
  final String patientId;
  final String admissionId;
  final String doctorName;

  const DoctorNotesSection({
    Key? key,
    required this.patientId,
    required this.admissionId,
    required this.doctorName,
  }) : super(key: key);

  @override
  _DoctorNotesSectionState createState() => _DoctorNotesSectionState();
}

class _DoctorNotesSectionState extends State<DoctorNotesSection> {
  final DoctorNotesService _notesService = DoctorNotesService();
  List<DoctorNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    final notes =
        await _notesService.fetchNotes(widget.patientId, widget.admissionId);

    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _addNewNote(String text) async {
    final success = await _notesService.addNote(
      widget.patientId,
      widget.admissionId,
      text,
      widget.doctorName,
    );

    if (success) {
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add note')),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final success = await _notesService.deleteNote(
      widget.patientId,
      widget.admissionId,
      noteId,
    );

    if (success) {
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note')),
      );
    }
  }

  void _showAddNoteDialog() {
    final TextEditingController _textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Note'),
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Enter note text...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _addNewNote(_textController.text.trim());
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),

        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_notes.isEmpty)
          Text('No notes available'),

        ..._notes
            .map((note) => Column(
                  children: [
                    _buildNoteItem(
                      id: note.id,
                      date: note.date,
                      note: note.text,
                      doctor: note.doctor,
                    ),
                    SizedBox(height: 8),
                  ],
                ))
            .toList(),

        SizedBox(height: 12),

        // Add note button
        _buildGradientButton(
          icon: Icons.add,
          text: 'Add Note',
          onPressed: _showAddNoteDialog,
        ),
      ],
    );
  }

  Widget _buildNoteItem({
    required String id,
    required String date,
    required String note,
    required String doctor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              Row(
                children: [
                  Text(
                    doctor,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(id),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            note,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(noteId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildDoctorNotes();
  }
}

// Usage Example:
// DoctorNotesSection(
//   patientId: 'TES540',
//   admissionId: '67db7e817a616dc887ebdb05',
//   doctorName: 'Dr. Johnson',
// )
