// import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
// import 'package:doctordesktop/authProvider/auth_provider.dart';
// import 'package:doctordesktop/screens/login_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // This screen handles doctor authentication flow
// class DoctorAuthScreen extends ConsumerStatefulWidget {
//   @override
//   ConsumerState<DoctorAuthScreen> createState() => _DoctorAuthScreenState();
// }

// class _DoctorAuthScreenState extends ConsumerState<DoctorAuthScreen> {
//   bool _isLoading = true;
  
//   @override
//   void initState() {
//     super.initState();
//     // Check authentication on init
//     _checkAuth();
//   }
  
//   // Check if user is already authenticated and is a doctor
//   Future<void> _checkAuth() async {
//     final authController = ref.read(authControllerProvider.notifier);
//     final token = await authController.checkLoginStatus();
    
//     if (token != null) {
//       // Get user type
//       final userType = await authController.getUsertype();
      
//       if (userType == 'doctor') {
//         // Already authenticated as doctor, navigate to doctor screen
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushReplacement(
//             context, 
//             MaterialPageRoute(builder: (context) => DoctorMainScreen())
//           );
//         });
//         return;
//       }
//     }
    
//     // Not authenticated or not a doctor, show login screen
//     setState(() {
//       _isLoading = false;
//     });
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     // Watch the auth state
//     final isLoggedIn = ref.watch(authControllerProvider);
    
//     // If already logged in as this point, it means the user just logged in
//     // through the login screen shown below
//     if (isLoggedIn) {
//       return FutureBuilder<String?>(
//         future: ref.read(authControllerProvider.notifier).getUsertype(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Scaffold(
//               body: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }
          
//           final userType = snapshot.data;
          
//           if (userType == 'doctor') {
//             // Navigate to doctor screen
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => DoctorMainScreen()),
//               );
//             });
//           }
          
//           // Show loading while navigating
//           return Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         },
//       );
//     }
    
//     // If still loading auth check
//     if (_isLoading) {
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
    
//     // Show login screen with title to indicate it's for doctors
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Doctor Login"),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: LoginScxreen(userType: 'doctor'),
//     );
//   }
// }