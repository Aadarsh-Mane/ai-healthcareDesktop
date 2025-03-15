import 'package:doctordesktop/Doctor/AssignedLabScreen.dart';
import 'package:doctordesktop/Doctor/AssignedPatientScreen.dart';
import 'package:doctordesktop/LogoutScreen.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/core/utils/DoctorCard.dart';
import 'package:doctordesktop/main.dart';
import 'package:doctordesktop/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';

class DoctorMainScreen extends StatefulWidget {
  @override
  _DoctorMainScreenState createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DoctorHomeScreen(),
    );
  }
}

class DoctorHomeScreen extends ConsumerStatefulWidget {
  @override
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(doctorProfileProvider.notifier).getDoctorProfile();
    });
  }

  final List<Map<String, dynamic>> doctorCards = [
    {
      'title': 'Assigned Patients',
      'imagePath': 'assets/images/assigned.png',
      'screen': AssignedPatientsScreen(),
    },
    {
      'title': 'Assigned Labs',
      'imagePath': 'assets/images/labs1.png',
      'screen': AssignedLabsScreen(),
    },
    {
      'title': 'Patients',
      'imagePath': 'assets/images/ask.png',
      'screen': PatientListScreen(),
    },
    {
      'title': 'Home',
      'imagePath': 'assets/images/lists.png',
      'screen': HomeScreen(),
    },
    {
      'title': 'Logout',
      'imagePath': 'assets/images/logout.png',
      'screen': LogoutScreen(),
    },
    // {
    //   'title': 'Home',
    //   'imagePath': 'assets/images/logout.png',
    //   'screen': HomeScreen(),
    // },
  ];
  @override
  Widget build(BuildContext context) {
    final doctorProfile = ref.watch(doctorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 10,
        toolbarHeight: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "${AppStrings.hospitalName} Doctor Portal,",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "“Your dedication saves lives, and your compassion inspires hope.”",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bb1.png'),
            opacity: 0.3,
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              // Doctor Profile Card with Animation and subtle gradient effect
              doctorProfile == null
                  ? Center(
                      child: ElevatedButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.deepPurpleAccent, // Cyan background color
                        foregroundColor: Colors.white, // White text color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9), // Padding for better appearance
                      ),
                      child: const Text(
                        "You are not logged in. Please login to continue",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Bold text for emphasis
                        ),
                      ),
                    ))
                  : AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF005F9E),
                            Color(0xFF00B8D4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                AssetImage('assets/images/doctor14.png'),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome, Dr. ${doctorProfile.doctorName}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Email: ${doctorProfile.email}",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 20),
                        ],
                      ),
                    ),
              const SizedBox(height: 10),

              // Navigation Buttons with improved hover effect and spacing
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.5,
                ),
                itemCount: doctorCards.length,
                itemBuilder: (context, index) {
                  final card = doctorCards[index];
                  return DoctorCard(
                    title: card['title'],
                    imagePath: card['imagePath'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => card['screen'],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // Animated Footer with fade-in effect
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Powered by 20s Developers",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.developer_mode, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          "${AppStrings.hospitalName}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent[100],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Navigation Button with Animation and hover effect
  Widget _buildNavButton(String label, IconData icon, VoidCallback onPressed) {
    bool isHovered = false; // Track the hover state

    return InkWell(
      onTap: onPressed,
      onHover: (isHoveredState) {
        setState(() {
          isHovered = isHoveredState; // Update hover state
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: isHovered ? Colors.cyan : Colors.cyan, // Change color on hover
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
