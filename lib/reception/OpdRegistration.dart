import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

// Import local dependencies
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/ToastMessage.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/reception/AssignScreen.dart';

class OPDRegistrationScreen extends StatefulWidget {
  const OPDRegistrationScreen({super.key});

  @override
  State<OPDRegistrationScreen> createState() => _OPDRegistrationScreenState();
}

class _OPDRegistrationScreenState extends State<OPDRegistrationScreen>
    with TickerProviderStateMixin {
  // Controllers and State Variables
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();

  File? _selectedImage;
  String _selectedGender = "Male";
  bool _isReturnVisit = false;
  String? _patientIdResult;
  List<String> _patientSuggestions = [];
  bool _isSubmitting = false;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  // API methods remain unchanged
  Future<void> _fetchPatientId() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a name to search."),
          backgroundColor: HospitalTheme.error,
        ),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/info?name=$name'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _patientIdResult = data['patientId'];
          _nameController.text = data['name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _selectedGender = data['gender'] ?? 'Male';
          _contactController.text = data['contact'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      } else {
        setState(() {
          _patientIdResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No patient found with that name."),
            backgroundColor: HospitalTheme.warning,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred. Please try again."),
          backgroundColor: HospitalTheme.error,
        ),
      );
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _patientSuggestions = []);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/suggestions?name=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() => _patientSuggestions = data.cast<String>());
      }
    } catch (e) {
      print("Error fetching OPD suggestions: $e");
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    } else {
      if (mounted) {
        ToastMessage().showToast(
            context, 'No image selected', '', ToastificationType.warning);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1000;

    return AnimatedBuilder(
      animation:
          Listenable.merge([_fadeAnimation, _slideAnimation, _glowAnimation]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white, // Clean white background
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildEnhancedOPDForm(isSmallScreen),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedOPDForm(bool isSmallScreen) {
    return SafeArea(
      child: Container(
        color: Colors.white, // Ensure clean white background
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : 1200,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Enhanced Header
                  _buildPremiumHeader(isSmallScreen),

                  const SizedBox(height: 32),

                  // Main Form Container
                  _buildPremiumFormContainer(isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HospitalTheme.primary,
            HospitalTheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isSmallScreen
          ? Column(
              children: [
                _buildHeaderIcon(),
                const SizedBox(height: 16),
                _buildHeaderText(),
                const SizedBox(height: 16),
                _buildHeaderLogo(),
              ],
            )
          : Row(
              children: [
                _buildHeaderIcon(),
                const SizedBox(width: 24),
                Expanded(child: _buildHeaderText()),
                const SizedBox(width: 24),
                _buildHeaderLogo(),
              ],
            ),
    );
  }

  Widget _buildHeaderIcon() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_glowAnimation.value * 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Icon(
            Icons.local_hospital_outlined,
            color: HospitalTheme.primary,
            size: 48,
          ),
        );
      },
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFe0e0e0)],
          ).createShader(bounds),
          child: Text(
            "OPD Patient Registration",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter patient details for out-patient department",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderLogo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        AppImages.logo,
        height: 60,
      ),
    );
  }

  Widget _buildPremiumFormContainer(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Search Section
            _buildPremiumSearchSection(isSmallScreen),

            // Divider with gradient
            _buildGradientDivider(),

            // Personal Information
            _buildPremiumPersonalInfo(isSmallScreen),

            // Visit Information
            _buildPremiumVisitInfo(isSmallScreen),

            // Photo Section
            _buildPremiumPhotoSection(isSmallScreen),

            // Submit Section
            _buildPremiumSubmitSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSearchSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // Clean white background
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Search Existing Patient", Icons.search),
          const SizedBox(height: 20),
          isSmallScreen
              ? Column(
                  children: [
                    _buildEnhancedSearchField(),
                    const SizedBox(height: 16),
                    _buildEnhancedPatientIdResult(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildEnhancedSearchField(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildEnhancedPatientIdResult(),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HospitalTheme.primary,
                HospitalTheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            HospitalTheme.primary.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Search Patient",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: HospitalTheme.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              _fetchSuggestions(textEditingValue.text);
              return _patientSuggestions.where((option) => option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selectedPatient) async {
              _searchController.text = selectedPatient;
              _fetchPatientId();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: "Patient Name",
                  hintText: "Search by patient name",
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HospitalTheme.primary,
                          HospitalTheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _fetchPatientId,
                    icon: Icon(
                      Icons.send,
                      color: HospitalTheme.primary,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: HospitalTheme.border,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: HospitalTheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPatientIdResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Patient ID Result",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _patientIdResult != null
                ? LinearGradient(
                    colors: [
                      HospitalTheme.primary.withOpacity(0.1),
                      HospitalTheme.primary.withOpacity(0.05),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      HospitalTheme.surfaceLight,
                      Colors.white,
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _patientIdResult != null
                  ? HospitalTheme.primary.withOpacity(0.3)
                  : HospitalTheme.border,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _patientIdResult != null ? Icons.check_circle : Icons.info,
                color: _patientIdResult != null
                    ? HospitalTheme.primary
                    : HospitalTheme.textMedium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  _patientIdResult != null
                      ? "$_patientIdResult"
                      : "No patient found",
                  style: TextStyle(
                    color: _patientIdResult != null
                        ? HospitalTheme.primary
                        : HospitalTheme.textMedium,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_patientIdResult != null)
                IconButton(
                  icon: Icon(Icons.copy, color: HospitalTheme.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _patientIdResult!));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Patient ID copied to clipboard!"),
                          backgroundColor: HospitalTheme.primary,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumPersonalInfo(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white, // Clean white background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Personal Information", Icons.person),
          const SizedBox(height: 20),
          isSmallScreen
              ? Column(
                  children: [
                    _buildEnhancedTextField(
                      label: "Full Name",
                      controller: _nameController,
                      hintText: 'Enter patient full name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter patient name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedTextField(
                            label: "Age",
                            controller: _ageController,
                            hintText: 'Age in years',
                            keyboardType: TextInputType.number,
                            icon: Icons.calendar_today,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter age';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildEnhancedTextField(
                            label: "Weight (kg)",
                            controller: _weightController,
                            hintText: 'Weight in kg',
                            keyboardType: TextInputType.number,
                            icon: Icons.monitor_weight,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter weight';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedTextField(
                      label: "Phone Number",
                      controller: _contactController,
                      hintText: 'Enter contact number',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedTextField(
                      label: "Address",
                      controller: _addressController,
                      hintText: 'Enter home address',
                      icon: Icons.home,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter address';
                        }
                        return null;
                      },
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildEnhancedTextField(
                      label: "Full Name",
                      controller: _nameController,
                      hintText: 'Enter patient full name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter patient name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedTextField(
                            label: "Age",
                            controller: _ageController,
                            hintText: 'Age in years',
                            keyboardType: TextInputType.number,
                            icon: Icons.calendar_today,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter age';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildEnhancedTextField(
                            label: "Weight (kg)",
                            controller: _weightController,
                            hintText: 'Weight in kg',
                            keyboardType: TextInputType.number,
                            icon: Icons.monitor_weight,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter weight';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildEnhancedTextField(
                            label: "Phone Number",
                            controller: _contactController,
                            hintText: 'Enter contact number',
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildEnhancedTextField(
                      label: "Address",
                      controller: _addressController,
                      hintText: 'Enter home address',
                      icon: Icons.home,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          _buildPremiumGenderSelection(),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: HospitalTheme.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HospitalTheme.primary,
                      HospitalTheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: HospitalTheme.border,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: HospitalTheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: HospitalTheme.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: HospitalTheme.error,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: HospitalTheme.textDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPremiumGenderOption(
              label: "Male",
              icon: Icons.male,
              isSelected: _selectedGender == "Male",
              onTap: () => setState(() => _selectedGender = "Male"),
              color: HospitalTheme.primary,
            ),
            const SizedBox(width: 12),
            _buildPremiumGenderOption(
              label: "Female",
              icon: Icons.female,
              isSelected: _selectedGender == "Female",
              onTap: () => setState(() => _selectedGender = "Female"),
              color: HospitalTheme.primary,
            ),
            const SizedBox(width: 12),
            _buildPremiumGenderOption(
              label: "Other",
              icon: Icons.transgender,
              isSelected: _selectedGender == "Other",
              onTap: () => setState(() => _selectedGender = "Other"),
              color: HospitalTheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : HospitalTheme.border,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : HospitalTheme.textMedium,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : HospitalTheme.textDark,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumVisitInfo(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white, // Clean white background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Visit Information", Icons.rotate_left),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HospitalTheme.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  HospitalTheme.primary,
                                  HospitalTheme.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.rotate_left,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Is this a return visit?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: _isReturnVisit,
                        onChanged: (value) {
                          setState(() {
                            _isReturnVisit = value;
                          });
                        },
                        activeColor: HospitalTheme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                if (_isReturnVisit) ...[
                  const SizedBox(height: 20),
                  _buildEnhancedTextField(
                    label: "Previous Patient ID",
                    controller: _patientIdController,
                    hintText: 'Enter previous patient ID',
                    icon: Icons.badge,
                    validator: (value) {
                      if (_isReturnVisit && (value == null || value.isEmpty)) {
                        return 'Patient ID is required for return patients';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPhotoSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white, // Clean white background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Patient Photo", Icons.add_a_photo),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: HospitalTheme.border,
                width: 2,
              ),
            ),
            child: isSmallScreen
                ? Column(
                    children: [
                      _buildPhotoPreview(),
                      const SizedBox(height: 20),
                      _buildPhotoInstructions(),
                      const SizedBox(height: 20),
                      _buildPhotoButtons(),
                    ],
                  )
                : Row(
                    children: [
                      _buildPhotoPreview(),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPhotoInstructions(),
                            const SizedBox(height: 20),
                            _buildPhotoButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: _selectedImage != null ? null : HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HospitalTheme.primary.withOpacity(0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HospitalTheme.primary.withOpacity(0.2),
                        HospitalTheme.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.add_a_photo,
                    color: HospitalTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "No image selected",
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildPhotoInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upload patient photo",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Please upload a clear photo of the patient's face for identification purposes. The image should be well-lit and show the patient's full face clearly.",
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: pickImage,
            icon: const Icon(Icons.file_upload),
            label: const Text("Select Image"),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedImage = null),
              icon: Icon(Icons.delete, color: HospitalTheme.error),
              label: Text(
                "Remove",
                style: TextStyle(color: HospitalTheme.error),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: HospitalTheme.error),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumSubmitSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, // Clean white background
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: HospitalTheme.primary
                        .withOpacity(_glowAnimation.value * 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _showConfirmationDialog(context);
                        }
                      },
                icon: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, size: 24),
                label: Text(
                  _isSubmitting ? "Processing..." : "Register OPD Patient",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 8,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper methods for confirmation dialog
  Widget _buildConfirmationSectionHeader(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Divider(color: color.withOpacity(0.5)),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: HospitalTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addOPDPatient(BuildContext context) async {
    final navigatorContext = context;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final uri = Uri.parse('${KVM_URL}/reception/addPatient');
      print("OPD Request URL: $uri");
      final request = http.MultipartRequest('POST', uri);

      request.fields['name'] = _nameController.text;
      request.fields['age'] = _ageController.text;
      request.fields['gender'] = _selectedGender;
      request.fields['contact'] = _contactController.text;
      request.fields['address'] = _addressController.text;
      request.fields['weight'] = _weightController.text;
      request.fields['isReadmission'] = _isReturnVisit.toString();

      if (_isReturnVisit) {
        if (_patientIdController.text.isEmpty) {
          setState(() {
            _isSubmitting = false;
          });
          if (mounted) {
            ToastMessage().showToast(
                context,
                'Patient ID is required for return visit',
                '',
                ToastificationType.error);
          }
          return;
        }
        request.fields['patientId'] = _patientIdController.text;
      }

      if (_selectedImage != null) {
        final imageFile = await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        );
        request.files.add(imageFile);
      }

      print("Sending OPD request...");
      final response = await request.send();
      print("OPD Response status code: ${response.statusCode}");

      final responseString = await response.stream.bytesToString();
      print("OPD Response body: $responseString");

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(responseString);
          print("OPD Parsed response: $responseBody");

          final patientId = responseBody['patientDetails']['patientId'];
          final admissionId =
              responseBody['patientDetails']['admissionRecords'][0]['_id'];

          print(
              "OPD Navigation data: patientId=$patientId, admissionId=$admissionId");

          if (mounted) {
            Navigator.of(navigatorContext).popUntil((route) => route.isFirst);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(navigatorContext).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AssignScreen(
                    patientId: patientId,
                    admissionId: admissionId,
                  ),
                ),
              );
            });
          }
        } catch (parseError) {
          print("Error parsing OPD response: $parseError");
          if (mounted) {
            ToastMessage().showToast(
              context,
              'Error processing response: $parseError',
              '',
              ToastificationType.error,
            );
          }
        }
      } else {
        String errorMessage = 'An unknown error occurred';
        try {
          final errorData = jsonDecode(responseString);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          print("Error parsing error response: $e");
        }

        if (mounted) {
          ToastMessage()
              .showToast(context, errorMessage, '', ToastificationType.error);
        }
      }
    } catch (e) {
      print("Exception in _addOPDPatient: $e");
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ToastMessage().showToast(context, 'Failed to register patient: $e', '',
            ToastificationType.error);
      }
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    final name = _nameController.text;
    final age = _ageController.text;
    final gender = _selectedGender;
    final contact = _contactController.text;
    final address = _addressController.text;
    final weight = _weightController.text;
    final isReturnVisit = _isReturnVisit;
    final patientId = _patientIdController.text;

    final themeColor = HospitalTheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: isSmallScreen ? double.infinity : 500,
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medical_information,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Confirm Patient Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedImage != null)
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: themeColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              image: DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                      _buildConfirmationSectionHeader(
                          "Personal Information", themeColor),
                      _buildConfirmationRow("Full Name", name),
                      _buildConfirmationRow("Age", "$age years"),
                      _buildConfirmationRow("Gender", gender),
                      _buildConfirmationRow("Phone", contact),
                      _buildConfirmationRow("Address", address),
                      _buildConfirmationRow("Weight", "$weight kg"),
                      SizedBox(height: 16),
                      _buildConfirmationSectionHeader(
                          "Visit Information", themeColor),
                      _buildConfirmationRow(
                          "Is Return Visit", isReturnVisit ? "Yes" : "No"),
                      if (isReturnVisit)
                        _buildConfirmationRow("Previous Patient ID", patientId),
                    ],
                  ),
                ),
              ),
              // Enhanced Footer
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Edit",
                        style: TextStyle(
                          color: HospitalTheme.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Future.delayed(Duration(milliseconds: 100), () {
                          _addOPDPatient(context);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        "Confirm & Register",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
