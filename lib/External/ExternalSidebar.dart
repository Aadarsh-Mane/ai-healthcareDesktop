import 'package:doctordesktop/External/DoctorCalendarView.dart';
import 'package:doctordesktop/External/ExternalDoctorlist.dart';
import 'package:doctordesktop/reception/CreateAppointment.dart';
import 'package:doctordesktop/reception/ExternalDoctorRegistration.dart';
import 'package:doctordesktop/reception/Sidebar.dart';
import 'package:flutter/material.dart';

class ExternalSideBar extends StatefulWidget {
  const ExternalSideBar({Key? key}) : super(key: key);

  @override
  State<ExternalSideBar> createState() => _ExternalSideBarState();
}

class _ExternalSideBarState extends State<ExternalSideBar> {
  int _selectedNavIndex = 0;

  // Map of screen widgets indexed by their navigation index
  late final Map<int, Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize all screens
    _screens = {
      0: const ExternalDoctorListScreen(),
      1: const ExternalDoctorRegister(),
      2: const Center(
        child: AboutDialog(
          applicationName: 'Doctor Desktop',
          applicationVersion: '1.0.0',
          applicationIcon: Icon(Icons.medical_services),
          children: [
            Text('This is a sample about dialog for Doctor Desktop.'),
          ],
        ),
      ),
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
                icon: Icons.person,
                label: 'External Doctors',
              ),
              NavigationItem(
                index: 1,
                icon: Icons.calendar_month,
                label: 'Registration',
              ),
              NavigationItem(
                index: 2,
                icon: Icons.meeting_room,
                label: 'Licenses',
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
