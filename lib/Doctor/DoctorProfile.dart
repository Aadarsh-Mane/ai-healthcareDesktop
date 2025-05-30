// import 'dart:convert';
// import 'dart:io';
// import 'package:doctordesktop/Doctor/DoctorPatientDetailScreen.dart';
// import 'package:doctordesktop/model/getNewPatientModel.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:file_picker/file_picker.dart';
// import 'package:intl/intl.dart';
// import '../constants/HospitalTheme.dart';
// import '../constants/Url.dart';

// class DoctorProfileScreen extends StatefulWidget {
//   const DoctorProfileScreen({Key? key}) : super(key: key);

//   @override
//   _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
// }

// class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
//   bool _isLoading = true;
//   bool _isUpdating = false;
//   String? _errorMessage;
//   Map<String, dynamic>? _doctorProfile;

//   // Add these properties to store the data from API
//   List<Map<String, dynamic>> _assignedPatients = [];
//   List<Map<String, dynamic>> _filteredPatients = [];

//   // Form controllers
//   final _nameController = TextEditingController();
//   final _specialityController = TextEditingController();
//   final _experienceController = TextEditingController();
//   final _departmentController = TextEditingController();
//   final _phoneController = TextEditingController();

//   // Search and filter controllers
//   final _searchController = TextEditingController();
//   DateTime? _selectedStartDate;
//   DateTime? _selectedEndDate;
//   String _sortBy = 'name'; // Default sort
//   bool _sortAscending = true;

//   // Form key for validation
//   final _formKey = GlobalKey<FormState>();

//   // Image file
//   File? _imageFile;
//   String? _imageUrl;

//   @override
//   void initState() {
//     super.initState();
//     _fetchDoctorProfile();

//     // Add listener to search controller
//     _searchController.addListener(_filterPatients);
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _specialityController.dispose();
//     _experienceController.dispose();
//     _departmentController.dispose();
//     _phoneController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   // Filter patients based on search text and date filters
//   void _filterPatients() {
//     setState(() {
//       _filteredPatients = _assignedPatients.where((patient) {
//         // Text search
//         final searchText = _searchController.text.toLowerCase();
//         final patientName = (patient['name'] ?? '').toLowerCase();
//         final patientId = (patient['patientId'] ?? '').toLowerCase();
//         final contains =
//             patientName.contains(searchText) || patientId.contains(searchText);

//         // Date filter
//         bool dateMatch = true;
//         if (_selectedStartDate != null || _selectedEndDate != null) {
//           try {
//             final admissionDate = patient['admissionDate'] != null
//                 ? DateTime.parse(patient['admissionDate'])
//                 : null;

//             if (admissionDate != null) {
//               if (_selectedStartDate != null &&
//                   admissionDate.isBefore(_selectedStartDate!)) {
//                 dateMatch = false;
//               }
//               if (_selectedEndDate != null) {
//                 // Include the whole end date by adding 1 day and subtracting 1 millisecond
//                 final endDayIncluded = _selectedEndDate!
//                     .add(Duration(days: 1))
//                     .subtract(Duration(milliseconds: 1));
//                 if (admissionDate.isAfter(endDayIncluded)) {
//                   dateMatch = false;
//                 }
//               }
//             }
//           } catch (e) {
//             // If date parsing fails, include the patient
//             dateMatch = true;
//           }
//         }

//         return contains && dateMatch;
//       }).toList();

//       // Apply sorting
//       _sortPatients();
//     });
//   }

//   // Sort patients based on current sort criteria
//   void _sortPatients() {
//     _filteredPatients.sort((a, b) {
//       dynamic valueA, valueB;

//       switch (_sortBy) {
//         case 'name':
//           valueA = a['name'] ?? '';
//           valueB = b['name'] ?? '';
//           break;
//         case 'patientId':
//           valueA = a['patientId'] ?? '';
//           valueB = b['patientId'] ?? '';
//           break;
//         case 'admissionDate':
//           try {
//             valueA = a['admissionDate'] != null
//                 ? DateTime.parse(a['admissionDate'])
//                 : DateTime(1900);
//             valueB = b['admissionDate'] != null
//                 ? DateTime.parse(b['admissionDate'])
//                 : DateTime(1900);
//           } catch (e) {
//             valueA = '';
//             valueB = '';
//           }
//           break;
//         default:
//           valueA = a['name'] ?? '';
//           valueB = b['name'] ?? '';
//       }

