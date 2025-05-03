import 'package:doctordesktop/reception/CreateAppointment.dart';
import 'package:doctordesktop/reception/IpdDetailScreen.dart';
import 'package:doctordesktop/reception/Sidebar.dart';
import 'package:flutter/material.dart';

class RegistrationDashboard extends StatefulWidget {
  const RegistrationDashboard({Key? key}) : super(key: key);

  @override
  State<RegistrationDashboard> createState() =>
      _RegistrationDashboardScreenState();
}

class _RegistrationDashboardScreenState extends State<RegistrationDashboard> {
  int _selectedNavIndex = 0;

  // Map of screen widgets indexed by their navigation index
  late final Map<int, Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize all screens
    _screens = {
      0: const IpdDetailScreen(),
      1: const Center(child: Text('Screen 2')),
      2: const Center(child: Text('Screen 3')),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          // ImprovedSidebar(
          //   selectedIndex: _selectedNavIndex,
          //   onDestinationSelected: (index) {
          //     setState(() {
          //       _selectedNavIndex = index;
          //     });
          //   },
          // ),

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
