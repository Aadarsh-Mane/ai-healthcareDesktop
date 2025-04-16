import 'package:doctordesktop/Admin/BedManagement.dart';
import 'package:doctordesktop/Doctor/Dashboard/HomeScreen.dart';
import 'package:doctordesktop/Doctor/SeeNurseAttendace.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/main.dart';
import 'package:doctordesktop/reception/CreateAppointment.dart';
import 'package:doctordesktop/reception/ExternalDoctorRegistration.dart';
import 'package:doctordesktop/reception/PatientAllDischargedScreen.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/reception/ReceptionAdmitted.dart';
import 'package:doctordesktop/reception/ReceptionMainScreen.dart';
import 'package:doctordesktop/screens/DoctorRegister.dart';
import 'package:doctordesktop/screens/ListPatienAssignToDoctor.dart';
import 'package:doctordesktop/screens/NurseRegister.dart';
import 'package:flutter/material.dart';

class ReceptionDashBoard extends StatelessWidget {
  const ReceptionDashBoard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF8FBFD),
      ),
      home: MainLayout(key: MainLayout.globalKey),
    );
  }
}

class MainLayout extends StatefulWidget {
  // Add this static GlobalKey
  static final GlobalKey<_MainLayoutState> globalKey =
      GlobalKey<_MainLayoutState>();

  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false; // Add this state variable

  final List<Widget> _screens = [
    // Your existing screens
    const PatientRegistrationScreen(),
    const DischargedPatientsScreen1(),
    PatientAssignmentScreen(),
    DoctorListScreen(),
    PatientListScreen(),
    ReceptionBedManagementScreen(),
    ExternalDoctorRegister(),
    const ReceptionMainScreen(),
  ];

  // Add this new public method
  void navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Add toggle method for sidebar
  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SidebarWidget(
            selectedIndex: _selectedIndex,
            isCollapsed: _isSidebarCollapsed, // Pass the collapsed state
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            onToggle: _toggleSidebar, // Pass the toggle function
          ),

          // Main Content Area (includes Navbar and Screen Content)
          Expanded(
            child: Column(
              children: [
                // Navbar at the top
                NavbarWidget(
                  onMenuTap: _toggleSidebar, // Allow toggling from navbar too
                ),

                // Screen Content
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Updated Sidebar Widget
class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final bool isCollapsed;
  final Function(int) onItemSelected;
  final VoidCallback onToggle;

  const SidebarWidget({
    Key? key,
    required this.selectedIndex,
    required this.isCollapsed,
    required this.onItemSelected,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 70 : 260, // Width changes based on collapse state
      color: const Color(0xFF1E2843),
      child: Column(
        children: [
          // App Logo and Brand Name with toggle button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'HMS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],

                // Toggle button
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    isCollapsed
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                  tooltip: isCollapsed ? 'Expand' : 'Collapse',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // User Profile Section - Only show fully when expanded
          if (!isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.blue.shade200,
                      child: const Center(
                        child: Image(image: AssetImage('${AppImages.logo}')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${AppStrings.hospitalName}",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Reception',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Simplified avatar for collapsed state
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.blue.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  label: 'Patient Registration',
                  isSelected: selectedIndex == 0,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(0),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.people_outline,
                  label: 'Discharged Patients',
                  isSelected: selectedIndex == 1,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(1),
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.calendar_today_outlined,
                  label: 'Patient Assignment',
                  isSelected: selectedIndex == 2,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(2),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.medical_services_outlined,
                  label: 'Doctors',
                  isSelected: selectedIndex == 3,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(3),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'SYSTEM',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                _buildNavItem(
                  index: 4,
                  icon: Icons.settings_outlined,
                  label: 'Patients',
                  isSelected: selectedIndex == 4,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(4),
                ),
                _buildNavItem(
                  index: 5,
                  icon: Icons
                      .person_add_outlined, // Changed icon to be more specific
                  label: 'Bed Assignment',
                  isSelected: selectedIndex == 5,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(5),
                ),
                _buildNavItem(
                  index: 6,
                  icon: Icons
                      .health_and_safety_outlined, // Changed icon to be more specific
                  label: 'External Doctor',
                  isSelected: selectedIndex == 6,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(6),
                ),
                _buildNavItem(
                  index: 6,
                  icon: Icons
                      .health_and_safety_outlined, // Changed icon to be more specific
                  label: 'Create Appointment',
                  isSelected: selectedIndex == 7,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(7),
                ),
              ],
            ),
          ),

          // Logout Button - adapted for collapsed state
          Padding(
            padding: EdgeInsets.all(isCollapsed ? 8 : 16),
            child: isCollapsed
                ? IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 24),
                    tooltip: 'Back',
                  )
                : OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: Colors.white70),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isCollapsed,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin:
          EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 12, horizontal: isCollapsed ? 8 : 16),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 22,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Updated Navbar Widget with menu toggle
class NavbarWidget extends StatelessWidget {
  final VoidCallback onMenuTap;

  const NavbarWidget({
    Key? key,
    required this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu toggle button
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onMenuTap,
            tooltip: 'Toggle sidebar',
            color: const Color(0xFF1E2843),
          ),

          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Search...',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Remaining navbar items (unchanged)
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Color(0xFF1E2843)),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.email_outlined, color: Color(0xFF1E2843)),
          ),

          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 30,
                    height: 30,
                    color: Colors.blue.shade100,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF1E2843),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E2843),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF1E2843),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