//       // Compare the values
//       int comparison;
//       if (valueA is DateTime && valueB is DateTime) {
//         comparison = valueA.compareTo(valueB);
//       } else {
//         String strA = valueA?.toString() ?? '';
//         String strB = valueB?.toString() ?? '';
//         comparison = strA.compareTo(strB);
//       }

//       return _sortAscending ? comparison : -comparison;
//     });
//   }

//   Future<void> _fetchDoctorProfile() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final token = await _getAuthToken();
//       if (token == null) {
//         setState(() {
//           _errorMessage = 'Authentication token not found';
//           _isLoading = false;
//         });
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('${KVM_URL}/doctors/getDoctorProfile'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _doctorProfile = data['doctorProfile'];
//           _assignedPatients = List<Map<String, dynamic>>.from(
//               data['patients']['assigned'] ?? []);

//           // Initialize filtered patients
//           _filteredPatients = List.from(_assignedPatients);

//           _isLoading = false;

//           // Set controller values
//           _nameController.text = _doctorProfile?['doctorName'] ?? '';
//           _specialityController.text = _doctorProfile?['speciality'] ?? '';
//           _experienceController.text =
//               _doctorProfile?['experience']?.toString() ?? '';
//           _departmentController.text = _doctorProfile?['department'] ?? '';
//           _phoneController.text = _doctorProfile?['phoneNumber'] ?? '';
//           _imageUrl = _doctorProfile?['imageUrl'];
//         });
//       } else {
//         final error = jsonDecode(response.body);
//         setState(() {
//           _errorMessage = error['message'] ?? 'Failed to fetch profile';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   // Get auth token from shared preferences
//   Future<String?> _getAuthToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   // Update doctor profile
//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isUpdating = true;
//       _errorMessage = null;
//     });

//     try {
//       final token = await _getAuthToken();
//       if (token == null) {
//         setState(() {
//           _errorMessage = 'Authentication token not found';
//           _isUpdating = false;
//         });
//         return;
//       }

//       // First, upload image if selected
//       String? updatedImageUrl = _imageUrl;
//       if (_imageFile != null) {
//         updatedImageUrl = await _uploadImage(_imageFile!, token);
//         if (updatedImageUrl == null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content:
//                   Text('Failed to upload image. Profile update will continue.'),
//               backgroundColor: HospitalTheme.warning,
//             ),
//           );
//         }
//       }

//       // Prepare request body
//       final body = {
//         'doctorName': _nameController.text,
//         'speciality': _specialityController.text,
//         'experience': _experienceController.text.isEmpty
//             ? null
//             : int.parse(_experienceController.text),
//         'department': _departmentController.text,
//         'phoneNumber': _phoneController.text,
//       };

//       if (updatedImageUrl != null) {
//         body['imageUrl'] = updatedImageUrl;
//       }

//       // Make update request
//       final response = await http.patch(
//         Uri.parse('${KVM_URL}/doctors/updateProfile'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           _doctorProfile = data['doctorProfile'];
//           _isUpdating = false;
//           _imageUrl = updatedImageUrl;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Profile updated successfully'),
//             backgroundColor: HospitalTheme.success,
//           ),
//         );
//       } else {
//         final error = jsonDecode(response.body);
//         setState(() {
//           _errorMessage = error['message'] ?? 'Failed to update profile';
//           _isUpdating = false;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(_errorMessage ?? 'Failed to update profile'),
//             backgroundColor: HospitalTheme.error,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: $e';
//         _isUpdating = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating profile: $e'),
//           backgroundColor: HospitalTheme.error,
//         ),
//       );
//     }
//   }

//   // Upload image to server
//   Future<String?> _uploadImage(File imageFile, String token) async {
//     try {
//       // Create multipart request
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${KVM_URL}/upload'),
//       );

//       // Add authorization header
//       request.headers.addAll({
//         'Authorization': 'Bearer $token',
//       });

//       // Add file to request
//       request.files.add(await http.MultipartFile.fromPath(
//         'file',
//         imageFile.path,
//       ));

//       // Send request
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);

//       // Parse response
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['fileUrl'];
//       } else {
//         print('Failed to upload image: ${response.statusCode}');
//         print('Response body: ${response.body}');
//         return null;
//       }
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }

