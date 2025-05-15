import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
class Medicine {
  final String id;
  final String name;
  final String manufacturer;
  final String category;
  final String? description; // Made optional
  final double mrp;
  final double purchasePrice;
  final DateTime? createdAt; // Made optional

  Medicine({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.category,
    this.description,
    required this.mrp,
    required this.purchasePrice,
    this.createdAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'],
      name: json['name'],
      manufacturer: json['manufacturer'],
      category: json['category'],
      description: json['description'],
      mrp: (json['mrp'] is int)
          ? json['mrp'].toDouble()
          : json['mrp']?.toDouble() ?? 0.0,
      purchasePrice: (json['purchasePrice'] is int)
          ? json['purchasePrice'].toDouble()
          : json['purchasePrice']?.toDouble() ?? 0.0,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class Distributor {
  final String id;
  final String name;
  final String contactNumber;
  final String email;
  final String? address; // Made optional
  final DateTime? createdAt; // Made optional

  Distributor({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.email,
    this.address,
    this.createdAt,
  });

  factory Distributor.fromJson(Map<String, dynamic> json) {
    return Distributor(
      id: json['_id'],
      name: json['name'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      address: json['address'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

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
      id: json['_id'],
      medicine: Medicine.fromJson(json['medicine']),
      batchNumber: json['batchNumber'],
      expiryDate: DateTime.parse(json['expiryDate']),
      quantity: json['quantity'],
      distributor: Distributor.fromJson(json['distributor']),
      addedOn: DateTime.parse(json['addedOn']),
    );
  }
}

class PaginatedResponse<T> {
  final bool success;
  final int count;
  final int totalPages;
  final int currentPage;
  final List<T> data;

  PaginatedResponse({
    required this.success,
    required this.count,
    required this.totalPages,
    required this.currentPage,
    required this.data,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PaginatedResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// API Service
class InventoryService {
  // Get all inventory items
  Future<PaginatedResponse<InventoryItem>> getInventory({int page = 1}) async {
    try {
      final response =
          await http.get(Uri.parse('$KVM_URL/pharma/getInventory?page=$page'));
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return PaginatedResponse.fromJson(
            responseData, (item) => InventoryItem.fromJson(item));
      } else {
        throw Exception('Failed to load inventory: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  // Search inventory items
  Future<List<InventoryItem>> searchInventory(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$KVM_URL/pharma/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];
        return data.map((item) => InventoryItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search inventory: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search inventory: $e');
    }
  }

  // Add to inventory
  Future<bool> addToInventory({
    required String medicineId,
    required String batchNumber,
    required DateTime expiryDate,
    required int quantity,
    required String distributorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$KVM_URL/pharma/addToInventory'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'medicineId': medicineId,
          'batchNumber': batchNumber,
          'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
          'quantity': quantity,
          'distributorId': distributorId,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to add to inventory: $e');
    }
  }

  // Update inventory item
  Future<bool> updateInventory({
    required String id,
    required int quantity,
    required DateTime expiryDate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$KVM_URL/pharma/updateInventory/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quantity': quantity,
          'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update inventory: $e');
    }
  }

  // Delete inventory item
  Future<bool> deleteInventory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$KVM_URL/pharma/deleteInventory/$id'),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to delete inventory: $e');
    }
  }

  // Get all medicines
  Future<List<Medicine>> getMedicines() async {
    try {
      final response =
          await http.get(Uri.parse('$KVM_URL/pharma/getMedicines'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];
        return data.map((item) => Medicine.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load medicines: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load medicines: $e');
    }
  }
}

// Filter Providers
final showLowStockOnlyProvider = StateProvider<bool>((ref) => false);
final showExpiringSoonOnlyProvider = StateProvider<bool>((ref) => false);
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final sortByProvider = StateProvider<String>((ref) => 'name');
final sortDirectionProvider =
    StateProvider<bool>((ref) => true); // true = ascending

// Providers
final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService();
});

final currentPageProvider = StateProvider<int>((ref) => 1);

final inventoryProvider =
    FutureProvider<PaginatedResponse<InventoryItem>>((ref) async {
  final inventoryService = ref.watch(inventoryServiceProvider);
  final currentPage = ref.watch(currentPageProvider);
  return await inventoryService.getInventory(page: currentPage);
});

final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  final inventoryService = ref.watch(inventoryServiceProvider);
  return await inventoryService.getMedicines();
});

final uniqueCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final inventoryResponse = await ref.watch(inventoryProvider.future);
  final Set<String> categories = {};

  for (var item in inventoryResponse.data) {
    categories.add(item.medicine.category);
  }

  return categories.toList()..sort();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredInventoryProvider =
    FutureProvider<List<InventoryItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final showLowStockOnly = ref.watch(showLowStockOnlyProvider);
  final showExpiringSoonOnly = ref.watch(showExpiringSoonOnlyProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final sortBy = ref.watch(sortByProvider);
  final sortAscending = ref.watch(sortDirectionProvider);

  final inventoryService = ref.watch(inventoryServiceProvider);

  List<InventoryItem> items;

  // First get the base items (either from search or all inventory)
  if (query.isEmpty) {
    final inventoryResponse = await ref.watch(inventoryProvider.future);
    items = inventoryResponse.data;
  } else {
    items = await inventoryService.searchInventory(query);
  }

  // Apply filters
  items = items.where((item) {
    // Apply low stock filter
    if (showLowStockOnly && item.quantity >= 10) {
      return false;
    }

    // Apply expiring soon filter
    if (showExpiringSoonOnly &&
        item.expiryDate.difference(DateTime.now()).inDays >= 90) {
      return false;
    }

    // Apply category filter
    if (selectedCategory != null &&
        selectedCategory.isNotEmpty &&
        item.medicine.category != selectedCategory) {
      return false;
    }

    return true;
  }).toList();

  // Apply sorting
  items.sort((a, b) {
    int comparison = 0;

    switch (sortBy) {
      case 'name':
        comparison = a.medicine.name.compareTo(b.medicine.name);
        break;
      case 'expiry':
        comparison = a.expiryDate.compareTo(b.expiryDate);
        break;
      case 'quantity':
        comparison = a.quantity.compareTo(b.quantity);
        break;
      case 'batch':
        comparison = a.batchNumber.compareTo(b.batchNumber);
        break;
      default:
        comparison = a.medicine.name.compareTo(b.medicine.name);
    }

    return sortAscending ? comparison : -comparison;
  });

  return items;
});

// Screen
class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isFiltersExpanded = false;

  @override
  void initState() {
    super.initState();

    // Add listener for search with debounce
    _searchController.addListener(_onSearchChanged);

    // Set up keyboard shortcuts
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  void _refreshInventory() {
    ref.invalidate(inventoryProvider);
    ref.invalidate(filteredInventoryProvider);
    ref.invalidate(uniqueCategoriesProvider);
  }

  void _goToPage(int page) {
    ref.read(currentPageProvider.notifier).state = page;
  }

  // Clear all filters
  void _clearFilters() {
    ref.read(showLowStockOnlyProvider.notifier).state = false;
    ref.read(showExpiringSoonOnlyProvider.notifier).state = false;
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(sortByProvider.notifier).state = 'name';
    ref.read(sortDirectionProvider.notifier).state = true;
  }

  // View details card instead of dialog
  Widget _buildDetailsCard(InventoryItem item) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(PharmaTheme.spacingM),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(PharmaTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item Details',
                    style: PharmaTheme.headingMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _closeDetailsCard(),
                ),
              ],
            ),
            Divider(color: PharmaTheme.border),
            const SizedBox(height: 8),

            // Medicine info
            Text(
              'Medicine Information',
              style: PharmaTheme.headingSmall,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Name', item.medicine.name),
            _buildInfoRow('Manufacturer', item.medicine.manufacturer),
            _buildInfoRow('Category', item.medicine.category),
            _buildInfoRow('MRP', '₹${item.medicine.mrp.toStringAsFixed(2)}'),
            _buildInfoRow('Purchase Price',
                '₹${item.medicine.purchasePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 16),

            // Inventory info
            Text(
              'Inventory Information',
              style: PharmaTheme.headingSmall,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Batch Number', item.batchNumber),
            _buildInfoRow('Quantity', item.quantity.toString()),
            _buildInfoRow('Expiry Date',
                DateFormat('yyyy-MM-dd').format(item.expiryDate)),
            _buildInfoRow(
                'Added On', DateFormat('yyyy-MM-dd').format(item.addedOn)),
            const SizedBox(height: 16),

            // Distributor info
            Text(
              'Distributor Information',
              style: PharmaTheme.headingSmall,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Name', item.distributor.name),
            _buildInfoRow('Contact', item.distributor.contactNumber),
            _buildInfoRow('Email', item.distributor.email),
            if (item.distributor.address != null)
              _buildInfoRow('Address', item.distributor.address!),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: () => _showDeleteConfirmation(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PharmaTheme.error,
                    side: BorderSide(color: PharmaTheme.error),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () => _showAddEditDialog(item: item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _closeDetailsCard() {
    ref.read(selectedItemProvider.notifier).state = null;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: PharmaTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: PharmaTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog({InventoryItem? item}) async {
    final medicinesData = await ref.read(medicinesProvider.future);

    if (!context.mounted) return;

    final Medicine? selectedMedicine = item?.medicine ??
        (medicinesData.isNotEmpty ? medicinesData.first : null);
    final TextEditingController batchController =
        TextEditingController(text: item?.batchNumber ?? '');
    final TextEditingController quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '');

    DateTime expiryDate =
        item?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
    String? medicineId = selectedMedicine?.id;
    String? distributorId = item?.distributor.id;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
            ),
            child: Container(
              width: 550, // Fixed width for better form layout
              padding: EdgeInsets.all(PharmaTheme.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    item == null ? 'Add Inventory Item' : 'Edit Inventory Item',
                    style: PharmaTheme.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item == null) ...[
                            const Text(
                              'Medicine:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: medicineId,
                              decoration: const InputDecoration(
                                hintText: 'Select Medicine',
                                filled: true,
                                prefixIcon: Icon(Icons.medication),
                              ),
                              items: medicinesData.map((medicine) {
                                return DropdownMenuItem<String>(
                                  value: medicine.id,
                                  child: Text(
                                    '${medicine.name} (${medicine.manufacturer})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  medicineId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              // Batch Number
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Batch Number:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: batchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter Batch Number',
                                        filled: true,
                                        prefixIcon: Icon(Icons.numbers),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Quantity
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quantity:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: 'Enter Quantity',
                                        filled: true,
                                        prefixIcon: Icon(Icons.inventory_2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Expiry Date
                          const Text(
                            'Expiry Date:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: expiryDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 3650)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: PharmaTheme.primary,
                                        onPrimary: PharmaTheme.textLight,
                                        surface: PharmaTheme.surface,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  expiryDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                hintText: 'Select Expiry Date',
                                filled: true,
                                prefixIcon: Icon(Icons.calendar_month),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(expiryDate),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          if (item == null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Distributor:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            // This would be filled with actual distributor data in a real app
                            DropdownButtonFormField<String>(
                              value: distributorId,
                              decoration: const InputDecoration(
                                hintText: 'Select Distributor',
                                filled: true,
                                prefixIcon: Icon(Icons.business),
                              ),
                              items: const [
                                DropdownMenuItem<String>(
                                  value: '6820ba61a79560ba9c6a14ea',
                                  child: Text('Serum'),
                                ),
                                DropdownMenuItem<String>(
                                  value: '68204d070b292f5b85b0eb44',
                                  child: Text('ABC Pharmaceuticals'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  distributorId = value;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: PharmaTheme.spacingM,
                            vertical: PharmaTheme.spacingS,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          // Validate inputs
                          if ((medicineId == null && item == null) ||
                              batchController.text.isEmpty ||
                              quantityController.text.isEmpty ||
                              (distributorId == null && item == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please fill all fields')),
                            );
                            return;
                          }

                          final int quantity =
                              int.tryParse(quantityController.text) ?? 0;
                          if (quantity <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Quantity must be greater than 0')),
                            );
                            return;
                          }

                          final service = ref.read(inventoryServiceProvider);
                          bool success;

                          if (item == null) {
                            // Add new inventory item
                            success = await service.addToInventory(
                              medicineId: medicineId!,
                              batchNumber: batchController.text,
                              expiryDate: expiryDate,
                              quantity: quantity,
                              distributorId: distributorId!,
                            );
                          } else {
                            // Update existing inventory item
                            success = await service.updateInventory(
                              id: item.id,
                              quantity: quantity,
                              expiryDate: expiryDate,
                            );
                          }

                          if (context.mounted) {
                            if (success) {
                              Navigator.of(context).pop();
                              _refreshInventory();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(item == null
                                      ? 'Inventory item added successfully'
                                      : 'Inventory item updated successfully'),
                                  backgroundColor: PharmaTheme.success,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(item == null
                                      ? 'Failed to add inventory item'
                                      : 'Failed to update inventory item'),
                                  backgroundColor: PharmaTheme.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmaTheme.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: PharmaTheme.spacingM,
                            vertical: PharmaTheme.spacingS,
                          ),
                        ),
                        child: Text(item == null ? 'Add' : 'Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(InventoryItem item) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: PharmaTheme.warning),
            const SizedBox(width: 8),
            const Text('Delete Inventory Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this item?',
              style: PharmaTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(PharmaTheme.spacingS),
              decoration: BoxDecoration(
                color: PharmaTheme.background,
                borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
                border: Border.all(color: PharmaTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medicine.name,
                    style: PharmaTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Batch: ${item.batchNumber} | Quantity: ${item.quantity}',
                    style: PharmaTheme.bodySmall,
                  ),
                  Text(
                    'Expiry: ${DateFormat('yyyy-MM-dd').format(item.expiryDate)}',
                    style: PharmaTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: PharmaTheme.bodySmall.copyWith(
                color: PharmaTheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: PharmaTheme.spacingM,
                vertical: PharmaTheme.spacingS,
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = ref.read(inventoryServiceProvider);
              final success = await service.deleteInventory(item.id);

              if (context.mounted) {
                Navigator.of(context).pop();
                _closeDetailsCard(); // Close details if open
                if (success) {
                  _refreshInventory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inventory item deleted successfully'),
                      backgroundColor: PharmaTheme.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete inventory item'),
                      backgroundColor: PharmaTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PharmaTheme.error,
              padding: EdgeInsets.symmetric(
                horizontal: PharmaTheme.spacingM,
                vertical: PharmaTheme.spacingS,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

// Enhanced keyboard shortcut handler
  bool _handleKeyPress(KeyEvent event) {
    // For search: Ctrl/Cmd+F
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyF &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      // Focus on search field
      FocusScope.of(context).requestFocus(FocusNode()..requestFocus());
      Future.delayed(const Duration(milliseconds: 50), () {
        FocusScope.of(context).requestFocus(FocusNode()..requestFocus());
        _searchController.selection = TextSelection(
            baseOffset: 0, extentOffset: _searchController.text.length);
      });
      return true;
    }

    // For adding new item: Ctrl/Cmd+N
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyN &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _showAddEditDialog();
      return true;
    }

    // For refreshing: F5 or Ctrl/Cmd+R
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.f5 ||
            (event.logicalKey == LogicalKeyboardKey.keyR &&
                (HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed)))) {
      _refreshInventory();
      return true;
    }

    // For clearing filters: Ctrl/Cmd+Shift+F
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyF &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) &&
        HardwareKeyboard.instance.isShiftPressed) {
      _clearFilters();
      return true;
    }

    // For toggling filters panel: Ctrl/Cmd+L
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyL &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      setState(() {
        _isFiltersExpanded = !_isFiltersExpanded;
      });
      return true;
    }

    // For navigating pages: Alt+Left/Right
    if (event is KeyDownEvent && HardwareKeyboard.instance.isAltPressed) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        final currentPage = ref.read(currentPageProvider);
        if (currentPage > 1) {
          _goToPage(currentPage - 1);
        }
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final currentPage = ref.read(currentPageProvider);
        final inventoryData = ref.read(inventoryProvider);
        if (inventoryData.value != null &&
            currentPage < inventoryData.value!.totalPages) {
          _goToPage(currentPage + 1);
        }
        return true;
      }
    }

    // For escaping from detail view: Escape key
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        ref.read(selectedItemProvider) != null) {
      _closeDetailsCard();
      return true;
    }

    return false;
  }

  // View details
  final selectedItemProvider = StateProvider<InventoryItem?>((ref) => null);

  void _viewItemDetails(InventoryItem item) {
    ref.read(selectedItemProvider.notifier).state = item;
  }

  // Build Filter UI
  Widget _buildFiltersSection() {
    final showLowStockOnly = ref.watch(showLowStockOnlyProvider);
    final showExpiringSoonOnly = ref.watch(showExpiringSoonOnlyProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final sortBy = ref.watch(sortByProvider);
    final sortAscending = ref.watch(sortDirectionProvider);
    final categories = ref.watch(uniqueCategoriesProvider);

    return Container(
      color: PharmaTheme.background,
      child: ExpansionTile(
        initiallyExpanded: _isFiltersExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isFiltersExpanded = expanded;
          });
        },
        title: Row(
          children: [
            const Icon(Icons.filter_list),
            const SizedBox(width: 8),
            const Text('Filters & Sorting'),
            const SizedBox(width: 16),
            if (showLowStockOnly ||
                showExpiringSoonOnly ||
                (selectedCategory != null && selectedCategory.isNotEmpty))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PharmaTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Filters Applied',
                  style: TextStyle(
                    color: PharmaTheme.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        textColor: PharmaTheme.primary,
        iconColor: PharmaTheme.primary,
        collapsedBackgroundColor: PharmaTheme.background,
        backgroundColor: PharmaTheme.background,
        children: [
          Padding(
            padding: EdgeInsets.all(PharmaTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock filters
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Filters',
                            style: PharmaTheme.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: PharmaTheme.spacingS,
                            runSpacing: PharmaTheme.spacingXs,
                            children: [
                              FilterChip(
                                label: const Text('Low Stock'),
                                selected: showLowStockOnly,
                                onSelected: (selected) {
                                  ref
                                      .read(showLowStockOnlyProvider.notifier)
                                      .state = selected;
                                },
                                backgroundColor: PharmaTheme.background,
                                selectedColor:
                                    PharmaTheme.primary.withOpacity(0.2),
                                checkmarkColor: PharmaTheme.primary,
                                labelStyle: TextStyle(
                                  color: showLowStockOnly
                                      ? PharmaTheme.primary
                                      : PharmaTheme.textPrimary,
                                ),
                              ),
                              FilterChip(
                                label: const Text('Expiring Soon'),
                                selected: showExpiringSoonOnly,
                                onSelected: (selected) {
                                  ref
                                      .read(
                                          showExpiringSoonOnlyProvider.notifier)
                                      .state = selected;
                                },
                                backgroundColor: PharmaTheme.background,
                                selectedColor:
                                    PharmaTheme.warning.withOpacity(0.2),
                                checkmarkColor: PharmaTheme.warning,
                                labelStyle: TextStyle(
                                  color: showExpiringSoonOnly
                                      ? PharmaTheme.warning
                                      : PharmaTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Category filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medicine Category',
                            style: PharmaTheme.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          categories.when(
                            data: (categoryList) {
                              if (categoryList.isEmpty) {
                                return const Text('No categories available');
                              }

                              return Wrap(
                                spacing: PharmaTheme.spacingS,
                                runSpacing: PharmaTheme.spacingXs,
                                children: [
                                  // All categories chip
                                  FilterChip(
                                    label: const Text('All Categories'),
                                    selected: selectedCategory == null ||
                                        selectedCategory.isEmpty,
                                    onSelected: (selected) {
                                      if (selected) {
                                        ref
                                            .read(selectedCategoryProvider
                                                .notifier)
                                            .state = null;
                                      }
                                    },
                                    backgroundColor: PharmaTheme.background,
                                    selectedColor:
                                        PharmaTheme.accent.withOpacity(0.2),
                                    checkmarkColor: PharmaTheme.accent,
                                    labelStyle: TextStyle(
                                      color: selectedCategory == null ||
                                              selectedCategory.isEmpty
                                          ? PharmaTheme.accent
                                          : PharmaTheme.textPrimary,
                                    ),
                                  ),
                                  ...categoryList
                                      .map((category) => FilterChip(
                                            label: Text(category),
                                            selected:
                                                selectedCategory == category,
                                            onSelected: (selected) {
                                              ref
                                                      .read(
                                                          selectedCategoryProvider
                                                              .notifier)
                                                      .state =
                                                  selected ? category : null;
                                            },
                                            backgroundColor:
                                                PharmaTheme.background,
                                            selectedColor: PharmaTheme
                                                .primaryLight
                                                .withOpacity(0.2),
                                            checkmarkColor:
                                                PharmaTheme.primaryLight,
                                            labelStyle: TextStyle(
                                              color:
                                                  selectedCategory == category
                                                      ? PharmaTheme.primary
                                                      : PharmaTheme.textPrimary,
                                            ),
                                          ))
                                      .toList(),
                                ],
                              );
                            },
                            loading: () => const CircularProgressIndicator(
                              color: PharmaTheme.primary,
                              strokeWidth: 2,
                            ),
                            error: (_, __) =>
                                const Text('Could not load categories'),
                          ),
                        ],
                      ),
                    ),

                    // Sorting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sort By',
                            style: PharmaTheme.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              DropdownButton<String>(
                                value: sortBy,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Text('Name'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'quantity',
                                    child: Text('Quantity'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'expiry',
                                    child: Text('Expiry Date'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'batch',
                                    child: Text('Batch Number'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    ref.read(sortByProvider.notifier).state =
                                        value;
                                  }
                                },
                                underline: Container(
                                  height: 1,
                                  color: PharmaTheme.primary,
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: PharmaTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(
                                  sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: PharmaTheme.primary,
                                ),
                                onPressed: () {
                                  ref
                                      .read(sortDirectionProvider.notifier)
                                      .state = !sortAscending;
                                },
                                tooltip:
                                    sortAscending ? 'Ascending' : 'Descending',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Action row for filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All Filters'),
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PharmaTheme.primary,
                        side: BorderSide(color: PharmaTheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = PharmaTheme.isMobile(context);
    final isTablet = PharmaTheme.isTablet(context);
    final filteredInventory = ref.watch(filteredInventoryProvider);
    final inventoryData = ref.watch(inventoryProvider);
    final selectedItem = ref.watch(selectedItemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: PharmaTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Keyboard Shortcuts',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Inventory',
            onPressed: _refreshInventory,
          ),
        ],
      ),
      body: Row(
        children: [
          // Main Inventory List
          Expanded(
            flex: selectedItem != null && !isMobile ? 2 : 3,
            child: Column(
              children: [
                // Search and Add Row
                Container(
                  padding: PharmaTheme.responsivePadding(context),
                  decoration: BoxDecoration(
                    color: PharmaTheme.surface,
                    boxShadow: PharmaTheme.shadowSmall,
                  ),
                  child: Row(
                    children: [
                      // Search Box
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search medicines or batch numbers...',
                            fillColor: PharmaTheme.background,
                            filled: true,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(PharmaTheme.radiusM),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(searchQueryProvider.notifier)
                                          .state = '';
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add Button
                      ElevatedButton.icon(
                        onPressed: _showAddEditDialog,
                        icon: const Icon(Icons.add),
                        label: Text(isMobile ? '' : 'Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmaTheme.accent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile
                                ? PharmaTheme.spacingS
                                : PharmaTheme.spacingM,
                            vertical: PharmaTheme.spacingS,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Filters section
                _buildFiltersSection(),

                // Table Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        PharmaTheme.responsivePadding(context).horizontal,
                    vertical: PharmaTheme.spacingS,
                  ),
                  color: PharmaTheme.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildColumnHeader(
                            'Medicine Name', Icons.medication),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildColumnHeader('Batch', Icons.numbers),
                      ),
                      Expanded(
                        flex: 1,
                        child:
                            _buildColumnHeader('Quantity', Icons.inventory_2),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildColumnHeader(
                            'Expiry Date', Icons.calendar_today),
                      ),
                      SizedBox(
                        width: 100,
                        child: _buildColumnHeader('Actions', Icons.settings),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Inventory List
                Expanded(
                  child: filteredInventory.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: PharmaTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No inventory items found',
                                style: PharmaTheme.headingMedium.copyWith(
                                  color: PharmaTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isNotEmpty ||
                                        ref.read(showLowStockOnlyProvider) ||
                                        ref.read(
                                            showExpiringSoonOnlyProvider) ||
                                        (ref.read(selectedCategoryProvider) !=
                                                null &&
                                            ref
                                                .read(selectedCategoryProvider)!
                                                .isNotEmpty)
                                    ? 'Try adjusting your filters or search term'
                                    : 'Add items to start managing your inventory',
                                style: PharmaTheme.bodyMedium.copyWith(
                                  color: PharmaTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_searchController.text.isNotEmpty ||
                                  ref.read(showLowStockOnlyProvider) ||
                                  ref.read(showExpiringSoonOnlyProvider) ||
                                  (ref.read(selectedCategoryProvider) != null &&
                                      ref
                                          .read(selectedCategoryProvider)!
                                          .isNotEmpty))
                                OutlinedButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.filter_alt_off),
                                  label: const Text('Clear Filters'),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _showAddEditDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PharmaTheme.accent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          _refreshInventory();
                        },
                        color: PharmaTheme.primary,
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isExpiringSoon = item.expiryDate
                                    .difference(DateTime.now())
                                    .inDays <
                                90;
                            final isLowStock = item.quantity < 10;
                            final isSelected = selectedItem?.id == item.id;

                            return Container(
                              color: isSelected
                                  ? PharmaTheme.primary
                                      .withOpacity(PharmaTheme.selectedOpacity)
                                  : index % 2 == 0
                                      ? Colors.white
                                      : PharmaTheme.background,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _viewItemDetails(item),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          PharmaTheme.responsivePadding(context)
                                              .horizontal,
                                      vertical: PharmaTheme.spacingS,
                                    ),
                                    child: Row(
                                      children: [
                                        // Medicine Name + Manufacturer
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.medicine.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              if (!isMobile)
                                                Text(
                                                  item.medicine.manufacturer,
                                                  style: PharmaTheme.caption,
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Batch Number
                                        Expanded(
                                          flex: 1,
                                          child: Text(item.batchNumber),
                                        ),
                                        // Quantity
                                        Expanded(
                                          flex: 1,
                                          child: Row(
                                            children: [
                                              if (isLowStock)
                                                const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: PharmaTheme.warning,
                                                  size: 16,
                                                ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.quantity.toString(),
                                                style: isLowStock
                                                    ? const TextStyle(
                                                        color:
                                                            PharmaTheme.warning,
                                                        fontWeight:
                                                            FontWeight.bold)
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Expiry Date
                                        Expanded(
                                          flex: 1,
                                          child: Row(
                                            children: [
                                              if (isExpiringSoon)
                                                const Icon(
                                                  Icons.access_time,
                                                  color: PharmaTheme.error,
                                                  size: 16,
                                                ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('yyyy-MM-dd')
                                                    .format(item.expiryDate),
                                                style: isExpiringSoon
                                                    ? const TextStyle(
                                                        color:
                                                            PharmaTheme.error,
                                                        fontWeight:
                                                            FontWeight.bold)
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Actions
                                        SizedBox(
                                          width: 100,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 20),
                                                color: PharmaTheme.primary,
                                                tooltip: 'Edit',
                                                onPressed: () =>
                                                    _showAddEditDialog(
                                                        item: item),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 20),
                                                color: PharmaTheme.error,
                                                tooltip: 'Delete',
                                                onPressed: () =>
                                                    _showDeleteConfirmation(
                                                        item),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: PharmaTheme.primary,
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: PharmaTheme.error),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading inventory',
                            style: PharmaTheme.headingMedium.copyWith(
                              color: PharmaTheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: PharmaTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refreshInventory,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PharmaTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pagination and Summary Footer
                Container(
                  padding: EdgeInsets.all(PharmaTheme.spacingM),
                  decoration: BoxDecoration(
                    color: PharmaTheme.background,
                    boxShadow: PharmaTheme.shadowSmall,
                  ),
                  child: Row(
                    children: [
                      // Pagination
                      Consumer(
                        builder: (context, ref, child) {
                          final inventoryData = ref.watch(inventoryProvider);
                          final currentPage = ref.watch(currentPageProvider);

                          return inventoryData.when(
                            data: (response) {
                              if (response.totalPages <= 1) {
                                return const SizedBox();
                              }

                              return Card(
                                elevation: 0,
                                color: PharmaTheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      PharmaTheme.radiusM),
                                  side: BorderSide(color: PharmaTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: currentPage > 1
                                          ? () => _goToPage(currentPage - 1)
                                          : null,
                                      tooltip: 'Previous Page',
                                      color: PharmaTheme.primary,
                                      disabledColor: PharmaTheme.textSecondary
                                          .withOpacity(0.5),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: PharmaTheme.spacingS,
                                      ),
                                      child: Text(
                                        'Page $currentPage of ${response.totalPages}',
                                        style: PharmaTheme.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      onPressed:
                                          currentPage < response.totalPages
                                              ? () => _goToPage(currentPage + 1)
                                              : null,
                                      tooltip: 'Next Page',
                                      color: PharmaTheme.primary,
                                      disabledColor: PharmaTheme.textSecondary
                                          .withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          );
                        },
                      ),
                      const Spacer(),
                      // Summary
                      Consumer(
                        builder: (context, ref, child) {
                          final inventory = ref.watch(inventoryProvider);
                          final filteredItems =
                              ref.watch(filteredInventoryProvider);

                          return inventory.when(
                            data: (response) => Row(
                              children: [
                                // Filter info
                                if (ref.read(showLowStockOnlyProvider) ||
                                    ref.read(showExpiringSoonOnlyProvider) ||
                                    (ref.read(selectedCategoryProvider) !=
                                            null &&
                                        ref
                                            .read(selectedCategoryProvider)!
                                            .isNotEmpty))
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: PharmaTheme.spacingS,
                                      vertical: PharmaTheme.spacingXxs,
                                    ),
                                    margin: EdgeInsets.only(
                                        right: PharmaTheme.spacingM),
                                    decoration: BoxDecoration(
                                      color:
                                          PharmaTheme.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          PharmaTheme.radiusS),
                                      border: Border.all(
                                          color: PharmaTheme.accent
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.filter_alt,
                                          size: 14,
                                          color: PharmaTheme.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          filteredItems.asData?.value.length ==
                                                  0
                                              ? 'No matches'
                                              : 'Showing ${filteredItems.asData?.value.length} of ${response.count}',
                                          style: PharmaTheme.bodySmall.copyWith(
                                            color: PharmaTheme.accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Total info
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: PharmaTheme.spacingM,
                                    vertical: PharmaTheme.spacingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PharmaTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        PharmaTheme.radiusM),
                                  ),
                                  child: Text(
                                    'Total Items: ${response.count} | Items on Page: ${filteredItems.asData?.value.length ?? 0}',
                                    style: PharmaTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: PharmaTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Panel (only shown on tablet/desktop when item is selected)
          if (selectedItem != null && !isMobile)
            Expanded(
              flex: 1,
              child: _buildDetailsCard(selectedItem),
            ),
        ],
      ),
      // Mobile-only bottom sheet for item details
      bottomSheet: isMobile && selectedItem != null
          ? BottomSheet(
              onClosing: _closeDetailsCard,
              builder: (context) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: PharmaTheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: PharmaTheme.shadowLarge,
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PharmaTheme.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: _buildDetailsCard(selectedItem),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
      floatingActionButton: screenWidth < 600 && selectedItem == null
          ? FloatingActionButton(
              onPressed: _showAddEditDialog,
              backgroundColor: PharmaTheme.accent,
              tooltip: 'Add Inventory Item',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildColumnHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: PharmaTheme.primary),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: PharmaTheme.primary,
          ),
        ),
      ],
    );
  }
}
