import 'package:doctordesktop/Doctor/SeeNurseAttendace.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/reception/PatientAllDischargedScreen.dart';
import 'package:doctordesktop/reception/PatientDischarge.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/screens/DoctorRegister.dart';
import 'package:doctordesktop/screens/ListPatienAssignToDoctor.dart';
import 'package:doctordesktop/screens/NurseRegister.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminAuthDialog extends StatefulWidget {
  @override
  _AdminAuthDialogState createState() => _AdminAuthDialogState();
}

class _AdminAuthDialogState extends State<AdminAuthDialog> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String correctUserId = "${AllUserPassword.adminUser}";
  final String correctPassword = "${AllUserPassword.adminPassword}";

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _authenticate(BuildContext context) {
    String userId = _userIdController.text;
    String password = _passwordController.text;

    if (userId == correctUserId && password == correctPassword) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DesktopButtonScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid User ID or Password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(), // Needed to capture keyboard events
      onKey: (RawKeyEvent event) {
        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          // Trigger login on Enter key press
          _authenticate(context);
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Admin Login',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _authenticate(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}

class DesktopButtonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6FCFF),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Admin Panel',
          style: TextStyle(color: Colors.cyan),
        ),
        backgroundColor: Colors.black,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('${AppImages.admin}'),
            fit: BoxFit.contain,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0, left: 10.0, top: 70.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Handle button 1 press
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DoctorListScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF7CDCE8), // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 80, vertical: 30),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rectangular shape
                        ),
                      ),
                      child: const Text('All Doctors'),
                    ),
                    const SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: () {
                        // Handle button 2 press
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PatientAssignmentScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF7CDCE8), // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rectangular shape
                        ),
                      ),
                      child: const Text('Doctor Assigned'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Handle button 3 press
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DoctorListScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF7CDCE8), // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 95, vertical: 30),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rectangular shape
                        ),
                      ),
                      child: const Text('Doctors'),
                    ),
                    const SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PatientListScreen()),
                        );
                        // Handle button 4 press
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF7CDCE8), // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 95, vertical: 30),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rectangular shape
                        ),
                      ),
                      child: const Text('Patients'),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Handle button 3 press
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DoctorRegisterScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF7CDCE8), // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rectangular shape
                        ),
                      ),
                      child: const Text('Doctor Register'),
                    ),
                    const SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NurseRegisterScreen()),
                        );
                        // Handle button 4 press
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF7CDCE8), // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rectangular shape
                        ),
                      ),
                      child: const Text('Nurse Register'),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Handle button 3 press
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GetAllAttendance()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF7CDCE8), // Background color
                        padding:
                            EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                        textStyle: TextStyle(fontSize: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rectangular shape
                        ),
                      ),
                      child: const Text('Nurse Attendance'),
                    ),
                    const SizedBox(width: 30),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (context) => NurseRegisterScreen()),
                    //     );
                    //     // Handle button 4 press
                    //   },
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Color(0XFF7CDCE8), // Background color
                    //     padding:
                    //         EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                    //     textStyle: TextStyle(fontSize: 20),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius:
                    //           BorderRadius.circular(8), // Rectangular shape
                    //     ),
                    //   ),
                    //   child: const Text('Nurse Register'),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
