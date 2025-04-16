import 'dart:convert';

import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DoctorNotesSection extends StatefulWidget {
  final String patientId;
  final String admissionId;

  DoctorNotesSection({required this.patientId, required this.admissionId});

  @override
  _DoctorNotesSectionState createState() => _DoctorNotesSectionState();
}

const _sectionGradient = LinearGradient(
  colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class _DoctorNotesSectionState extends State<DoctorNotesSection> {
  // Use a key to force refresh the FutureBuilder
  Key _futureBuilderKey = UniqueKey();

  final doctor = DoctorRepository();
  // Function to refresh the notes list
  void _refreshNotes() {
    setState(() {
      _futureBuilderKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildDoctorNotes(context, widget.patientId, widget.admissionId);
  }

  Widget _buildDoctorNotes(
      BuildContext context, String patientId, String admissionId) {
    // Create a state variable to hold the notes
    return FutureBuilder(
      key: _futureBuilderKey, // Add key here to force refresh
      future: _fetchDoctorNotes(patientId, admissionId),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
              Text('No notes available'),
              SizedBox(height: 12),
              _buildGradientButton(
                icon: Icons.add,
                text: 'Add Note',
                onPressed: () =>
                    _showAddNoteDialog(context, patientId, admissionId),
              ),
            ],
          );
        }

        // If we have data, display the notes
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
            // Display all notes from the API
            ...snapshot.data!.map((note) => Column(
                  children: [
                    _buildNoteItem(
                      date: note['date'],
                      note: note['text'],
                      doctor: note['doctorName'],
                      noteId: note['_id'],
                      onDelete: () =>
                          _deleteNote(patientId, admissionId, note['_id']),
                    ),
                    SizedBox(height: 8),
                  ],
                )),
            SizedBox(height: 12),
            // Add note button
            _buildGradientButton(
              icon: Icons.add,
              text: 'Add Note',
              onPressed: () =>
                  _showAddNoteDialog(context, patientId, admissionId),
            ),
          ],
        );
      },
    );
  }

  // Modified to include delete option
  Widget _buildNoteItem({
    required String date,
    required String note,
    required String doctor,
    required String noteId,
    required Function onDelete,
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
                    onTap: () => onDelete(),
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

  // Function to show add note dialog
  void _showAddNoteDialog(
      BuildContext context, String patientId, String admissionId) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Doctor Note'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter your note here',
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
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                // Get current date in the required format
                final now = DateTime.now();
                final formattedDate =
                    "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

                // Add the note
                await _addDoctorNote(
                    patientId, admissionId, textController.text, formattedDate);

                // Close dialog and refresh notes
                Navigator.pop(context);
                _refreshNotes();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Function to fetch doctor notes
  Future<List<dynamic>> _fetchDoctorNotes(
      String patientId, String admissionId) async {
    final url =
        Uri.parse('${KVM_URL}/doctors/fetchNotes/$patientId/$admissionId');
    print(url);
    try {
      final response = await http.get(url);
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['doctorNotes'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception("Error: ${error['message']}");
      }
    } catch (e) {
      throw Exception("Failed to fetch doctor notes: $e");
    }
  }

  // Function to add a doctor note
  Future<void> _addDoctorNote(
      String patientId, String admissionId, String text, String date) async {
    try {
      await doctor.addDoctorNote(
        patientId: patientId,
        admissionId: admissionId,
        text: text,
        date: date,
      );
    } catch (e) {
      print("Error adding note: $e");
    }
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: _sectionGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isLoading) Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLoading
                      ? const SizedBox(
                          width: 60,
                          height: 20,
                          child: CustomLoadingAnimation(),
                        )
                      : Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
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

  // Function to delete a doctor note
  Future<void> _deleteNote(
      String patientId, String admissionId, String noteId) async {
    try {
      await doctor.deleteDoctorNote(
        patientId: patientId,
        admissionId: admissionId,
        noteId: noteId,
      );

      // Refresh notes after deletion
      _refreshNotes();
    } catch (e) {
      print("Error deleting note: $e");
    }
  }
}
