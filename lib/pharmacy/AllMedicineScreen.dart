import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/AddMedicinesScreen.dart';
import 'package:doctordesktop/pharmacy/getInventoryModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

// Enhanced Models with better error handling
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
      id: json['_id']?.toString() ?? '',
      medicine: Medicine.fromJson(json['medicine'] ?? {}),
      batchNumber: json['batchNumber']?.toString() ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : DateTime.now(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      distributor: Distributor.fromJson(json['distributor'] ?? {}),
      addedOn: json['addedOn'] != null
          ? DateTime.parse(json['addedOn'])
          : DateTime.now(),
    );
  }
}

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
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      mrp: _parseDouble(json['mrp']),
      purchasePrice: _parseDouble(json['purchasePrice']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
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

// Enhanced API Response Models
class BulkCreateResponse {
  final bool success;
  final String message;
  final List<Medicine> created;
  final List<Map<String, dynamic>> duplicates;
  final List<Map<String, dynamic>> errors;

  BulkCreateResponse({
    required this.success,
    required this.message,
    required this.created,
    required this.duplicates,
    required this.errors,
  });

  factory BulkCreateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return BulkCreateResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      created: (data['created'] as List? ?? [])
          .map((item) => Medicine.fromJson(item))
          .toList(),
      duplicates: List<Map<String, dynamic>>.from(data['duplicates'] ?? []),
      errors: List<Map<String, dynamic>>.from(data['errors'] ?? []),
    );
  }
}

