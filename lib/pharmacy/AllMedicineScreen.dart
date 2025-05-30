import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/getInventoryModel.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class InventoryItem {
  final String id;
  final Medicine medicine;
  final String batchNumber;
  final DateTime expiryDate;
  final int quantity;
  final Distributor distributor;
  final DateTime addedOn;

  InventoryItem({
    required this.id,
    required this.medicine,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.distributor,
    required this.addedOn,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? '',
      medicine: Medicine.fromJson(json['medicine'] ?? {}),
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : DateTime.now(),
      quantity: json['quantity'] ?? 0,
      distributor: Distributor.fromJson(json['distributor'] ?? {}),
      addedOn: json['addedOn'] != null
          ? DateTime.parse(json['addedOn'])
          : DateTime.now(),
    );
  }
}

// Model class for Medicine
class Medicine {
  final String id;
  final String name;
  final String manufacturer;
  final String? category;
  final String? description;
  final double mrp;
  final double purchasePrice;
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.name,
    required this.manufacturer,
    this.category,
    this.description,
    required this.mrp,
    required this.purchasePrice,
    required this.createdAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'],
      description: json['description'],
      mrp: json['mrp'] != null
          ? (json['mrp'] is int)
              ? json['mrp'].toDouble()
              : double.parse(json['mrp'].toString())
          : 0.0,
      purchasePrice: json['purchasePrice'] != null
          ? (json['purchasePrice'] is int)
              ? json['purchasePrice'].toDouble()
              : double.parse(json['purchasePrice'].toString())
          : 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'manufacturer': manufacturer,
      'category': category,
      'description': description,
      'mrp': mrp,
      'purchasePrice': purchasePrice,
    };
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? manufacturer,
    String? category,
    String? description,
    double? mrp,
    double? purchasePrice,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      description: description ?? this.description,
      mrp: mrp ?? this.mrp,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// API Service for Medicines
class MedicineService {
  // Get all medicines
  Future<List<Medicine>> getMedicines() async {
    try {
      final response =
          await http.get(Uri.parse('$KVM_URL/pharma/getMedicines'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((item) => Medicine.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching medicines: $e');
      return [];
    }
  }

  // Create a new medicine
  Future<bool> createMedicine(Medicine medicine) async {
    try {
      final response = await http.post(
        Uri.parse('$KVM_URL/pharma/createMedicine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode([medicine.toJson()]), // API expects an array
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating medicine: $e');
      return false;
    }
  }

  Future<List<Distributor>> getDistributors() async {
    try {
      final response =
          await http.get(Uri.parse('$KVM_URL/pharma/getDistributors'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((item) => Distributor.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching distributors: $e');
      return [];
    }
  }

  // Update a medicine
  Future<bool> updateMedicine(String id, Medicine medicine) async {
    try {
      final response = await http.patch(
        Uri.parse('$KVM_URL/pharma/updateMedicine/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(medicine.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating medicine: $e');
      return false;
    }
  }

  // Delete a medicine
  Future<bool> deleteMedicine(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$KVM_URL/pharma/deleteMedicine/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      return false;
    }
  }

  Future<bool> addToInventory(String medicineId, String distributorId,
      String batchNumber, int quantity, DateTime expiryDate) async {
    try {
      // Print out the medicine ID for debugging
      debugPrint('Medicine ID being used: "$medicineId"');

      // Format the data exactly as Postman would send it
      final data = {
        'medicineId':
            medicineId.trim(), // Ensure no leading/trailing whitespace
        'distributorId': distributorId.trim(),
        'batchNumber': batchNumber,
        'quantity': quantity,
        'expiryDate': expiryDate.toIso8601String(),
      };

      debugPrint('Adding to inventory: ${json.encode(data)}');

      // Use the exact same headers as Postman
      final response = await http.post(
        Uri.parse('$KVM_URL/pharma/addToInventory'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );
      print('Server response status: ${response.body}');
      debugPrint('Server response status: ${response.statusCode}');
      debugPrint('Server response body: ${response.body}');

      // Parse the response to get more detailed error
      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final errorData = json.decode(response.body);
          debugPrint(
              'Detailed error: ${errorData['message'] ?? 'Unknown error'}');
        } catch (e) {
          debugPrint('Failed to parse error response');
        }
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Exception in addToInventory: $e');
      return false;
    }
  }

  Future<List<InventoryItem>> getInventory() async {
    try {
      final response =
          await http.get(Uri.parse('$KVM_URL/pharma/getInventory'));
      print("HELLO WORLD");
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((item) => InventoryItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      return [];
    }
  }

  // Add to your MedicineService class if not already there
}

// Providers for state management
final medicineServiceProvider = Provider<MedicineService>((ref) {
  return MedicineService();
});

final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  final medicineService = ref.watch(medicineServiceProvider);
  return await medicineService.getMedicines();
});
final distributorsProvider = FutureProvider<List<Distributor>>((ref) async {
  final medicineService = ref.watch(medicineServiceProvider);
  return await medicineService.getDistributors();
});
final selectedMedicineProvider = StateProvider<Medicine?>((ref) => null);
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final medicineService = ref.watch(medicineServiceProvider);
  return await medicineService.getInventory();
});
// Screen for Medicine Management

// Model class remains the same
// MedicineService remains the same
// Providers remain the same

class AllMedicineScreen extends ConsumerStatefulWidget {
  const AllMedicineScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AllMedicineScreen> createState() => _AllMedicineScreenState();
}

class _AllMedicineScreenState extends ConsumerState<AllMedicineScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _filteredMedicines = [];
  Medicine? _selectedMedicine;

  // Sort state
  String _sortColumn = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        // Create new medicine (Ctrl+N or Cmd+N)
        if (event.logicalKey == LogicalKeyboardKey.keyN &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _showMedicineDialog(context);
          return true;
        }
        // Search (Ctrl+F or Cmd+F)
        if (event.logicalKey == LogicalKeyboardKey.keyF &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          // Focus on search field
          FocusScope.of(context).requestFocus(FocusNode());
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
          return true;
        }
      }
      return false;
    });
  }