//   // Pick image using FilePicker
//   Future<void> _pickImage() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//         allowMultiple: false,
//       );

//       if (result != null && result.files.isNotEmpty) {
//         final path = result.files.single.path;
//         if (path != null) {
//           setState(() {
//             _imageFile = File(path);
//           });
//         }
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error selecting image: $e'),
//           backgroundColor: HospitalTheme.error,
//         ),
//       );
//     }
//   }

//   Future<void> _selectDateRange(BuildContext context) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       initialDateRange: _selectedStartDate != null && _selectedEndDate != null
//           ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
//           : null,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now().add(Duration(days: 365)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: HospitalTheme.primary,
//               onPrimary: HospitalTheme.textOnPrimary,
//               surface: HospitalTheme.cardBackground,
//               onSurface: HospitalTheme.textDark,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         _selectedStartDate = picked.start;
//         _selectedEndDate = picked.end;
//       });
//       _filterPatients();
//     }
//   }

//   void _clearDateFilter() {
//     setState(() {
//       _selectedStartDate = null;
//       _selectedEndDate = null;
//     });
//     _filterPatients();
//   }

//   void _changeSortOrder(String field) {
//     setState(() {
//       if (_sortBy == field) {
//         // Toggle direction if same field
//         _sortAscending = !_sortAscending;
//       } else {
//         // New field, default to ascending
//         _sortBy = field;
//         _sortAscending = true;
//       }
//     });
//     _sortPatients();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? _buildLoadingView()
//           : _errorMessage != null
//               ? _buildErrorView()
//               : _buildProfileView(),
//     );
//   }

//   Widget _buildLoadingView() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
//           ),
//           SizedBox(height: 16),
//           Text(
//             'Loading profile...',
//             style: TextStyle(
//               color: HospitalTheme.textDark,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorView() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.error_outline,
//             size: 80,
//             color: HospitalTheme.error,
//           ),
//           SizedBox(height: 16),
//           Text(
//             _errorMessage ?? 'An error occurred',
//             style: TextStyle(
//               color: HospitalTheme.textDark,
//               fontSize: 16,
//             ),
//           ),
//           SizedBox(height: 24),
//           ElevatedButton.icon(
//             icon: Icon(Icons.refresh),
//             label: Text('Retry'),
//             onPressed: _fetchDoctorProfile,
//             style: ElevatedButton.styleFrom(
//               foregroundColor: HospitalTheme.textOnPrimary,
//               backgroundColor: HospitalTheme.primary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileView() {
//     return Row(
//       children: [
//         // Left Sidebar
//         Container(
//           width: 280,
//           decoration: BoxDecoration(
//             color: HospitalTheme.navBackground,
//             borderRadius: BorderRadius.only(
//               topRight: Radius.circular(16),
//               bottomRight: Radius.circular(16),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: Offset(3, 0),
//               ),
//             ],
//           ),
//           padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Profile Management',
//                 style: TextStyle(
//                   color: HospitalTheme.textOnPrimary,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 48),
//               _buildSidebarItem(
//                 icon: Icons.person,
//                 title: 'Personal Information',
//                 isActive: true,
//               ),
//               // _buildSidebarItem(
//               //   icon: Icons.people,
//               //   title: 'Assigned Patients',
//               //   isActive: false,
//               // ),
//             ],
//           ),
//         ),

//         // Main Content
//         Expanded(
//           child: Container(
//             padding: EdgeInsets.all(32),
//             child: SingleChildScrollView(
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header
//                     Row(
//                       children: [
//                         Text(
//                           'Doctor Profile',
//                           style: TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: HospitalTheme.textDark,
//                           ),
//                         ),
//                         Spacer(),
//                         // Update button
//                         _isUpdating
//                             ? CircularProgressIndicator()
//                             : ElevatedButton.icon(
//                                 onPressed: _updateProfile,
//                                 icon: Icon(Icons.save),
//                                 label: Text('Save Changes'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: HospitalTheme.success,
//                                   foregroundColor: Colors.white,
//                                   padding: EdgeInsets.symmetric(
//                                     horizontal: 20,
//                                     vertical: 12,
//                                   ),
//                                 ),
//                               ),
//                         SizedBox(width: 16),
//                         // Close button
//                         HospitalTheme.buildGradientButton(
//                           label: 'Close',
//                           onPressed: () {
//                             Navigator.of(context).pop();
//                           },
//                           icon: Icons.close,
//                           startColor: HospitalTheme.textLight,
//                           endColor: HospitalTheme.textMedium,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 32),

