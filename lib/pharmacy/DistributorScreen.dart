import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// Model class for Distributor
class Distributor {
  final String id;
  final String name;
  final String contactNumber;
  final String email;
  final String address;
  final DateTime createdAt;

  Distributor({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.address,
    required this.createdAt,
  });

  factory Distributor.fromJson(Map<String, dynamic> json) {
    return Distributor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
    };
  }

  Distributor copyWith({
    String? id,
    String? name,
    String? contactNumber,
    String? email,
    String? address,
    DateTime? createdAt,
  }) {
    return Distributor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// API Service for Distributors
class DistributorService {
  static const String baseUrl = 'http://localhost:5001/pharma';

  // Get all distributors
  Future<List<Distributor>> getDistributors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getDistributors'));
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

  // Create a new distributor
  Future<bool> createDistributor(Distributor distributor) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/createDistributor'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(distributor.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating distributor: $e');
      return false;
    }
  }

  // Update a distributor
  Future<bool> updateDistributor(String id, Distributor distributor) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/updateDistributor/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(distributor.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating distributor: $e');
      return false;
    }
  }

  // Delete a distributor
  Future<bool> deleteDistributor(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/deleteDistributor/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting distributor: $e');
      return false;
    }
  }

// Add this to the DistributorService class
  Future<bool> addToInventory({
    required String medicineId,
    required String batchNumber,
    required DateTime expiryDate,
    required int quantity,
    required String distributorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addToInventory'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'medicineId': medicineId,
          'batchNumber': batchNumber,
          'expiryDate': expiryDate.toIso8601String(),
          'quantity': quantity,
          'distributorId': distributorId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding to inventory: $e');
      return false;
    }
  }

// Also add this method to fetch available medicines
  Future<List<Map<String, dynamic>>> getMedicines() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getMedicines'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching medicines: $e');
      return [];
    }
  }

  // Get medicines for a distributor
  Future<List<Map<String, dynamic>>> getDistributorMedicines(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getDistributorMedicines/$id'),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching distributor medicines: $e');
      return [];
    }
  }
}

// Providers for state management
final distributorServiceProvider = Provider<DistributorService>((ref) {
  return DistributorService();
});

final distributorsProvider = FutureProvider<List<Distributor>>((ref) async {
  final distributorService = ref.watch(distributorServiceProvider);
  return await distributorService.getDistributors();
});

final selectedDistributorProvider = StateProvider<Distributor?>((ref) => null);

// Screen for Distributor Management
class DistributorScreen extends ConsumerStatefulWidget {
  const DistributorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DistributorScreen> createState() => _DistributorScreenState();
}

