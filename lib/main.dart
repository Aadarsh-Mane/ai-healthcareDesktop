import 'dart:async';
import 'dart:math';

import 'package:doctordesktop/Admin/AdminAuthDialod.dart';
import 'package:doctordesktop/Admin/AdminDashboard.dart';
import 'package:doctordesktop/Admin/BedManagement.dart';
import 'package:doctordesktop/Admin/BillTrackScreen.dart';
import 'package:doctordesktop/Admin/ReceptionAuthDialog.dart';
import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/AddMedicine.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/Doctor/MedicalRecordScreen.dart';
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
import 'package:doctordesktop/oet.dart';
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
import 'package:doctordesktop/screens/tess.dart';
import 'package:doctordesktop/screens/theme_showcase_screen.dart';
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
    // return HmsApp();
    // return ThemeShowcaseScreen();
    return HomePage();
    // MedicalRecordsScreen(
    //   patientId: 'LAL361', // Example patient ID
    //   admissionId: '6891097233773366b828eefe', // Example admission ID
    // );
  }

  // Drawer widget
}
