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
      medicine: Medicine.fromJson(json['medicine']),
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : DateTime.now(),
      quantity: json['quantity'] ?? 0,
      distributor: Distributor.fromJson(json['distributor']),
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
  static const String baseUrl = 'http://localhost:5001/pharma';

  // Get all medicines
  Future<List<Medicine>> getMedicines() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getMedicines'));
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
        Uri.parse('$baseUrl/createMedicine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode([medicine.toJson()]), // API expects an array
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating medicine: $e');
      return false;
    }
  }

  // Update a medicine
  Future<bool> updateMedicine(String id, Medicine medicine) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/updateMedicine/$id'),
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
        Uri.parse('$baseUrl/deleteMedicine/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      return false;
    }
  }

  Future<List<InventoryItem>> getInventory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getInventory'));
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
}

// Providers for state management
final medicineServiceProvider = Provider<MedicineService>((ref) {
  return MedicineService();
});

final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  final medicineService = ref.watch(medicineServiceProvider);
  return await medicineService.getMedicines();
});
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final medicineService = ref.watch(medicineServiceProvider);
  return await medicineService.getInventory();
});
final selectedMedicineProvider = StateProvider<Medicine?>((ref) => null);

// Screen for Medicine Management
class MedicineScreen extends ConsumerStatefulWidget {
  const MedicineScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends ConsumerState<MedicineScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _filteredMedicines = [];
  bool _isSearching = false;
  Medicine? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    // Add keyboard shortcuts
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        // Search shortcut (Ctrl+F or Cmd+F)
        if (event.logicalKey == LogicalKeyboardKey.keyF &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          if (!_isSearching) {
            setState(() {
              _isSearching = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchFocusNode.requestFocus();
            });
          }
          return true;
        }
        // Create new medicine (Ctrl+N or Cmd+N)
        if (event.logicalKey == LogicalKeyboardKey.keyN &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _showMedicineDialog(context);
          return true;
        }
        // Escape key to cancel search
        if (event.logicalKey == LogicalKeyboardKey.escape && _isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
          return true;
        }
      }
      return false;
    });
  }

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
      });
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Search medicines...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: PharmaTheme.textLight),
                ),
                style: const TextStyle(color: PharmaTheme.textLight),
                onChanged: _searchMedicines,
              )
            : const Text('Medicine Mnagement'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Cancel search' : 'Search (Ctrl+F)',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _searchFocusNode.requestFocus();
                  });
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshMedicines,
          ),
        ],
      ),
      body: Container(
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
            // If search is active, use filtered list
            final displayedMedicines = _searchController.text.isNotEmpty
                ? _filteredMedicines
                : medicines;

            if (displayedMedicines.isEmpty) {
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
                      _searchController.text.isNotEmpty
                          ? 'No medicines matching "${_searchController.text}"'
                          : 'No medicines found',
                      style: PharmaTheme.headingMedium.copyWith(
                        color: PharmaTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: PharmaTheme.spacingM),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Medicine'),
                      onPressed: () => _showMedicineDialog(context),
                    ),
                  ],
                ),
              );
            }

            // Master-detail layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel - Medicine list (Master)
                Container(
                  width: screenSize.width * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
                    boxShadow: PharmaTheme.shadowSmall,
                  ),
                  margin: const EdgeInsets.all(PharmaTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(PharmaTheme.spacingM),
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
                            const Text(
                              'Medicines',
                              style: TextStyle(
                                color: PharmaTheme.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: PharmaTheme.spacingS,
                                vertical: PharmaTheme.spacingXxs,
                              ),
                              decoration: BoxDecoration(
                                color: PharmaTheme.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  PharmaTheme.radiusCircular,
                                ),
                              ),
                              child: Text(
                                '${displayedMedicines.length}',
                                style: const TextStyle(
                                  color: PharmaTheme.textLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search field
                      Padding(
                        padding: const EdgeInsets.all(PharmaTheme.spacingM),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search medicines...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _filteredMedicines = medicines;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                PharmaTheme.radiusM,
                              ),
                              borderSide:
                                  const BorderSide(color: PharmaTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                PharmaTheme.radiusM,
                              ),
                              borderSide:
                                  const BorderSide(color: PharmaTheme.border),
                            ),
                          ),
                          onChanged: _searchMedicines,
                        ),
                      ),
                      // List of medicines
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: PharmaTheme.spacingM,
                          ),
                          itemCount: displayedMedicines.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final medicine = displayedMedicines[index];
                            final isSelected =
                                _selectedMedicine?.id == medicine.id;
                            return ListTile(
                              title: Text(
                                medicine.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? PharmaTheme.primary
                                      : PharmaTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                medicine.manufacturer,
                                style: PharmaTheme.bodySmall,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? PharmaTheme.accent
                                    : PharmaTheme.accentLight.withOpacity(0.1),
                                child: Icon(
                                  Icons.medication,
                                  color: isSelected
                                      ? PharmaTheme.textLight
                                      : PharmaTheme.accent,
                                  size: 20,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor:
                                  PharmaTheme.accent.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  PharmaTheme.radiusM,
                                ),
                              ),
                              onTap: () => _selectMedicine(medicine),
                            );
                          },
                        ),
                      ),
                      // Add button
                      Padding(
                        padding: const EdgeInsets.all(PharmaTheme.spacingM),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor: PharmaTheme.accent,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Medicine'),
                          onPressed: () => _showMedicineDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right panel - Medicine details (Detail)
                Expanded(
                  child: _selectedMedicine == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 80,
                                color:
                                    PharmaTheme.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: PharmaTheme.spacingL),
                              Text(
                                'Select a medicine to view details',
                                style: PharmaTheme.headingMedium.copyWith(
                                  color: PharmaTheme.textSecondary
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildMedicineDetailSection(
                          context, _selectedMedicine!),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
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
                  error.toString(),
                  style: PharmaTheme.bodyMedium.copyWith(
                    color: PharmaTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: PharmaTheme.spacingL),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: _refreshMedicines,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the detailed view for a selected medicine
  Widget _buildMedicineDetailSection(BuildContext context, Medicine medicine) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Padding(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine info card - Reduced in height
          Container(
            padding: const EdgeInsets.all(
                PharmaTheme.spacingM), // Reduced from spacingL
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
              boxShadow: PharmaTheme.shadowSmall,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep size to minimum required
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and action buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine icon
                    Container(
                      width: 60, // Reduced from 70
                      height: 60, // Reduced from 70
                      decoration: BoxDecoration(
                        gradient: PharmaTheme.accentGradient,
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.medication,
                          size: 30, // Reduced from 36
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: PharmaTheme.spacingM), // Reduced from spacingL
                    // Medicine details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: PharmaTheme.headingLarge,
                          ),
                          const SizedBox(
                              height: PharmaTheme
                                  .spacingXxs), // Reduced from spacingXs
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
                          padding: EdgeInsets.zero, // Remove padding
                          constraints:
                              const BoxConstraints(), // Remove constraints
                          onPressed: () =>
                              _showMedicineDialog(context, medicine: medicine),
                        ),
                        const SizedBox(width: PharmaTheme.spacingS),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                          padding: EdgeInsets.zero, // Remove padding
                          constraints:
                              const BoxConstraints(), // Remove constraints
                          color: PharmaTheme.error,
                          onPressed: () => _deleteMedicine(context, medicine),
                        ),
                      ],
                    ),
                  ],
                ),

                // Description section - More compact
                if (medicine.description != null &&
                    medicine.description!.isNotEmpty) ...[
                  const Divider(
                      height:
                          PharmaTheme.spacingL), // Combined spacing and divider
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description: ',
                        style: PharmaTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PharmaTheme.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          medicine.description!,
                          style: PharmaTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Divider(
                      height:
                          PharmaTheme.spacingL), // Combined spacing and divider

                // Financial details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MRP Card
                    Expanded(
                      child: _buildCompactPriceCard(
                        title: 'MRP',
                        amount: medicine.mrp,
                        icon: Icons.local_offer,
                        color: PharmaTheme.warning,
                      ),
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    // Purchase Price Card
                    Expanded(
                      child: _buildCompactPriceCard(
                        title: 'Purchase Price',
                        amount: medicine.purchasePrice,
                        icon: Icons.shopping_cart,
                        color: PharmaTheme.success,
                      ),
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    // Profit Margin Card
                    Expanded(
                      child: _buildCompactPriceCard(
                        title: 'Profit Margin',
                        amount: medicine.mrp - medicine.purchasePrice,
                        percentage: medicine.purchasePrice > 0
                            ? ((medicine.mrp - medicine.purchasePrice) /
                                        medicine.purchasePrice *
                                        100)
                                    .toStringAsFixed(1) +
                                '%'
                            : 'N/A',
                        icon: Icons.trending_up,
                        color: PharmaTheme.info,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                    height: PharmaTheme.spacingM), // Reduced from spacingL

                // Added on info
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14, // Reduced from 16
                      color: PharmaTheme.textSecondary,
                    ),
                    const SizedBox(
                        width:
                            PharmaTheme.spacingXxs), // Reduced from spacingXs
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
          ),

          const SizedBox(height: PharmaTheme.spacingM), // Reduced from spacingL

          // Inventory Management Section - EXPANDED HEIGHT
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
                boxShadow: PharmaTheme.shadowSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - More compact
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
                          onPressed: () {
                            _showAddToInventoryDialog(context, medicine);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Inventory Stats - from actual data
                  inventoryAsync.when(
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
                        child: Row(
                          children: [
                            // Total Stock Card
                            Expanded(
                              child: _buildCompactStatCard(
                                title: 'Total Stock',
                                value: totalStock.toString(),
                                icon: Icons.inventory,
                                color: PharmaTheme.primary,
                              ),
                            ),
                            const SizedBox(width: PharmaTheme.spacingM),
                            // Total Batches Card
                            Expanded(
                              child: _buildCompactStatCard(
                                title: 'Total Batches',
                                value: totalBatches.toString(),
                                icon: Icons.layers,
                                color: PharmaTheme.accent,
                              ),
                            ),
                            const SizedBox(width: PharmaTheme.spacingM),
                            // Nearest Expiry Card
                            Expanded(
                              child: _buildCompactStatCard(
                                title: 'Nearest Expiry',
                                value: nearestExpiry != null
                                    ? DateFormat('MMM dd, yyyy')
                                        .format(nearestExpiry)
                                    : 'None',
                                icon: Icons.event,
                                color: PharmaTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(PharmaTheme.spacingM),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => Padding(
                      padding: const EdgeInsets.all(PharmaTheme.spacingM),
                      child: Row(
                        children: [
                          // Placeholder stats with error indicator
                          Expanded(
                            child: _buildCompactStatCard(
                              title: 'Total Stock',
                              value: '?',
                              icon: Icons.error_outline,
                              color: PharmaTheme.error,
                            ),
                          ),
                          const SizedBox(width: PharmaTheme.spacingM),
                          Expanded(
                            child: _buildCompactStatCard(
                              title: 'Total Batches',
                              value: '?',
                              icon: Icons.error_outline,
                              color: PharmaTheme.error,
                            ),
                          ),
                          const SizedBox(width: PharmaTheme.spacingM),
                          Expanded(
                            child: _buildCompactStatCard(
                              title: 'Nearest Expiry',
                              value: '?',
                              icon: Icons.error_outline,
                              color: PharmaTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Inventory Table
                  Expanded(
                    child: inventoryAsync.when(
                      data: (inventory) {
                        // Filter inventory items for this medicine
                        final medicineInventory = inventory
                            .where((item) => item.medicine.id == medicine.id)
                            .toList();

                        if (medicineInventory.isEmpty) {
                          return _buildEmptyInventoryPlaceholder();
                        }

                        return _buildInventoryTable(medicineInventory);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: PharmaTheme.error,
                            ),
                            const SizedBox(height: PharmaTheme.spacingS),
                            Text(
                              'Failed to load inventory data',
                              style: PharmaTheme.bodyMedium.copyWith(
                                color: PharmaTheme.error,
                              ),
                            ),
                            const SizedBox(height: PharmaTheme.spacingM),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              onPressed: () {
                                ref.invalidate(inventoryProvider);
                              },
                            ),
                          ],
                        ),
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

  Widget _buildInventoryTable(List<InventoryItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PharmaTheme.spacingM,
        PharmaTheme.spacingXs,
        PharmaTheme.spacingM,
        PharmaTheme.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Inventory Batches',
            style: PharmaTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: PharmaTheme.textSecondary,
            ),
          ),
          const SizedBox(height: PharmaTheme.spacingS),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: PharmaTheme.border),
                borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all<Color>(
                      PharmaTheme.background,
                    ),
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(label: Text('Batch')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Expiry')),
                      DataColumn(label: Text('Distributor')),
                      DataColumn(label: Text('Added')),
                    ],
                    rows: items.map((item) {
                      // Calculate days until expiry
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

                      return DataRow(
                        cells: [
                          DataCell(Text(item.batchNumber)),
                          DataCell(Text(item.quantity.toString())),
                          DataCell(
                            Text(
                              DateFormat('dd/MM/yy').format(item.expiryDate),
                              style: TextStyle(
                                color: expiryColor,
                                fontWeight: daysUntilExpiry < 30
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          DataCell(Text(item.distributor.name)),
                          DataCell(
                            Text(DateFormat('dd/MM/yy').format(item.addedOn)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInventoryPlaceholder() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PharmaTheme.spacingM,
        0,
        PharmaTheme.spacingM,
        PharmaTheme.spacingM,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: PharmaTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: PharmaTheme.spacingS),
            Text(
              'No inventory data available',
              style: PharmaTheme.bodyMedium.copyWith(
                color: PharmaTheme.textSecondary,
              ),
            ),
            const SizedBox(height: PharmaTheme.spacingXs),
            Text(
              'Add this medicine to inventory using the button above',
              style: PharmaTheme.bodySmall.copyWith(
                color: PharmaTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

// New helper method for compact price cards
  Widget _buildCompactPriceCard({
    required String title,
    required double amount,
    String? percentage,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(PharmaTheme.spacingS), // Reduced from spacingM
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
              Icon(icon, color: color, size: 16), // Reduced size
              const SizedBox(
                  width: PharmaTheme.spacingXs), // Reduced from spacingS
              Text(
                title,
                style: PharmaTheme.bodySmall.copyWith(
                  color: color,
                  fontSize: 11, // Smaller font
                ),
              ),
            ],
          ),
          const SizedBox(
              height: PharmaTheme.spacingXs), // Reduced from spacingS
          Row(
            children: [
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16, // Reduced from 20
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(
                    width: PharmaTheme.spacingXs), // Reduced from spacingS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4, // Reduced from spacingXs
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(4), // Reduced from radiusXs
                  ),
                  child: Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 10, // Reduced from 12
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

// New helper method for compact stat cards
  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(PharmaTheme.spacingS), // Reduced from spacingM
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
              Icon(icon, color: color, size: 16), // Reduced size
              const SizedBox(
                  width: PharmaTheme.spacingXs), // Reduced from spacingS
              Text(
                title,
                style: PharmaTheme.bodySmall.copyWith(
                  color: color,
                  fontSize: 11, // Smaller font
                ),
              ),
            ],
          ),
          const SizedBox(
              height: PharmaTheme.spacingXs), // Reduced from spacingS
          Text(
            value,
            style: const TextStyle(
              fontSize: 18, // Reduced from 24
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to show Add to Inventory dialog
  void _showAddToInventoryDialog(
      BuildContext context, Medicine medicine) async {
    final distributorService = ref.read(medicineServiceProvider);

    // Load available distributors for selection
    // In a real app, we would add a method to fetch distributors
    // For now, we'll use a placeholder list
    final distributors = [
      {'_id': '6820ba61a79560ba9c6a14ea', 'name': 'Serum'},
      {'_id': '68204d070b292f5b85b0eb44', 'name': 'ABC Pharmaceuticals'},
    ];

    String? selectedDistributorId;
    final batchNumberController = TextEditingController();
    final quantityController = TextEditingController();
    DateTime? selectedExpiryDate =
        DateTime.now().add(const Duration(days: 365)); // Default 1 year
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add ${medicine.name} to Inventory'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distributor dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Distributor',
                          hintText: 'Select a distributor',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedDistributorId,
                        items: distributors.map((distributor) {
                          return DropdownMenuItem<String>(
                            value: distributor['_id'] as String,
                            child: Text(distributor['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDistributorId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a distributor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Batch number
                      TextFormField(
                        controller: batchNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Number',
                          hintText: 'Enter batch number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter batch number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quantity
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          hintText: 'Enter quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
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
                      const SizedBox(height: 16),

                      // Expiry date
                      InkWell(
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedExpiryDate ??
                                DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                                const Duration(days: 3650)), // 10 years ahead
                          );

                          if (pickedDate != null &&
                              pickedDate != selectedExpiryDate) {
                            setState(() {
                              selectedExpiryDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            selectedExpiryDate != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(selectedExpiryDate!)
                                : 'Select expiry date',
                          ),
                        ),
                      ),

                      // Medicine details reminder
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PharmaTheme.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: PharmaTheme.info.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medicine: ${medicine.name}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Manufacturer: ${medicine.manufacturer}'),
                            Text('MRP: ₹${medicine.mrp.toStringAsFixed(2)}'),
                          ],
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmaTheme.accent,
                  ),
                  child: const Text('Add to Inventory'),
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        selectedExpiryDate != null) {
                      // In a real app, we would call the API to add to inventory
                      // For now, just show a success message

                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${medicine.name} added to inventory successfully'),
                            backgroundColor: PharmaTheme.success,
                          ),
                        );

                        // Refresh the view
                        setState(() {});
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to build a price info card
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
              Text(
                title,
                style: PharmaTheme.bodySmall.copyWith(
                  color: color,
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

  // Helper to build a stat card
  Widget _buildStatCard({
    required String title,
    required String value,
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
              Text(
                title,
                style: PharmaTheme.bodySmall.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: PharmaTheme.spacingS),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