class _DistributorScreenState extends ConsumerState<DistributorScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<Distributor> _filteredDistributors = [];
  bool _isSearching = false;
  Distributor? _selectedDistributor;

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
        // Create new distributor (Ctrl+N or Cmd+N)
        if (event.logicalKey == LogicalKeyboardKey.keyN &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _showDistributorDialog(context);
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

  void _searchDistributors(String query) {
    ref.watch(distributorsProvider).whenData((distributors) {
      if (!mounted) return; // Add this check
      setState(() {
        _filteredDistributors = query.isEmpty
            ? distributors
            : distributors.where((distributor) {
                final lowercaseQuery = query.toLowerCase();
                return distributor.name
                        .toLowerCase()
                        .contains(lowercaseQuery) ||
                    distributor.email.toLowerCase().contains(lowercaseQuery) ||
                    distributor.contactNumber.contains(query) ||
                    distributor.address.toLowerCase().contains(lowercaseQuery);
              }).toList();
      });
    });
  }

  void _refreshDistributors() {
    ref.invalidate(distributorsProvider);
    _searchController.clear();
    setState(() {
      _filteredDistributors = [];
      _selectedDistributor = null;
    });
  }

  void _selectDistributor(Distributor distributor) {
    setState(() {
      _selectedDistributor = distributor;
    });
    ref.read(selectedDistributorProvider.notifier).state = distributor;
  }

  Future<void> _showDistributorDialog(BuildContext context,
      {Distributor? distributor}) async {
    final nameController = TextEditingController(text: distributor?.name ?? '');
    final contactController =
        TextEditingController(text: distributor?.contactNumber ?? '');
    final emailController =
        TextEditingController(text: distributor?.email ?? '');
    final addressController =
        TextEditingController(text: distributor?.address ?? '');
    final formKey = GlobalKey<FormState>();

    final isEditing = distributor != null;
    if (!mounted) return; // Add this check

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Distributor' : 'Add New Distributor'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter distributor name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter distributor name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      hintText: 'Enter contact number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter contact number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email address';
                      }
                      final emailRegExp =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter address',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },
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
            TextButton(
              child: Text(isEditing ? 'Update' : 'Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final distributorService =
                      ref.read(distributorServiceProvider);
                  final newDistributor = Distributor(
                    id: distributor?.id ?? '',
                    name: nameController.text,
                    contactNumber: contactController.text,
                    email: emailController.text,
                    address: addressController.text,
                    createdAt: distributor?.createdAt ?? DateTime.now(),
                  );

                  bool success;
                  if (isEditing) {
                    success = await distributorService.updateDistributor(
                      distributor.id,
                      newDistributor,
                    );
                  } else {
                    success = await distributorService.createDistributor(
                      newDistributor,
                    );
                  }

                  if (success) {
                    _refreshDistributors();
                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Distributor updated successfully'
                                : 'Distributor added successfully',
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
                                ? 'Failed to update distributor'
                                : 'Failed to add distributor',
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

  Future<void> _showAddMedicineDialog(
      BuildContext context, String distributorId) async {
    final distributorService = ref.read(distributorServiceProvider);

    // Load available medicines for selection
    final medicines = await distributorService.getMedicines();
    if (!mounted) return;

    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No medicines available. Please add medicines to the system first.'),
        ),
      );
      return;
    }

    String? selectedMedicineId;
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
              title: const Text('Add Medicine to Inventory'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Medicine',
                          hintText: 'Select a medicine',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedMedicineId,
                        items: medicines.map((medicine) {
                          return DropdownMenuItem<String>(
                            value: medicine['_id'] as String,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: medicine['name'] as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: ' (${medicine['manufacturer']})',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMedicineId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a medicine';
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
                                ? '${selectedExpiryDate!.day.toString().padLeft(2, '0')}/${selectedExpiryDate!.month.toString().padLeft(2, '0')}/${selectedExpiryDate!.year}'
                                : 'Select expiry date',
                          ),
                        ),
                      ),

                      // Display selected medicine details
                      if (selectedMedicineId != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PharmaTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: PharmaTheme.primary.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Medicine Details:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: PharmaTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...medicines
                                  .where((m) => m['_id'] == selectedMedicineId)
                                  .map((m) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Name: ${m['name']}'),
                                          Text(
                                              'Manufacturer: ${m['manufacturer']}'),
                                          Text(
                                              'Category: ${m['category'] ?? 'N/A'}'),
                                          if (m['description'] != null)
                                            Text(
                                                'Description: ${m['description']}'),
                                          Text('MRP: ₹${m['mrp']}'),
                                          Text(
                                              'Purchase Price: ₹${m['purchasePrice']}'),
                                        ],
                                      ))
                                  .toList(),
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
                      final success = await distributorService.addToInventory(
                        medicineId: selectedMedicineId!,
                        batchNumber: batchNumberController.text,
                        expiryDate: selectedExpiryDate!,
                        quantity: int.parse(quantityController.text),
                        distributorId: distributorId,
                      );

                      if (context.mounted) {
                        Navigator.of(dialogContext).pop();

                        if (success) {
                          _refreshDistributors();
                          // Refresh the medicines list
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Medicine added to inventory successfully'),
                              backgroundColor: PharmaTheme.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Failed to add medicine to inventory'),
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
      },
    );
  }

  Future<void> _deleteDistributor(
      BuildContext context, Distributor distributor) async {
    if (!mounted) return; // Add this check

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${distributor.name}?'),
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
                final distributorService = ref.read(distributorServiceProvider);
                final success =
                    await distributorService.deleteDistributor(distributor.id);

                if (success) {
                  if (_selectedDistributor?.id == distributor.id) {
                    setState(() {
                      _selectedDistributor = null;
                    });
                    ref.read(selectedDistributorProvider.notifier).state = null;
                  }
                  _refreshDistributors();
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Distributor deleted successfully'),
                        backgroundColor: PharmaTheme.success,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete distributor'),
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

  Future<void> _showDistributorMedicines(BuildContext context,
      String distributorId, String distributorName) async {
    final distributorService = ref.read(distributorServiceProvider);
    final medicines =
        await distributorService.getDistributorMedicines(distributorId);
    if (!mounted) return; // Add this check after any await

    if (context.mounted) {
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('$distributorName\'s Medicines'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: medicines.isEmpty
                  ? const Center(
                      child: Text('No medicines found for this distributor'),
                    )
                  : ListView.separated(
                      itemCount: medicines.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final medicine = medicines[index];
                        final expiryDate = medicine['nearestExpiry'] != null
                            ? DateTime.parse(medicine['nearestExpiry'])
                            : null;

                        return ListTile(
                          title: Text(medicine['name'] ?? 'Unknown Medicine'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Manufacturer: ${medicine['manufacturer'] ?? 'Unknown'}'),
                              Text(
                                  'Quantity: ${medicine['totalQuantity'] ?? 'Unknown'}'),
                              if (expiryDate != null)
                                Text(
                                  'Nearest Expiry: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: PharmaTheme.spacingXs,
                            horizontal: PharmaTheme.spacingM,
                          ),
                        );
                      },
                    ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final distributorsAsync = ref.watch(distributorsProvider);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            onPressed: _refreshDistributors,
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
        child: distributorsAsync.when(
          data: (distributors) {
            // If search is active, use filtered list
            final displayedDistributors = _searchController.text.isNotEmpty
                ? _filteredDistributors
                : distributors;

            if (displayedDistributors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.business,
                      size: 64,
                      color: PharmaTheme.textSecondary,
                    ),
                    const SizedBox(height: PharmaTheme.spacingL),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No distributors matching "${_searchController.text}"'
                          : 'No distributors found',
                      style: PharmaTheme.headingMedium.copyWith(
                        color: PharmaTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: PharmaTheme.spacingM),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Distributor'),
                      onPressed: () => _showDistributorDialog(context),
                    ),
                  ],
                ),
              );
            }

            // Desktop layout with sectioned design
            if (screenSize.width >= PharmaTheme.tabletBreakpoint) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel - Distributor list
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
                                'Distributors',
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
                                  '${displayedDistributors.length}',
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
                              hintText: 'Search distributors...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _filteredDistributors = distributors;
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
                            onChanged: _searchDistributors,
                          ),
                        ),
                        // List of distributors
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: PharmaTheme.spacingM,
                            ),
                            itemCount: displayedDistributors.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final distributor = displayedDistributors[index];
                              final isSelected =
                                  _selectedDistributor?.id == distributor.id;
                              return ListTile(
                                title: Text(
                                  distributor.name,
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
                                  distributor.email,
                                  style: PharmaTheme.bodySmall,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? PharmaTheme.primary
                                      : PharmaTheme.primaryLight
                                          .withOpacity(0.1),
                                  child: Text(
                                    distributor.name.substring(0, 1),
                                    style: TextStyle(
                                      color: isSelected
                                          ? PharmaTheme.textLight
                                          : PharmaTheme.primary,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                selectedTileColor:
                                    PharmaTheme.primary.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    PharmaTheme.radiusM,
                                  ),
                                ),
                                onTap: () => _selectDistributor(distributor),
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
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Distributor'),
                            onPressed: () => _showDistributorDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right panel - Details and medicines
                  Expanded(
                    child: _selectedDistributor == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  size: 80,
                                  color: PharmaTheme.textSecondary
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: PharmaTheme.spacingL),
                                Text(
                                  'Select a distributor to view details',
                                  style: PharmaTheme.headingMedium.copyWith(
                                    color: PharmaTheme.textSecondary
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildDistributorDetailSection(
                            context, _selectedDistributor!),
                  ),
                ],
              );
            } else {
              // Mobile/Tablet layout - List or Grid view depending on width
              return Padding(
                padding: PharmaTheme.responsivePadding(context),
                child: screenSize.width < PharmaTheme.tabletBreakpoint
                    ? ListView.separated(
                        itemCount: displayedDistributors.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final distributor = displayedDistributors[index];
                          return _buildDistributorListItem(distributor);
                        },
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              screenSize.width < PharmaTheme.desktopBreakpoint
                                  ? 2
                                  : 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: PharmaTheme.spacingL,
                          mainAxisSpacing: PharmaTheme.spacingL,
                        ),
                        itemCount: displayedDistributors.length,
                        itemBuilder: (context, index) {
                          final distributor = displayedDistributors[index];
                          return _buildDistributorCard(distributor);
                        },
                      ),
              );
            }
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
                  'Failed to load distributors',
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
                  onPressed: _refreshDistributors,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: MediaQuery.of(context).size.width <
              PharmaTheme.tabletBreakpoint
          ? FloatingActionButton(
              onPressed: () => _showDistributorDialog(context),
              tooltip: 'Add Distributor (Ctrl+N)',
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB on desktop layout since we have Add button in left panel
    );
  }

