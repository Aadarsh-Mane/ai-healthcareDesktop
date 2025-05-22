import 'package:doctordesktop/External/DoctorCalendarView.dart';
import 'package:doctordesktop/External/ExternalDoctorlist.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/reception/CreateAppointment.dart';
import 'package:doctordesktop/reception/ExternalDoctorRegistration.dart';
import 'package:doctordesktop/reception/IpdDetailScreen.dart';
import 'package:doctordesktop/reception/IpdRegistration.dart';
import 'package:doctordesktop/reception/OpdRegistration.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/reception/ReceptionAdmitted.dart';
import 'package:doctordesktop/reception/Sidebar.dart';
import 'package:flutter/material.dart';

class RegistrationSideBar extends StatefulWidget {
  const RegistrationSideBar({Key? key}) : super(key: key);

  @override
  State<RegistrationSideBar> createState() => _ExternalSideBarState();
}

class _ExternalSideBarState extends State<RegistrationSideBar> {
  int _selectedNavIndex = 0;

  // Map of screen widgets indexed by their navigation index
  late final Map<int, Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize all screens
    _screens = {
      // 0: const PatientRegistrationScreen(),
      0: const OPDRegistrationScreen(),
      1: const IpdDetailScreen(),
      2: const PatientListScreen(),
      3: const ReceptionBedManagementScreen()
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          ImprovedSidebar(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
            navigationItems: [
              NavigationItem(
                index: 0,
                icon: Icons.medical_information,
                label: 'OPD',
              ),
              NavigationItem(
                index: 1,
                icon: Icons.medical_information,
                label: 'IPD',
              ),
              NavigationItem(
                index: 2,
                icon: Icons.person_pin,
                label: 'Patients',
              ),
              NavigationItem(
                index: 3,
                icon: Icons.meeting_room,
                label: 'Bed Assignment',
              ),
            ],
          ),

          // Content area - shows the selected screen
          Expanded(
            child: _screens[_selectedNavIndex] ??
                const Center(child: Text('Screen not implemented yet')),
          ),
        ],
      ),
    );
  }
}
