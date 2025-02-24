import 'package:doctordesktop/Admin/AdminAuthDialod.dart';
import 'package:doctordesktop/Admin/ReceptionAuthDialog.dart';
import 'package:doctordesktop/Lab/LabAuthDialog.dart';
import 'package:doctordesktop/Lab/LabScreen.dart';
import 'package:doctordesktop/Working.dart';
import 'package:doctordesktop/constants/AppTheme.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/model/getPatientHistory.dart';
import 'package:doctordesktop/reception/PatientDischarge.dart';
import 'package:doctordesktop/screens/3d.dart';
import 'package:doctordesktop/screens/AssignDoctor.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/screens/DoctorRegister.dart';
import 'package:doctordesktop/screens/ListPatienAssignToDoctor.dart';
import 'package:doctordesktop/screens/NurseRegister.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/screens/login_screen.dart';
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
          title: 'Flutter Windows App',
          theme: AppTheme.lightTheme,
          // theme: ThemeData(
          //   primarySwatch: Colors.blue,
          //   textTheme: GoogleFonts.poppinsTextTheme(),
          // ),
          home: HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFeff7f8),
        title: Text(
          '${AppStrings.hospitalName}',
          style: TextStyle(
            color: Colors.cyan,
          ),
        ),
        bottom: TabBar(
          labelColor: Colors.deepPurpleAccent,
          unselectedLabelColor: Colors.grey,
          controller: _tabController,
          tabs: [
            Tab(text: 'Home'),
            Tab(text: 'Admin'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _homeTab(),
          _screensTab(),
          _settingsTab(),
        ],
      ),
    );
  }

  // Drawer widget
  Widget _buildDrawer(BuildContext context) {
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
            title: Text('Doctor Login'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Doct()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add_alt),
            title: Text('Lab Login'),
            onTap: () {
              // Add functionality if needed
              showDialog(
                context: context,
                builder: (context) => LabAuthDialog(),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add_alt),
            title: Text('Admin Login'),
            onTap: () {
              // Add functionality if needed
              showDialog(
                context: context,
                builder: (context) => AdminAuthDialog(),
              );
            },
          ),
          // ListTile(
          //   leading: Icon(Icons.person_add_alt_1),
          //   title: Text('Register Patient'),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => Desktop3DScreen()),
          //     );
          //   },
          // ),
          ListTile(
            leading: Icon(Icons.list),
            title: Text('Patient List'),
            onTap: () {
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DoctorListScreen()),
              );
            },
          ),
          // New Screens
          // ListTile(
          //   leading: Icon(Icons.assignment_ind),
          //   title: Text('Assign Doctor'),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => AssignDoctorScreen()),
          //     );
          //   },
          // ),
          // ListTile(
          //   leading: Icon(Icons.assignment),
          //   title: Text('Patient Assignments'),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //           builder: (context) => PatientAssignmentScreen()),
          //     );
          //   },
          // ),
          // ListTile(
          //   leading: Icon(Icons.settings),
          //   title: Text('Reception Login'),
          //   onTap: () {
          //     // Add functionality if needed
          //     showDialog(
          //       context: context,
          //       builder: (context) => ReceptionAuthDialog(),
          //     );
          //   },
          // ),
          // s
          // ListTile(
          //   leading: Icon(Icons.login_outlined),
          //   title: Text('Doctor Login'),
          //   onTap: () {
          //     // Add functionality if needed
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => Doct()),
          //     );
          //   },
          // ),
          // ListTile(
          //   leading: Icon(Icons.info),
          //   title: Text('Lab '),
          //   onTap: () {
          //     // Add functionality if needed
          //     showDialog(
          //       context: context,
          //       builder: (context) => LabAuthDialog(),
          //     );
          //   },
          // ),
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
              // Text(
              //   'Welcome to the Flutter Windows App',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: 32.sp,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              SizedBox(height: 180.h),
              Wrap(
                spacing: 100.w,
                runSpacing: 30.h,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Add functionality if needed
                      showDialog(
                        context: context,
                        builder: (context) => ReceptionAuthDialog(),
                      );
                    },
                    style: _buttonStyle(),
                    child: Text('Reception Login', style: _buttonTextStyle()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Doct()),
                      );
                    },
                    style: _buttonStyle(),
                    child: Text('Doctor Login ', style: _buttonTextStyle()),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Add functionality if needed
                      showDialog(
                        context: context,
                        builder: (context) => LabAuthDialog(),
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
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => PatientListScreen()),
              //     );
              //   },
              //   style: _buttonStyle(),
              //   child: Text('Get Patient', style: _buttonTextStyle()),
              // ),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => DoctorListScreen()),
              //     );
              //   },
              //   style: _buttonStyle(),
              //   child: Text('Get Doctor', style: _buttonTextStyle()),
              // ),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => AssignDoctorScreen()),
              //     );
              //   },
              //   style: _buttonStyle(),
              //   child: Text('Assign Doctor', style: _buttonTextStyle()),
              // ),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => PatientAssignmentScreen()),
              //     );
              //   },
              //   style: _buttonStyle(),
              //   child: Text('Doctor Patient', style: _buttonTextStyle()),
              // ),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => DischargedPatientsScreen()),
              //     );
              //   },
              //   style: _buttonStyle(),
              //   child: Text('Discharged Patient', style: _buttonTextStyle()),
              // ),
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