  Future<void> _showMedicineDialog(BuildContext context,
      {Medicine? medicine}) async {
    final nameController = TextEditingController(text: medicine?.name ?? '');
    final manufacturerController =
        TextEditingController(text: medicine?.manufacturer ?? '');
    final categoryController =
        TextEditingController(text: medicine?.category ?? '');
    final descriptionController =
        TextEditingController(text: medicine?.description ?? '');
    final mrpController =
        TextEditingController(text: medicine?.mrp.toString() ?? '');
    final purchasePriceController =
        TextEditingController(text: medicine?.purchasePrice.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final isEditing = medicine != null;
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Medicine' : 'Add New Medicine'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter medicine name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter medicine name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Manufacturer
                  TextFormField(
                    controller: manufacturerController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer',
                      hintText: 'Enter manufacturer name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter manufacturer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'Enter category (tablet, syrup, etc.)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Price section in two columns
                  Row(
                    children: [
                      // MRP
                      Expanded(
                        child: TextFormField(
                          controller: mrpController,
                          decoration: const InputDecoration(
                            labelText: 'MRP (₹)',
                            hintText: 'Enter MRP',
                            prefixText: '₹ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter MRP';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Purchase Price
                      Expanded(
                        child: TextFormField(
                          controller: purchasePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price (₹)',
                            hintText: 'Enter purchase price',
                            prefixText: '₹ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter purchase price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmaTheme.accent,
              ),
              child: Text(isEditing ? 'Update' : 'Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final medicineService = ref.read(medicineServiceProvider);
                  final newMedicine = Medicine(
                    id: medicine?.id ?? '',
                    name: nameController.text,
                    manufacturer: manufacturerController.text,
                    category: categoryController.text.isEmpty
                        ? null
                        : categoryController.text,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    mrp: double.parse(mrpController.text),
                    purchasePrice: double.parse(purchasePriceController.text),
                    createdAt: medicine?.createdAt ?? DateTime.now(),
                  );

                  bool success;
                  if (isEditing) {
                    success = await medicineService.updateMedicine(
                      medicine.id,
                      newMedicine,
                    );
                  } else {
                    success = await medicineService.createMedicine(
                      newMedicine,
                    );
                  }

                  if (success) {
                    _refreshMedicines();
                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Medicine updated successfully'
                                : 'Medicine added successfully',
                          ),
                          backgroundColor: PharmaTheme.success,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Failed to update medicine'
                                : 'Failed to add medicine',
                          ),
                          backgroundColor: PharmaTheme.error,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

// Inside _AllMedicineScreenState class, add this method to show Add to Inventory dialog
  Future<void> _showAddToInventoryDialog(
      BuildContext context, Medicine medicine) async {
    final medicineService = ref.read(medicineServiceProvider);
    final quantityController = TextEditingController();
    final batchNumberController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime selectedExpiryDate = DateTime.now().add(const Duration(days: 365));
    Distributor? selectedDistributor;
    String? errorMessage;

    // Pre-fetch distributors to check if we have any
    try {
      final distributors = await medicineService.getDistributors();
      if (distributors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No distributors available. Please add distributors first.'),
            backgroundColor: PharmaTheme.error,
          ),
        );
        return; // Exit early if no distributors
      }
    } catch (e) {
      debugPrint('Error pre-fetching distributors: $e');
      // Continue to show dialog anyway, will display error there
    }

    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final distributorsAsync = ref.watch(distributorsProvider);

                return AlertDialog(
                  title: const Text('Add to Inventory'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: ListBody(
                        children: <Widget>[
                          // Medicine info
                          Container(
                            padding: const EdgeInsets.all(PharmaTheme.spacingS),
                            decoration: BoxDecoration(
                              color: PharmaTheme.primary.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(PharmaTheme.radiusM),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.medication,
                                  color: PharmaTheme.primary,
                                ),
                                const SizedBox(width: PharmaTheme.spacingS),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        medicine.manufacturer,
                                        style: PharmaTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: PharmaTheme.spacingM),

                          // Display error message if any
                          if (errorMessage != null) ...[
                            Container(
                              padding:
                                  const EdgeInsets.all(PharmaTheme.spacingS),
                              decoration: BoxDecoration(
                                color: PharmaTheme.error.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(PharmaTheme.radiusM),
                                border: Border.all(
                                    color: PharmaTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: PharmaTheme.error, size: 18),
                                  const SizedBox(width: PharmaTheme.spacingS),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: PharmaTheme.bodySmall
                                          .copyWith(color: PharmaTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: PharmaTheme.spacingM),
                          ],

                          // Batch Number
                          TextFormField(
                            controller: batchNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Batch Number',
                              hintText: 'Enter batch number',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter batch number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: PharmaTheme.spacingM),

                          // Quantity
                          TextFormField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              hintText: 'Enter quantity',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return 'Please enter a valid quantity';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: PharmaTheme.spacingM),

                          // Expiry Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Expiry Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: PharmaTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: PharmaTheme.spacingXs),
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedExpiryDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 3650)),
                                  );
                                  if (picked != null &&
                                      picked != selectedExpiryDate) {
                                    setState(() {
                                      selectedExpiryDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: PharmaTheme.spacingM,
                                    vertical: PharmaTheme.spacingS,
                                  ),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: PharmaTheme.border),
                                    borderRadius: BorderRadius.circular(
                                        PharmaTheme.radiusM),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM, yyyy')
                                            .format(selectedExpiryDate),
                                        style: PharmaTheme.bodyMedium,
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: PharmaTheme.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: PharmaTheme.spacingM),

                          // Distributor Dropdown
                          distributorsAsync.when(
                            data: (distributors) {
                              if (distributors.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(
                                      PharmaTheme.spacingS),
                                  decoration: BoxDecoration(
                                    color: PharmaTheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        PharmaTheme.radiusM),
                                    border: Border.all(
                                        color:
                                            PharmaTheme.error.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: PharmaTheme.error, size: 18),
                                      SizedBox(width: PharmaTheme.spacingS),
                                      Expanded(
                                        child: Text(
                                          'No distributors available. Please add distributors first.',
                                          style: TextStyle(
                                              color: PharmaTheme.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Initialize selectedDistributor if it's null
                              if (selectedDistributor == null &&
                                  distributors.isNotEmpty) {
                                selectedDistributor = distributors.first;
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Distributor',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: PharmaTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: PharmaTheme.spacingXs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: PharmaTheme.spacingS,
                                    ),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: PharmaTheme.border),
                                      borderRadius: BorderRadius.circular(
                                          PharmaTheme.radiusM),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Distributor>(
                                        isExpanded: true,
                                        value: selectedDistributor,
                                        items: distributors.map((distributor) {
                                          return DropdownMenuItem<Distributor>(
                                            value: distributor,
                                            child: Text(distributor.name),
                                          );
                                        }).toList(),
                                        onChanged: (Distributor? value) {
                                          if (value != null) {
                                            setState(() {
                                              selectedDistributor = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: PharmaTheme.spacingS),
                                  Text(
                                    'Loading distributors...',
                                    style: PharmaTheme.bodySmall.copyWith(
                                      color: PharmaTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            error: (error, _) => Container(
                              padding:
                                  const EdgeInsets.all(PharmaTheme.spacingS),
                              decoration: BoxDecoration(
                                color: PharmaTheme.error.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(PharmaTheme.radiusM),
                                border: Border.all(
                                    color: PharmaTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: PharmaTheme.error, size: 18),
                                  const SizedBox(width: PharmaTheme.spacingS),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Failed to load distributors',
                                          style: TextStyle(
                                              color: PharmaTheme.error),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          error.toString(),
                                          style: PharmaTheme.bodySmall.copyWith(
                                              color: PharmaTheme.error),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    distributorsAsync.when(
                      data: (distributors) {
                        if (distributors.isEmpty) {
                          return TextButton(
                            onPressed: null,
                            child: const Text('Save'),
                          );
                        }

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PharmaTheme.accent,
                          ),
                          child: const Text('Save'),
                          onPressed: () async {
                            if (formKey.currentState!.validate() &&
                                selectedDistributor != null) {
                              // Reset error message
                              setState(() {
                                errorMessage = null;
                              });

                              try {
                                final success =
                                    await medicineService.addToInventory(
                                  medicine.id,
                                  selectedDistributor!.id,
                                  batchNumberController.text,
                                  int.parse(quantityController.text),
                                  selectedExpiryDate,
                                );

                                if (success) {
                                  // Refresh inventory data
                                  ref.invalidate(inventoryProvider);
                                  if (context.mounted) {
                                    Navigator.of(dialogContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Added to inventory successfully'),
                                        backgroundColor: PharmaTheme.success,
                                      ),
                                    );
                                  }
                                } else {
                                  setState(() {
                                    errorMessage =
                                        'Failed to add to inventory. Please check that the medicine still exists in the database.';
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  errorMessage = 'Error: ${e.toString()}';
                                });
                              }
                            }
                          },
                        );
                      },
                      loading: () => const SizedBox(
                        height: 36,
                        width: 36,
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => OutlinedButton(
                        onPressed: () {
                          // Retry loading distributors
                          ref.invalidate(distributorsProvider);
                        },
                        child: const Text('Retry Loading'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Rest of the methods remain the same
  void _searchMedicines(String query) {
    ref.watch(medicinesProvider).whenData((medicines) {
      if (!mounted) return;
      setState(() {
        _filteredMedicines = query.isEmpty
            ? medicines
            : medicines.where((medicine) {
                final lowercaseQuery = query.toLowerCase();
                return medicine.name.toLowerCase().contains(lowercaseQuery) ||
                    medicine.manufacturer
                        .toLowerCase()
                        .contains(lowercaseQuery) ||
                    (medicine.category
                            ?.toLowerCase()
                            .contains(lowercaseQuery) ??
                        false) ||
                    (medicine.description
                            ?.toLowerCase()
                            .contains(lowercaseQuery) ??
                        false);
              }).toList();

        // Apply current sort
        _sortMedicines(_sortColumn, _sortAscending);
      });
    });
  }

  void _sortMedicines(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;

      switch (column) {
        case 'name':
          _filteredMedicines.sort((a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
          break;
        case 'manufacturer':
          _filteredMedicines.sort((a, b) => ascending
              ? a.manufacturer.compareTo(b.manufacturer)
              : b.manufacturer.compareTo(a.manufacturer));
          break;
        case 'category':
          _filteredMedicines.sort((a, b) {
            final aCategory = a.category ?? '';
            final bCategory = b.category ?? '';
            return ascending
                ? aCategory.compareTo(bCategory)
                : bCategory.compareTo(aCategory);
          });
          break;
        case 'mrp':
          _filteredMedicines.sort((a, b) =>
              ascending ? a.mrp.compareTo(b.mrp) : b.mrp.compareTo(a.mrp));
          break;
        case 'purchasePrice':
          _filteredMedicines.sort((a, b) => ascending
              ? a.purchasePrice.compareTo(b.purchasePrice)
              : b.purchasePrice.compareTo(a.purchasePrice));
          break;
        case 'createdAt':
          _filteredMedicines.sort((a, b) => ascending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  void _refreshMedicines() {
    ref.invalidate(medicinesProvider);
    _searchController.clear();
    setState(() {
      _filteredMedicines = [];
      _selectedMedicine = null;
    });
  }

  void _selectMedicine(Medicine medicine) {
    setState(() {
      _selectedMedicine = medicine;
    });
    ref.read(selectedMedicineProvider.notifier).state = medicine;
  }

  Future<void> _deleteMedicine(BuildContext context, Medicine medicine) async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${medicine.name}?'),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone and will remove all associated data.',
                  style: TextStyle(color: PharmaTheme.warning),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: PharmaTheme.error),
              child: const Text('Delete'),
              onPressed: () async {
                final medicineService = ref.read(medicineServiceProvider);
                final success =
                    await medicineService.deleteMedicine(medicine.id);

                if (success) {
                  if (_selectedMedicine?.id == medicine.id) {
                    setState(() {
                      _selectedMedicine = null;
                    });
                    ref.read(selectedMedicineProvider.notifier).state = null;
                  }
                  _refreshMedicines();
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Medicine deleted successfully'),
                        backgroundColor: PharmaTheme.success,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete medicine'),
                        backgroundColor: PharmaTheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshMedicines,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: PharmaTheme.background,
          image: DecorationImage(
            image: const AssetImage('assets/images/pattern_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
            colorFilter: ColorFilter.mode(
              PharmaTheme.primary.withOpacity(0.1),
              BlendMode.dstIn,
            ),
          ),
        ),
        child: medicinesAsync.when(
          data: (medicines) {
            // Initialize filtered medicines if empty
            if (_filteredMedicines.isEmpty) {
              _filteredMedicines = List.from(medicines);
              _sortMedicines(_sortColumn, _sortAscending);
            }
            if (medicines.isEmpty) {
              return _EmptyMedicineList(
                onAdd: () => _showMedicineDialog(context),
              );
            }

            // Responsive layout
            return isSmallScreen
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorWidget(
            error: error.toString(),
            onRetry: _refreshMedicines,
          ),
        ),
      ),
    );
  }

  // Extracted layouts for better organization
  Widget _buildDesktopLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Use a more flexible width calculation that adapts to the available space
    final tableWidth = _selectedMedicine == null
        ? size.width * 0.95 // Almost full width when no medicine is selected
        : size.width * 0.6; // 60% width when medicine is selected

    return Padding(
      padding: const EdgeInsets.all(8.0), // Add padding to avoid overflow
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel - Medicine table (Master)
          SizedBox(
            width: tableWidth,
            child: _MedicineTable(
              filteredMedicines: _filteredMedicines,
              searchController: _searchController,
              selectedMedicine: _selectedMedicine,
              onSearch: _searchMedicines,
              onSort: _sortMedicines,
              onSelect: _selectMedicine,
              onAdd: () => _showMedicineDialog(context),
              onEdit: (medicine) =>
                  _showMedicineDialog(context, medicine: medicine),
              onDelete: (medicine) => _deleteMedicine(context, medicine),
            ),
          ),

          // Right panel - Medicine details (Detail)
          if (_selectedMedicine != null)
            Expanded(
              child: SingleChildScrollView(
                // Wrap in SingleChildScrollView to prevent overflow
                child: _MedicineDetail(
                  medicine: _selectedMedicine!,
                  onEdit: () =>
                      _showMedicineDialog(context, medicine: _selectedMedicine),
                  onDelete: () => _deleteMedicine(context, _selectedMedicine!),
                  onAddToInventory: (medicine) =>
                      _showAddToInventoryDialog(context, medicine),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Top search and actions
        Padding(
          padding: const EdgeInsets.all(PharmaTheme.spacingM),
          child: _SearchBar(
            controller: _searchController,
            onSearch: _searchMedicines,
          ),
        ),

        // Table takes full width
        Expanded(
          child: _selectedMedicine == null
              ? _MedicineTable(
                  filteredMedicines: _filteredMedicines,
                  searchController: _searchController,
                  selectedMedicine: _selectedMedicine,
                  onSearch: _searchMedicines,
                  onSort: _sortMedicines,
                  onSelect: (medicine) {
                    setState(() {
                      _selectedMedicine = medicine;
                    });
                    // On mobile, navigate to detail screen
                    _showMedicineDetailScreen(context, medicine);
                  },
                  onAdd: () => _showMedicineDialog(context),
                  onEdit: (medicine) =>
                      _showMedicineDialog(context, medicine: medicine),
                  onDelete: (medicine) => _deleteMedicine(context, medicine),
                  isCompact: true,
                )
              : _MedicineDetail(
                  medicine: _selectedMedicine!,
                  onEdit: () =>
                      _showMedicineDialog(context, medicine: _selectedMedicine),
                  onDelete: () => _deleteMedicine(context, _selectedMedicine!),
                  onAddToInventory: (medicine) =>
                      _showAddToInventoryDialog(context, medicine),
                  onBack: () {
                    setState(() {
                      _selectedMedicine = null;
                    });
                  },
                ),
        ),
      ],
    );
  }

  // Method to show medicine detail in a separate screen on mobile
  void _showMedicineDetailScreen(BuildContext context, Medicine medicine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(medicine.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedMedicine = null;
                });
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.pop(context);
                  _showMedicineDialog(context, medicine: medicine);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: PharmaTheme.error,
                onPressed: () {
                  Navigator.pop(context);
                  _deleteMedicine(context, medicine);
                },
              ),
            ],
          ),
          body: _MedicineDetail(
            medicine: medicine,
            onEdit: () {
              Navigator.pop(context);
              _showMedicineDialog(context, medicine: medicine);
            },
            onDelete: () {
              Navigator.pop(context);
              _deleteMedicine(context, medicine);
            },
            onAddToInventory: (medicine) =>
                _showAddToInventoryDialog(context, medicine),
          ),
        ),
      ),
    );
  }
}

// Extracted widgets for better composition and reusability

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search medicines...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onSearch('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusL),
          borderSide: BorderSide(color: PharmaTheme.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
      ),
      onChanged: onSearch,
    );
  }
}

class _EmptyMedicineList extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyMedicineList({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.medication,
            size: 64,
            color: PharmaTheme.textSecondary,
          ),
          const SizedBox(height: PharmaTheme.spacingL),
          Text(
            'No medicines found',
            style: PharmaTheme.headingMedium.copyWith(
              color: PharmaTheme.textSecondary,
            ),
          ),
          const SizedBox(height: PharmaTheme.spacingM),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: PharmaTheme.error,
          ),
          const SizedBox(height: PharmaTheme.spacingL),
          Text(
            'Failed to load medicines',
            style: PharmaTheme.headingMedium,
          ),
          const SizedBox(height: PharmaTheme.spacingM),
          Text(
            error,
            style: PharmaTheme.bodyMedium.copyWith(
              color: PharmaTheme.textSecondary,
            ),
          ),
          const SizedBox(height: PharmaTheme.spacingL),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _MedicineTable extends StatelessWidget {
  final List<Medicine> filteredMedicines;
  final TextEditingController searchController;
  final Medicine? selectedMedicine;
  final Function(String) onSearch;
  final Function(String, bool) onSort;
  final Function(Medicine) onSelect;
  final VoidCallback onAdd;
  final Function(Medicine) onEdit;
  final Function(Medicine) onDelete;
  final bool isCompact;

  const _MedicineTable({
    required this.filteredMedicines,
    required this.searchController,
    required this.selectedMedicine,
    required this.onSearch,
    required this.onSort,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        boxShadow: PharmaTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and search
          _buildHeader(context),

          // Data table
          Expanded(
            child: _buildTable(context),
          ),

          // Footer with add button
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: PharmaTheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(PharmaTheme.radiusM),
          topRight: Radius.circular(PharmaTheme.radiusM),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: PharmaTheme.spacingM),
          Text(
            'Medicines',
            style: PharmaTheme.headingMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(width: PharmaTheme.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PharmaTheme.spacingS,
              vertical: PharmaTheme.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(PharmaTheme.radiusCircular),
            ),
            child: Text(
              '${filteredMedicines.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Search field - only show in desktop mode
          if (!isCompact)
            SizedBox(
              width: 300,
              child: _SearchBar(
                controller: searchController,
                onSearch: onSearch,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine which columns to show based on available width
    final showManufacturer = screenWidth > 700;
    final showCategory = screenWidth > 800;
    final showPurchasePrice = screenWidth > 900;
    final showMargin = screenWidth > 1000;

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all<Color>(
            PharmaTheme.background,
          ),
          columnSpacing: isCompact ? 10 : 20,
          horizontalMargin: isCompact ? 10 : 20,
          columns: [
            DataColumn(
              label: const Text('Name'),
              onSort: (columnIndex, ascending) {
                onSort('name', ascending);
              },
            ),
            if (showManufacturer)
              DataColumn(
                label: const Text('Manufacturer'),
                onSort: (columnIndex, ascending) {
                  onSort('manufacturer', ascending);
                },
              ),
            if (showCategory)
              DataColumn(
                label: const Text('Category'),
                onSort: (columnIndex, ascending) {
                  onSort('category', ascending);
                },
              ),
            DataColumn(
              label: const Text('MRP (₹)'),
              numeric: true,
              onSort: (columnIndex, ascending) {
                onSort('mrp', ascending);
              },
            ),
            if (showPurchasePrice)
              DataColumn(
                label: const Text('Purchase (₹)'),
                numeric: true,
                onSort: (columnIndex, ascending) {
                  onSort('purchasePrice', ascending);
                },
              ),
            if (showMargin)
              DataColumn(
                label: const Text('Margin'),
                numeric: true,
              ),
            DataColumn(
              label: const Text('Actions'),
            ),
          ],
          rows: filteredMedicines.map((medicine) {
            final profit = medicine.mrp - medicine.purchasePrice;
            final profitPercentage = medicine.purchasePrice > 0
                ? (profit / medicine.purchasePrice * 100).toStringAsFixed(1)
                : 'N/A';

            final isSelected = selectedMedicine?.id == medicine.id;

            return DataRow(
              selected: isSelected,
              color: isSelected
                  ? MaterialStateProperty.all<Color>(
                      PharmaTheme.accent.withOpacity(0.1),
                    )
                  : null,
              cells: [
                DataCell(
                  Text(
                    medicine.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSelect(medicine),
                ),
                if (showManufacturer)
                  DataCell(
                    Text(
                      medicine.manufacturer,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelect(medicine),
                  ),
                if (showCategory)
                  DataCell(
                    Text(
                      medicine.category ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelect(medicine),
                  ),
                DataCell(
                  Text('₹${medicine.mrp.toStringAsFixed(2)}'),
                  onTap: () => onSelect(medicine),
                ),
                if (showPurchasePrice)
                  DataCell(
                    Text('₹${medicine.purchasePrice.toStringAsFixed(2)}'),
                    onTap: () => onSelect(medicine),
                  ),
                if (showMargin)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${profit.toStringAsFixed(2)}'),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PharmaTheme.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$profitPercentage%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: PharmaTheme.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => onSelect(medicine),
                  ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onEdit(medicine),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        color: PharmaTheme.error,
                        onPressed: () => onDelete(medicine),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: PharmaTheme.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(PharmaTheme.radiusM),
          bottomRight: Radius.circular(PharmaTheme.radiusM),
        ),
        border: Border(
          top: BorderSide(
            color: PharmaTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Medicines: ${filteredMedicines.length}',
            style: PharmaTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaTheme.accent,
              padding: const EdgeInsets.symmetric(
                horizontal: PharmaTheme.spacingL,
                vertical: PharmaTheme.spacingS,
              ),
            ),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _MedicineDetail extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Medicine) onAddToInventory;
  final VoidCallback? onBack;

  const _MedicineDetail({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
    required this.onAddToInventory,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(bottom: PharmaTheme.spacingM),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to List'),
                onPressed: onBack,
              ),
            ),
          // Medicine info card
          _buildMedicineInfoCard(context),

          const SizedBox(height: PharmaTheme.spacingM),

          // Inventory Management Section
          _buildInventorySection(context),
        ],
      ),
    );
  }

// Update the _buildInventorySection to display actual inventory data
  Widget _buildInventorySection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final inventoryAsync = ref.watch(inventoryProvider);

        return Container(
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: 500, // Add max height
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
            boxShadow: PharmaTheme.shadowSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: PharmaTheme.spacingS,
                  horizontal: PharmaTheme.spacingM,
                ),
                decoration: BoxDecoration(
                  color: PharmaTheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(PharmaTheme.radiusM),
                    topRight: Radius.circular(PharmaTheme.radiusM),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            size: 16,
                            color: PharmaTheme.textLight,
                          ),
                        ),
                        const SizedBox(width: PharmaTheme.spacingS),
                        Text(
                          'Inventory Management',
                          style: PharmaTheme.headingSmall.copyWith(
                            color: PharmaTheme.textLight,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    // Add to Inventory button
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        size: 16,
                        color: PharmaTheme.primary,
                      ),
                      label: const Text(
                        'Add to Inventory',
                        style: TextStyle(
                          color: PharmaTheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: PharmaTheme.spacingM,
                          vertical: PharmaTheme.spacingXs,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () => onAddToInventory(medicine),
                    ),
                  ],
                ),
              ),

              // Inventory Stats
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(PharmaTheme.spacingM),
                    child: inventoryAsync.when(
                      data: (inventory) {
                        // Filter inventory items for this medicine
                        final medicineInventory = inventory
                            .where((item) => item.medicine.id == medicine.id)
                            .toList();

                        // Calculate stats
                        final totalStock = medicineInventory.fold(
                            0, (sum, item) => sum + item.quantity);

                        final totalBatches = medicineInventory.length;

                        DateTime? nearestExpiry;
                        if (medicineInventory.isNotEmpty) {
                          nearestExpiry = medicineInventory
                              .map((item) => item.expiryDate)
                              .reduce((a, b) => a.isBefore(b) ? a : b);
                        }

                        return Padding(
                          padding: const EdgeInsets.all(PharmaTheme.spacingM),
                          child: _buildInventoryStatsRow(
                            totalStock: totalStock,
                            totalBatches: totalBatches,
                            nearestExpiry: nearestExpiry,
                          ),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(PharmaTheme.spacingM),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => _buildInventoryStatsRow(
                        totalStock: 0,
                        totalBatches: 0,
                        nearestExpiry: null,
                        hasError: true,
                      ),
                    ),
                  ),
                ),
              ),

              // Inventory items list
              Padding(
                padding: const EdgeInsets.all(PharmaTheme.spacingM),
                child: inventoryAsync.when(
                  data: (inventory) {
                    // Filter inventory items for this medicine
                    final medicineInventory = inventory
                        .where((item) => item.medicine.id == medicine.id)
                        .toList();

                    if (medicineInventory.isEmpty) {
                      return _buildInventoryPlaceholder();
                    }

                    return _buildInventoryItemsList(
                        medicineInventory.cast<InventoryItem>());
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildInventoryPlaceholder(hasError: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryStatsRow({
    required int totalStock,
    required int totalBatches,
    DateTime? nearestExpiry,
    bool hasError = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on available width
        final isNarrow = constraints.maxWidth < 600;

        final stats = [
          _InventoryStat(
            title: 'Total Stock',
            value: hasError ? '?' : totalStock.toString(),
            icon: hasError ? Icons.error_outline : Icons.inventory,
            color: hasError ? PharmaTheme.error : PharmaTheme.primary,
          ),
          _InventoryStat(
            title: 'Total Batches',
            value: hasError ? '?' : totalBatches.toString(),
            icon: hasError ? Icons.error_outline : Icons.layers,
            color: hasError ? PharmaTheme.error : PharmaTheme.accent,
          ),
          _InventoryStat(
            title: 'Nearest Expiry',
            value: hasError
                ? '?'
                : (nearestExpiry != null
                    ? DateFormat('dd MMM, yyyy').format(nearestExpiry)
                    : 'None'),
            icon: hasError ? Icons.error_outline : Icons.event,
            color: hasError ? PharmaTheme.error : PharmaTheme.warning,
          ),
        ];

        if (isNarrow) {
          // Vertical layout for narrow screens
          return Column(
            children: stats.map((stat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: PharmaTheme.spacingM),
                child: _buildCompactStatCard(
                  title: stat.title,
                  value: stat.value,
                  icon: stat.icon,
                  color: stat.color,
                ),
              );
            }).toList(),
          );
        } else {
          // Horizontal layout for wider screens
          return Row(
            children: stats.map((stat) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: stat != stats.last ? PharmaTheme.spacingM : 0,
                  ),
                  child: _buildCompactStatCard(
                    title: stat.title,
                    value: stat.value,
                    icon: stat.icon,
                    color: stat.color,
                  ),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildInventoryItemsList(List<InventoryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Batches',
          style: PharmaTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: PharmaTheme.textSecondary,
          ),
        ),
        const SizedBox(height: PharmaTheme.spacingM),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: PharmaTheme.border),
            borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final daysUntilExpiry =
                  item.expiryDate.difference(DateTime.now()).inDays;

              // Determine text color based on expiry
              Color expiryColor = PharmaTheme.textPrimary;
              if (daysUntilExpiry < 0) {
                expiryColor = PharmaTheme.error;
              } else if (daysUntilExpiry < 30) {
                expiryColor = PharmaTheme.warning;
              } else if (daysUntilExpiry < 90) {
                expiryColor = PharmaTheme.info;
              }

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: PharmaTheme.primary.withOpacity(0.1),
                  child: Text(
                    item.quantity.toString(),
                    style: TextStyle(
                      color: PharmaTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'Batch: ${item.batchNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('From: ${item.distributor.name}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Expires: ${DateFormat('dd MMM, yyyy').format(item.expiryDate)}',
                      style: TextStyle(
                        color: expiryColor,
                        fontWeight: daysUntilExpiry < 30
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      'Added: ${DateFormat('dd MMM, yyyy').format(item.addedOn)}',
                      style: PharmaTheme.bodySmall.copyWith(
                        color: PharmaTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryPlaceholder({bool hasError = false}) {
    return Container(
      height: 200, // Fixed height to prevent overflow
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.inventory_2_outlined,
              size: 48,
              color: hasError
                  ? PharmaTheme.error.withOpacity(0.5)
                  : PharmaTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: PharmaTheme.spacingS),
            Text(
              hasError
                  ? 'Failed to load inventory data'
                  : 'No inventory data available',
              style: PharmaTheme.bodyMedium.copyWith(
                color: hasError ? PharmaTheme.error : PharmaTheme.textSecondary,
              ),
            ),
            const SizedBox(height: PharmaTheme.spacingXs),
            Text(
              hasError
                  ? 'Please refresh and try again'
                  : 'Add this medicine to inventory using the button above',
              style: PharmaTheme.bodySmall.copyWith(
                color: PharmaTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasError) ...[
              const SizedBox(height: PharmaTheme.spacingM),
              Consumer(
                builder: (context, ref, _) {
                  return OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () {
                      ref.invalidate(inventoryProvider);
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        boxShadow: PharmaTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: PharmaTheme.accentGradient,
                  borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
                ),
                child: const Center(
                  child: Icon(
                    Icons.medication,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: PharmaTheme.spacingM),
              // Medicine details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: PharmaTheme.headingLarge,
                    ),
                    const SizedBox(height: PharmaTheme.spacingXxs),
                    Text(
                      'Manufactured by ${medicine.manufacturer}',
                      style: PharmaTheme.bodyMedium.copyWith(
                        color: PharmaTheme.textSecondary,
                      ),
                    ),
                    if (medicine.category != null &&
                        medicine.category!.isNotEmpty)
                      Text(
                        'Category: ${medicine.category}',
                        style: PharmaTheme.bodyMedium.copyWith(
                          color: PharmaTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    color: PharmaTheme.error,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),

          // Description section
          if (medicine.description != null &&
              medicine.description!.isNotEmpty) ...[
            const Divider(height: PharmaTheme.spacingL),
            Container(
              padding: const EdgeInsets.all(PharmaTheme.spacingM),
              decoration: BoxDecoration(
                color: PharmaTheme.background,
                borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
                border: Border.all(
                  color: PharmaTheme.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: PharmaTheme.headingSmall.copyWith(
                      color: PharmaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: PharmaTheme.spacingS),
                  Text(
                    medicine.description!,
                    style: PharmaTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: PharmaTheme.spacingM),

          // Financial details
          _buildFinancialDetailsSection(context),

          const SizedBox(height: PharmaTheme.spacingM),

          // Added on info
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: PharmaTheme.textSecondary,
              ),
              const SizedBox(width: PharmaTheme.spacingXxs),
              Text(
                'Added on ${DateFormat('dd MMM, yyyy').format(medicine.createdAt)}',
                style: PharmaTheme.bodySmall.copyWith(
                  color: PharmaTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialDetailsSection(BuildContext context) {
    // Use LayoutBuilder to check available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we should stack cards vertically
        final isNarrow = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(PharmaTheme.spacingM),
          decoration: BoxDecoration(
            color: PharmaTheme.background,
            borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
            border: Border.all(
              color: PharmaTheme.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pricing Information',
                style: PharmaTheme.headingSmall.copyWith(
                  color: PharmaTheme.textSecondary,
                ),
              ),
              const SizedBox(height: PharmaTheme.spacingM),
              isNarrow
                  ? _buildVerticalPriceCards()
                  : _buildHorizontalPriceCards(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalPriceCards() {
    final profit = medicine.mrp - medicine.purchasePrice;
    final profitPercentage = medicine.purchasePrice > 0
        ? ((profit / medicine.purchasePrice) * 100).toStringAsFixed(1)
        : 'N/A';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MRP Card
        Expanded(
          child: _buildPriceCard(
            title: 'MRP',
            amount: medicine.mrp,
            icon: Icons.local_offer,
            color: PharmaTheme.warning,
          ),
        ),
        const SizedBox(width: PharmaTheme.spacingM),
        // Purchase Price Card
        Expanded(
          child: _buildPriceCard(
            title: 'Purchase Price',
            amount: medicine.purchasePrice,
            icon: Icons.shopping_cart,
            color: PharmaTheme.success,
          ),
        ),
        const SizedBox(width: PharmaTheme.spacingM),
        // Profit Margin Card
        Expanded(
          child: _buildPriceCard(
            title: 'Profit Margin',
            amount: profit,
            percentage: profitPercentage,
            icon: Icons.trending_up,
            color: PharmaTheme.info,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalPriceCards() {
    final profit = medicine.mrp - medicine.purchasePrice;
    final profitPercentage = medicine.purchasePrice > 0
        ? ((profit / medicine.purchasePrice) * 100).toStringAsFixed(1)
        : 'N/A';

    return Column(
      children: [
        // MRP Card
        _buildPriceCard(
          title: 'MRP',
          amount: medicine.mrp,
          icon: Icons.local_offer,
          color: PharmaTheme.warning,
        ),
        const SizedBox(height: PharmaTheme.spacingM),
        // Purchase Price Card
        _buildPriceCard(
          title: 'Purchase Price',
          amount: medicine.purchasePrice,
          icon: Icons.shopping_cart,
          color: PharmaTheme.success,
        ),
        const SizedBox(height: PharmaTheme.spacingM),
        // Profit Margin Card
        _buildPriceCard(
          title: 'Profit Margin',
          amount: profit,
          percentage: profitPercentage,
          icon: Icons.trending_up,
          color: PharmaTheme.info,
        ),
      ],
    );
  }

  Widget _buildPriceCard({
    required String title,
    required double amount,
    String? percentage,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: PharmaTheme.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: PharmaTheme.bodySmall.copyWith(
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: PharmaTheme.spacingS),
          Row(
            children: [
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(width: PharmaTheme.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PharmaTheme.spacingXs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
                  ),
                  child: Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStats(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on available width
        final isNarrow = constraints.maxWidth < 600;

        final stats = [
          _InventoryStat(
            title: 'Total Stock',
            value: '0',
            icon: Icons.inventory,
            color: PharmaTheme.primary,
          ),
          _InventoryStat(
            title: 'Total Batches',
            value: '0',
            icon: Icons.layers,
            color: PharmaTheme.accent,
          ),
          _InventoryStat(
            title: 'Nearest Expiry',
            value: 'None',
            icon: Icons.event,
            color: PharmaTheme.warning,
          ),
        ];

        if (isNarrow) {
          // Vertical layout for narrow screens
          return Padding(
            padding: const EdgeInsets.all(PharmaTheme.spacingM),
            child: Column(
              children: stats.map((stat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: PharmaTheme.spacingM),
                  child: _buildCompactStatCard(
                    title: stat.title,
                    value: stat.value,
                    icon: stat.icon,
                    color: stat.color,
                  ),
                );
              }).toList(),
            ),
          );
        } else {
          // Horizontal layout for wider screens
          return Padding(
            padding: const EdgeInsets.all(PharmaTheme.spacingM),
            child: Row(
              children: stats.map((stat) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: stat != stats.last ? PharmaTheme.spacingM : 0,
                    ),
                    child: _buildCompactStatCard(
                      title: stat.title,
                      value: stat.value,
                      icon: stat.icon,
                      color: stat.color,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(PharmaTheme.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: PharmaTheme.spacingXs),
              Expanded(
                child: Text(
                  title,
                  style: PharmaTheme.bodySmall.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: PharmaTheme.spacingXs),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for inventory stats
class _InventoryStat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InventoryStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
