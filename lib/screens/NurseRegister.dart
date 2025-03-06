import 'package:doctordesktop/constants/ToastMessage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:toastification/toastification.dart';

class NurseRegisterScreen extends StatefulWidget {
  @override
  _NurseRegisterScreenState createState() => _NurseRegisterScreenState();
}

class _NurseRegisterScreenState extends State<NurseRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  String userType = 'nurse';

  String email = '';
  String password = '';
  String doctorName = '';

  Future<void> submitData() async {
    final url =
        '${KVM_URL}/reception/addNurse'; // Replace with your backend URL
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'usertype': userType,
          'doctorName': doctorName,
        }),
      );
      print(response.body);
      if (response.statusCode == 201) {
        // _showSnackbar('Data submitted successfully!');
        ToastMessage().showToast(context, 'Nurse Registered Successfully', '',
            ToastificationType.success);
      }
    } catch (error) {
      print(error);
      ToastMessage().showToast(
          context, 'Nurse Not Registered', '', ToastificationType.error);
    }
  }

  // void _showSnackbar(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       duration: const Duration(seconds: 2),
  //       behavior: SnackBarBehavior.floating,
  //       backgroundColor: Colors.green,
  //     ),
  //   );
  // }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Nurse'),
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
                "Register Nurse",
                style: GoogleFonts.poppins(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: _buildInputDecoration('Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                    ),
                    SizedBox(height: 26.h),
                    TextFormField(
                      decoration: _buildInputDecoration('Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                    ),
                    SizedBox(height: 26.h),
                    TextFormField(
                      controller:
                          TextEditingController(text: "User Type : Nurse"),
                      readOnly: true,
                      decoration: _buildInputDecoration('User Type'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the user type';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          userType = value;
                        });
                      },
                    ),
                    SizedBox(height: 26.h),
                    TextFormField(
                      decoration: _buildInputDecoration('Doctor Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the doctor\'s name';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          doctorName = value;
                        });
                      },
                    ),
                    SizedBox(height: 20.h),
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
            ],
          ),
        ),
      ),
    );
  }
}
