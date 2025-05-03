import 'package:doctordesktop/Doctor/Tabs/GetInvestigation.dart';
import 'package:doctordesktop/Lab/LabScreen.dart';
import 'package:doctordesktop/reception/CreateAppointment.dart';
import 'package:doctordesktop/reception/IpdDetailScreen.dart';
import 'package:doctordesktop/reception/Sidebar.dart';
import 'package:flutter/material.dart';

class LabDashBoardScreen extends StatefulWidget {
  const LabDashBoardScreen({Key? key}) : super(key: key);

  @override
  State<LabDashBoardScreen> createState() =>
      _RegistrationDashboardScreenState();
}

class _RegistrationDashboardScreenState extends State<LabDashBoardScreen> {
  int _selectedNavIndex = 0;

  // Map of screen widgets indexed by their navigation index
  late final Map<int, Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize all screens
    _screens = {
      0: const LabPatientsScreen(),
      1: const InvestigationScreen1(),
      2: const Center(child: Text('Screen 3')),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          ImprovedSidebar(
            navigationItems: [
              NavigationItem(
                index: 0,
                icon: Icons.person,
                label: 'Patients',
              ),
              NavigationItem(
                index: 1,
                icon: Icons.search,
                label: 'Investigations',
              ),
              // NavigationItem(
              //   index: 2,
              //   icon: Icons.info,
              //   label: 'About',
              // ),
            ],
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
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