// Enhanced Medicine Service with better error handling
class MedicineService {
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
      throw Exception('Failed to fetch medicines: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error fetching medicines: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<BulkCreateResponse> createMedicines(List<Medicine> medicines) async {
    try {
      final jsonList = medicines.map((medicine) => medicine.toJson()).toList();

      final response = await http.post(
        Uri.parse('$KVM_URL/pharma/createMedicine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonList),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BulkCreateResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating medicines: $e');
      throw Exception('Failed to create medicines: $e');
    }
  }

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

  Future<List<InventoryItem>> getInventory() async {
    try {
      final response =
          await http.get(Uri.parse('$KVM_URL/pharma/getInventory'));
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

// Enhanced Providers
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

// Search and Filter Provider
final medicineSearchProvider = StateProvider<String>((ref) => '');
final medicineSortProvider = StateProvider<MedicineSort>(
    (ref) => const MedicineSort(column: 'name', ascending: true));

class MedicineSort {
  final String column;
  final bool ascending;

  const MedicineSort({required this.column, required this.ascending});

  MedicineSort copyWith({String? column, bool? ascending}) {
    return MedicineSort(
      column: column ?? this.column,
      ascending: ascending ?? this.ascending,
    );
  }
}

// Filtered Medicines Provider
final filteredMedicinesProvider = Provider<List<Medicine>>((ref) {
  final medicines = ref.watch(medicinesProvider).asData?.value ?? [];
  final searchQuery = ref.watch(medicineSearchProvider);
  final sort = ref.watch(medicineSortProvider);

  var filtered = medicines;

  // Apply search filter
  if (searchQuery.isNotEmpty) {
    final lowercaseQuery = searchQuery.toLowerCase();
    filtered = filtered.where((medicine) {
      return medicine.name.toLowerCase().contains(lowercaseQuery) ||
          medicine.manufacturer.toLowerCase().contains(lowercaseQuery) ||
          (medicine.category?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          (medicine.description?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  // Apply sorting
  filtered.sort((a, b) {
    dynamic aValue, bValue;
    switch (sort.column) {
      case 'name':
        aValue = a.name;
        bValue = b.name;
        break;
      case 'manufacturer':
        aValue = a.manufacturer;
        bValue = b.manufacturer;
        break;
      case 'category':
        aValue = a.category ?? '';
        bValue = b.category ?? '';
        break;
      case 'mrp':
        aValue = a.mrp;
        bValue = b.mrp;
        break;
      case 'purchasePrice':
        aValue = a.purchasePrice;
        bValue = b.purchasePrice;
        break;
      case 'createdAt':
        aValue = a.createdAt;
        bValue = b.createdAt;
        break;
      default:
        aValue = a.name;
        bValue = b.name;
    }

    final comparison = aValue.toString().compareTo(bValue.toString());
    return sort.ascending ? comparison : -comparison;
  });

  return filtered;
});

// Main Screen - Medicine Management
class AllMedicineScreen extends ConsumerStatefulWidget {
  const AllMedicineScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AllMedicineScreen> createState() => _AllMedicineScreenState();
}

class _AllMedicineScreenState extends ConsumerState<AllMedicineScreen> {
  Medicine? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        // Create new medicine (Ctrl+N or Cmd+N)
        if (event.logicalKey == LogicalKeyboardKey.keyN &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _navigateToAddMedicine();
          return true;
        }
        // Search (Ctrl+F or Cmd+F)
        if (event.logicalKey == LogicalKeyboardKey.keyF &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          // Focus search will be handled by the search widget
          return true;
        }
        // Refresh (F5)
        if (event.logicalKey == LogicalKeyboardKey.f5) {
          _refreshMedicines();
          return true;
        }
        // Close detail panel (Escape)
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _closeDetailPanel();
          return true;
        }
      }
      return false;
    });
  }

  void _navigateToAddMedicine() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const OptimizedAddMedicineScreen(),
      ),
    )
        .then((result) {
      if (result == true) {
        _refreshMedicines();
      }
    });
  }

  void _refreshMedicines() {
    ref.invalidate(medicinesProvider);
    setState(() {
      _selectedMedicine = null;
    });
  }

  void _selectMedicine(Medicine medicine) {
    setState(() {
      _selectedMedicine = medicine;
    });
    ref.read(selectedMedicineProvider.notifier).state = medicine;
  }

  void _closeDetailPanel() {
    setState(() {
      _selectedMedicine = null;
    });
    ref.read(selectedMedicineProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1200;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Medicine Management',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Medicine (Ctrl+N)',
            onPressed: _navigateToAddMedicine,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh (F5)',
            onPressed: _refreshMedicines,
          ),
        ],
      ),
      body: medicinesAsync.when(
        data: (medicines) {
          if (medicines.isEmpty) {
            return _EmptyMedicineState(onAdd: _navigateToAddMedicine);
          }

          return isDesktop
              ? _DesktopLayout(
                  selectedMedicine: _selectedMedicine,
                  onMedicineSelected: _selectMedicine,
                  onRefresh: _refreshMedicines,
                  onCloseDetail: _closeDetailPanel,
                )
              : _MobileLayout(
                  selectedMedicine: _selectedMedicine,
                  onMedicineSelected: _selectMedicine,
                  onRefresh: _refreshMedicines,
                );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading medicines...'),
            ],
          ),
        ),
        error: (error, stack) => _ErrorState(
          error: error.toString(),
          onRetry: _refreshMedicines,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddMedicine,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
        backgroundColor: HospitalTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Desktop Layout with Master-Detail (FIXED)
class _DesktopLayout extends ConsumerWidget {
  final Medicine? selectedMedicine;
  final Function(Medicine) onMedicineSelected;
  final VoidCallback onRefresh;
  final VoidCallback onCloseDetail;

  const _DesktopLayout({
    required this.selectedMedicine,
    required this.onMedicineSelected,
    required this.onRefresh,
    required this.onCloseDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Use LayoutBuilder to prevent overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width properly
        final availableWidth = constraints.maxWidth;

        // Set minimum widths to prevent overflow
        const minMasterWidth = 400.0;
        const minDetailWidth = 350.0;

        // If screen is too small for both panels, prioritize master
        if (selectedMedicine != null &&
            availableWidth < (minMasterWidth + minDetailWidth)) {
          return Row(
            children: [
              // Master Panel - constrained width
              SizedBox(
                width: availableWidth * 0.5, // Use 50% for master
                child: _MedicineListPanel(
                  onMedicineSelected: onMedicineSelected,
                  selectedMedicine: selectedMedicine,
                  onRefresh: onRefresh,
                ),
              ),
              // Detail Panel - use remaining width
              Expanded(
                child: _MedicineDetailPanel(
                  medicine: selectedMedicine!,
                  onRefresh: onRefresh,
                  onClose: onCloseDetail,
                ),
              ),
            ],
          );
        }

        // Normal layout with proper width calculation
        final masterWidth = selectedMedicine == null
            ? availableWidth - 32 // Leave some margin
            : (availableWidth * 0.6)
                .clamp(minMasterWidth, availableWidth - minDetailWidth);

        return Row(
          children: [
            // Master Panel - Medicine List
            SizedBox(
              width: masterWidth,
              child: _MedicineListPanel(
                onMedicineSelected: onMedicineSelected,
                selectedMedicine: selectedMedicine,
                onRefresh: onRefresh,
              ),
            ),

            // Detail Panel - Medicine Details
            if (selectedMedicine != null)
              Expanded(
                child: _MedicineDetailPanel(
                  medicine: selectedMedicine!,
                  onRefresh: onRefresh,
                  onClose: onCloseDetail,
                ),
              ),
          ],
        );
      },
    );
  }
}