//                     // Profile Content in two columns
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Left column with profile photo
//                         Expanded(
//                           flex: 1,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               _buildProfilePhotoSection(),
//                               SizedBox(height: 48),
//                               _buildStatsCard(),
//                             ],
//                           ),
//                         ),
//                         SizedBox(width: 32),

//                         // Right column with form fields
//                         Expanded(
//                           flex: 2,
//                           child: HospitalTheme.buildCard(
//                             padding: EdgeInsets.all(24),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Personal Information',
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: HospitalTheme.textDark,
//                                   ),
//                                 ),
//                                 SizedBox(height: 24),

//                                 // Form fields
//                                 _buildFormField(
//                                   controller: _nameController,
//                                   label: 'Full Name',
//                                   icon: Icons.person_outline,
//                                   validator: (value) {
//                                     if (value == null || value.isEmpty) {
//                                       return 'Please enter your name';
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                                 SizedBox(height: 16),

//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: _buildFormField(
//                                         controller: _specialityController,
//                                         label: 'Speciality',
//                                         icon: Icons.medical_services_outlined,
//                                       ),
//                                     ),
//                                     SizedBox(width: 16),
//                                     Expanded(
//                                       child: _buildFormField(
//                                         controller: _experienceController,
//                                         label: 'Experience (years)',
//                                         icon: Icons.timeline_outlined,
//                                         keyboardType: TextInputType.number,
//                                         validator: (value) {
//                                           if (value != null &&
//                                               value.isNotEmpty) {
//                                             if (int.tryParse(value) == null) {
//                                               return 'Please enter a valid number';
//                                             }
//                                           }
//                                           return null;
//                                         },
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 16),

//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: _buildFormField(
//                                         controller: _departmentController,
//                                         label: 'Department',
//                                         icon: Icons.business_outlined,
//                                       ),
//                                     ),
//                                     SizedBox(width: 16),
//                                     Expanded(
//                                       child: _buildFormField(
//                                         controller: _phoneController,
//                                         label: 'Phone Number',
//                                         icon: Icons.phone_outlined,
//                                         keyboardType: TextInputType.phone,
//                                         validator: (value) {
//                                           if (value != null &&
//                                               value.isNotEmpty) {
//                                             if (!RegExp(r'^\+?[0-9]{10,15}$')
//                                                 .hasMatch(value)) {
//                                               return 'Please enter a valid phone number';
//                                             }
//                                           }
//                                           return null;
//                                         },
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 16),

//                                 // Email field (disabled, can't edit)
//                                 TextFormField(
//                                   initialValue: _doctorProfile?['email'] ?? '',
//                                   decoration: InputDecoration(
//                                     labelText: 'Email',
//                                     prefixIcon: Icon(Icons.email_outlined),
//                                     border: OutlineInputBorder(),
//                                     filled: true,
//                                     fillColor: Colors.grey.shade100,
//                                   ),
//                                   readOnly: true,
//                                   enabled: false,
//                                 ),

//                                 // Save button at the bottom of the form
//                                 SizedBox(height: 24),
//                                 Center(
//                                   child: ElevatedButton.icon(
//                                     onPressed:
//                                         _isUpdating ? null : _updateProfile,
//                                     icon: _isUpdating
//                                         ? SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               color: Colors.white,
//                                               strokeWidth: 2,
//                                             ),
//                                           )
//                                         : Icon(Icons.save),
//                                     label: Text(_isUpdating
//                                         ? 'Saving...'
//                                         : 'Save Changes'),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: HospitalTheme.primary,
//                                       foregroundColor: Colors.white,
//                                       padding: EdgeInsets.symmetric(
//                                         horizontal: 32,
//                                         vertical: 16,
//                                       ),
//                                       minimumSize: Size(200, 50),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 32),

