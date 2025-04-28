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
      'screen': LaboratoryAssignmentsScreen(),
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
                              builder: (context) => LoginScreen1()),
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
// import 'package:doctordesktop/Doctor/AssignedLabScreen.dart';
// import 'package:doctordesktop/Doctor/AssignedPatientScreen.dart';
// import 'package:doctordesktop/LogoutScreen.dart';
// import 'package:doctordesktop/Patient/fetchPatient.dart';
// import 'package:doctordesktop/authProvider/auth_provider.dart';
// import 'package:doctordesktop/constants/Assets.dart';
// import 'package:doctordesktop/core/utils/DoctorCard.dart';
// import 'package:doctordesktop/main.dart';
// import 'package:doctordesktop/screens/login_screen.dart';
// import 'package:doctordesktop/services/motion_control.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class DoctorMainScreen extends StatefulWidget {
//   @override
//   _DoctorMainScreenState createState() => _DoctorMainScreenState();
// }

// class _DoctorMainScreenState extends State<DoctorMainScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: DoctorHomeScreen(),
//     );
//   }
// }

// class DoctorHomeScreen extends ConsumerStatefulWidget {
//   @override
//   _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
// }

// class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
//   MotionControlServer? _motionServer;
//   final List<String> _logMessages = [];
//   bool _showLogs = false;
//   int _selectedCardIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       ref.read(doctorProfileProvider.notifier).getDoctorProfile();
//       _initMotionServer();
//     });
//   }

//   @override
//   void dispose() {
//     _stopMotionServer();
//     super.dispose();
//   }

//   // Initialize the motion control server
//   Future<void> _initMotionServer() async {
//     _motionServer = MotionControlServer(
//       ref,
//       onLog: (message) {
//         setState(() {
//           _logMessages.add(message);
//           // Keep only the last 20 messages
//           if (_logMessages.length > 20) {
//             _logMessages.removeAt(0);
//           }
//         });
//       },
//       onIndexChanged: (index) {
//         setState(() {
//           _selectedCardIndex = index;
//         });
//       },
//       onSelectCurrentOption: () {
//         _navigateToSelectedScreen();
//       },
//     );

//     // Start the server
//     await _motionServer!.startServer();
//   }

//   // Stop the motion control server
//   Future<void> _stopMotionServer() async {
//     if (_motionServer != null) {
//       await _motionServer!.stopServer();
//     }
//   }

//   // Navigate to the currently selected screen
//   void _navigateToSelectedScreen() {
//     if (_selectedCardIndex >= 0 && _selectedCardIndex < doctorCards.length) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => doctorCards[_selectedCardIndex]['screen'],
//         ),
//       );
//     }
//   }