// Mobile Layout
class _MobileLayout extends ConsumerWidget {
  final Medicine? selectedMedicine;
  final Function(Medicine) onMedicineSelected;
  final VoidCallback onRefresh;

  const _MobileLayout({
    required this.selectedMedicine,
    required this.onMedicineSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MedicineListPanel(
      onMedicineSelected: (medicine) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MedicineDetailScreen(
              medicine: medicine,
              onRefresh: onRefresh,
            ),
          ),
        );
      },
      selectedMedicine: selectedMedicine,
      onRefresh: onRefresh,
      isMobile: true,
    );
  }
}

// Medicine List Panel
class _MedicineListPanel extends ConsumerWidget {
  final Function(Medicine) onMedicineSelected;
  final Medicine? selectedMedicine;
  final VoidCallback onRefresh;
  final bool isMobile;

  const _MedicineListPanel({
    required this.onMedicineSelected,
    required this.selectedMedicine,
    required this.onRefresh,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Search and Filter Bar
        _SearchAndFilterBar(),

        // Medicine List/Table
        Expanded(
          child: _ResponsiveMedicineTable(
            onMedicineSelected: onMedicineSelected,
            selectedMedicine: selectedMedicine,
            isMobile: isMobile,
            onRefresh: onRefresh,
          ),
        ),
      ],
    );
  }
}

