import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

final nursesProvider = FutureProvider<List<String>>((ref) async {
  final response = await http.get(Uri.parse('${KVM_URL}/doctors/allNurses'));
  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    final filteredNurses = data
        .where((nurse) =>
            nurse['nurseName'] != null && nurse['nurseName'].isNotEmpty)
        .toList();
    return filteredNurses
        .map((nurse) => nurse['nurseName'].toString())
        .toList();
  } else {
    throw Exception('Failed to load nurses');
  }
});

final attendanceProvider =
    FutureProvider.family<List<Attendance>, String>((ref, name) async {
  final response =
      await http.get(Uri.parse('${KVM_URL}/doctors/allAttendees/?name=$name'));
  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map((json) => Attendance.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load attendance');
  }
});

class Attendance {
  final String date;
  final CheckIn checkIn;
  final CheckOut? checkOut;
  final String status;

  Attendance(
      {required this.date,
      required this.checkIn,
      this.checkOut,
      required this.status});

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      date: json['date'],
      checkIn: CheckIn.fromJson(json['checkIn']),
      checkOut:
          json['checkOut'] != null ? CheckOut.fromJson(json['checkOut']) : null,
      status: json['status'],
    );
  }
}

class CheckIn {
  final String time;
  CheckIn({required this.time});
  factory CheckIn.fromJson(Map<String, dynamic> json) =>
      CheckIn(time: json['time']);
}

class CheckOut {
  final String time;
  CheckOut({required this.time});
  factory CheckOut.fromJson(Map<String, dynamic> json) =>
      CheckOut(time: json['time']);
}

class GetAllAttendance extends ConsumerStatefulWidget {
  @override
  _GetAllAttendanceState createState() => _GetAllAttendanceState();
}

class _GetAllAttendanceState extends ConsumerState<GetAllAttendance> {
  String? selectedNurse;
  DateTime selectedDay = DateTime.now();
  Map<DateTime, bool> presentDays = {}; // Store present status

  void fetchAttendance(WidgetRef ref) {
    if (selectedNurse == null) return;

    ref.read(attendanceProvider(selectedNurse!).future).then((attendanceList) {
      Map<DateTime, bool> newPresentDays = {};

      for (var attendance in attendanceList) {
        DateTime apiDate = DateTime.parse(
            attendance.date.split(" ")[0].split('-').reversed.join('-'));
        if (attendance.status == "Present") {
          newPresentDays[apiDate] = true;
        }
      }

      setState(() {
        presentDays = newPresentDays;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final nursesState = ref.watch(nursesProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Nurse Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Color(0xffff96a8),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "Select Nurse to view attendance",
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 10),
            nursesState.when(
              data: (nurses) => Container(
                padding: const EdgeInsets.only(
                    right: 12.0,
                    left: 12.0), // Add padding inside the container

                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButton<String>(
                  focusColor: Colors.amber,
                  iconEnabledColor: Colors.cyan,
                  value: selectedNurse,
                  hint: Text("Select Nurse"),
                  items: nurses
                      .map((nurse) =>
                          DropdownMenuItem(value: nurse, child: Text(nurse)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedNurse = value;
                      presentDays.clear();
                    });
                    fetchAttendance(ref);
                  },
                ),
              ),
              loading: () => CircularProgressIndicator(),
              error: (e, _) => Text("Error loading nurses ${e.toString()}"),
            ),
            SizedBox(height: 10),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() => this.selectedDay = selectedDay);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  DateTime dayOnly = DateTime(date.year, date.month, date.day);
                  if (presentDays[dayOnly] == true) {
                    // Ensure it checks for `true`
                    return Positioned(
                      bottom: 5,
                      child: Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                    );
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 10),
            if (selectedNurse != null)
              AttendanceList(
                  nurseName: selectedNurse!, selectedDate: selectedDay),
          ],
        ),
      ),
    );
  }
}

class AttendanceList extends ConsumerWidget {
  final String nurseName;
  final DateTime selectedDate;

  AttendanceList({required this.nurseName, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceProvider(nurseName));
    return Expanded(
      child: attendanceState.when(
        data: (attendanceList) {
          // Filter the attendance records by selectedDate
          final filteredList = attendanceList.where((attendance) {
            DateTime apiDate = DateTime.parse(
                attendance.date.split(" ")[0].split('-').reversed.join('-'));
            return isSameDay(apiDate, selectedDate);
          }).toList();

          if (filteredList.isEmpty) {
            return Center(child: Text("No attendance records found."));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (displayed once)

              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text("Date", style: _headerStyle)),
                    const VerticalDivider(),
                    Expanded(child: Text("Check-in", style: _headerStyle)),
                    const VerticalDivider(),
                    Expanded(child: Text("Check-out", style: _headerStyle)),
                    const VerticalDivider(),
                    Expanded(child: Text("Status", style: _headerStyle)),
                  ],
                ),
              ),

              // List of Attendance Cards
              Expanded(
                child: ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return AttendanceCard(attendance: filteredList[index]);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error.toString(), style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );
}

class AttendanceCard extends StatelessWidget {
  final Attendance attendance;
  AttendanceCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(attendance.date)),
              VerticalDivider(),
              Expanded(child: Text(attendance.checkIn.time)),
              VerticalDivider(),
              Expanded(child: Text(attendance.checkOut?.time ?? "-")),
              VerticalDivider(),
              Expanded(
                child: Text(
                  attendance.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: attendance.status == "Present"
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );
}