//                     // Assigned Patients Section
//                     _buildAssignedPatientsSection(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSidebarItem({
//     required IconData icon,
//     required String title,
//     required bool isActive,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       child: InkWell(
//         onTap: () {
//           // Handle navigation to different sections (not implemented)
//         },
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             color: isActive
//                 ? HospitalTheme.primaryLight.withOpacity(0.2)
//                 : Colors.transparent,
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 icon,
//                 color: isActive
//                     ? HospitalTheme.textOnPrimary
//                     : HospitalTheme.textOnPrimary.withOpacity(0.7),
//                 size: 20,
//               ),
//               SizedBox(width: 12),
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: isActive
//                       ? HospitalTheme.textOnPrimary
//                       : HospitalTheme.textOnPrimary.withOpacity(0.7),
//                   fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                   fontSize: 14,
//                 ),
//               ),
//               if (isActive) ...[
//                 Spacer(),
//                 Container(
//                   width: 6,
//                   height: 6,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: HospitalTheme.textOnPrimary,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProfilePhotoSection() {
//     final double photoSize = 180;

//     return Column(
//       children: [
//         Stack(
//           children: [
//             // Profile image
//             Container(
//               width: photoSize,
//               height: photoSize,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: HospitalTheme.surfaceLight,
//                 border: Border.all(
//                   color: HospitalTheme.primary,
//                   width: 4,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 15,
//                     offset: Offset(0, 5),
//                   ),
//                 ],
//                 image: (_imageFile != null)
//                     ? DecorationImage(
//                         image: FileImage(_imageFile!),
//                         fit: BoxFit.cover,
//                       )
//                     : (_imageUrl != null && _imageUrl!.isNotEmpty)
//                         ? DecorationImage(
//                             image: NetworkImage(_imageUrl!),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//               ),
//               child: (_imageFile == null &&
//                       (_imageUrl == null || _imageUrl!.isEmpty))
//                   ? Center(
//                       child: Icon(
//                         Icons.person,
//                         size: photoSize * 0.5,
//                         color: HospitalTheme.primary,
//                       ),
//                     )
//                   : null,
//             ),

//             // Edit button
//             Positioned(
//               bottom: 0,
//               right: 0,
//               child: InkWell(
//                 onTap: _pickImage,
//                 child: Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: HospitalTheme.primary,
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Colors.white,
//                       width: 2,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 5,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     Icons.edit,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 16),
//         Text(
//           _nameController.text,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: HospitalTheme.textDark,
//           ),
//         ),
//         SizedBox(height: 4),
//         Text(
//           _specialityController.text.isNotEmpty
//               ? _specialityController.text
//               : 'Speciality not specified',
//           style: TextStyle(
//             fontSize: 16,
//             color: HospitalTheme.textMedium,
//           ),
//         ),

//         // Preview vs Current note
//         if (_imageFile != null) ...[
//           SizedBox(height: 16),
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: HospitalTheme.surfaceLight,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: HospitalTheme.primary),
//             ),
//             child: Text(
//               'New photo selected - save to apply changes',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: HospitalTheme.primary,
//                 fontStyle: FontStyle.italic,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildStatsCard() {
//     return HospitalTheme.buildCard(
//       backgroundColor: HospitalTheme.surfaceLight.withOpacity(0.5),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             'Account Stats',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: HospitalTheme.primary,
//             ),
//           ),
//           SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildStatItem(
//                 value: _doctorProfile?['createdAt'] != null
//                     ? '${_calculateAccountAge(_doctorProfile!['createdAt'])}d'
//                     : '0d',
//                 label: 'Account Age',
//               ),
//               _buildStatItem(
//                 value: '${_assignedPatients.length}',
//                 label: 'Patients',
//               ),
//               _buildStatItem(
//                 value: '${_doctorProfile?['experience'] ?? 'N/A'}',
//                 label: 'Experience',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   int _calculateAccountAge(String createdAt) {
//     final creationDate = DateTime.parse(createdAt);
//     final now = DateTime.now();
//     return now.difference(creationDate).inDays;
//   }

//   Widget _buildStatItem({required String value, required String label}) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: HospitalTheme.primary,
//           ),
//         ),
//         SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: HospitalTheme.textMedium,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFormField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: OutlineInputBorder(),
//       ),
//       keyboardType: keyboardType,
//       validator: validator,
//     );
//   }

//   Widget _buildAssignedPatientsSection() {
//     return HospitalTheme.buildCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.people_alt, color: HospitalTheme.medical),
//               SizedBox(width: 12),
//               Text(
//                 'Assigned Patients',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: HospitalTheme.textDark,
//                 ),
//               ),
//               Spacer(),
//               _buildPatientsCounter(),
//             ],
//           ),

