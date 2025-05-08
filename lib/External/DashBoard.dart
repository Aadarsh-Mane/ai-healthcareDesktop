import 'dart:convert';
import 'package:doctordesktop/External/AppointMentScreen.dart';
import 'package:doctordesktop/External/CommonScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/reception/Sidebar.dart';
// import 'package:doctordesktop/reception/Sidebar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DoctorDashboard extends StatefulWidget {
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  late String _userName = '';
  late String _userType = '';
  late String _userSpeciality = '';
  int _selectedIndex = 0;
  bool _isLoadingAppointments = false;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  bool _isContentLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchUpcomingAppointments();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Doctor';
      _userType = prefs.getString('user_type') ?? 'doctor';
      _userSpeciality = prefs.getString('doctor_speciality') ?? 'Specialist';
    });
  }

  Future<void> _fetchUpcomingAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _isContentLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('doctor_token') ?? '';

      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getDoctorAppointments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allAppointments = data['doctorAppointments'] ?? [];

        // Convert to List<Map<String, dynamic>> and take only upcoming appointments
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          _upcomingAppointments = allAppointments
              .map((item) => item as Map<String, dynamic>)
              .where((appointment) {
                final appointmentDate =
                    DateTime.parse(appointment['date'] as String);
                return appointmentDate.isAfter(today) ||
                    appointmentDate.isAtSameMomentAs(today);
              })
              .take(5) // Only take the next 5 appointments
              .toList();

          _isLoadingAppointments = false;
          _isContentLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load appointments. Please try again.';
          _isLoadingAppointments = false;
          _isContentLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoadingAppointments = false;
        _isContentLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    // Update selected index and navigate to appropriate screen
    // Add more navigation options as needed
    _selectedIndex = index;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorAppointmentsScreen(),
      ),
    );
    // Navigate to appropriate screen based on selection

    // Add more navigation options as needed
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to appropriate screen based on selection

    // Add more navigation options as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: HospitalTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Back',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side: Improved Sidebar
          ImprovedSidebar(
            navigationItems: [],
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavItemTapped,
          ),

          // Right side: Main content
          Expanded(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),

                // Main Content Area
                Expanded(
                  child: _isContentLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: HospitalTheme.primary),
                              const SizedBox(height: 16),
                              Text(
                                'Loading dashboard...',
                                style:
                                    TextStyle(color: HospitalTheme.textMedium),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64,
                                      color:
                                          HospitalTheme.error.withOpacity(0.7)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error Loading Data',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: HospitalTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage,
                                    style: TextStyle(
                                        color: HospitalTheme.textMedium),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _fetchUpcomingAppointments,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _buildDashboardContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Doctor Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const Spacer(),

          // Quick Actions
          IconButton(
            icon: Icon(
              Icons.refresh_outlined,
              color: HospitalTheme.primary,
            ),
            tooltip: 'Refresh Data',
            onPressed: _fetchUpcomingAppointments,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              // Show notifications in future implementation
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              // Show settings in future implementation
            },
          ),
          const SizedBox(width: 16),

          // User profile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: HospitalTheme.border),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: HospitalTheme.surfaceLight,
                  child: Text(
                    _userName.isNotEmpty
                        ? _userName.substring(0, 1).toUpperCase()
                        : 'D',
                    style: TextStyle(
                      color: HospitalTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Dr. $_userName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _userSpeciality,
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        // _navigateToProfile();
                        break;
                      case 'account':
                        // _navigateToAccountSettings();
                        break;
                      case 'logout':
                        _logout();
                        break;
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              color: HospitalTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('My Profile', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'account',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined,
                              color: HospitalTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Account Settings',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout,
                              color: HospitalTheme.error, size: 18),
                          const SizedBox(width: 8),
                          Text('Logout',
                              style: TextStyle(
                                  color: HospitalTheme.error, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card and Upcoming Appointments in the same row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Welcome Card with Stats
              Expanded(
                flex: 2,
                child: HospitalTheme.buildCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor Profile
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: HospitalTheme.primary.withOpacity(0.3),
                                  width: 4),
                              color: HospitalTheme.surfaceLight,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: HospitalTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Doctor Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Welcome back, Dr. $_userName',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: HospitalTheme.surfaceLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            DateTime.now().day.toString(),
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: HospitalTheme.primary,
                                            ),
                                          ),
                                          Text(
                                            _getMonthAbbreviation(
                                                DateTime.now().month),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: HospitalTheme.textMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_userSpeciality - ${_getUserTypeLabel()}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: HospitalTheme.textMedium,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Status badge and additional info
                                Row(
                                  children: [
                                    HospitalTheme.buildStatusBadge(
                                      'Active Session',
                                      color: HospitalTheme.success,
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: HospitalTheme.surfaceLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: HospitalTheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Last Login: Today, 9:30 AM',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: HospitalTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Statistics Row
                      Row(
                        children: [
                          _buildStatItem(
                            title: 'Total Appointments',
                            count: _upcomingAppointments.length.toString(),
                            icon: Icons.calendar_today_outlined,
                            iconColor: HospitalTheme.medical,
                          ),
                          _buildStatDivider(),
                          _buildStatItem(
                            title: 'Today\'s Appointments',
                            count: _getTodayAppointmentsCount().toString(),
                            icon: Icons.today_outlined,
                            iconColor: HospitalTheme.primary,
                          ),
                          _buildStatDivider(),
                          _buildStatItem(
                            title: 'Total Patients',
                            count: '48',
                            icon: Icons.people_outlined,
                            iconColor: HospitalTheme.laboratory,
                          ),
                          _buildStatDivider(),
                          _buildStatItem(
                            title: 'Pending Reports',
                            count: '7',
                            icon: Icons.description_outlined,
                            iconColor: HospitalTheme.warning,
                          ),
                        ],
                      ),

                      // Button row
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              // Show detailed statistics
                            },
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('View Analytics'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HospitalTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              side: BorderSide(color: HospitalTheme.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DoctorAppointmentsScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('New Appointment'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right side: Upcoming Appointments
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader(
                      'Upcoming Appointments',
                      trailing: TextButton.icon(
                        onPressed: () => _onNavItemTapped(1),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          foregroundColor: HospitalTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Appointment list
                    Container(
                      constraints: const BoxConstraints(maxHeight: 500),
                      child: _isLoadingAppointments
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                    color: HospitalTheme.primary),
                              ),
                            )
                          : _upcomingAppointments.isEmpty
                              ? HospitalTheme.buildCard(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            size: 48,
                                            color: HospitalTheme.textLight,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No upcoming appointments',
                                            style: TextStyle(
                                              color: HospitalTheme.textMedium,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _onNavItemTapped(1),
                                            icon: const Icon(Icons.add),
                                            label: const Text(
                                                'Schedule Appointment'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  HospitalTheme.primary,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _upcomingAppointments.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: _buildEnhancedAppointmentItem(
                                          _upcomingAppointments[index]),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Main content section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Dashboard cards
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader(
                      'Quick Actions',
                      trailing: TextButton.icon(
                        onPressed: () {
                          // Navigate to full dashboard
                        },
                        icon: const Icon(Icons.dashboard_customize, size: 16),
                        label: const Text('Customize Dashboard'),
                        style: TextButton.styleFrom(
                          foregroundColor: HospitalTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick actions grid with hover effects
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          title: 'Manage Appointments',
                          description: 'View and manage all appointments',
                          icon: Icons.calendar_today_outlined,
                          color: HospitalTheme.medical,
                          onTap: () => _onNavItemTapped(1),
                        ),
                        _buildActionCard(
                          title: 'Patient Records',
                          description: 'Search and access patient records',
                          icon: Icons.people_outlined,
                          color: HospitalTheme.primary,
                          onTap: () => _onNavItemTapped(2),
                        ),
                        _buildActionCard(
                          title: 'Today\'s Schedule',
                          description: 'View today\'s appointments',
                          icon: Icons.schedule_outlined,
                          color: HospitalTheme.laboratory,
                          onTap: () => _onNavItemTapped(1),
                        ),
                        _buildActionCard(
                          title: 'Messages',
                          description: 'Check messages and notifications',
                          icon: Icons.message_outlined,
                          color: HospitalTheme.info,
                          onTap: () {},
                        ),
                        _buildActionCard(
                          title: 'Medical Reports',
                          description: 'View and create medical reports',
                          icon: Icons.description_outlined,
                          color: HospitalTheme.pharmacy,
                          onTap: () {},
                        ),
                        _buildActionCard(
                          title: 'Referrals',
                          description: 'Create and manage referrals',
                          icon: Icons.share_outlined,
                          color: HospitalTheme.warning,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Recent activity section
                    HospitalTheme.buildSectionHeader(
                      'Recent Activity',
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DoctorAppointmentsScreen(),
                            ),
                          );
                          // View all activity
                        },
                        child: const Text('View All'),
                        style: TextButton.styleFrom(
                          foregroundColor: HospitalTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Activity list
                    HospitalTheme.buildCard(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        children: _buildActivityItems(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right column - Calendar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HospitalTheme.buildSectionHeader(
                      'Calendar',
                      trailing: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.date_range, size: 16),
                        label: const Text('Month View'),
                        style: TextButton.styleFrom(
                          foregroundColor: HospitalTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Calendar card
                    HospitalTheme.buildCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'March 2025',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.textDark,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chevron_left,
                                        size: 20, color: HospitalTheme.primary),
                                    onPressed: () {},
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right,
                                        size: 20, color: HospitalTheme.primary),
                                    onPressed: () {},
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Calendar slots would go here in a real implementation
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: HospitalTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Calendar View',
                                style: TextStyle(
                                  color: HospitalTheme.textMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40, // Reduced from 50 to 40
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8), // Reduced from 16 to 8
      color: HospitalTheme.border,
    );
  }

  Widget _buildStatItem({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // Reduced padding from 12 to 8
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20, // Reduced size from 24 to 20
            ),
          ),
          const SizedBox(width: 8), // Reduced spacing from 12 to 8
          Expanded(
            // Added Expanded to make text wrap if needed
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20, // Reduced from 22 to 20
                    fontWeight: FontWeight.bold,
                  ),
                  overflow:
                      TextOverflow.ellipsis, // Add this to prevent overflow
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12, // Reduced from 14 to 12
                    color: HospitalTheme.textMedium,
                  ),
                  overflow:
                      TextOverflow.ellipsis, // Add this to prevent overflow
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: HospitalTheme.radiusMedium,
      child: HospitalTheme.buildCard(
        padding: const EdgeInsets.all(16), // Reduced from 20 to 16
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40, // Reduced from 50 to 40
                  height: 40, // Reduced from 50 to 40
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(10), // Reduced from 12 to 10
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24, // Reduced from 28 to 24
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: HospitalTheme.textLight,
                  size: 16, // Reduced from 18 to 16
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced from 16 to 12
            Text(
              title,
              style: const TextStyle(
                fontSize: 15, // Reduced from 16 to 15
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2), // Reduced from 4 to 2
            Text(
              description,
              style: TextStyle(
                fontSize: 13, // Reduced from 14 to 13
                color: HospitalTheme.textMedium,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityItems() {
    final activities = [
      {
        'title': 'Appointment Completed',
        'description': 'You completed an appointment with Sarah Johnson',
        'time': '2 hours ago',
        'icon': Icons.check_circle_outline,
        'color': HospitalTheme.success,
      },
      {
        'title': 'Medical Report Created',
        'description': 'You created a medical report for patient #12845',
        'time': 'Yesterday, 3:45 PM',
        'icon': Icons.description_outlined,
        'color': HospitalTheme.info,
      },
      {
        'title': 'New Message',
        'description': 'Dr. Robert Smith sent you a message about a patient',
        'time': 'Yesterday, 11:30 AM',
        'icon': Icons.message_outlined,
        'color': HospitalTheme.primary,
      },
    ];

    return activities.map((activity) {
      final bool isLast = activities.indexOf(activity) == activities.length - 1;

      return Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (activity['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: activity['color'] as Color,
                size: 24,
              ),
            ),
            title: Text(
              activity['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  activity['description'] as String,
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    color: HospitalTheme.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.more_horiz,
              color: HospitalTheme.textLight,
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              indent: 70,
            ),
        ],
      );
    }).toList();
  }

  Widget _buildEnhancedAppointmentItem(Map<String, dynamic> appointment) {
    final String patientName = appointment['patientName'] ?? 'Patient';
    final String patientId = appointment['patientId'] ?? 'Unknown ID';
    final String time = appointment['time'] ?? '00:00';
    final String appointmentType = appointment['appointmentType'] ?? 'offline';
    final String dateString =
        appointment['date'] ?? DateTime.now().toString().substring(0, 10);
    final DateTime appointmentDate = DateTime.parse(dateString);
    final String symptoms = appointment['symptoms'] ?? 'No symptoms recorded';
    final String status = appointment['status'] ?? 'confirmed';
    final bool isToday = _isToday(appointmentDate);

    return HospitalTheme.buildCard(
      hasShadow: true,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Header with date and status
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10), // Reduced vertical padding
            decoration: BoxDecoration(
              color: isToday
                  ? HospitalTheme.primary.withOpacity(0.1)
                  : HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Wrap with Expanded to allow overflow handling
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 14, // Reduced from 16 to 14
                        color: isToday
                            ? HospitalTheme.primary
                            : HospitalTheme.textMedium,
                      ),
                      const SizedBox(width: 6), // Reduced from 8 to 6
                      Flexible(
                        // Use Flexible to allow text to wrap if needed
                        child: Text(
                          isToday
                              ? 'Today, ${appointmentDate.day} ${_getMonthAbbreviation(appointmentDate.month)}'
                              : '${appointmentDate.day} ${_getMonthAbbreviation(appointmentDate.month)} ${appointmentDate.year}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13, // Added smaller font size
                            color: isToday
                                ? HospitalTheme.primary
                                : HospitalTheme.textMedium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                HospitalTheme.buildStatusBadge(
                  status.substring(0, 1).toUpperCase() + status.substring(1),
                  color: _getStatusColor(status),
                ),
              ],
            ),
          ),

          // Body with patient details - Need to fix the overflow here
          Padding(
            padding: const EdgeInsets.all(12), // Reduced from 16 to 12
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                  children: [
                    // Patient avatar or initials
                    CircleAvatar(
                      radius: 20, // Reduced from 24 to 20
                      backgroundColor: HospitalTheme.surfaceLight,
                      child: Text(
                        patientName.isNotEmpty
                            ? patientName.substring(0, 1).toUpperCase()
                            : 'P',
                        style: TextStyle(
                          fontSize: 16, // Reduced from 18 to 16
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Reduced from 16 to 12

                    // Patient info
                    Expanded(
                      flex: 3, // Give more space to patient info
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 15, // Reduced from 16 to 15
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Add ellipsis if text is too long
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Patient ID: $patientId',
                            style: TextStyle(
                              fontSize: 12, // Reduced from 13 to 12
                              color: HospitalTheme.textMedium,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),

                    // Time and type with smaller flexible space
                    Expanded(
                      flex: 2, // Give less space to time info
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4), // Reduced padding
                            decoration: BoxDecoration(
                              color: HospitalTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(
                                  16), // Reduced from 20 to 16
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Added smaller font size
                                color: HospitalTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize
                                .min, // Keep row as small as possible
                            children: [
                              Icon(
                                appointmentType.toLowerCase() == 'online'
                                    ? Icons.videocam_outlined
                                    : Icons.person_outlined,
                                size: 12, // Reduced from 14 to 12
                                color: HospitalTheme.textMedium,
                              ),
                              const SizedBox(width: 2), // Reduced from 4 to 2
                              Text(
                                appointmentType.toLowerCase() == 'online'
                                    ? 'Online' // Shortened from 'Tele-consultation'
                                    : 'In-person',
                                style: TextStyle(
                                  fontSize: 11, // Reduced from 13 to 11
                                  color: HospitalTheme.textMedium,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Symptoms section if available
                if (symptoms.isNotEmpty &&
                    symptoms != 'No symptoms recorded') ...[
                  const SizedBox(height: 12), // Reduced from 16 to 12
                  const Divider(height: 1),
                  const SizedBox(height: 8), // Reduced from 12 to 8
                  Text(
                    'Symptoms:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13, // Reduced from 14 to 13
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced from 4 to 2
                  Text(
                    symptoms,
                    style: TextStyle(
                      fontSize: 12, // Reduced from 14 to 12
                      color: HospitalTheme.textMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Action buttons
                const SizedBox(height: 12), // Reduced from 16 to 12
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // View appointment details
                      },
                      icon: Icon(Icons.visibility_outlined,
                          size: 16,
                          color:
                              HospitalTheme.primary), // Reduced from 18 to 16
                      label: Text('View',
                          style: TextStyle(
                            color: HospitalTheme.primary,
                            fontSize: 13, // Added smaller font size
                          )),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4), // Reduced padding
                      ),
                    ),
                    const SizedBox(width: 4), // Reduced from 8 to 4
                    if (appointmentType.toLowerCase() == 'online')
                      TextButton.icon(
                        onPressed: () {
                          // Start video consultation
                        },
                        icon: Icon(Icons.videocam_outlined,
                            size: 16,
                            color:
                                HospitalTheme.medical), // Reduced from 18 to 16
                        label: Text('Call', // Shortened from 'Start Call'
                            style: TextStyle(
                              color: HospitalTheme.medical,
                              fontSize: 13, // Added smaller font size
                            )),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4), // Reduced padding
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return HospitalTheme.success;
      case 'cancelled':
        return HospitalTheme.error;
      case 'rescheduled':
        return HospitalTheme.warning;
      case 'completed':
        return HospitalTheme.info;
      default:
        return HospitalTheme.secondary;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getUserTypeLabel() {
    switch (_userType) {
      case 'hospital_doctor':
        return 'Hospital Doctor';
      case 'doctor':
        return 'External Doctor';
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      default:
        return 'User';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  int _getTodayAppointmentsCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _upcomingAppointments
        .where((appointment) => appointment['date'] == todayString)
        .length;
  }
}
