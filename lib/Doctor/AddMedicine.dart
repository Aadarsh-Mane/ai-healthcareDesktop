import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctordesktop/constants/colors.dart';

// Import the HospitalTheme

class Medicine1 {
  final String id;
  final String name;
  final String category;
  final String morning;
  final String afternoon;
  final String night;
  final String comment;
  final DoctorInfo addedBy;

  Medicine1({
    required this.id,
    required this.name,
    required this.category,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.comment,
    required this.addedBy,
  });

  factory Medicine1.fromJson(Map<String, dynamic> json) {
    return Medicine1(
      id: json['_id'],
      name: json['name'],
      category: json['category'],
      morning: json['morning'] ?? "0",
      afternoon: json['afternoon'] ?? "0",
      night: json['night'] ?? "0",
      comment: json['comment'] ?? "",
      addedBy: DoctorInfo.fromJson(json['addedBy']),
    );
  }
}

class DoctorInfo {
  final String doctorId;
  final String doctorName;

  DoctorInfo({
    required this.doctorId,
    required this.doctorName,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
    );
  }
}

class MedicineManagementScreen extends StatefulWidget {
  const MedicineManagementScreen({Key? key}) : super(key: key);

  @override
  State<MedicineManagementScreen> createState() =>
      _MedicineManagementScreenState();
}

class _MedicineManagementScreenState extends State<MedicineManagementScreen> {
  final List<Medicine1> _medicines = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers for add medicine form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _morningController =
      TextEditingController(text: "0");
  final TextEditingController _afternoonController =
      TextEditingController(text: "0");
  final TextEditingController _nightController =
      TextEditingController(text: "0");
  final TextEditingController _commentController = TextEditingController();