//           SizedBox(height: 24),

//           // Search and filter controls
//           _buildSearchAndFilterBar(),

//           SizedBox(height: 16),

//           // Date filter display
//           if (_selectedStartDate != null || _selectedEndDate != null)
//             _buildActiveDateFilter(),

//           SizedBox(height: 16),

//           // Column headers with sort functionality
//           _buildTableHeader(),

//           SizedBox(height: 8),
//           Divider(),

//           // Patients list
//           _buildPatientsList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildPatientsCounter() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: HospitalTheme.medical.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Showing ${_filteredPatients.length} of ${_assignedPatients.length}',
//             style: TextStyle(
//               color: HospitalTheme.medical,
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchAndFilterBar() {
//     return Row(
//       children: [
//         // Search box
//         Expanded(
//           flex: 3,
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search by patient name or ID',
//               prefixIcon: Icon(Icons.search),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               contentPadding: EdgeInsets.symmetric(vertical: 12),
//             ),
//           ),
//         ),
//         SizedBox(width: 16),

//         // Date filter button
//         OutlinedButton.icon(
//           onPressed: () => _selectDateRange(context),
//           icon: Icon(Icons.date_range),
//           label: Text('Filter by Date'),
//           style: OutlinedButton.styleFrom(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             side: BorderSide(color: HospitalTheme.primary),
//           ),
//         ),

//         SizedBox(width: 8),

//         // Refresh button
//         IconButton(
//           onPressed: () {
//             _searchController.clear();
//             setState(() {
//               _selectedStartDate = null;
//               _selectedEndDate = null;
//               _filteredPatients = List.from(_assignedPatients);
//             });
//           },
//           icon: Icon(Icons.refresh),
//           tooltip: 'Reset all filters',
//           color: HospitalTheme.primary,
//         ),
//       ],
//     );
//   }

//   Widget _buildActiveDateFilter() {
//     final dateFormat = DateFormat('MMM d, yyyy');
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: HospitalTheme.surfaceLight,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: HospitalTheme.border),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.filter_list, color: HospitalTheme.primary, size: 18),
//           SizedBox(width: 8),
//           Text(
//             _selectedStartDate != null && _selectedEndDate != null
//                 ? 'Date: ${dateFormat.format(_selectedStartDate!)} - ${dateFormat.format(_selectedEndDate!)}'
//                 : _selectedStartDate != null
//                     ? 'From: ${dateFormat.format(_selectedStartDate!)}'
//                     : 'Until: ${dateFormat.format(_selectedEndDate!)}',
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               color: HospitalTheme.primary,
//             ),
//           ),
//           SizedBox(width: 8),
//           InkWell(
//             onTap: _clearDateFilter,
//             child: Icon(Icons.close, color: HospitalTheme.primary, size: 18),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTableHeader() {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         children: [
//           // Patient ID
//           _buildSortableColumnHeader(
//             title: 'Patient ID',
//             field: 'patientId',
//             flex: 1,
//           ),

//           // Patient Name
//           _buildSortableColumnHeader(
//             title: 'Patient Name',
//             field: 'name',
//             flex: 2,
//           ),

//           // Admission Date
//           _buildSortableColumnHeader(
//             title: 'Ad Date',
//             field: 'admissionDate',
//             flex: 1,
//           ),

//           // Gender
//           Expanded(
//             flex: 1,
//             child: Text(
//               'Gender',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: HospitalTheme.textMedium,
//               ),
//             ),
//           ),

//           // Status
//           Expanded(
//             flex: 1,
//             child: Text(
//               'Status',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: HospitalTheme.textMedium,
//               ),
//             ),
//           ),

//           // Actions
//           SizedBox(width: 80, child: Text('Actions')),
//         ],
//       ),
//     );
//   }

//   Widget _buildSortableColumnHeader({
//     required String title,
//     required String field,
//     required int flex,
//   }) {
//     final isActive = _sortBy == field;

