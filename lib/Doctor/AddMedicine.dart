import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Models extracted to separate files for better organization
class Medicine2 {
  final String id;
  final String name;
  final String category;
  final String morning;
  final String afternoon;
  final String night;
  final String comment;
  final DoctorInfo addedBy;

  const Medicine2({
    required this.id,
    required this.name,
    required this.category,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.comment,
    required this.addedBy,
  });

  factory Medicine2.fromJson(Map<String, dynamic> json) {
    return Medicine2(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Other',
      morning: json['morning'] ?? "0",
      afternoon: json['afternoon'] ?? "0",
      night: json['night'] ?? "0",
      comment: json['comment'] ?? "",
      addedBy: DoctorInfo.fromJson(json['addedBy'] ?? {}),
    );
  }
}

class DoctorInfo {
  final String doctorId;
  final String doctorName;

  const DoctorInfo({
    required this.doctorId,
    required this.doctorName,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? 'Unknown Doctor',
    );
  }
}

// Custom input formatter for dosage fields
class DosageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Allow empty string or numeric values
    if (newValue.text.isEmpty || RegExp(r'^[0-9]+$').hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class MedicineManagementScreen extends StatefulWidget {
  const MedicineManagementScreen({Key? key}) : super(key: key);

  @override
  State<MedicineManagementScreen> createState() =>
      _MedicineManagementScreenState();
}

class _MedicineManagementScreenState extends State<MedicineManagementScreen> {
  final List<Medicine2> _medicines = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMedicineAdding = false;

  // Controllers for add medicine form with focus nodes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _morningController =
      TextEditingController(text: "0");
  final TextEditingController _afternoonController =
      TextEditingController(text: "0");
  final TextEditingController _nightController =
      TextEditingController(text: "0");
  final TextEditingController _commentController = TextEditingController();

  // Add focus nodes for better keyboard navigation
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _morningFocusNode = FocusNode();
  final FocusNode _afternoonFocusNode = FocusNode();
  final FocusNode _nightFocusNode = FocusNode();
  final FocusNode _commentFocusNode = FocusNode();

  // Controllers for edit medicine form
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();
  final TextEditingController _editMorningController = TextEditingController();
  final TextEditingController _editAfternoonController =
      TextEditingController();
  final TextEditingController _editNightController = TextEditingController();
  final TextEditingController _editCommentController = TextEditingController();

  // Add focus nodes for edit form
  final FocusNode _editNameFocusNode = FocusNode();
  final FocusNode _editCategoryFocusNode = FocusNode();
  final FocusNode _editMorningFocusNode = FocusNode();
  final FocusNode _editAfternoonFocusNode = FocusNode();
  final FocusNode _editNightFocusNode = FocusNode();
  final FocusNode _editCommentFocusNode = FocusNode();

  // For search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  // Category suggestions for autocomplete
  static const List<String> _categorySuggestions = [
    'Antipyretics',
    'Analgesics',
    'Antibiotics',
    'Antidepressants',
    'Antidiabetics',
    'Antihypertensives',
    'Anticoagulants',
    'Antihistamines',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
    _setupDosageFieldListeners();
    _setupKeyboardShortcuts();

    // Set up search listener
    _searchController.addListener(_updateSearchQuery);
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _setupDosageFieldListeners() {
    // For Add form
    _morningFocusNode.addListener(() {
      if (_morningFocusNode.hasFocus && _morningController.text == '0') {
        _morningController.clear();
      } else if (!_morningFocusNode.hasFocus &&
          _morningController.text.isEmpty) {
        _morningController.text = '0';
      }
    });

    _afternoonFocusNode.addListener(() {
      if (_afternoonFocusNode.hasFocus && _afternoonController.text == '0') {
        _afternoonController.clear();
      } else if (!_afternoonFocusNode.hasFocus &&
          _afternoonController.text.isEmpty) {
        _afternoonController.text = '0';
      }
    });

    _nightFocusNode.addListener(() {
      if (_nightFocusNode.hasFocus && _nightController.text == '0') {
        _nightController.clear();
      } else if (!_nightFocusNode.hasFocus && _nightController.text.isEmpty) {
        _nightController.text = '0';
      }
    });

    // For Edit form
    _editMorningFocusNode.addListener(() {
      if (_editMorningFocusNode.hasFocus &&
          _editMorningController.text == '0') {
        _editMorningController.clear();
      } else if (!_editMorningFocusNode.hasFocus &&
          _editMorningController.text.isEmpty) {
        _editMorningController.text = '0';
      }
    });

    _editAfternoonFocusNode.addListener(() {
      if (_editAfternoonFocusNode.hasFocus &&
          _editAfternoonController.text == '0') {
        _editAfternoonController.clear();
      } else if (!_editAfternoonFocusNode.hasFocus &&
          _editAfternoonController.text.isEmpty) {
        _editAfternoonController.text = '0';
      }
    });

    _editNightFocusNode.addListener(() {
      if (_editNightFocusNode.hasFocus && _editNightController.text == '0') {
        _editNightController.clear();
      } else if (!_editNightFocusNode.hasFocus &&
          _editNightController.text.isEmpty) {
        _editNightController.text = '0';
      }
    });
  }

  void _setupKeyboardShortcuts() {
    // Set up keyboard shortcuts for common actions
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      // Check if Ctrl+F is pressed for search focus
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.keyF &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _searchController.selection = TextSelection(
            baseOffset: 0, extentOffset: _searchController.text.length);
        FocusScope.of(context).requestFocus();
        return true;
      }

      // Check if Ctrl+R is pressed for refresh
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.keyR &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _fetchMedicines();
        return true;
      }

      // Check if Ctrl+N is pressed for new medicine
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.keyN &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _nameFocusNode.requestFocus();
        return true;
      }

      return false;
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _categoryController.dispose();
    _morningController.dispose();
    _afternoonController.dispose();
    _nightController.dispose();
    _commentController.dispose();
    _editNameController.dispose();
    _editCategoryController.dispose();
    _editMorningController.dispose();
    _editAfternoonController.dispose();
    _editNightController.dispose();
    _editCommentController.dispose();
    _searchController.dispose();

    // Dispose focus nodes
    _nameFocusNode.dispose();
    _categoryFocusNode.dispose();
    _morningFocusNode.dispose();
    _afternoonFocusNode.dispose();
    _nightFocusNode.dispose();
    _commentFocusNode.dispose();
    _editNameFocusNode.dispose();
    _editCategoryFocusNode.dispose();
    _editMorningFocusNode.dispose();
    _editAfternoonFocusNode.dispose();
    _editNightFocusNode.dispose();
    _editCommentFocusNode.dispose();

    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchMedicines() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getDoctorMedicines'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> medicinesJson = json.decode(response.body);
        setState(() {
          _medicines.clear();
          _medicines.addAll(
            medicinesJson.map((json) => Medicine2.fromJson(json)).toList(),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load medicines: ${response.reasonPhrase ?? "Unknown error"}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _addMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isMedicineAdding = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isMedicineAdding = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${KVM_URL}/doctors/addMedicine'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text,
          'category': _categoryController.text,
          'morning': _morningController.text,
          'afternoon': _afternoonController.text,
          'night': _nightController.text,
          'comment': _commentController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reset form fields
        _nameController.clear();
        _categoryController.clear();
        _morningController.text = "0";
        _afternoonController.text = "0";
        _nightController.text = "0";
        _commentController.clear();

        // Return focus to name field for quick consecutive entries
        _nameFocusNode.requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medicine added successfully'),
            backgroundColor: HospitalTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Set button back to normal state
        setState(() {
          _isMedicineAdding = false;
        });

        _fetchMedicines(); // Refresh the list
      } else {
        setState(() {
          _errorMessage =
              'Failed to add medicine: ${_getErrorMessage(response)}';
          _isMedicineAdding = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isMedicineAdding = false;
      });
    }
  }

  String _getErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> errorJson = json.decode(response.body);
      return errorJson['message'] ?? response.reasonPhrase ?? 'Unknown error';
    } catch (_) {
      return response.reasonPhrase ?? 'Unknown error';
    }
  }

  Future<void> _deleteMedicine(String medicineId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('${KVM_URL}/doctors/deleteDoctorMedicine/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medicine deleted successfully'),
            backgroundColor: HospitalTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchMedicines(); // Refresh the list
      } else {
        setState(() {
          _errorMessage =
              'Failed to delete medicine: ${_getErrorMessage(response)}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMedicine(String medicineId) async {
    if (!_editFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      final response = await http.patch(
        Uri.parse('${KVM_URL}/doctors/updateMedicine/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _editNameController.text,
          'category': _editCategoryController.text,
          'morning': _editMorningController.text,
          'afternoon': _editAfternoonController.text,
          'night': _editNightController.text,
          'comment': _editCommentController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medicine updated successfully'),
            backgroundColor: HospitalTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchMedicines(); // Refresh the list
      } else {
        setState(() {
          _errorMessage =
              'Failed to update medicine: ${_getErrorMessage(response)}';
          _isLoading = false;
        });
        Navigator.of(context)
            .pop(); // Close the dialog even if there's an error
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Close the dialog even if there's an error
    }
  }

  void _showEditDialog(Medicine2 medicine) {
    // Set initial values
    _editNameController.text = medicine.name;
    _editCategoryController.text = medicine.category;
    _editMorningController.text = medicine.morning;
    _editAfternoonController.text = medicine.afternoon;
    _editNightController.text = medicine.night;
    _editCommentController.text = medicine.comment;

    // Show dialog with responsive width
    showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final dialogWidth = size.width > 600 ? 600.0 : size.width * 0.9;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getCategoryIcon(medicine.category),
                color: HospitalTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Edit Medicine'),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            child: Form(
              key: _editFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _editNameController,
                      focusNode: _editNameFocusNode,
                      label: 'Medicine Name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a medicine name';
                        }
                        return null;
                      },
                      nextFocus: _editCategoryFocusNode,
                    ),
                    const SizedBox(height: 16),
                    _buildAutocompleteField(
                      controller: _editCategoryController,
                      focusNode: _editCategoryFocusNode,
                      label: 'Category',
                      suggestions: _categorySuggestions,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category';
                        }
                        return null;
                      },
                      nextFocus: _editMorningFocusNode,
                    ),
                    const SizedBox(height: 16),
                    _buildDosageSection(
                      context: context,
                      morningController: _editMorningController,
                      morningFocusNode: _editMorningFocusNode,
                      afternoonController: _editAfternoonController,
                      afternoonFocusNode: _editAfternoonFocusNode,
                      nightController: _editNightController,
                      nightFocusNode: _editNightFocusNode,
                      commentFocusNode: _editCommentFocusNode,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _editCommentController,
                      focusNode: _editCommentFocusNode,
                      label: 'Comment',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: HospitalTheme.textMedium)),
            ),
            HospitalTheme.buildGradientButton(
              icon: Icons.save,
              label: 'Update',
              onPressed: () => _updateMedicine(medicine.id),
              width: 120,
              height: 40,
            ),
          ],
        );
      },
    );
  }

  // Building reusable components
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    String? Function(String?)? validator,
    FocusNode? nextFocus,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: HospitalTheme.textMedium),
        enabledBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.error, width: 2),
        ),
      ),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          nextFocus.requestFocus();
        }
      },
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required List<String> suggestions,
    String? Function(String?)? validator,
    FocusNode? nextFocus,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return suggestions.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
        if (nextFocus != null) {
          nextFocus.requestFocus();
        }
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sync the autocomplete's controller with our controller
        fieldController.text = controller.text;

        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: HospitalTheme.textMedium),
            hintText: 'Type or select a category',
            enabledBorder: OutlineInputBorder(
              borderRadius: HospitalTheme.radiusSmall,
              borderSide: BorderSide(color: HospitalTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: HospitalTheme.radiusSmall,
              borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: HospitalTheme.radiusSmall,
              borderSide: BorderSide(color: HospitalTheme.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: HospitalTheme.radiusSmall,
              borderSide: BorderSide(color: HospitalTheme.error, width: 2),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: HospitalTheme.textMedium,
            ),
          ),
          validator: validator,
          onChanged: (value) {
            // Keep our controller in sync with the autocomplete's controller
            controller.text = value;
          },
          textInputAction:
              nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              nextFocus.requestFocus();
            }
          },
        );
      },
    );
  }

  Widget _buildDosageSection({
    required BuildContext context,
    required TextEditingController morningController,
    required FocusNode morningFocusNode,
    required TextEditingController afternoonController,
    required FocusNode afternoonFocusNode,
    required TextEditingController nightController,
    required FocusNode nightFocusNode,
    required FocusNode commentFocusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dosage Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            Tooltip(
              message: 'Dosage units per time of day',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: HospitalTheme.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDosageField(
                controller: morningController,
                focusNode: morningFocusNode,
                label: 'Morning',
                nextFocus: afternoonFocusNode,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDosageField(
                controller: afternoonController,
                focusNode: afternoonFocusNode,
                label: 'Afternoon',
                nextFocus: nightFocusNode,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDosageField(
                controller: nightController,
                focusNode: nightFocusNode,
                label: 'Night',
                nextFocus: commentFocusNode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDosageField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required FocusNode nextFocus,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: HospitalTheme.textMedium),
        enabledBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.error, width: 1),
        ),
        suffixIcon: Icon(
          _getDosageIcon(label.toLowerCase()),
          color: HospitalTheme.textMedium,
          size: 16,
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        DosageInputFormatter(),
        LengthLimitingTextInputFormatter(3),
      ],
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        nextFocus.requestFocus();
      },
    );
  }

  IconData _getDosageIcon(String time) {
    switch (time) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_twighlight;
      case 'night':
        return Icons.nightlight_outlined;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: HospitalTheme.textMedium,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                hintStyle: TextStyle(color: HospitalTheme.textLight),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Press Ctrl+F to focus search',
            child: Icon(
              Icons.keyboard,
              color: HospitalTheme.textLight,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;

    // Filter medicines based on search query
    List<Medicine2> filteredMedicines = _medicines;
    if (_searchQuery.isNotEmpty) {
      filteredMedicines = _medicines.where((medicine) {
        return medicine.name.toLowerCase().contains(_searchQuery) ||
            medicine.category.toLowerCase().contains(_searchQuery) ||
            medicine.comment.toLowerCase().contains(_searchQuery) ||
            medicine.addedBy.doctorName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Medicine Management',
        actions: [
          Tooltip(
            message: 'Refresh (Ctrl+R)',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchMedicines,
            ),
          ),
          Tooltip(
            message: 'Add New Medicine (Ctrl+N)',
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _nameFocusNode.requestFocus(),
            ),
          ),
        ],
        centerTitle: false,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel - Add Medicine Form
              Expanded(
                flex: isWideScreen ? 1 : 2,
                child: HospitalTheme.buildCard(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HospitalTheme.buildSectionHeader(
                            'Add New Medicine',
                            trailing: Tooltip(
                              message: 'Keyboard shortcut: Ctrl+N',
                              child: Icon(
                                Icons.keyboard,
                                color: HospitalTheme.textLight,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            label: 'Medicine Name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a medicine name';
                              }
                              return null;
                            },
                            nextFocus: _categoryFocusNode,
                          ),
                          const SizedBox(height: 16),
                          _buildAutocompleteField(
                            controller: _categoryController,
                            focusNode: _categoryFocusNode,
                            label: 'Category',
                            suggestions: _categorySuggestions,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a category';
                              }
                              return null;
                            },
                            nextFocus: _morningFocusNode,
                          ),
                          const SizedBox(height: 16),
                          _buildDosageSection(
                            context: context,
                            morningController: _morningController,
                            morningFocusNode: _morningFocusNode,
                            afternoonController: _afternoonController,
                            afternoonFocusNode: _afternoonFocusNode,
                            nightController: _nightController,
                            nightFocusNode: _nightFocusNode,
                            commentFocusNode: _commentFocusNode,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            label: 'Comment',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: HospitalTheme.buildGradientButton(
                              icon: Icons.add_circle_outline,
                              label: 'Add Medicine',
                              onPressed: _isMedicineAdding
                                  ? () {} // Empty function when loading (not null)
                                  : () => _addMedicine(),
                              isLoading: _isMedicineAdding,
                              width: double.infinity,
                              height: 50,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: HospitalTheme.error.withOpacity(0.1),
                                borderRadius: HospitalTheme.radiusSmall,
                                border: Border.all(
                                  color: HospitalTheme.error.withOpacity(0.3),
                                ),
                              ),
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: HospitalTheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style:
                                          TextStyle(color: HospitalTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Right Panel - Medicines List
              Expanded(
                flex: isWideScreen ? 2 : 3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSearchBar(),
                    ),
                    Expanded(
                      child: _isLoading && _medicines.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: HospitalTheme.primary),
                            )
                          : _medicines.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.medication_outlined,
                                        size: 80,
                                        color: HospitalTheme.textLight,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No medicines found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: HospitalTheme.textMedium,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add a new medicine using the form',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: HospitalTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      HospitalTheme.buildSectionHeader(
                                        'Medicines List',
                                        trailing:
                                            HospitalTheme.buildStatusBadge(
                                          '${filteredMedicines.length} ${_searchQuery.isNotEmpty ? "Filtered" : "Total"}',
                                          color: HospitalTheme.info,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: HospitalTheme.buildCard(
                                          padding: EdgeInsets.zero,
                                          child: filteredMedicines.isEmpty &&
                                                  _searchQuery.isNotEmpty
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.search_off,
                                                        size: 60,
                                                        color: HospitalTheme
                                                            .textLight,
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      Text(
                                                        'No medicines match your search',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: HospitalTheme
                                                              .textMedium,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextButton.icon(
                                                        onPressed: () {
                                                          _searchController
                                                              .clear();
                                                        },
                                                        icon: Icon(
                                                          Icons.clear,
                                                          color: HospitalTheme
                                                              .primary,
                                                          size: 18,
                                                        ),
                                                        label: Text(
                                                          'Clear Search',
                                                          style: TextStyle(
                                                            color: HospitalTheme
                                                                .primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount:
                                                      filteredMedicines.length,
                                                  separatorBuilder:
                                                      (context, index) =>
                                                          Divider(
                                                    color: HospitalTheme.border,
                                                    height: 1,
                                                  ),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final medicine =
                                                        filteredMedicines[
                                                            index];
                                                    return _buildMedicineListItem(
                                                        medicine);
                                                  },
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMedicineListItem(Medicine2 medicine) {
    return HospitalTheme.buildListTile(
      title: medicine.name,
      subtitle: 'Category: ${medicine.category}\n'
          'Dosage: ${_formatDosage(medicine)}\n'
          '${medicine.comment.isNotEmpty ? "Comment: ${medicine.comment}\n" : ""}'
          'Added by: ${medicine.addedBy.doctorName}',
      leading: CircleAvatar(
        backgroundColor: HospitalTheme.surfaceLight,
        child: Icon(
          _getCategoryIcon(medicine.category),
          color: HospitalTheme.primary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: HospitalTheme.info),
            onPressed: () => _showEditDialog(medicine),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: HospitalTheme.error),
            onPressed: () => _showDeleteConfirmation(medicine),
            tooltip: 'Delete',
          ),
        ],
      ),
      onTap: () => _showEditDialog(medicine),
    );
  }

  String _formatDosage(Medicine2 medicine) {
    final parts = <String>[];

    if (medicine.morning != '0') {
      parts.add('M:${medicine.morning}');
    }

    if (medicine.afternoon != '0') {
      parts.add('A:${medicine.afternoon}');
    }

    if (medicine.night != '0') {
      parts.add('N:${medicine.night}');
    }

    return parts.isEmpty ? 'None' : parts.join(', ');
  }

  void _showDeleteConfirmation(Medicine2 medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(color: HospitalTheme.textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMedicine(medicine.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'antipyretics':
        return Icons.thermostat;
      case 'analgesics':
        return Icons.healing;
      case 'antibiotics':
        return Icons.microwave;
      case 'antidepressants':
        return Icons.psychology;
      case 'antidiabetics':
        return Icons.bloodtype;
      case 'antihypertensives':
        return Icons.monitor_heart;
      case 'anticoagulants':
        return Icons.water_drop;
      case 'antihistamines':
        return Icons.ac_unit;
      default:
        return Icons.medication;
    }
  }
}
