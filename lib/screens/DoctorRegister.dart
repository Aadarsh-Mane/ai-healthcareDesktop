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
  const DoctorRegisterScreen({Key? key}) : super(key: key);

  @override
  _DoctorRegisterScreenState createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Add these variables to track custom input
  bool _isCustomSpecialty = false;
  bool _isCustomDepartment = false;
  String _customSpecialty = '';
  String _customDepartment = '';

  // Form fields
  String userType = 'doctor';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String doctorName = '';
  String experience = '';
  String? speciality;
  String? department;

  String phoneNumber = '';
  File? doctorImage = null;

  // UI state
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Enhanced colors for consistent appearance with hospital theme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF8FBFD);
  final Color textPrimaryColor = const Color(0xFF2D3748);
  final Color textSecondaryColor = const Color(0xFF5A6B7F);
  final Color borderColor = const Color(0xFFDFEAF4);
  final Color successColor = const Color(0xFF00BF6D);

  // List of specialties
  final List<String> _specialties = [
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Surgeon',
    'Orthopedics',
    'Dermatology',
    'Oncology',
    'Psychiatry',
    'Endocrinology',
    'Other'
  ];

  // List of departments
  final List<String> _departments = [
    'General',
    'Emergency',
    'ICU',
    'Outpatient',
    'Surgery',
    'Radiology',
    'Laboratory',
    'Pharmacy',
    'Other'
  ];

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (password != confirmPassword) {
      ToastMessage().showToast(
          context, 'Passwords do not match', '', ToastificationType.error);
      return;
    }

    if (doctorImage == null) {
      ToastMessage().showToast(context, 'Please select a profile image', '',
          ToastificationType.error);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('${KVM_URL}/reception/addDoctor'))
        ..fields['email'] = email
        ..fields['password'] = password
        ..fields['usertype'] = userType
        ..fields['doctorName'] = doctorName
        ..fields['speciality'] = speciality ?? ''
        ..fields['experience'] = experience
        ..fields['department'] = department ?? ''
        ..fields['phoneNumber'] = phoneNumber
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          doctorImage!.path,
        ));

      final response = await request.send();

      if (response.statusCode == 201) {
        _resetForm();
        ToastMessage().showToast(context, 'Doctor Registered Successfully', '',
            ToastificationType.success);
      } else {
        final responseData = await response.stream.bytesToString();
        ToastMessage().showToast(context, 'Registration Failed: $responseData',
            '', ToastificationType.error);
      }
    } catch (error) {
      ToastMessage()
          .showToast(context, 'Error: $error', '', ToastificationType.error);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      email = '';
      password = '';
      confirmPassword = '';
      doctorName = '';
      speciality = null; // Reset to null instead of empty string
      experience = '';
      department = null; // Reset to null instead of empty string
      phoneNumber = '';
      doctorImage = null;
      // Reset custom states
      _isCustomSpecialty = false;
      _isCustomDepartment = false;
      _customSpecialty = '';
      _customDepartment = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildRegistrationForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 32,
              color: primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              'Register New Doctor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _resetForm,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reset Form'),
          style: ElevatedButton.styleFrom(
            foregroundColor: primaryColor,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileImagePicker(),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPersonalInfoSection(),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _buildProfessionalInfoSection(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              image: doctorImage != null
                  ? DecorationImage(
                      image: FileImage(doctorImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: doctorImage == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: primaryColor.withOpacity(0.7),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: pickImage,
          icon: const Icon(Icons.photo_camera, size: 16),
          label: const Text('Upload Photo'),
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
          ),
        ),
        if (doctorImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected: ${_getFileName(doctorImage!.path)}',
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        Stack(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 8), // To align with prefix icon
              child: Row(
                children: [
                  SizedBox(width: 48), // Width of prefix icon + padding
                  Text(
                    'Dr. ',
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildTextField(
              label: 'Full Name',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter doctor\'s name';
                }
                return null;
              },
              onChanged: (value) => setState(() => doctorName = value),
              contentPadding: const EdgeInsets.only(
                  left: 32.0), // Add extra padding for the "Dr." prefix
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Email',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email';
            }
            return null;
          },
          onChanged: (value) => setState(() => email = value),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Phone Number',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
          onChanged: (value) => setState(() => phoneNumber = value),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'Password',
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          onChanged: (value) => setState(() => password = value),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: 'Confirm Password',
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm password';
            }
            if (value != password) {
              return 'Passwords do not match';
            }
            return null;
          },
          onChanged: (value) => setState(() => confirmPassword = value),
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Professional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        // Specialty dropdown with fixed value handling
        _buildDropdownField(
          label: 'Specialty',
          prefixIcon: Icons.medical_services,
          value: _isCustomSpecialty
              ? 'Other'
              : (_specialties.contains(speciality) ? speciality : null),
          items: _specialties,
          hint: 'Select Specialty',
          validator: (value) {
            if (!_isCustomSpecialty && (value == null || value.isEmpty)) {
              return 'Please select a specialty';
            }
            if (_isCustomSpecialty && (_customSpecialty.isEmpty)) {
              return 'Please enter custom specialty';
            }
            return null;
          },
          onChanged: (value) {
            if (value != null) {
              setState(() {
                if (value == 'Other') {
                  _isCustomSpecialty = true;
                  speciality =
                      _customSpecialty.isNotEmpty ? _customSpecialty : '';
                } else {
                  _isCustomSpecialty = false;
                  speciality = value;
                  _customSpecialty =
                      ''; // Clear custom value when selecting predefined
                }
              });
            }
          },
        ),

        // Custom specialty field
        if (_isCustomSpecialty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildTextField(
              label: 'Custom Specialty',
              prefixIcon: Icons.medical_services_outlined,
              initialValue: _customSpecialty,
              validator: (value) {
                if (_isCustomSpecialty && (value == null || value.isEmpty)) {
                  return 'Please enter custom specialty';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _customSpecialty = value;
                  speciality = value; // Also update main specialty value
                });
              },
            ),
          ),

        const SizedBox(height: 16),

        // Department dropdown with fixed value handling
        _buildDropdownField(
          label: 'Department',
          prefixIcon: Icons.business,
          value: _isCustomDepartment
              ? 'Other'
              : (_departments.contains(department) ? department : null),
          items: _departments,
          hint: 'Select Department',
          validator: (value) {
            if (!_isCustomDepartment && (value == null || value.isEmpty)) {
              return 'Please select a department';
            }
            if (_isCustomDepartment && (_customDepartment.isEmpty)) {
              return 'Please enter custom department';
            }
            return null;
          },
          onChanged: (value) {
            if (value != null) {
              setState(() {
                if (value == 'Other') {
                  _isCustomDepartment = true;
                  department =
                      _customDepartment.isNotEmpty ? _customDepartment : '';
                } else {
                  _isCustomDepartment = false;
                  department = value;
                  _customDepartment =
                      ''; // Clear custom value when selecting predefined
                }
              });
            }
          },
        ),

        // Custom department field
        if (_isCustomDepartment)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildTextField(
              label: 'Custom Department',
              prefixIcon: Icons.business_outlined,
              initialValue: _customDepartment,
              validator: (value) {
                if (_isCustomDepartment && (value == null || value.isEmpty)) {
                  return 'Please enter custom department';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _customDepartment = value;
                  department = value; // Also update main department value
                });
              },
            ),
          ),

        const SizedBox(height: 16),

        _buildTextField(
          label: 'Years of Experience',
          prefixIcon: Icons.work,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter years of experience';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (value) => setState(() => experience = value),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Important Notes:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoItem('Create a strong password for security.'),
              _buildInfoItem('Profile picture should be professional.'),
              _buildInfoItem('Make sure all details are accurate.'),
              _buildInfoItem(
                  'Doctor will receive login credentials via email.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? initialValue,
    bool readOnly = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: primaryColor),
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF005F9E)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: primaryColor,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData prefixIcon,
    required String? value,
    required List<String> items,
    required String hint,
    String? Function(String?)? validator,
    void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: Text(hint),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: 300,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : submitData,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: successColor,
          disabledBackgroundColor: successColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Registering...'),
                ],
              )
            : const Text(
                'Register Doctor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