//   final List<Map<String, dynamic>> doctorCards = [
//     {
//       'title': 'Assigned Patients',
//       'imagePath': 'assets/images/assigned.png',
//       'screen': AssignedPatientsScreen(),
//       'specialty': 'Patient Management',
//     },
//     {
//       'title': 'Assigned Labs',
//       'imagePath': 'assets/images/labs1.png',
//       'screen': AssignedLabsScreen(),
//       'specialty': 'Laboratory Tests',
//     },
//     {
//       'title': 'Patients',
//       'imagePath': 'assets/images/ask.png',
//       'screen': PatientListScreen(),
//       'specialty': 'Patient Directory',
//     },
//     {
//       'title': 'Home',
//       'imagePath': 'assets/images/lists.png',
//       'screen': HomeScreen(),
//       'specialty': 'Dashboard',
//     },
//     {
//       'title': 'Logout',
//       'imagePath': 'assets/images/logout.png',
//       'screen': LogoutScreen(),
//       'specialty': 'Exit Application',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final doctorProfile = ref.watch(doctorProfileProvider);
//     final isConnected = ref.watch(connectionStatusProvider);
//     final connectedDevice = ref.watch(connectedDeviceProvider);

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue[900],
//         elevation: 10,
//         toolbarHeight: 90,
//         actions: [
//           // Mobile control status indicator
//           if (isConnected && connectedDevice != null)
//             Padding(
//               padding: const EdgeInsets.only(right: 16.0),
//               child: Row(
//                 children: [
//                   Icon(Icons.phone_android, color: Colors.green),
//                   SizedBox(width: 8),
//                   Text(
//                     "Mobile Connected",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.info_outline),
//                     onPressed: () {
//                       _showConnectionInfoDialog();
//                     },
//                     color: Colors.white,
//                   ),
//                 ],
//               ),
//             ),
//           // Toggle logs
//           IconButton(
//             icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
//             onPressed: () {
//               setState(() {
//                 _showLogs = !_showLogs;
//               });
//             },
//             tooltip: _showLogs ? "Hide Logs" : "Show Logs",
//           ),
//         ],
//         title: Padding(
//           padding: const EdgeInsets.only(left: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "${AppStrings.hospitalName} Doctor Portal,",
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Your dedication saves lives, and your compassion inspires hope.",
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: Colors.white70,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       backgroundColor: Colors.grey[50],
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/images/bb1.png'),
//             opacity: 0.3,
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Stack(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(15.0),
//               child: Column(
//                 children: [
//                   // Doctor Profile Card with Animation and subtle gradient effect
//                   doctorProfile == null
//                       ? Center(
//                           child: ElevatedButton(
//                           onPressed: () async {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => LoginScreen()),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors
//                                 .deepPurpleAccent, // Cyan background color
//                             foregroundColor: Colors.white, // White text color
//                             shape: RoundedRectangleBorder(
//                               borderRadius:
//                                   BorderRadius.circular(8), // Rounded corners
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 9), // Padding for better appearance
//                           ),
//                           child: const Text(
//                             "You are not logged in. Please login to continue",
//                             style: TextStyle(
//                               fontWeight:
//                                   FontWeight.bold, // Bold text for emphasis
//                             ),
//                           ),
//                         ))
//                       : AnimatedContainer(
//                           duration: Duration(milliseconds: 500),
//                           padding: const EdgeInsets.all(10.0),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Color(0xFF005F9E),
//                                 Color(0xFF00B8D4),
//                               ],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black12,
//                                 blurRadius: 10,
//                                 offset: Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               CircleAvatar(
//                                 radius: 60,
//                                 backgroundImage:
//                                     AssetImage('assets/images/doctor14.png'),
//                               ),
//                               const SizedBox(width: 20),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "Welcome, Dr. ${doctorProfile.doctorName}",
//                                     style: TextStyle(
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   Text(
//                                     "Email: ${doctorProfile.email}",
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       color: Colors.white70,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(width: 20),
//                             ],
//                           ),
//                         ),
//                   const SizedBox(height: 20),

//                   // Connection status banner for mobile control
//                   if (isConnected && connectedDevice != null)
//                     Container(
//                       margin: EdgeInsets.only(bottom: 20),
//                       padding:
//                           EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.green[100],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.green[400]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.phone_android, color: Colors.green[700]),
//                           SizedBox(width: 12),
//                           Text(
//                             "Mobile Control Active: Use phone to navigate menu",
//                             style: TextStyle(
//                               color: Colors.green[800],
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Spacer(),
//                           Text(
//                             "Item ${_selectedCardIndex + 1} of ${doctorCards.length}",
//                             style: TextStyle(
//                               color: Colors.green[800],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                   // Menu cards with modified visual indicator for selection
//                   GridView.builder(
//                     shrinkWrap: true,
//                     physics: NeverScrollableScrollPhysics(),
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       crossAxisSpacing: 20,
//                       mainAxisSpacing: 20,
//                       childAspectRatio: 2.2,
//                     ),
//                     itemCount: doctorCards.length,
//                     itemBuilder: (context, index) {
//                       final card = doctorCards[index];
//                       // Add selection indicator for currently selected card via motion control
//                       return Stack(
//                         children: [
//                           // Original DoctorCard
//                           DoctorCard(
//                             title: card['title'],
//                             imagePath: card['imagePath'],
//                             specialty: card['specialty'] ?? '',
//                             onTap: () {
//                               setState(() {
//                                 _selectedCardIndex = index;
//                               });
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => card['screen'],
//                                 ),
//                               );
//                             },
//                           ),
//                           // Selection indicator overlay
//                           if (index == _selectedCardIndex && isConnected)
//                             Positioned(
//                               top: 10,
//                               right: 10,
//                               child: Container(
//                                 padding: EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.green[700],
//                                   shape: BoxShape.circle,
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black26,
//                                       blurRadius: 4,
//                                       offset: Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Icon(
//                                   Icons.touch_app,
//                                   color: Colors.white,
//                                   size: 20,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       );
//                     },
//                   ),

//                   const SizedBox(height: 20),

//                   // Animated Footer with fade-in effect
//                   AnimatedContainer(
//                     duration: Duration(milliseconds: 500),
//                     padding: const EdgeInsets.symmetric(vertical: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[900],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       children: [
//                         const Text(
//                           "Powered by 20s Developers",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.white70,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.developer_mode,
//                                 color: Colors.white70),
//                             const SizedBox(width: 8),
//                             Text(
//                               "${AppStrings.hospitalName}",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.lightBlueAccent[100],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Logs overlay when enabled
//             if (_showLogs)
//               Positioned(
//                 right: 20,
//                 bottom: 20,
//                 width: 300,
//                 height: 200,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.7),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   padding: EdgeInsets.all(10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Connection Logs",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.close, color: Colors.white),
//                             onPressed: () {
//                               setState(() {
//                                 _showLogs = false;
//                               });
//                             },
//                             iconSize: 16,
//                             padding: EdgeInsets.zero,
//                             constraints: BoxConstraints(),
//                           ),
//                         ],
//                       ),
//                       Divider(color: Colors.white30),
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: _logMessages.length,
//                           reverse: true,
//                           itemBuilder: (context, index) {
//                             return Padding(
//                               padding: const EdgeInsets.only(bottom: 4.0),
//                               child: Text(
//                                 _logMessages[_logMessages.length - 1 - index],
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             // Navigation hints for mobile control
//             if (isConnected && connectedDevice != null)
//               Positioned(
//                 bottom: 20,
//                 left: 20,
//                 child: Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 8,
//                         offset: Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.swipe, color: Colors.blue[900]),
//                       SizedBox(width: 8),
//                       Text(
//                         "Tilt phone to navigate",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[900],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Show connection info dialog
//   void _showConnectionInfoDialog() async {
//     String ipAddress = await _motionServer?.getLocalIpAddress() ?? 'Unknown';

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.phone_android, color: Colors.green),
//             SizedBox(width: 8),
//             Text('Mobile Control Active'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Your desktop is being controlled by a mobile device.'),
//             SizedBox(height: 16),
//             Text('Desktop IP: $ipAddress:8080',
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//             SizedBox(height: 8),
//             Text('Instructions:'),
//             SizedBox(height: 4),
//             Text('• Tilt phone left/right to navigate'),
//             Text('• Tilt phone forward to select'),
//             Text('• Use buttons for manual control'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: Text('OK'),
//           ),
//           TextButton(
//             onPressed: () async {
//               await _stopMotionServer();
//               await _initMotionServer();
//               Navigator.of(context).pop();
//             },
//             child: Text('Restart Server'),
//           ),
//         ],
//       ),
//     );
//   }
// }
