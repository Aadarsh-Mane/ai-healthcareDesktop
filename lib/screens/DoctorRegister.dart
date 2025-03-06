import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:doctordesktop/constants/ToastMessage.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:toastification/toastification.dart';

class DoctorRegisterScreen extends StatefulWidget {
  @override
  _DoctorRegisterScreenState createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String userType = 'doctor';
  String email = '';
  String password = '';
  String doctorName = '';
  String speciality = '';
  String experience = '';
  String department = '';
  String phoneNumber = '';
  File? doctorImage;

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        doctorImage = File(result.files.single.path!);
      });
    } else {
      ToastMessage().showToast(
          context, 'No image selected', '', ToastificationType.warning);
    }
  }

  Future<void> submitData() async {
    final url = '${KVM_URL}/reception/addDoctor';
    if (doctorImage == null) {
      ToastMessage().showToast(
          context, 'Please select an image', '', ToastificationType.error);
      return;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['email'] = email
        ..fields['password'] = password
        ..fields['usertype'] = userType
        ..fields['doctorName'] = doctorName
        ..fields['speciality'] = speciality
        ..fields['experience'] = experience
        ..fields['department'] = department
        ..fields['phoneNumber'] = phoneNumber
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          doctorImage!.path,
        ));

      final response = await request.send();
      if (response.statusCode == 201) {
        ToastMessage().showToast(context, 'Doctor Registered Successfully', '',
            ToastificationType.success);
      } else {
        ToastMessage().showToast(
            context, 'Doctor Not Registered', '', ToastificationType.error);
      }
    } catch (error) {
      ToastMessage().showToast(
          context, 'Something went wrong', '', ToastificationType.error);
    }
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF5FCF9),
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      border: const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
    );
  }
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// class ProductDetailAnimation extends StatefulWidget {
//   const ProductDetailAnimation({
//     super.key,
//   });

//   @override
//   State<ProductDetailAnimation> createState() => _ProductDetailAnimationState();
// }

// class _ProductDetailAnimationState extends State<ProductDetailAnimation>
//     with SingleTickerProviderStateMixin {
//   bool up = false;
//   late AnimationController controller;

//   @override
//   void initState() {
//     super.initState();
//     controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//       reverseDuration: const Duration(milliseconds: 2300),
//     )..addStatusListener((AnimationStatus status) {
//         if (status == AnimationStatus.completed) controller.reverse();
//         if (status == AnimationStatus.dismissed) controller.forward();
//       });

//     controller.forward();
//   }

//   @override
//   void dispose() {
//     // Dispose of the AnimationController
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 35),
//       child: SizedBox(
//           height: 150,
//           width: double.infinity,
//           child: SlideTransition(
//               position: Tween<Offset>(
//                       begin: const Offset(0, -0.1), end: const Offset(0, 0.24))
//                   .animate(controller),
//               child: Image.asset('assets/headphone.png'))),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Doctor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              Image.network(
                "https://i.postimg.cc/nz0YBQcH/Logo-light.png",
                height: 100.h,
              ),
              SizedBox(height: 40.h),
              Text(
                "Register Doctor",
                style: GoogleFonts.poppins(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 36.h),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: _buildInputDecoration('Email'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter your email'
                                : null,
                            onChanged: (value) => setState(() => email = value),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            decoration: _buildInputDecoration('Password'),
                            obscureText: true,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter your password'
                                : null,
                            onChanged: (value) =>
                                setState(() => password = value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 36.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: "Doctor"),
                            readOnly: true,
                            decoration: _buildInputDecoration('User Type'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            decoration: _buildInputDecoration('Doctor Name'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter the doctor\'s name'
                                : null,
                            onChanged: (value) =>
                                setState(() => doctorName = value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 36.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: _buildInputDecoration('Speciality'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter the speciality'
                                : null,
                            onChanged: (value) =>
                                setState(() => speciality = value),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            decoration: _buildInputDecoration('Experience'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter experience'
                                : null,
                            onChanged: (value) =>
                                setState(() => experience = value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 36.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: _buildInputDecoration('Department'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter the department'
                                : null,
                            onChanged: (value) =>
                                setState(() => department = value),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            decoration: _buildInputDecoration('Phone Number'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter phone number'
                                : null,
                            onChanged: (value) =>
                                setState(() => phoneNumber = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              if (doctorImage != null)
                Column(
                  children: [
                    Text(
                      "Selected Image:",
                      style: GoogleFonts.poppins(fontSize: 16.sp),
                    ),
                    SizedBox(height: 12.h),
                    Image.file(
                      doctorImage!,
                      height: 150.h,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      doctorImage!.path,
                      style: GoogleFonts.poppins(fontSize: 12.sp),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => doctorImage = null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Remove Image"),
                    ),
                  ],
                ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: pickImage,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF00BF6D),
                  foregroundColor: Colors.white,
                  minimumSize: Size(33, 48.h),
                  shape: const StadiumBorder(),
                ),
                child: const Text("Pick Image"),
              ),
              SizedBox(height: 36.h),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    submitData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF00BF6D),
                  foregroundColor: Colors.white,
                  minimumSize: Size(33, 48.h),
                  shape: const StadiumBorder(),
                ),
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
