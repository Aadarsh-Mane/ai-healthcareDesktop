import 'package:doctordesktop/Admin/BedManagement.dart';
import 'package:doctordesktop/Admin/PatientBillingScreen.dart';
import 'package:doctordesktop/Admin/PatientManagement.dart';
import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/Dashboard/HomeScreen.dart';
import 'package:doctordesktop/Doctor/SeeNurseAttendace.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/main.dart';
import 'package:doctordesktop/reception/BillingAnalyticsDashboard.dart';
import 'package:doctordesktop/screens/DoctorRegister.dart';
import 'package:doctordesktop/screens/ListPatienAssignToDoctor.dart';
import 'package:doctordesktop/screens/NurseRegister.dart';
import 'package:flutter/material.dart';

class AdminDashBoardScreen extends StatelessWidget {
  const AdminDashBoardScreen({Key? key}) : super(key: key);

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
  final List<Widget> _screens = [
    // Your existing screens
    const DashboardScreen(),
    const BedManagementDashboard(),
    PatientAssignmentScreen(),
    DoctorListScreen(),
    PatientListScreen(),
    DoctorRegisterScreen(),
    NurseRegisterScreen(),
    AdmissionManagementScreen(),
    BillingAnalyticsDashboard(),
  ];

  // Add this new public method
  void navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
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
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),

          // Main Content Area (includes Navbar and Screen Content)
          Expanded(
            child: Column(
              children: [
                // Navbar at the top
                const NavbarWidget(),

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

// Sidebar Widget
class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarWidget({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF1E2843),
      child: Column(
        children: [
          // App Logo and Brand Name
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
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
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'HMS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // User Profile Section
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
                      'Admin',
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

          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemSelected(0),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.people_outline,
                  label: 'Bed Management',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemSelected(1),
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.calendar_today_outlined,
                  label: 'Patient Assignment',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemSelected(2),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.medical_services_outlined,
                  label: 'Doctors',
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemSelected(3),
                ),
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
                _buildNavItem(
                  index: 4,
                  icon: Icons.settings_outlined,
                  label: 'Patients',
                  isSelected: selectedIndex == 4,
                  onTap: () => onItemSelected(4),
                ),
                _buildNavItem(
                  index: 5,
                  icon: Icons.settings_outlined,
                  label: 'Register Doctor',
                  isSelected: selectedIndex == 5,
                  onTap: () => onItemSelected(5),
                ),
                _buildNavItem(
                  index: 6,
                  icon: Icons.settings_outlined,
                  label: 'Register Nurse',
                  isSelected: selectedIndex == 6,
                  onTap: () => onItemSelected(6),
                ),
                _buildNavItem(
                  index: 7,
                  icon: Icons.settings_outlined,
                  label: 'Patient Management',
                  isSelected: selectedIndex == 7,
                  onTap: () => onItemSelected(7),
                ),
                _buildNavItem(
                  index: 8,
                  icon: Icons.settings_outlined,
                  label: 'Analysis',
                  isSelected: selectedIndex == 8,
                  onTap: () => onItemSelected(8),
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
                // Handle logout
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
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 22,
                ),
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
            ),
          ),
        ),
      ),
    );
  }
}

// Navbar Widget
class NavbarWidget extends StatelessWidget {
  const NavbarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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

          const SizedBox(width: 16),

          // Notification Bell
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

          // Messages
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

          // User Profile Button
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

// Screen Widgets
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HospitalDashboardApp();
  }
}