  // Controllers for edit medicine form
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();
  final TextEditingController _editMorningController = TextEditingController();
  final TextEditingController _editAfternoonController =
      TextEditingController();
  final TextEditingController _editNightController = TextEditingController();
  final TextEditingController _editCommentController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  // Category options for dropdown
  final List<String> _categories = [
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
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchMedicines() async {
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
            medicinesJson.map((json) => Medicine1.fromJson(json)).toList(),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load medicines: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addMedicine() async {
    if (!_formKey.currentState!.validate()) return;

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
        // Medicine added successfully
        _nameController.clear();
        _categoryController.clear();
        _morningController.text = "0";
        _afternoonController.text = "0";
        _nightController.text = "0";
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medicine added successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );
        _fetchMedicines(); // Refresh the list
      } else {
        setState(() {
          _errorMessage = 'Failed to add medicine: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
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
            content: Text('Medicine deleted successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );
        _fetchMedicines(); // Refresh the list
      } else {
        setState(() {
          _errorMessage = 'Failed to delete medicine: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
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
            content: Text('Medicine updated successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );
        _fetchMedicines(); // Refresh the list
      } else {
        setState(() {
          _errorMessage = 'Failed to update medicine: ${response.body}';
          _isLoading = false;
        });
        Navigator.of(context)
            .pop(); // Close the dialog even if there's an error
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Close the dialog even if there's an error
    }
  }

  void _showEditDialog(Medicine1 medicine) {
    _editNameController.text = medicine.name;
    _editCategoryController.text = medicine.category;
    _editMorningController.text = medicine.morning;
    _editAfternoonController.text = medicine.afternoon;
    _editNightController.text = medicine.night;
    _editCommentController.text = medicine.comment;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medicine'),
        content: Form(
          key: _editFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _editNameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    labelStyle: TextStyle(color: HospitalTheme.textMedium),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide: BorderSide(color: HospitalTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide:
                          BorderSide(color: HospitalTheme.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide:
                          BorderSide(color: HospitalTheme.error, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide:
                          BorderSide(color: HospitalTheme.error, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a medicine name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _editCategoryController.text,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: HospitalTheme.textMedium),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide: BorderSide(color: HospitalTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide:
                          BorderSide(color: HospitalTheme.primary, width: 2),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _editCategoryController.text = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _editMorningController,
                        decoration: InputDecoration(
                          labelText: 'Morning',
                          labelStyle:
                              TextStyle(color: HospitalTheme.textMedium),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(color: HospitalTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.primary, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _editAfternoonController,
                        decoration: InputDecoration(
                          labelText: 'Afternoon',
                          labelStyle:
                              TextStyle(color: HospitalTheme.textMedium),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(color: HospitalTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.primary, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _editNightController,
                        decoration: InputDecoration(
                          labelText: 'Night',
                          labelStyle:
                              TextStyle(color: HospitalTheme.textMedium),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(color: HospitalTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.primary, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _editCommentController,
                  decoration: InputDecoration(
                    labelText: 'Comment',
                    labelStyle: TextStyle(color: HospitalTheme.textMedium),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide: BorderSide(color: HospitalTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: HospitalTheme.radiusSmall,
                      borderSide:
                          BorderSide(color: HospitalTheme.primary, width: 2),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Medicine Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMedicines,
            tooltip: 'Refresh',
          ),
        ],
        centerTitle: false,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Row(
        children: [
          // Left Panel - Add Medicine Form
          Expanded(
            flex: 1,
            child: HospitalTheme.buildCard(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HospitalTheme.buildSectionHeader('Add New Medicine'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Medicine Name',
                          labelStyle:
                              TextStyle(color: HospitalTheme.textMedium),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(color: HospitalTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.error, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.error, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a medicine name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle:
                              TextStyle(color: HospitalTheme.textMedium),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(color: HospitalTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.primary, width: 2),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _categoryController.text = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dosage Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _morningController,
                              decoration: InputDecoration(
                                labelText: 'Morning',
                                labelStyle:
                                    TextStyle(color: HospitalTheme.textMedium),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: HospitalTheme.radiusSmall,
                                  borderSide:
                                      BorderSide(color: HospitalTheme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: HospitalTheme.radiusSmall,
                                  borderSide: BorderSide(
                                      color: HospitalTheme.primary, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _afternoonController,
                              decoration: InputDecoration(
                                labelText: 'Afternoon',
                                labelStyle:
                                    TextStyle(color: HospitalTheme.textMedium),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: HospitalTheme.radiusSmall,
                                  borderSide:
                                      BorderSide(color: HospitalTheme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: HospitalTheme.radiusSmall,
                                  borderSide: BorderSide(
                                      color: HospitalTheme.primary, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _nightController,
                              decoration: InputDecoration(
                                labelText: 'Night',
                                labelStyle:
                                    TextStyle(color: HospitalTheme.textMedium),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: HospitalTheme.radiusSmall,
                                  borderSide:
                                      BorderSide(color: HospitalTheme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: HospitalTheme.radiusSmall,
                                  borderSide: BorderSide(
                                      color: HospitalTheme.primary, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          labelText: 'Comment',
                          labelStyle:
                              TextStyle(color: HospitalTheme.textMedium),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(color: HospitalTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: HospitalTheme.radiusSmall,
                            borderSide: BorderSide(
                                color: HospitalTheme.primary, width: 2),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: HospitalTheme.buildGradientButton(
                          icon: Icons.add_circle_outline,
                          label: 'Add Medicine',
                          onPressed: _isLoading ? () {} : _addMedicine,
                          isLoading: _isLoading,
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
                                color: HospitalTheme.error.withOpacity(0.3)),
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
                                  style: TextStyle(color: HospitalTheme.error),
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
            flex: 2,
            child: _isLoading && _medicines.isEmpty
                ? Center(
                    child:
                        CircularProgressIndicator(color: HospitalTheme.primary))
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HospitalTheme.buildSectionHeader(
                              'Medicines List',
                              trailing: HospitalTheme.buildStatusBadge(
                                  '${_medicines.length} Total',
                                  color: HospitalTheme.info),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: HospitalTheme.buildCard(
                                padding: EdgeInsets.zero,
                                child: ListView.separated(
                                  itemCount: _medicines.length,
                                  separatorBuilder: (context, index) => Divider(
                                    color: HospitalTheme.border,
                                    height: 1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final medicine = _medicines[index];
                                    return HospitalTheme.buildListTile(
                                      title: medicine.name,
                                      subtitle:
                                          'Category: ${medicine.category}\nDosage: M:${medicine.morning}, A:${medicine.afternoon}, N:${medicine.night}\n${medicine.comment.isNotEmpty ? "Comment: ${medicine.comment}" : ""}\nAdded by: ${medicine.addedBy.doctorName}',
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            HospitalTheme.surfaceLight,
                                        child: Icon(
                                          _getCategoryIcon(medicine.category),
                                          color: HospitalTheme.primary,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined,
                                                color: HospitalTheme.info),
                                            onPressed: () =>
                                                _showEditDialog(medicine),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: HospitalTheme.error),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Confirm Delete'),
                                                  content: Text(
                                                      'Are you sure you want to delete ${medicine.name}?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: Text('Cancel',
                                                          style: TextStyle(
                                                              color: HospitalTheme
                                                                  .textMedium)),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        _deleteMedicine(
                                                            medicine.id);
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            HospitalTheme.error,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                      child:
                                                          const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showEditDialog(medicine),
                                    );
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