// In the _buildDistributorDetailSection method, modify the column children ratio
// to give more space to the medicine section
  Widget _buildDistributorDetailSection(
      BuildContext context, Distributor distributor) {
    final Future<List<Map<String, dynamic>>> medicinesFuture = ref
        .read(distributorServiceProvider)
        .getDistributorMedicines(distributor.id);

    return Padding(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with distributor info (make this more compact)
          Container(
            padding: const EdgeInsets.all(PharmaTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
              boxShadow: PharmaTheme.shadowSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Distributor avatar
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: PharmaTheme.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                      ),
                      child: Center(
                        child: Text(
                          distributor.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: PharmaTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: PharmaTheme.spacingL),
                    // Distributor details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            distributor.name,
                            style: PharmaTheme.headingLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: PharmaTheme.spacingXs),
                          Row(
                            children: [
                              const Icon(Icons.email,
                                  size: 16, color: PharmaTheme.textSecondary),
                              const SizedBox(width: PharmaTheme.spacingXs),
                              Text(
                                distributor.email,
                                style: PharmaTheme.bodyMedium.copyWith(
                                  color: PharmaTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 16, color: PharmaTheme.textSecondary),
                              const SizedBox(width: PharmaTheme.spacingXs),
                              Text(
                                distributor.contactNumber,
                                style: PharmaTheme.bodyMedium.copyWith(
                                  color: PharmaTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: PharmaTheme.spacingM),
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: PharmaTheme.textSecondary),
                              const SizedBox(width: PharmaTheme.spacingXs),
                              Expanded(
                                child: Text(
                                  distributor.address,
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    color: PharmaTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                          onPressed: () => _showDistributorDialog(context,
                              distributor: distributor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                          color: PharmaTheme.error,
                          onPressed: () =>
                              _deleteDistributor(context, distributor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: PharmaTheme.spacingM),
                // Stats and additional info
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.calendar_today,
                        title: 'Added On',
                        value:
                            '${distributor.createdAt.day}/${distributor.createdAt.month}/${distributor.createdAt.year}',
                      ),
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: medicinesFuture,
                        builder: (context, snapshot) {
                          final medicineCount =
                              snapshot.hasData ? snapshot.data!.length : 0;
                          return _buildStatCard(
                            icon: Icons.medical_services_outlined,
                            title: 'Medicines',
                            value: medicineCount.toString(),
                            color: PharmaTheme.accent,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Orders',
                        value: '0',
                        color: PharmaTheme.info,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: PharmaTheme.spacingM),

          // Medicines section header with enhanced styling
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PharmaTheme.spacingM,
              vertical: PharmaTheme.spacingS,
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
                    const Icon(
                      Icons.medication_outlined,
                      color: PharmaTheme.textLight,
                    ),
                    const SizedBox(width: PharmaTheme.spacingS),
                    Text(
                      'Medicines Supplied',
                      style: PharmaTheme.headingSmall.copyWith(
                        color: PharmaTheme.textLight,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.refresh,
                    color: PharmaTheme.textLight,
                  ),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(color: PharmaTheme.textLight),
                  ),
                  onPressed: () {
                    if (mounted) {
                      setState(
                          () {}); // Refresh state to rebuild the FutureBuilder
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: PharmaTheme.primaryLight.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          // Medicines list - takes up more space now (Expanded with flex: 4)
          Expanded(
            flex: 4, // Increase the flex value to give more space to medicines
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(PharmaTheme.radiusM),
                  bottomRight: Radius.circular(PharmaTheme.radiusM),
                ),
                boxShadow: PharmaTheme.shadowSmall,
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: medicinesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: PharmaTheme.spacingM),
                          Text('Loading medicines...'),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: PharmaTheme.error,
                          ),
                          const SizedBox(height: PharmaTheme.spacingM),
                          Text(
                            'Failed to load medicines',
                            style: PharmaTheme.headingSmall,
                          ),
                          const SizedBox(height: PharmaTheme.spacingS),
                          Text(
                            snapshot.error.toString(),
                            style: PharmaTheme.bodySmall,
                          ),
                          const SizedBox(height: PharmaTheme.spacingM),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            onPressed: () {
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: PharmaTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.medication_outlined,
                              size: 60,
                              color: PharmaTheme.primary.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: PharmaTheme.spacingL),
                          Text(
                            'No medicines found for this distributor',
                            style: PharmaTheme.headingMedium.copyWith(
                              color: PharmaTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: PharmaTheme.spacingS),
                          Text(
                            'Try adding medicines or refreshing the list',
                            style: PharmaTheme.bodyMedium.copyWith(
                              color: PharmaTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: PharmaTheme.spacingL),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Medicine'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: PharmaTheme.spacingL,
                                vertical: PharmaTheme.spacingM,
                              ),
                            ),
                            onPressed: () {
                              _showAddMedicineDialog(context, distributor.id);

                              // Implement add medicine functionality
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    final medicines = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table header with enhanced styling
                        // Table header with proper alignment
                        // Table header with proper alignment
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: PharmaTheme.spacingM,
                            horizontal: PharmaTheme.spacingL,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFEEEEEE),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Medicine Name - aligned to the left
                              SizedBox(
                                width: 260, // Same fixed width as in row
                                child: Text(
                                  'Medicine Name',
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: PharmaTheme.primary,
                                  ),
                                ),
                              ),
                              // Manufacturer - aligned to the left
                              SizedBox(
                                width: 150, // Same fixed width as in row
                                child: Text(
                                  'Manufacturer',
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: PharmaTheme.primary,
                                  ),
                                ),
                              ),
                              // Quantity - aligned to the center
                              SizedBox(
                                width: 100, // Same fixed width as in row
                                child: Text(
                                  'Quantity',
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: PharmaTheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Nearest Expiry - aligned to the center
                              SizedBox(
                                width: 150, // Same fixed width as in row
                                child: Text(
                                  'Nearest Expiry',
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: PharmaTheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Actions - aligned to the center
                              SizedBox(
                                width: 60, // Same fixed width as in row
                                child: Text(
                                  'Actions',
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: PharmaTheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Table body with enhanced styling
                        Expanded(
                          child: ListView.separated(
                            itemCount: medicines.length,
                            separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFEEEEEE)),
                            itemBuilder: (context, index) {
                              final medicine = medicines[index];
                              final expiryDate = medicine['nearestExpiry'] !=
                                      null
                                  ? DateTime.parse(medicine['nearestExpiry'])
                                  : null;

                              // Calculate if expiry is near (less than 3 months)
                              final isExpiryNear = expiryDate != null &&
                                  DateTime.now().difference(expiryDate).inDays >
                                      -90;

                              // Get formatted expiry date
                              final formattedExpiry = expiryDate != null
                                  ? '${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}'
                                  : 'Unknown';

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: PharmaTheme.spacingM,
                                  horizontal: PharmaTheme.spacingL,
                                ),
                                color: Colors.white,
                                child: Row(
                                  children: [
                                    // Medicine name with icon - aligned to the left
                                    // Use SizedBox with fixed width instead of Expanded
                                    SizedBox(
                                      width:
                                          260, // Fixed width for Medicine Name column
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE6F7F5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.medication,
                                              color: Color(0xFF4ECDC4),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: PharmaTheme.spacingM),
                                          Expanded(
                                            child: Text(
                                              medicine['name'] ??
                                                  'Unknown Medicine',
                                              style: PharmaTheme.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Manufacturer - aligned to the left
                                    // Use SizedBox with fixed width instead of Expanded
                                    SizedBox(
                                      width:
                                          150, // Fixed width for Manufacturer column
                                      child: Text(
                                        medicine['manufacturer'] ?? 'Unknown',
                                        style: PharmaTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Quantity - aligned to the center
                                    // Use SizedBox with fixed width instead of Expanded
                                    SizedBox(
                                      width:
                                          100, // Fixed width for Quantity column
                                      child: Center(
                                        child: Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: PharmaTheme.spacingXs,
                                            horizontal: PharmaTheme.spacingS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF3FF),
                                            borderRadius: BorderRadius.circular(
                                                PharmaTheme.radiusS),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            medicine['totalQuantity']
                                                    ?.toString() ??
                                                '0',
                                            style:
                                                PharmaTheme.bodyMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: PharmaTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Nearest Expiry - aligned to the center
                                    // Use SizedBox with fixed width instead of Expanded
                                    SizedBox(
                                      width:
                                          150, // Fixed width for Nearest Expiry column
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: PharmaTheme.spacingXs,
                                            horizontal: PharmaTheme.spacingS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isExpiryNear
                                                ? const Color(0xFFFFF8E6)
                                                : const Color(0xFFE6F7F5),
                                            borderRadius: BorderRadius.circular(
                                                PharmaTheme.radiusS),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isExpiryNear)
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 16,
                                                  color:
                                                      const Color(0xFFFFA000),
                                                ),
                                              if (isExpiryNear)
                                                const SizedBox(width: 4),
                                              Text(
                                                formattedExpiry,
                                                style: PharmaTheme.bodyMedium
                                                    .copyWith(
                                                  color: isExpiryNear
                                                      ? const Color(0xFFFFA000)
                                                      : Colors.black,
                                                  fontWeight: isExpiryNear
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Actions - aligned to the center
                                    SizedBox(
                                      width:
                                          60, // Fixed width for Actions column
                                      child: Center(
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.info,
                                            size: 24,
                                            color: PharmaTheme.primary,
                                          ),
                                          onPressed: () {
                                            _showMedicineBatchDetails(
                                                context, medicine);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Summary footer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: PharmaTheme.spacingM,
                            horizontal: PharmaTheme.spacingL,
                          ),
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
                                'Total Medicines: ${medicines.length}',
                                style: PharmaTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Medicine'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PharmaTheme.accent,
                                ),
                                onPressed: () {
                                  _showAddMedicineDialog(
                                      context, distributor.id);

                                  // Implement add medicine functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Add medicine functionality to be implemented'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

// Add this new helper method to show medicine batch details in an enhanced dialog
  void _showMedicineBatchDetails(
      BuildContext context, Map<String, dynamic> medicine) {
    final batches = medicine['batches'] as List<dynamic>?;

    if (batches == null || batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No batch information available'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        ),
        child: Container(
          width: 600,
          height: 500,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  children: [
                    const Icon(
                      Icons.medication,
                      color: PharmaTheme.textLight,
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine['name'] ?? 'Medicine Batches',
                            style: PharmaTheme.headingMedium.copyWith(
                              color: PharmaTheme.textLight,
                            ),
                          ),
                          if (medicine['manufacturer'] != null)
                            Text(
                              'Manufacturer: ${medicine['manufacturer']}',
                              style: PharmaTheme.bodySmall.copyWith(
                                color: PharmaTheme.textLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: PharmaTheme.textLight,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Batch stats
              Padding(
                padding: const EdgeInsets.all(PharmaTheme.spacingM),
                child: Row(
                  children: [
                    _buildBatchStatCard(
                      icon: Icons.inventory_2,
                      title: 'Total Batches',
                      value: batches.length.toString(),
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    _buildBatchStatCard(
                      icon: Icons.shopping_cart,
                      title: 'Total Quantity',
                      value: medicine['totalQuantity']?.toString() ?? '0',
                      color: PharmaTheme.accent,
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    _buildBatchStatCard(
                      icon: Icons.event,
                      title: 'Nearest Expiry',
                      value: medicine['nearestExpiry'] != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(medicine['nearestExpiry']))
                          : 'Unknown',
                      color: PharmaTheme.warning,
                    ),
                  ],
                ),
              ),

              // Batch list header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: PharmaTheme.spacingS,
                  horizontal: PharmaTheme.spacingM,
                ),
                color: PharmaTheme.background,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Batch Number',
                        style: PharmaTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Quantity',
                        style: PharmaTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Expiry Date',
                        style: PharmaTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Batch list
              Expanded(
                child: ListView.separated(
                  itemCount: batches.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final batch = batches[index];
                    final batchExpiry = batch['expiryDate'] != null
                        ? DateTime.parse(batch['expiryDate'])
                        : null;

                    // Calculate if expiry is near
                    final isExpiryNear = batchExpiry != null &&
                        DateTime.now().difference(batchExpiry).inDays > -90;

                    return Container(
                      color: index % 2 == 0
                          ? Colors.white
                          : PharmaTheme.background,
                      padding: const EdgeInsets.symmetric(
                        vertical: PharmaTheme.spacingM,
                        horizontal: PharmaTheme.spacingM,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: PharmaTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: PharmaTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: PharmaTheme.spacingS),
                                Text(
                                  batch['batchNumber'] ?? 'Unknown',
                                  style: PharmaTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: PharmaTheme.spacingS,
                                vertical: PharmaTheme.spacingXxs,
                              ),
                              decoration: BoxDecoration(
                                color: PharmaTheme.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  PharmaTheme.radiusS,
                                ),
                              ),
                              child: Text(
                                batch['quantity']?.toString() ?? '0',
                                style: PharmaTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PharmaTheme.accent,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: batchExpiry != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: PharmaTheme.spacingS,
                                      vertical: PharmaTheme.spacingXxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isExpiryNear
                                          ? PharmaTheme.warning.withOpacity(0.1)
                                          : PharmaTheme.success
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        PharmaTheme.radiusS,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isExpiryNear
                                              ? Icons.warning_amber_outlined
                                              : Icons.check_circle_outline,
                                          size: 16,
                                          color: isExpiryNear
                                              ? PharmaTheme.warning
                                              : PharmaTheme.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${batchExpiry.day.toString().padLeft(2, '0')}/${batchExpiry.month.toString().padLeft(2, '0')}/${batchExpiry.year}',
                                          style:
                                              PharmaTheme.bodyMedium.copyWith(
                                            fontWeight: isExpiryNear
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isExpiryNear
                                                ? PharmaTheme.warning
                                                : PharmaTheme.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Text('Unknown'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Footer
              Container(
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: PharmaTheme.spacingM),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Batch'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Add batch functionality to be implemented'),
                          ),
                        );
                      },
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

// Helper method for batch statistics cards
  Widget _buildBatchStatCard({
    required IconData icon,
    required String title,
    required String value,
    Color color = PharmaTheme.primary,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(PharmaTheme.spacingS),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: PharmaTheme.spacingS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PharmaTheme.bodySmall.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  value,
                  style: PharmaTheme.headingSmall.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build stat card
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    Color color = PharmaTheme.primary,
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

  Widget _buildDistributorListItem(Distributor distributor) {
    return ListTile(
      title: Text(
        distributor.name,
        style: PharmaTheme.headingSmall,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: PharmaTheme.spacingXxs),
          Row(
            children: [
              const Icon(Icons.email,
                  size: 16, color: PharmaTheme.textSecondary),
              const SizedBox(width: PharmaTheme.spacingXs),
              Expanded(
                child: Text(
                  distributor.email,
                  style: PharmaTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: PharmaTheme.spacingXxs),
          Row(
            children: [
              const Icon(Icons.phone,
                  size: 16, color: PharmaTheme.textSecondary),
              const SizedBox(width: PharmaTheme.spacingXs),
              Text(distributor.contactNumber, style: PharmaTheme.bodySmall),
            ],
          ),
          const SizedBox(height: PharmaTheme.spacingXxs),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: PharmaTheme.textSecondary),
              const SizedBox(width: PharmaTheme.spacingXs),
              Expanded(
                child: Text(
                  distributor.address,
                  style: PharmaTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.medication_outlined),
            tooltip: 'View Medicines',
            onPressed: () => _showDistributorMedicines(
              context,
              distributor.id,
              distributor.name,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () =>
                _showDistributorDialog(context, distributor: distributor),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () => _deleteDistributor(context, distributor),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributorCard(Distributor distributor) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(PharmaTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        distributor.name,
                        style: PharmaTheme.headingSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Options',
                      onSelected: (value) {
                        switch (value) {
                          case 'medicines':
                            _showDistributorMedicines(
                              context,
                              distributor.id,
                              distributor.name,
                            );
                            break;
                          case 'edit':
                            _showDistributorDialog(context,
                                distributor: distributor);
                            break;
                          case 'delete':
                            _deleteDistributor(context, distributor);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'medicines',
                          child: Row(
                            children: [
                              Icon(Icons.medication_outlined),
                              SizedBox(width: PharmaTheme.spacingS),
                              Text('View Medicines'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: PharmaTheme.spacingS),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: PharmaTheme.spacingS),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: PharmaTheme.spacingXs),
                Row(
                  children: [
                    const Icon(Icons.email,
                        size: 16, color: PharmaTheme.textSecondary),
                    const SizedBox(width: PharmaTheme.spacingXs),
                    Expanded(
                      child: Text(
                        distributor.email,
                        style: PharmaTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PharmaTheme.spacingXs),
                Row(
                  children: [
                    const Icon(Icons.phone,
                        size: 16, color: PharmaTheme.textSecondary),
                    const SizedBox(width: PharmaTheme.spacingXs),
                    Text(distributor.contactNumber,
                        style: PharmaTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: PharmaTheme.spacingXs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: PharmaTheme.textSecondary),
                    const SizedBox(width: PharmaTheme.spacingXs),
                    Expanded(
                      child: Text(
                        distributor.address,
                        style: PharmaTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PharmaTheme.spacingXs),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: PharmaTheme.textSecondary),
                    const SizedBox(width: PharmaTheme.spacingXs),
                    Text(
                      'Added on ${distributor.createdAt.day}/${distributor.createdAt.month}/${distributor.createdAt.year}',
                      style: PharmaTheme.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: PharmaTheme.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(PharmaTheme.radiusM),
                bottomRight: Radius.circular(PharmaTheme.radiusM),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: PharmaTheme.spacingXs,
              horizontal: PharmaTheme.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.medication_outlined,
                      color: PharmaTheme.textLight),
                  label: const Text('View Medicines',
                      style: TextStyle(color: PharmaTheme.textLight)),
                  onPressed: () => _showDistributorMedicines(
                    context,
                    distributor.id,
                    distributor.name,
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