// Responsive Search and Filter Bar
class _SearchAndFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(medicineSearchProvider);
    final sortState = ref.watch(medicineSortProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Column(
        children: [
          // Use LayoutBuilder for responsive search bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              if (isNarrow) {
                return Column(
                  children: [
                    // Search Field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search medicines... (Ctrl+F)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  ref
                                      .read(medicineSearchProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(medicineSearchProvider.notifier).state = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Sort controls
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: sortState.column,
                            decoration: const InputDecoration(
                              labelText: 'Sort By',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'name', child: Text('Name')),
                              DropdownMenuItem(
                                  value: 'manufacturer',
                                  child: Text('Manufacturer')),
                              DropdownMenuItem(
                                  value: 'category', child: Text('Category')),
                              DropdownMenuItem(
                                  value: 'mrp', child: Text('MRP')),
                              DropdownMenuItem(
                                  value: 'purchasePrice',
                                  child: Text('Purchase Price')),
                              DropdownMenuItem(
                                  value: 'createdAt',
                                  child: Text('Date Added')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(medicineSortProvider.notifier).state =
                                    sortState.copyWith(column: value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            sortState.ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                          tooltip:
                              sortState.ascending ? 'Ascending' : 'Descending',
                          onPressed: () {
                            ref.read(medicineSortProvider.notifier).state =
                                sortState.copyWith(
                                    ascending: !sortState.ascending);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Wide layout
              return Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search medicines... (Ctrl+F)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  ref
                                      .read(medicineSearchProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(medicineSearchProvider.notifier).state = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Sort Dropdown
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: sortState.column,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(
                            value: 'manufacturer', child: Text('Manufacturer')),
                        DropdownMenuItem(
                            value: 'category', child: Text('Category')),
                        DropdownMenuItem(value: 'mrp', child: Text('MRP')),
                        DropdownMenuItem(
                            value: 'purchasePrice',
                            child: Text('Purchase Price')),
                        DropdownMenuItem(
                            value: 'createdAt', child: Text('Date Added')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(medicineSortProvider.notifier).state =
                              sortState.copyWith(column: value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort Direction
                  IconButton(
                    icon: Icon(
                      sortState.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    tooltip: sortState.ascending ? 'Ascending' : 'Descending',
                    onPressed: () {
                      ref.read(medicineSortProvider.notifier).state =
                          sortState.copyWith(ascending: !sortState.ascending);
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          // Statistics Row
          _StatisticsRow(),
        ],
      ),
    );
  }
}

// Statistics Row
class _StatisticsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredMedicines = ref.watch(filteredMedicinesProvider);
    final allMedicines = ref.watch(medicinesProvider).asData?.value ?? [];

    final totalValue = filteredMedicines.fold<double>(
      0,
      (sum, medicine) => sum + (medicine.mrp * 1),
    );

    final totalPurchaseValue = filteredMedicines.fold<double>(
      0,
      (sum, medicine) => sum + (medicine.purchasePrice * 1),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final stats = [
          _StatCard(
            title: 'Total Medicines',
            value: filteredMedicines.length.toString(),
            subtitle: 'of ${allMedicines.length}',
            icon: Icons.medication,
            color: HospitalTheme.primary,
          ),
          _StatCard(
            title: 'Total MRP Value',
            value: '₹${totalValue.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet,
            color: HospitalTheme.success,
          ),
          _StatCard(
            title: 'Purchase Value',
            value: '₹${totalPurchaseValue.toStringAsFixed(0)}',
            icon: Icons.shopping_cart,
            color: HospitalTheme.info,
          ),
          _StatCard(
            title: 'Potential Profit',
            value: '₹${(totalValue - totalPurchaseValue).toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: HospitalTheme.warning,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: stats[0]),
                  const SizedBox(width: 8),
                  Expanded(child: stats[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: stats[2]),
                  const SizedBox(width: 8),
                  Expanded(child: stats[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: stats
              .expand((stat) => [
                    Expanded(child: stat),
                    if (stat != stats.last) const SizedBox(width: 16),
                  ])
              .toList(),
        );
      },
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: HospitalTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Responsive Medicine Table
// Responsive Medicine Table (FIXED for full width)
class _ResponsiveMedicineTable extends ConsumerWidget {
  final Function(Medicine) onMedicineSelected;
  final Medicine? selectedMedicine;
  final bool isMobile;
  final VoidCallback onRefresh;

  const _ResponsiveMedicineTable({
    required this.onMedicineSelected,
    required this.selectedMedicine,
    this.isMobile = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredMedicines = ref.watch(filteredMedicinesProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: HospitalTheme.shadow,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.medication,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Medicines',
                  style: HospitalTheme.themeData.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredMedicines.length} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Content - FIXED for full width
          Expanded(
            child: _buildTableContent(context, ref, filteredMedicines),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent(
      BuildContext context, WidgetRef ref, List<Medicine> medicines) {
    if (medicines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No medicines found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your search criteria',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the actual available width
        final availableWidth = constraints.maxWidth;

        // Determine which columns to show based on available width
        final showManufacturer = availableWidth > 600;
        final showCategory = availableWidth > 700;
        final showPurchasePrice = availableWidth > 800;
        final showMargin = availableWidth > 900;

        // Calculate optimal column spacing based on available width
        final baseSpacing = availableWidth > 1000
            ? 20.0
            : availableWidth > 800
                ? 16.0
                : availableWidth > 600
                    ? 12.0
                    : 8.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: availableWidth, // Ensure table uses full width
            ),
            child: DataTable(
              // Remove horizontal margin to use full width
              horizontalMargin: 0,
              // Adjust column spacing based on available width
              columnSpacing: baseSpacing,
              headingRowColor:
                  MaterialStateProperty.all(HospitalTheme.surfaceLight),
              dataRowMaxHeight: 60,
              // Make columns responsive to available width
              columns: _buildDataColumns(
                showManufacturer: showManufacturer,
                showCategory: showCategory,
                showPurchasePrice: showPurchasePrice,
                showMargin: showMargin,
              ),
              rows: medicines.map((medicine) {
                final profit = medicine.mrp - medicine.purchasePrice;
                final profitPercentage = medicine.purchasePrice > 0
                    ? (profit / medicine.purchasePrice * 100).toStringAsFixed(1)
                    : 'N/A';

                final isSelected = selectedMedicine?.id == medicine.id;

                return DataRow(
                  selected: isSelected,
                  color: isSelected
                      ? MaterialStateProperty.all(
                          HospitalTheme.primaryLight.withOpacity(0.1))
                      : null,
                  onSelectChanged: (_) => onMedicineSelected(medicine),
                  cells: _buildDataCells(
                    medicine: medicine,
                    profit: profit,
                    profitPercentage: profitPercentage,
                    showManufacturer: showManufacturer,
                    showCategory: showCategory,
                    showPurchasePrice: showPurchasePrice,
                    showMargin: showMargin,
                    context: context,
                    ref: ref,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Extract column building to separate method for better organization
  List<DataColumn> _buildDataColumns({
    required bool showManufacturer,
    required bool showCategory,
    required bool showPurchasePrice,
    required bool showMargin,
  }) {
    return [
      const DataColumn(
        label: Expanded(
          child: Text(
            'Medicine',
            style: TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      if (showManufacturer)
        const DataColumn(
          label: Expanded(
            child: Text(
              'Manufacturer',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      if (showCategory)
        const DataColumn(
          label: Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      const DataColumn(
        label: Text(
          'MRP (₹)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        numeric: true,
      ),
      if (showPurchasePrice)
        const DataColumn(
          label: Text(
            'Purchase (₹)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
      if (showMargin)
        const DataColumn(
          label: Text(
            'Margin',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
      const DataColumn(
        label: Text(
          'Actions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  // Extract cell building to separate method for better organization
  List<DataCell> _buildDataCells({
    required Medicine medicine,
    required double profit,
    required String profitPercentage,
    required bool showManufacturer,
    required bool showCategory,
    required bool showPurchasePrice,
    required bool showMargin,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return [
      DataCell(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                medicine.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (!showManufacturer)
                Text(
                  medicine.manufacturer,
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
      if (showManufacturer)
        DataCell(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              medicine.manufacturer,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      if (showCategory)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: HospitalTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                medicine.category ?? 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '₹${medicine.mrp.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      if (showPurchasePrice)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '₹${medicine.purchasePrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: HospitalTheme.textMedium,
              ),
            ),
          ),
        ),
      if (showMargin)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: profit >= 0
                        ? HospitalTheme.success
                        : HospitalTheme.error,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (profit >= 0
                            ? HospitalTheme.success
                            : HospitalTheme.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$profitPercentage%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: profit >= 0
                          ? HospitalTheme.success
                          : HospitalTheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Edit Medicine',
                onPressed: () => _editMedicine(context, medicine),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                tooltip: 'Delete Medicine',
                color: HospitalTheme.error,
                onPressed: () => _deleteMedicine(context, ref, medicine),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _editMedicine(BuildContext context, Medicine medicine) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) =>
            OptimizedAddMedicineScreen(medicineToEdit: medicine),
      ),
    )
        .then((result) {
      if (result == true) {
        onRefresh();
      }
    });
  }

  void _deleteMedicine(BuildContext context, WidgetRef ref, Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${medicine.name}"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: HospitalTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Deleting medicine...'),
                    ],
                  ),
                ),
              );

              final medicineService = ref.read(medicineServiceProvider);
              final success = await medicineService.deleteMedicine(medicine.id);

              if (success) {
                onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Medicine deleted successfully'),
                    backgroundColor: HospitalTheme.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete medicine'),
                    backgroundColor: HospitalTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Medicine Detail Panel (UPDATED with close button)
class _MedicineDetailPanel extends ConsumerWidget {
  final Medicine medicine;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const _MedicineDetailPanel({
    required this.medicine,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Close button header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: HospitalTheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Medicine Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close Details (Esc)',
                  onPressed: onClose,
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: HospitalTheme.shadow,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine Info Card
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: HospitalTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medication,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine.name,
                                    style: HospitalTheme
                                        .themeData.textTheme.headlineSmall,
                                  ),
                                  Text(
                                    'by ${medicine.manufacturer}',
                                    style: TextStyle(
                                      color: HospitalTheme.textMedium,
                                    ),
                                  ),
                                  if (medicine.category != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            HospitalTheme.info.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        medicine.category!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: HospitalTheme.info,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (medicine.description != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Description',
                            style:
                                HospitalTheme.themeData.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            medicine.description!,
                            style: TextStyle(
                              color: HospitalTheme.textMedium,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Pricing Information
                        Text(
                          'Pricing Information',
                          style: HospitalTheme.themeData.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        _PriceCard(
                          title: 'MRP',
                          amount: medicine.mrp,
                          color: HospitalTheme.warning,
                          icon: Icons.local_offer,
                        ),

                        const SizedBox(height: 12),

                        _PriceCard(
                          title: 'Purchase Price',
                          amount: medicine.purchasePrice,
                          color: HospitalTheme.success,
                          icon: Icons.shopping_cart,
                        ),

                        const SizedBox(height: 12),

                        _PriceCard(
                          title: 'Profit Margin',
                          amount: medicine.mrp - medicine.purchasePrice,
                          color: HospitalTheme.info,
                          icon: Icons.trending_up,
                          showPercentage: true,
                          percentage: medicine.purchasePrice > 0
                              ? ((medicine.mrp - medicine.purchasePrice) /
                                  medicine.purchasePrice *
                                  100)
                              : 0,
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context)
                                      .push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OptimizedAddMedicineScreen(
                                              medicineToEdit: medicine),
                                    ),
                                  )
                                      .then((result) {
                                    if (result == true) {
                                      onRefresh();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Medicine'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HospitalTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Price Card Widget
class _PriceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool showPercentage;
  final double? percentage;

  const _PriceCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.showPercentage = false,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showPercentage && percentage != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage!.toStringAsFixed(1)}%',
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
}

// Medicine Detail Screen (for mobile)
class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onRefresh;

  const MedicineDetailScreen({
    Key? key,
    required this.medicine,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: medicine.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) =>
                      OptimizedAddMedicineScreen(medicineToEdit: medicine),
                ),
              )
                  .then((result) {
                if (result == true) {
                  onRefresh();
                  Navigator.pop(context);
                }
              });
            },
          ),
        ],
      ),
      body: _MedicineDetailPanel(
        medicine: medicine,
        onRefresh: onRefresh,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

// Empty State Widget
class _EmptyMedicineState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyMedicineState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 120,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 24),
          Text(
            'No Medicines Added Yet',
            style: HospitalTheme.themeData.textTheme.headlineMedium?.copyWith(
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start building your medicine inventory by adding your first medicine',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HospitalTheme.textLight,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Medicine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Error State Widget
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: HospitalTheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to Load Medicines',
            style: HospitalTheme.themeData.textTheme.headlineMedium?.copyWith(
              color: HospitalTheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Add Medicine Screen - You'll need to add this part as well (same as before)

// Add Medicine Screen - Separate screen for adding/editing medicines
