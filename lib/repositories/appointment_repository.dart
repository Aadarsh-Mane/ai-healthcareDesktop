// services/appointment_service.dart
import 'dart:convert';
import 'package:doctordesktop/External/DoctorCalendarView.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:http/http.dart' as http;

class AppointmentService {
  // Get all external doctors
  Future<List<Doctor>> getExternalDoctors() async {
    final response = await http.get(
      Uri.parse('$KVM_URL/reception/listExternalDoctors'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['doctors'] as List)
          .map((json) => Doctor.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load doctors');
    }
  }

  // Get all appointments
  Future<List<Appointment>> getAllAppointments() async {
    final response = await http.get(
      Uri.parse('$KVM_URL/reception/getAllAppointments'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['appointments'] as List)
          .map((json) => Appointment.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }
}