//     return Expanded(
//       flex: flex,
//       child: InkWell(
//         onTap: () => _changeSortOrder(field),
//         child: Row(
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color:
//                     isActive ? HospitalTheme.primary : HospitalTheme.textMedium,
//               ),
//             ),
//             SizedBox(width: 4),
//             if (isActive)
//               Icon(
//                 _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
//                 size: 16,
//                 color: HospitalTheme.primary,
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientsList() {
//     if (_filteredPatients.isEmpty) {
//       return Container(
//         height: 200,
//         alignment: Alignment.center,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.search_off,
//               size: 48,
//               color: HospitalTheme.textLight,
//             ),
//             SizedBox(height: 16),
//             Text(
//               _assignedPatients.isEmpty
//                   ? 'No patients assigned to you yet'
//                   : 'No patients match your search criteria',
//               style: TextStyle(
//                 color: HospitalTheme.textMedium,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(
//       height: 500, // Fixed height for the list
//       child: ListView.separated(
//         itemCount: _filteredPatients.length,
//         separatorBuilder: (context, index) => Divider(height: 1),
//         itemBuilder: (context, index) {
//           final patient = _filteredPatients[index];
//           return _buildPatientRow(patient);
//         },
//       ),
//     );
//   }

//   Widget _buildPatientRow(Map<String, dynamic> patient) {
//     final status = patient['status'] ?? 'Active';
//     Color statusColor;

//     // Determine status color
//     switch (status.toLowerCase()) {
//       case 'admitted':
//         statusColor = HospitalTheme.info;
//         break;
//       case 'discharged':
//         statusColor = HospitalTheme.success;
//         break;
//       case 'critical':
//         statusColor = HospitalTheme.error;
//         break;
//       default:
//         statusColor = HospitalTheme.medical;
//     }

//     // Format admission date
//     String formattedDate = 'N/A';
//     if (patient['admissionDate'] != null) {
//       try {
//         final date = DateTime.parse(patient['admissionDate']);
//         formattedDate = DateFormat('MMM d, yyyy').format(date);
//       } catch (e) {
//         formattedDate = patient['admissionDate'] ?? 'N/A';
//       }
//     }

//     return InkWell(
//       onTap: () {
//         // Convert the Map to a Patient1 object before navigation
//         final patientObj = _convertMapToPatient(patient);

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PatientDetailScreen4(
//               patient: patientObj,
//             ),
//           ),
//         );
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border(
//             bottom: BorderSide(color: HospitalTheme.border),
//           ),
//         ),
//         child: Row(
//           children: [
//             // Patient ID
//             Expanded(
//               flex: 1,
//               child: Text(
//                 patient['patientId'] ?? 'N/A',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w500,
//                   color: HospitalTheme.textDark,
//                 ),
//               ),
//             ),

//             // Patient Name
//             Expanded(
//               flex: 2,
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 16,
//                     backgroundColor: HospitalTheme.surfaceLight,
//                     child: Text(
//                       (patient['name'] ?? 'N/A').isNotEmpty
//                           ? (patient['name'] as String)
//                               .substring(0, 1)
//                               .toUpperCase()
//                           : 'N/A',
//                       style: TextStyle(
//                         color: HospitalTheme.primary,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Text(
//                     patient['name'] ?? 'N/A',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w500,
//                       color: HospitalTheme.textDark,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Admission Date
//             Expanded(
//               flex: 1,
//               child: Text(
//                 formattedDate,
//                 style: TextStyle(
//                   color: HospitalTheme.textMedium,
//                 ),
//               ),
//             ),

//             // Gender
//             Expanded(
//               flex: 1,
//               child: Text(
//                 patient['gender'] ?? 'N/A',
//                 style: TextStyle(
//                   color: HospitalTheme.textMedium,
//                 ),
//               ),
//             ),

//             // Status
//             Expanded(
//               flex: 1,
//               child: HospitalTheme.buildStatusBadge(
//                 status,
//                 color: statusColor,
//               ),
//             ),

//             // Actions
//             SizedBox(
//               width: 80,
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.visibility, color: HospitalTheme.primary),
//                     tooltip: 'View Details',
//                     onPressed: () {
//                       // Navigate to patient details using the same conversion
//                       final patientObj = _convertMapToPatient(patient);
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PatientDetailScreen4(
//                             patient: patientObj,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.medical_services,
//                         color: HospitalTheme.secondary),
//                     tooltip: 'Manage Treatment',
//                     onPressed: () {
//                       // Navigate to treatment management
//                       final patientObj = _convertMapToPatient(patient);
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PatientDetailScreen4(
//                             patient: patientObj,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// // Helper method to convert a Map to a Patient1 object
//   Patient1 _convertMapToPatient(Map<String, dynamic> patientMap) {
//     // First, create an admission record with all the required fields
//     List<AdmissionRecord> admissionRecords = [];

//     if (patientMap['admissionRecords'] != null &&
//         patientMap['admissionRecords'] is List) {
//       // If we have admission records in the map, convert them properly
//       admissionRecords = (patientMap['admissionRecords'] as List)
//           .map((record) => AdmissionRecord(
//                 id: record['id'] ?? record['_id'] ?? '',
//                 admissionDate: record['admissionDate'] ?? '',
//                 reasonForAdmission: record['reasonForAdmission'] ?? '',
//                 symptoms: record['symptoms'] ?? '',
//                 initialDiagnosis: record['initialDiagnosis'] ?? '',
//                 status: record['status'] ?? '',
//                 doctorConsultant:
//                     List<String>.from(record['doctorConsultant'] ?? []),
//                 reports: record['reports'] ?? [],
//                 followUps: _parseFollowUps(record['followUps']),
//                 doctorPrescriptions:
//                     _parsePrescriptions(record['doctorPrescriptions']),
//                 symptomsByDoctor:
//                     List<String>.from(record['symptomsByDoctor'] ?? []),
//                 diagnosisByDoctor:
//                     List<String>.from(record['diagnosisByDoctor'] ?? []),
//                 vitals: _parseVitals(record['vitals']),
//                 doctorConsulting: _parseConsulting(record['doctorConsulting']),
//               ))
//           .toList();
//     } else {
//       // Create a default admission record if none exists
//       admissionRecords.add(AdmissionRecord(
//         id: patientMap['admissionId'] ?? '',
//         admissionDate: patientMap['admissionDate'] ?? '',
//         reasonForAdmission: '',
//         symptoms: '',
//         initialDiagnosis: '',
//         status: patientMap['status'] ?? 'Pending',
//         doctorConsultant: [],
//         reports: [],
//         followUps: [],
//         doctorPrescriptions: [],
//         symptomsByDoctor: [],
//         diagnosisByDoctor: [],
//         vitals: [],
//         doctorConsulting: [],
//       ));
//     }

//     // Create and return a Patient1 object
//     return Patient1(
//       id: patientMap['id'] ?? patientMap['_id'] ?? '',
//       patientId: patientMap['patientId'] ?? '',
//       name: patientMap['name'] ?? '',
//       age: patientMap['age'] is int
//           ? patientMap['age']
//           : int.tryParse(patientMap['age']?.toString() ?? '0') ?? 0,
//       gender: patientMap['gender'] ?? '',
//       contact: patientMap['contact'] ?? '',
//       address: patientMap['address'] ?? '',
//       imageUrl: patientMap['imageUrl'] ?? '',
//       pendingAmount: patientMap['pendingAmount'] is int
//           ? patientMap['pendingAmount']
//           : int.tryParse(patientMap['pendingAmount']?.toString() ?? '0') ?? 0,
//       admissionRecords: admissionRecords,
//     );
//   }

// // Helper methods to parse nested objects
//   List<FollowUp> _parseFollowUps(dynamic followUpsData) {
//     if (followUpsData == null || !(followUpsData is List)) {
//       return [];
//     }

//     return (followUpsData as List)
//         .map((followUp) => FollowUp.fromJson(followUp))
//         .toList();
//   }

//   List<DoctorPrescription> _parsePrescriptions(dynamic prescriptionsData) {
//     if (prescriptionsData == null || !(prescriptionsData is List)) {
//       return [];
//     }

//     return (prescriptionsData as List)
//         .map((prescription) => DoctorPrescription.fromJson(prescription))
//         .toList();
//   }

//   List<Vitals> _parseVitals(dynamic vitalsData) {
//     if (vitalsData == null || !(vitalsData is List)) {
//       return [];
//     }

//     return (vitalsData as List).map((vital) => Vitals.fromJson(vital)).toList();
//   }

//   List<DoctorConsulting> _parseConsulting(dynamic consultingData) {
//     if (consultingData == null || !(consultingData is List)) {
//       return [];
//     }

//     return (consultingData as List)
//         .map((consulting) => DoctorConsulting.fromJson(consulting))
//         .toList();
//   }
// }
