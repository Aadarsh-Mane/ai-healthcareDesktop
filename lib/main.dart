import 'dart:async';
import 'dart:math';

import 'package:doctordesktop/Admin/AdminAuthDialod.dart';
import 'package:doctordesktop/Admin/AdminDashboard.dart';
import 'package:doctordesktop/Admin/BedManagement.dart';
import 'package:doctordesktop/Admin/ReceptionAuthDialog.dart';
import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/AddMedicine.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/Doctor/pa.dart';
import 'package:doctordesktop/External/CommonScreen.dart';
import 'package:doctordesktop/External/DashBoard.dart';
import 'package:doctordesktop/Lab/LabAuthDialog.dart';
import 'package:doctordesktop/Lab/LabDashBoard.dart';
import 'package:doctordesktop/Lab/LabScreen.dart';
import 'package:doctordesktop/Working.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/AppTheme.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/gamm.dart';
import 'package:doctordesktop/model/getPatientHistory.dart';
import 'package:doctordesktop/pharmacy/CreateSalesScreen.dart';
import 'package:doctordesktop/pharmacy/PrescriptionScreen.dart';
import 'package:doctordesktop/reception/PatientDischarge.dart';
import 'package:doctordesktop/reception/ReceptionAdmitted.dart';
import 'package:doctordesktop/reception/ReceptionDashboard.dart';
import 'package:doctordesktop/screens/3d.dart';
import 'package:doctordesktop/screens/AssignDoctor.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/screens/DoctorRegister.dart';
import 'package:doctordesktop/screens/ListPatienAssignToDoctor.dart';
import 'package:doctordesktop/screens/NurseRegister.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/screens/login_screen.dart';
import 'package:doctordesktop/services/motion_control.dart';
import 'package:doctordesktop/services/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(1920, 1080),
      builder: (context, child) {
        return MaterialApp(
          scaffoldMessengerKey: SnackbarService.rootScaffoldMessengerKey,

          title: 'Flutter Windows App',
          theme: AppTheme.lightTheme,
          // home: CreateSaleScreen(),
          // home: PrescriptionToSaleScreen(),
          home: HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    // Check authentication status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).checkLoginStatus();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePage();
  }

  // Drawer widget
  Widget _buildDrawer(BuildContext context) {
    final isLoggedIn = ref.watch(authControllerProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Doctor Dashboard'),
            onTap: () async {
              // Check if already logged in
              final isLoggedIn = ref.read(authControllerProvider);
              final userType =
                  await ref.read(authControllerProvider.notifier).getUsertype();

              if (isLoggedIn && userType == 'doctor') {
                // Navigate directly to doctor main screen
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorMainScreen()),
                );
              } else {
                // Navigate to login screen
                Navigator.pop(context); // Close the drawer first
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => DoctorAuthScreen()),
                // );
              }
            },
          ),
          ListTile(
              leading: Icon(Icons.person_add_alt),
              title: Text('Lab Login'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LabPatientsScreen()),
                );
              }
              // Navigator.pop(context); // Close the drawer first
              // showDialog(
              //   context: context,
              //   builder: (context) => LabAuthDialog(),

              ),
          ListTile(
            leading: Icon(Icons.person_add_alt),
            title: Text('Admin Login'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              showDialog(
                context: context,
                builder: (context) => AdminAuthDialog(),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add_alt_1),
            title: Text('External Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SplashScreen1()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Patient List'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientListScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.list_alt),
            title: Text('Doctor List'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorListScreen()),
              );
            },
          ),
          if (isLoggedIn)
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                Navigator.pop(context); // Close the drawer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully logged out')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _homeTab() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.home),
              fit: BoxFit.fill,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 180.h),
              Wrap(
                spacing: 100.w,
                runSpacing: 30.h,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ReceptionDashBoard()),
                      );
                    },
                    style: _buttonStyle(),
                    child: Text('Reception Login', style: _buttonTextStyle()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Check if already logged in first
                      final isLoggedIn = ref.read(authControllerProvider);
                      if (isLoggedIn) {
                        // If already logged in, check user type
                        ref
                            .read(authControllerProvider.notifier)
                            .getUsertype()
                            .then((userType) {
                          if (userType == 'doctor') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DoctorMainScreen()),
                            );
                          } else {
                            // Not a doctor, go to login
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen1()),
                            );
                          }
                        });
                      } else {
                        // Not logged in, go to login
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen1()),
                        );
                      }
                    },
                    style: _buttonStyle(),
                    child: Text('Doctor Login', style: _buttonTextStyle()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LabDashBoardScreen()),
                      );
                    },
                    style: _buttonStyle(),
                    child: Text('Lab Login', style: _buttonTextStyle()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _screensTab() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/sk.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 83.0),
        child: Center(
          child: Wrap(
            spacing: 40.w,
            runSpacing: 30.h,
            children: [
              // Add your admin screen buttons here
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTab() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('${AppImages.home}'),
          fit: BoxFit.fill,
        ),
      ),
      child: Center(),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blueAccent,
      elevation: 8,
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      shadowColor: Colors.blueGrey.withOpacity(0.5),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ).copyWith(
      side: MaterialStateProperty.all(
        BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }

  TextStyle _buttonTextStyle() {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Colors.white,
    );
  }
}
