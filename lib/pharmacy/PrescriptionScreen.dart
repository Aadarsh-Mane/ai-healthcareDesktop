import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PrescriptionToSaleScreen extends StatefulWidget {
  const PrescriptionToSaleScreen({Key? key}) : super(key: key);

  @override
  _PrescriptionToSaleScreenState createState() =>
      _PrescriptionToSaleScreenState();
}

class _PrescriptionToSaleScreenState extends State<PrescriptionToSaleScreen> {
  // Color scheme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color warningColor = const Color(0xFFF57C00);
  final Color errorColor = const Color(0xFFD32F2F);
  final Color successColor = const Color(0xFF388E3C);
  Map<String, Map<String, String>> _editedDosages = {};
  bool _isEditingDosage = false;
  // State variables
  bool _isLoading = false;
  bool _isInventoryLoading = false;
  bool _isSaleLoading = false;
  bool _showSuccessCard = false;
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  List<Map<String, dynamic>> _selectedPrescriptions = [];
  List<Map<String, dynamic>> _inventory = [];
  Map<String, List<Map<String, dynamic>>> _medicineInventoryMap = {};
  Map<String, dynamic>? _saleResponse;
  Map<String, bool> _medicineAvailabilityMap = {};
  Map<String, dynamic> _errorResponse = {};

  // Form controllers
  final TextEditingController _daysController =
      TextEditingController(text: '3');
  final TextEditingController _doctorNotesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  String _searchQuery = '';

  // Tab controller for inventory
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
    _fetchInventory();
  }

  // Fetch prescriptions from API
  Future<void> _fetchPrescriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/pharma/getAllPrescriptions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _patients = List<Map<String, dynamic>>.from(data['data']);

            // If there are patients, select the first one by default
            if (_patients.isNotEmpty) {
              _handlePatientSelection(_patients.first);
            }
          });
        }
      } else {
        _showErrorSnackBar('Failed to load prescriptions');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch inventory from API
  Future<void> _fetchInventory({
    String? medicineId,
    String? batchNumber,
    bool? expiringSoon,
  }) async {
    setState(() {
      _isInventoryLoading = true;
    });

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (medicineId != null && medicineId.isNotEmpty) {
        queryParams['medicineId'] = medicineId;
      }
      if (batchNumber != null && batchNumber.isNotEmpty) {
        queryParams['batchNumber'] = batchNumber;
      }
      if (expiringSoon != null) {
        queryParams['expiringSoon'] = expiringSoon.toString();
      }

      // Create URI with query parameters
      final uri = Uri.parse('${BASE_URL}/pharma/getInventory')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _inventory = List<Map<String, dynamic>>.from(data['data']);

            // Group inventory by medicine name for easy lookup
            _medicineInventoryMap = {};
            for (final item in _inventory) {
              final medicine = item['medicine'] as Map<String, dynamic>;
              final medicineName = medicine['name'];

              if (!_medicineInventoryMap.containsKey(medicineName)) {
                _medicineInventoryMap[medicineName] = [];
              }

              _medicineInventoryMap[medicineName]!.add(item);
            }

            // Check availability for selected prescriptions
            _checkMedicineAvailability();
          });
        }
      } else {
        _showErrorSnackBar('Failed to load inventory');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isInventoryLoading = false;
      });
    }
  }

  // Handle patient selection
  void _handlePatientSelection(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
      _selectedPrescriptions =
          List<Map<String, dynamic>>.from(patient['prescriptions'] as List)
              .map((prescription) => {
                    ...prescription,
                    'isSelected': true, // Select all prescriptions by default
                  })
              .toList();

      // Initialize the edited dosages with original values
      _editedDosages = {};
      for (var prescription in _selectedPrescriptions) {
        final id = prescription['_id'] ?? prescription['medicineName'];
        _editedDosages[id] = {
          'morning': prescription['morning'].toString(),
          'afternoon': prescription['afternoon'].toString(),
          'night': prescription['night'].toString(),
        };
      }

      // Check availability for selected medicines
      _checkMedicineAvailability();
    });
  }

  // Check medicine availability for selected prescriptions
  void _checkMedicineAvailability() {
    if (_selectedPrescriptions.isEmpty || _medicineInventoryMap.isEmpty) {
      return;
    }

    final days = int.tryParse(_daysController.text) ?? 3;
    _medicineAvailabilityMap = {};

    for (final prescription in _selectedPrescriptions) {
      if (prescription['isSelected'] != true) continue;

      final medicineName = prescription['medicineName'];
      final requiredQuantity = _calculateTotalQuantity(prescription, days);

      // Check if medicine exists in inventory
      if (!_medicineInventoryMap.containsKey(medicineName)) {
        _medicineAvailabilityMap[medicineName] = false;
        continue;
      }

      // Calculate total available quantity across all batches
      int availableQuantity = 0;
      final inventoryItems = _medicineInventoryMap[medicineName]!;

      for (final item in inventoryItems) {
        availableQuantity += item['quantity'] as int;
      }

      // Check if enough quantity is available
      _medicineAvailabilityMap[medicineName] =
          availableQuantity >= requiredQuantity;
    }
  }

  // Create sale from selected prescriptions
  Future<void> _createSale() async {
    if (_selectedPatient == null) {
      _showErrorSnackBar('Please select a patient');
      return;
    }

    final selectedPrescriptions =
        _selectedPrescriptions.where((p) => p['isSelected'] == true).toList();

    if (selectedPrescriptions.isEmpty) {
      _showErrorSnackBar('Please select at least one prescription');
      return;
    }

    final int days = int.tryParse(_daysController.text) ?? 3;
    if (days <= 0) {
      _showErrorSnackBar('Days must be greater than 0');
      return;
    }

    // Check medicine availability before proceeding
    List<String> unavailableMedicines = [];
    final daysValue = int.tryParse(_daysController.text) ?? 3;

    for (final prescription in selectedPrescriptions) {
      final medicineName = prescription['medicineName'];
      if (_medicineAvailabilityMap[medicineName] == false) {
        unavailableMedicines.add(medicineName);
      }
    }

    if (unavailableMedicines.isNotEmpty) {
      _showUnavailableMedicinesDialog(unavailableMedicines);
      return;
    }

    // Prepare request body
    final requestBody = {
      'patientId': _selectedPatient!['patientId'],
      'patientName': _selectedPatient!['name'],
      'patientContact': _selectedPatient!['contact'],
      'days': days,
      'doctorNotes': _doctorNotesController.text,
      'paymentMethod': _selectedPaymentMethod,
      'prescriptions': selectedPrescriptions.map((prescription) {
        final id = prescription['_id'] ?? prescription['medicineName'];
        final editedDosage = _editedDosages[id];

        return {
          'medicineName': prescription['medicineName'],
          'morning': editedDosage?['morning'] ?? prescription['morning'],
          'afternoon': editedDosage?['afternoon'] ?? prescription['afternoon'],
          'night': editedDosage?['night'] ?? prescription['night'],
          'prescribedDate': prescription['prescribedDate'],
        };
      }).toList(),
    };
    setState(() {
      _isSaleLoading = true;
      _errorResponse = {};
    });

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}/pharma/createSaleFromPatientPrescription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success']) {
          setState(() {
            _saleResponse = data['data'];
            _showSuccessCard = true;
          });
          // Refresh inventory after successful sale
          _fetchInventory();
        } else {
          setState(() {
            _errorResponse = data;
          });
          _showErrorSnackBar(data['message'] ?? 'Failed to create sale');
        }
      } else {
        setState(() {
          _errorResponse = data;
        });

        if (data['message'] ==
                "Cannot create sale. No medicines are available." &&
            data['unavailableMedicines'] != null) {
          final unavailableMedicines =
              List<String>.from(data['unavailableMedicines']);
          _showUnavailableMedicinesDialog(unavailableMedicines);
        } else {
          _showErrorSnackBar(data['message'] ?? 'Failed to create sale');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isSaleLoading = false;
      });
    }
  }

  // Show dialog for unavailable medicines
  void _showUnavailableMedicinesDialog(List<String> unavailableMedicines) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: warningColor),
            SizedBox(width: 8),
            Text('Insufficient Stock'),
          ],
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following medicines have insufficient stock:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: unavailableMedicines.map((medicineName) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: errorColor, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              medicineName,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Please update your inventory or adjust the prescription.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectedTabIndex = 1; // Switch to inventory tab
              setState(() {});
            },
            child: Text('View Inventory'),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Format date
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format date with time
  String _formatDateTime(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy h:mm a').format(date);
  }

  // Calculate days difference between two dates
  int _daysDifference(String date1, String date2) {
    final first = DateTime.parse(date1);
    final second = DateTime.parse(date2);
    return (second.difference(first).inHours / 24).round();
  }

  // Calculate total quantity for a prescription over a certain number of days
  int _calculateTotalQuantity(Map<String, dynamic> prescription, int days) {
    final id = prescription['_id'] ?? prescription['medicineName'];
    final morning = int.tryParse(_editedDosages[id]?['morning'] ??
            prescription['morning'].toString()) ??
        0;
    final afternoon = int.tryParse(_editedDosages[id]?['afternoon'] ??
            prescription['afternoon'].toString()) ??
        0;
    final night = int.tryParse(
            _editedDosages[id]?['night'] ?? prescription['night'].toString()) ??
        0;
    return (morning + afternoon + night) * days;
  }

  Widget _buildEditableDosageChip({
    required String label,
    required String prescriptionId,
    required String dosageKey,
    required String originalDosage,
    required Color color,
  }) {
    final currentDosage =
        _editedDosages[prescriptionId]?[dosageKey] ?? originalDosage;

    return GestureDetector(
      onTap: () {
        if (_isEditingDosage) {
          _showDosageEditDialog(
              prescriptionId, dosageKey, currentDosage, label);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isEditingDosage
              ? color.withOpacity(0.2)
              : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isEditingDosage ? color : color.withOpacity(0.3),
            width: _isEditingDosage ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _isEditingDosage
                    ? color.withOpacity(0.3)
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                currentDosage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                ),
              ),
            ),
            if (_isEditingDosage)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child:
                    Icon(Icons.edit, size: 12, color: color.withOpacity(0.8)),
              ),
          ],
        ),
      ),
    );
  }

  void _showDosageEditDialog(String prescriptionId, String dosageKey,
      String currentValue, String timeLabel) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $timeLabel Dosage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the new dosage for $timeLabel:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Dosage',
                hintText: 'Enter a number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text;
              if (newValue.isNotEmpty && int.tryParse(newValue) != null) {
                setState(() {
                  if (_editedDosages[prescriptionId] == null) {
                    _editedDosages[prescriptionId] = {};
                  }
                  _editedDosages[prescriptionId]![dosageKey] = newValue;
                  _checkMedicineAvailability(); // Recalculate availability
                });
                Navigator.of(context).pop();
              } else {
                // Show error for invalid input
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: errorColor,
                  ),
                );
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Filter patients based on search query
  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _patients;
    }

    return _patients.where((patient) {
      final String name = patient['name'].toString().toLowerCase();
      final String id = patient['patientId'].toString().toLowerCase();
      final String contact = patient['contact'].toString().toLowerCase();
      final String query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          id.contains(query) ||
          contact.contains(query);
    }).toList();
  }

  // Check if medicine is expiring soon
  bool _isExpiringSoon(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      return difference > 0 && difference <= 30;
    } catch (e) {
      return false;
    }
  }

  // Check if medicine is expired
  bool _isExpired(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  // Launch PDF invoice
  void _launchPdf(String url) {
    print('Opening PDF: $url');
    // Implement your PDF opening logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Sale from Prescription',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchPrescriptions();
              _fetchInventory();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading && _isInventoryLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _buildResponsiveLayout(),
    );
  }

  // Responsive layout
  Widget _buildResponsiveLayout() {
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine layout based on screen width
    if (screenWidth < 1200) {
      // Stacked layout for smaller screens
      return _buildStackedLayout();
    } else {
      // Side-by-side layout for larger screens
      return _buildSideBySideLayout();
    }
  }

  // Stacked layout for smaller screens
  Widget _buildStackedLayout() {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTabIndex == 0
                              ? primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Prescriptions',
                        style: TextStyle(
                          color: _selectedTabIndex == 0
                              ? primaryColor
                              : Colors.grey[700],
                          fontWeight: _selectedTabIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTabIndex == 1
                              ? primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Inventory',
                        style: TextStyle(
                          color: _selectedTabIndex == 1
                              ? primaryColor
                              : Colors.grey[700],
                          fontWeight: _selectedTabIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content based on selected tab
        Expanded(
          child: _selectedTabIndex == 0
              ? _buildPrescriptionsTab()
              : _buildInventoryTab(),
        ),
      ],
    );
  }

  // Prescriptions tab content
  Widget _buildPrescriptionsTab() {
    return Column(
      children: [
        // Top section with search and patient list
        Container(
          height: 300,
          color: backgroundColor,
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildPatientsList()),
            ],
          ),
        ),

        // Bottom section with prescription details and create sale form
        Expanded(
          child: _selectedPatient == null
              ? _buildNoPatientSelectedMessage()
              : _showSuccessCard
                  ? _buildSuccessCard()
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPatientDetails(),
                          SizedBox(height: 16),
                          _buildPrescriptionsList(),
                          SizedBox(height: 16),
                          _buildCreateSaleForm(),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  // Inventory tab content
  Widget _buildInventoryTab() {
    return Column(
      children: [
        // Inventory search bar
        _buildInventorySearchBar(),

        // Inventory content
        Expanded(
          child: _isInventoryLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _buildInventoryList(),
        ),
      ],
    );
  }

  // Side-by-side layout for larger screens
  Widget _buildSideBySideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar with patient search and list
        Container(
          width: 400,
          color: backgroundColor,
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildPatientsList()),
            ],
          ),
        ),

        // Main content with tabs
        Expanded(
          child: Column(
            children: [
              // Tab bar
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 0
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Prescriptions',
                              style: TextStyle(
                                color: _selectedTabIndex == 0
                                    ? primaryColor
                                    : Colors.grey[700],
                                fontWeight: _selectedTabIndex == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 1
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Inventory',
                              style: TextStyle(
                                color: _selectedTabIndex == 1
                                    ? primaryColor
                                    : Colors.grey[700],
                                fontWeight: _selectedTabIndex == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content based on selected tab
              Expanded(
                child: _selectedTabIndex == 0
                    ? (_selectedPatient == null
                        ? _buildNoPatientSelectedMessage()
                        : _showSuccessCard
                            ? _buildSuccessCard()
                            : SingleChildScrollView(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPatientDetails(),
                                    SizedBox(height: 24),
                                    _buildPrescriptionsList(),
                                    SizedBox(height: 24),
                                    _buildCreateSaleForm(),
                                  ],
                                ),
                              ))
                    : Column(
                        children: [
                          _buildInventorySearchBar(),
                          Expanded(
                            child: _isInventoryLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: accentColor))
                                : _buildInventoryList(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Search bar for patients
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients by name or ID...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Search bar for inventory
  Widget _buildInventorySearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search inventory...',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      // Implement inventory search
                    },
                  ),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchInventory(expiringSoon: true),
                icon: Icon(Icons.warning_amber_rounded, size: 20),
                label: Text('Expiring Soon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: warningColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _fetchInventory(),
                icon: Icon(Icons.refresh, size: 20),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Patients list
  Widget _buildPatientsList() {
    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _filteredPatients.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        final prescriptions = List.from(patient['prescriptions'] as List);
        final isSelected = _selectedPatient != null &&
            _selectedPatient!['patientId'] == patient['patientId'];

        return Card(
          elevation: isSelected ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          child: InkWell(
            onTap: () => _handlePatientSelection(patient),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar/icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.person,
                          color: isSelected ? primaryColor : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),

                      // Patient details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  patient['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    patient['patientId'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Contact: ${patient['contact']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'From: ${patient['from']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Prescription count
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${prescriptions.length} prescription${prescriptions.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? primaryColor : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Inventory list
  Widget _buildInventoryList() {
    if (_inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No inventory items found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _fetchInventory(),
              icon: Icon(Icons.refresh),
              label: Text('Refresh Inventory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: constraints.maxWidth > 800
              ? _buildInventoryTable()
              : _buildInventoryGrid(),
        );
      },
    );
  }

  // Inventory table for larger screens
  Widget _buildInventoryTable() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status counts
          Row(
            children: [
              _buildStatusCard(
                title: 'Total Items',
                count: _inventory.length,
                icon: Icons.inventory_2_outlined,
                color: primaryColor,
              ),
              SizedBox(width: 16),
              _buildStatusCard(
                title: 'Low Stock',
                count: _inventory.where((item) => item['quantity'] < 10).length,
                icon: Icons.warning_amber_rounded,
                color: warningColor,
              ),
              SizedBox(width: 16),
              _buildStatusCard(
                title: 'Expiring Soon',
                count: _inventory
                    .where((item) => _isExpiringSoon(item['expiryDate']))
                    .length,
                icon: Icons.event_busy,
                color: Colors.orange,
              ),
              SizedBox(width: 16),
              _buildStatusCard(
                title: 'Expired',
                count: _inventory
                    .where((item) => _isExpired(item['expiryDate']))
                    .length,
                icon: Icons.error_outline,
                color: errorColor,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    // Return grey background for even rows
                    if (states.contains(MaterialState.selected)) {
                      return primaryColor.withOpacity(0.1);
                    }
                    return null;
                  },
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'Medicine',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Batch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Stock',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Expiry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'MRP',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Supplier',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _inventory.map((item) {
                  final medicine = item['medicine'] as Map<String, dynamic>;
                  final distributor =
                      item['distributor'] as Map<String, dynamic>;
                  final isExpiringSoon = _isExpiringSoon(item['expiryDate']);
                  final isExpired = _isExpired(item['expiryDate']);
                  final isLowStock = (item['quantity'] as int) < 10;

                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              medicine['name'],
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              medicine['manufacturer'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(item['batchNumber']),
                      ),
                      DataCell(
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? warningColor.withOpacity(0.1)
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['quantity']}',
                            style: TextStyle(
                              color:
                                  isLowStock ? warningColor : Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            if (isExpired || isExpiringSoon)
                              Icon(
                                isExpired
                                    ? Icons.error_outline
                                    : Icons.warning_amber_rounded,
                                color: isExpired ? errorColor : warningColor,
                                size: 16,
                              ),
                            SizedBox(width: 4),
                            Text(
                              _formatDate(item['expiryDate']),
                              style: TextStyle(
                                color: isExpired
                                    ? errorColor
                                    : isExpiringSoon
                                        ? warningColor
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          '₹${medicine['mrp']}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Text(distributor['name']),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Inventory grid for smaller screens
  Widget _buildInventoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status counts in a wrap
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatusCard(
              title: 'Total Items',
              count: _inventory.length,
              icon: Icons.inventory_2_outlined,
              color: primaryColor,
              isSmall: true,
            ),
            _buildStatusCard(
              title: 'Low Stock',
              count: _inventory.where((item) => item['quantity'] < 10).length,
              icon: Icons.warning_amber_rounded,
              color: warningColor,
              isSmall: true,
            ),
            _buildStatusCard(
              title: 'Expiring Soon',
              count: _inventory
                  .where((item) => _isExpiringSoon(item['expiryDate']))
                  .length,
              icon: Icons.event_busy,
              color: Colors.orange,
              isSmall: true,
            ),
            _buildStatusCard(
              title: 'Expired',
              count: _inventory
                  .where((item) => _isExpired(item['expiryDate']))
                  .length,
              icon: Icons.error_outline,
              color: errorColor,
              isSmall: true,
            ),
          ],
        ),

        SizedBox(height: 24),

        // Grid
        Expanded(
          child: ListView.separated(
            itemCount: _inventory.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _inventory[index];
              final medicine = item['medicine'] as Map<String, dynamic>;
              final distributor = item['distributor'] as Map<String, dynamic>;
              final isExpiringSoon = _isExpiringSoon(item['expiryDate']);
              final isExpired = _isExpired(item['expiryDate']);
              final isLowStock = (item['quantity'] as int) < 10;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine name and stock
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicine['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  medicine['manufacturer'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? warningColor.withOpacity(0.1)
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Stock: ${item['quantity']}',
                              style: TextStyle(
                                color: isLowStock
                                    ? warningColor
                                    : Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 24),

                      // Details grid
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _buildDetailItem(
                            label: 'Batch',
                            value: item['batchNumber'],
                          ),
                          _buildDetailItem(
                            label: 'MRP',
                            value: '₹${medicine['mrp']}',
                          ),
                          _buildDetailItem(
                            label: 'Supplier',
                            value: distributor['name'],
                          ),
                          _buildDetailItem(
                            label: 'Expiry',
                            value: _formatDate(item['expiryDate']),
                            valueColor: isExpired
                                ? errorColor
                                : isExpiringSoon
                                    ? warningColor
                                    : null,
                            icon: isExpired || isExpiringSoon
                                ? isExpired
                                    ? Icons.error_outline
                                    : Icons.warning_amber_rounded
                                : null,
                            iconColor: isExpired ? errorColor : warningColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Status card
  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      width: isSmall ? 150 : 170,
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmall ? 18 : 20,
                ),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: isSmall ? 13 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 8 : 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 20 : 24,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Detail item for inventory grid
  Widget _buildDetailItem({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor,
                  size: 14,
                ),
                SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // No patient selected message
  Widget _buildNoPatientSelectedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'Select a patient to create a sale',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Choose a patient from the list on the left',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Patient details card
  Widget _buildPatientDetails() {
    if (_selectedPatient == null) return SizedBox();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Patient Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),

            // Patient information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar/icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 36,
                  ),
                ),
                SizedBox(width: 24),

                // Patient details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedPatient!['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _selectedPatient!['patientId'],
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Info grid - responsive
                      Wrap(
                        spacing: 32,
                        runSpacing: 16,
                        children: [
                          _buildInfoItem(
                            icon: Icons.phone,
                            label: 'Contact',
                            value: _selectedPatient!['contact'],
                          ),
                          _buildInfoItem(
                            icon: Icons.source,
                            label: 'From',
                            value: _selectedPatient!['from'],
                          ),
                          _buildInfoItem(
                            icon: Icons.medication,
                            label: 'Prescriptions',
                            value:
                                '${_selectedPatient!['prescriptions'].length}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Info item
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Prescriptions list
  Widget _buildPrescriptionsList() {
    if (_selectedPatient == null) return SizedBox();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with additional edit button
            Row(
              children: [
                Text(
                  'Prescriptions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Spacer(),
                // Add Toggle Edit Mode button
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditingDosage = !_isEditingDosage;
                    });
                  },
                  icon: Icon(
                    _isEditingDosage ? Icons.edit_off : Icons.edit,
                    size: 18,
                    color: _isEditingDosage ? accentColor : Colors.grey[700],
                  ),
                  label: Text(
                    _isEditingDosage ? 'Exit Edit Mode' : 'Edit Dosages',
                    style: TextStyle(
                      color: _isEditingDosage ? accentColor : Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedPrescriptions = _selectedPrescriptions
                          .map((p) => {
                                ...p,
                                'isSelected': true,
                              })
                          .toList();
                      _checkMedicineAvailability();
                    });
                  },
                  icon: Icon(Icons.select_all, size: 18),
                  label: Text('Select All'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                ),
                SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedPrescriptions = _selectedPrescriptions
                          .map((p) => {
                                ...p,
                                'isSelected': false,
                              })
                          .toList();
                      _checkMedicineAvailability();
                    });
                  },
                  icon: Icon(Icons.deselect, size: 18),
                  label: Text('Deselect All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),

            // Add helper text when in edit mode
            if (_isEditingDosage)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: accentColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap on any dosage chip to modify the dosage amount. This helps when you need to adjust prescriptions based on available inventory.',
                        style: TextStyle(color: accentColor),
                      ),
                    ),
                  ],
                ),
              ),

            // Rest of the prescription list remains the same...
            _selectedPrescriptions.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No prescriptions found for this patient',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive design - use different layouts based on width
                      if (constraints.maxWidth < 800) {
                        // Card layout for smaller screens
                        return Column(
                          children: _selectedPrescriptions
                              .map((prescription) =>
                                  _buildPrescriptionCard(prescription))
                              .toList(),
                        );
                      } else {
                        // Table layout for larger screens
                        return _buildPrescriptionsTable();
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // Prescription card for smaller screens
// Complete remaining code for prescription UI enhancements

// Fix for the prescription card (fixing the right column - quantity information)
  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    final isSelected = prescription['isSelected'] ?? false;
    final medicineName = prescription['medicineName'];
    final prescriptionId = prescription['_id'] ?? medicineName;
    final days = int.tryParse(_daysController.text) ?? 3;
    final requiredQuantity = _calculateTotalQuantity(prescription, days);
    final isAvailable = _medicineAvailabilityMap[medicineName] ?? false;

    // Original dosage values
    final originalMorning =
        int.tryParse(prescription['morning'].toString()) ?? 0;
    final originalAfternoon =
        int.tryParse(prescription['afternoon'].toString()) ?? 0;
    final originalNight = int.tryParse(prescription['night'].toString()) ?? 0;

    // Current values
    final currentMorning = int.tryParse(_editedDosages[prescriptionId]
                ?['morning'] ??
            prescription['morning'].toString()) ??
        0;
    final currentAfternoon = int.tryParse(_editedDosages[prescriptionId]
                ?['afternoon'] ??
            prescription['afternoon'].toString()) ??
        0;
    final currentNight = int.tryParse(_editedDosages[prescriptionId]
                ?['night'] ??
            prescription['night'].toString()) ??
        0;

    // Check if dosage was modified
    final isDosageModified = currentMorning != originalMorning ||
        currentAfternoon != originalAfternoon ||
        currentNight != originalNight;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Toggle selection when tapping the card
          setState(() {
            prescription['isSelected'] = !isSelected;
            _checkMedicineAvailability();
          });
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: primaryColor.withOpacity(0.1),
        highlightColor: primaryColor.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.07),
                      primaryColor.withOpacity(0.02)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with medicine name and checkbox
              Row(
                children: [
                  // Checkbox with ripple effect
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          prescription['isSelected'] = !isSelected;
                          _checkMedicineAvailability();
                        });
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.white,
                            border: Border.all(
                              color:
                                  isSelected ? primaryColor : Colors.grey[400]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 1),
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),

                  // Medicine name with tag if modified
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                medicineName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isDosageModified)
                              Container(
                                margin: EdgeInsets.only(left: 8, top: 2),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Modified',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6),

                        // Prescription date
                        Row(
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Prescribed: ${_formatDate(prescription['prescribedDate'])}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Availability indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isAvailable ? Colors.green[200]! : Colors.red[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color:
                              isAvailable ? Colors.green[600] : Colors.red[600],
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          isAvailable ? 'In Stock' : 'Low Stock',
                          style: TextStyle(
                            color: isAvailable
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),
              Divider(height: 1, thickness: 1, color: Colors.grey[200]),
              SizedBox(height: 16),

              // Dosage information in card layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - dosage chips
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dosage',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildEnhancedDosageChip(
                              label: 'Morning',
                              icon: Icons.wb_sunny_outlined,
                              prescriptionId: prescriptionId,
                              dosageKey: 'morning',
                              originalDosage:
                                  prescription['morning'].toString(),
                              color: Colors.amber[700]!,
                              editable: _isEditingDosage,
                            ),
                            _buildEnhancedDosageChip(
                              label: 'Afternoon',
                              icon: Icons.wb_sunny,
                              prescriptionId: prescriptionId,
                              dosageKey: 'afternoon',
                              originalDosage:
                                  prescription['afternoon'].toString(),
                              color: Colors.orange[700]!,
                              editable: _isEditingDosage,
                            ),
                            _buildEnhancedDosageChip(
                              label: 'Night',
                              icon: Icons.nightlight_round,
                              prescriptionId: prescriptionId,
                              dosageKey: 'night',
                              originalDosage: prescription['night'].toString(),
                              color: Colors.indigo[700]!,
                              editable: _isEditingDosage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right column - quantity information
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Required Quantity',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '$requiredQuantity units',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'For ${days} days',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Show comment if available
              if (prescription['comment'] != null &&
                  prescription['comment'] != '')
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: ${prescription['comment']}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                              fontSize: 13,
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
      ),
    );
  }

  // Enhanced version of the editable dosage chip with better visual design
  Widget _buildEnhancedDosageChip({
    required String label,
    required IconData icon,
    required String prescriptionId,
    required String dosageKey,
    required String originalDosage,
    required Color color,
    required bool editable,
  }) {
    final currentDosage =
        _editedDosages[prescriptionId]?[dosageKey] ?? originalDosage;
    final isModified = currentDosage != originalDosage;

    return GestureDetector(
      onTap: editable
          ? () {
              _showDosageEditDialog(
                  prescriptionId, dosageKey, currentDosage, label);
            }
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(editable ? 0.15 : 0.1),
              color.withOpacity(editable ? 0.07 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isModified
                ? color.withOpacity(0.8)
                : color.withOpacity(editable ? 0.5 : 0.3),
            width: isModified ? 1.5 : 1,
          ),
          boxShadow: editable
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (editable)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.edit,
                      size: 11,
                      color: color.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isModified ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentDosage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                ),
                if (isModified)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Tooltip(
                      message: 'Original: $originalDosage',
                      child: Icon(
                        Icons.change_circle_outlined,
                        size: 14,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Fixed ending of the _buildPrescriptionsTable method
  Widget _buildPrescriptionsTable() {
    final days = int.tryParse(_daysController.text) ?? 3;

    return Column(
      children: [
        // Header buttons for edit options
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isEditingDosage)
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 16,
                      color: accentColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Editing Mode Active',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isEditingDosage = !_isEditingDosage;
                });
              },
              icon: Icon(
                _isEditingDosage ? Icons.edit_off : Icons.edit,
                size: 18,
                color: _isEditingDosage ? accentColor : Colors.grey[700],
              ),
              label: Text(
                _isEditingDosage ? 'Exit Edit Mode' : 'Edit Dosages',
                style: TextStyle(
                  color: _isEditingDosage ? accentColor : Colors.grey[700],
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: _isEditingDosage
                        ? accentColor.withOpacity(0.5)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                backgroundColor: _isEditingDosage
                    ? accentColor.withOpacity(0.1)
                    : Colors.transparent,
              ),
            ),
            SizedBox(width: 12),
            if (_isEditingDosage)
              TextButton.icon(
                onPressed: () {
                  // Reset to original dosages
                  setState(() {
                    _editedDosages = {};
                    for (var prescription in _selectedPrescriptions) {
                      final id =
                          prescription['_id'] ?? prescription['medicineName'];
                      _editedDosages[id] = {
                        'morning': prescription['morning'].toString(),
                        'afternoon': prescription['afternoon'].toString(),
                        'night': prescription['night'].toString(),
                      };
                    }
                    _checkMedicineAvailability();
                  });
                },
                icon: Icon(Icons.restore, size: 18, color: warningColor),
                label: Text('Reset Dosages',
                    style: TextStyle(color: warningColor)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: warningColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  backgroundColor: warningColor.withOpacity(0.05),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),

        // Help text for editing mode
        if (_isEditingDosage)
          Container(
            margin: EdgeInsets.only(bottom: 16, top: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: accentColor, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap on any dosage chip to modify the amount. This helps when you need to adjust prescriptions based on available inventory.',
                    style: TextStyle(
                      color: accentColor.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Enhanced data table with better styling
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 5,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.grey[200],
                dataTableTheme: DataTableThemeData(
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 14,
                  ),
                  dataTextStyle: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 16,
                headingRowHeight: 56,
                dataRowHeight: 84,
                headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                dividerThickness: 1,
                showCheckboxColumn: false,
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return primaryColor.withOpacity(0.07);
                    }
                    return null;
                  },
                ),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                columns: [
                  DataColumn(
                    label: Text('Select'),
                  ),
                  DataColumn(
                    label: Text('Medicine Name'),
                  ),
                  DataColumn(
                    label: Text('Dosage'),
                  ),
                  DataColumn(
                    label: Text('Required Qty'),
                  ),
                  DataColumn(
                    label: Text('Availability'),
                  ),
                  DataColumn(
                    label: Text('Prescribed Date'),
                  ),
                ],
                rows: _selectedPrescriptions.map((prescription) {
                  final isSelected = prescription['isSelected'] ?? false;
                  final medicineName = prescription['medicineName'];
                  final prescriptionId = prescription['_id'] ?? medicineName;
                  final requiredQuantity =
                      _calculateTotalQuantity(prescription, days);
                  final isAvailable =
                      _medicineAvailabilityMap[medicineName] ?? false;

                  // Check if dosage is modified
                  final originalMorning =
                      int.tryParse(prescription['morning'].toString()) ?? 0;
                  final originalAfternoon =
                      int.tryParse(prescription['afternoon'].toString()) ?? 0;
                  final originalNight =
                      int.tryParse(prescription['night'].toString()) ?? 0;

                  final currentMorning = int.tryParse(
                          _editedDosages[prescriptionId]?['morning'] ??
                              prescription['morning'].toString()) ??
                      0;
                  final currentAfternoon = int.tryParse(
                          _editedDosages[prescriptionId]?['afternoon'] ??
                              prescription['afternoon'].toString()) ??
                      0;
                  final currentNight = int.tryParse(
                          _editedDosages[prescriptionId]?['night'] ??
                              prescription['night'].toString()) ??
                      0;

                  final isDosageModified = currentMorning != originalMorning ||
                      currentAfternoon != originalAfternoon ||
                      currentNight != originalNight;

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (value) {
                      setState(() {
                        prescription['isSelected'] = value;
                        _checkMedicineAvailability();
                      });
                    },
                    cells: [
                      DataCell(
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  prescription['isSelected'] = !isSelected;
                                  _checkMedicineAvailability();
                                });
                              },
                              borderRadius: BorderRadius.circular(50),
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  primaryColor.withOpacity(0.3),
                                              blurRadius: 5,
                                              offset: Offset(0, 1),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                medicineName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDosageModified)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Modified',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 6,
                            children: [
                              _buildTableDosageChip(
                                label: 'M',
                                icon: Icons.wb_sunny_outlined,
                                dosage: _editedDosages[prescriptionId]
                                        ?['morning'] ??
                                    prescription['morning'].toString(),
                                isOriginal: (_editedDosages[prescriptionId]
                                            ?['morning'] ??
                                        prescription['morning'].toString()) ==
                                    prescription['morning'].toString(),
                                color: Colors.amber[700]!,
                                prescriptionId: prescriptionId,
                                dosageKey: 'morning',
                                editable: _isEditingDosage,
                              ),
                              _buildTableDosageChip(
                                label: 'A',
                                icon: Icons.wb_sunny,
                                dosage: _editedDosages[prescriptionId]
                                        ?['afternoon'] ??
                                    prescription['afternoon'].toString(),
                                isOriginal: (_editedDosages[prescriptionId]
                                            ?['afternoon'] ??
                                        prescription['afternoon'].toString()) ==
                                    prescription['afternoon'].toString(),
                                color: Colors.orange[700]!,
                                prescriptionId: prescriptionId,
                                dosageKey: 'afternoon',
                                editable: _isEditingDosage,
                              ),
                              _buildTableDosageChip(
                                label: 'N',
                                icon: Icons.nightlight_round,
                                dosage: _editedDosages[prescriptionId]
                                        ?['night'] ??
                                    prescription['night'].toString(),
                                isOriginal: (_editedDosages[prescriptionId]
                                            ?['night'] ??
                                        prescription['night'].toString()) ==
                                    prescription['night'].toString(),
                                color: Colors.indigo[700]!,
                                prescriptionId: prescriptionId,
                                dosageKey: 'night',
                                editable: _isEditingDosage,
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            '$requiredQuantity units',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                isAvailable ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAvailable
                                  ? Colors.green[200]!
                                  : Colors.red[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: isAvailable
                                    ? Colors.green[600]
                                    : Colors.red[600],
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                isAvailable ? 'Available' : 'Low Stock',
                                style: TextStyle(
                                  color: isAvailable
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6),
                            Text(
                              _formatDate(prescription['prescribedDate']),
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

// Dosage chip for the data table with compact design
  Widget _buildTableDosageChip({
    required String label,
    required IconData icon,
    required String dosage,
    required bool isOriginal,
    required Color color,
    required String prescriptionId,
    required String dosageKey,
    required bool editable,
  }) {
    return GestureDetector(
      onTap: editable
          ? () {
              _showDosageEditDialog(prescriptionId, dosageKey, dosage, label);
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(isOriginal ? 0.08 : 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withOpacity(isOriginal ? 0.3 : 0.6),
            width: isOriginal ? 1 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: color,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dosage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (editable)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.edit,
                  size: 10,
                  color: color.withOpacity(0.7),
                ),
              ),
            if (!isOriginal)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Tooltip(
                  message: 'Modified from original',
                  child: Icon(
                    Icons.change_history,
                    size: 10,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Dosage chip
  Widget _buildDosageChip({
    required String label,
    required String dosage,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dosage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Create sale form
  Widget _buildCreateSaleForm() {
    if (_selectedPatient == null) return SizedBox();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create Sale',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),

            // Display error message if any
            if (_errorResponse.isNotEmpty && _errorResponse['message'] != null)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: errorColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: errorColor,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorResponse['message'],
                        style: TextStyle(
                          color: errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form fields
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Days and Payment Method
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDaysField()),
                          SizedBox(width: 16),
                          Expanded(child: _buildPaymentMethodField()),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDaysField(),
                          SizedBox(height: 16),
                          _buildPaymentMethodField(),
                        ],
                      ),

                    SizedBox(height: 16),

                    // Doctor Notes
                    _buildDoctorNotesField(),

                    SizedBox(height: 24),

                    // Prescription summary
                    _buildPrescriptionSummary(),

                    SizedBox(height: 24),

                    // Create sale button
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        onPressed:
                            _areAnyPrescriptionsSelected() && !_isSaleLoading
                                ? _createSale
                                : null,
                        icon: _isSaleLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.shopping_cart_checkout),
                        label: Text(
                          _isSaleLoading ? 'Creating Sale...' : 'Create Sale',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Check if any prescriptions are selected
  bool _areAnyPrescriptionsSelected() {
    return _selectedPrescriptions.any((p) => p['isSelected'] == true);
  }

  // Days field
  Widget _buildDaysField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Days',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter number of days',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              suffixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'days',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              // Recalculate medicine availability when days change
              setState(() {
                _checkMedicineAvailability();
              });
            },
          ),
        ),
      ],
    );
  }

  // Payment method field
  Widget _buildPaymentMethodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedPaymentMethod,
              icon: Icon(Icons.arrow_drop_down, color: primaryColor),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                }
              },
              items: [
                _buildPaymentMethodItem('cash', Icons.money, 'Cash'),
                _buildPaymentMethodItem('card', Icons.credit_card, 'Card'),
                _buildPaymentMethodItem('upi', Icons.account_balance, 'UPI'),
                _buildPaymentMethodItem('credit', Icons.event_note, 'Credit'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Payment method dropdown item
  DropdownMenuItem<String> _buildPaymentMethodItem(
    String value,
    IconData icon,
    String label,
  ) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Doctor notes field
  Widget _buildDoctorNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor Notes',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _doctorNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter doctor notes (optional)',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // Prescription summary
  Widget _buildPrescriptionSummary() {
    final days = int.tryParse(_daysController.text) ?? 3;
    final selectedPrescriptions = _selectedPrescriptions
        .where((prescription) => prescription['isSelected'] == true)
        .toList();

    if (selectedPrescriptions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No prescriptions selected',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedPrescriptions.length} prescription${selectedPrescriptions.length > 1 ? 's' : ''} selected',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'For $days days',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),

              // Medicine list with quantities and modified indicator
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;

                  return Column(
                    children: selectedPrescriptions.map((prescription) {
                      final medicineName = prescription['medicineName'];
                      final prescriptionId =
                          prescription['_id'] ?? medicineName;
                      final totalQuantity =
                          _calculateTotalQuantity(prescription, days);

                      // Original values
                      final originalMorning =
                          int.tryParse(prescription['morning'].toString()) ?? 0;
                      final originalAfternoon =
                          int.tryParse(prescription['afternoon'].toString()) ??
                              0;
                      final originalNight =
                          int.tryParse(prescription['night'].toString()) ?? 0;

                      // Current values
                      final currentMorning = int.tryParse(
                              _editedDosages[prescriptionId]?['morning'] ??
                                  prescription['morning'].toString()) ??
                          0;
                      final currentAfternoon = int.tryParse(
                              _editedDosages[prescriptionId]?['afternoon'] ??
                                  prescription['afternoon'].toString()) ??
                          0;
                      final currentNight = int.tryParse(
                              _editedDosages[prescriptionId]?['night'] ??
                                  prescription['night'].toString()) ??
                          0;

                      // Check if dosage was modified
                      final isDosageModified =
                          currentMorning != originalMorning ||
                              currentAfternoon != originalAfternoon ||
                              currentNight != originalNight;

                      final isAvailable =
                          _medicineAvailabilityMap[medicineName] ?? false;

                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Icon(
                                          isAvailable
                                              ? Icons.check_circle
                                              : Icons.error_outline,
                                          color: isAvailable
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  medicineName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (isDosageModified)
                                                Container(
                                                  margin:
                                                      EdgeInsets.only(left: 8),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: accentColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Modified',
                                                    style: TextStyle(
                                                      color: accentColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${currentMorning}-${currentAfternoon}-${currentNight}',
                                          style: TextStyle(
                                            color: isDosageModified
                                                ? accentColor
                                                : Colors.grey[700],
                                            fontWeight: isDosageModified
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (isDosageModified)
                                          Tooltip(
                                            message:
                                                'Original: ${originalMorning}-${originalAfternoon}-${originalNight}',
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(Icons.edit,
                                                  size: 14, color: accentColor),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$totalQuantity units',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isAvailable
                                            ? Icons.check_circle
                                            : Icons.error_outline,
                                        color: isAvailable
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                medicineName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            if (isDosageModified)
                                              Container(
                                                margin:
                                                    EdgeInsets.only(left: 8),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: accentColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Modified',
                                                  style: TextStyle(
                                                    color: accentColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Dosage: ',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${currentMorning}-${currentAfternoon}-${currentNight}',
                                            style: TextStyle(
                                              color: isDosageModified
                                                  ? accentColor
                                                  : Colors.grey[700],
                                              fontWeight: isDosageModified
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (isDosageModified)
                                            Tooltip(
                                              message:
                                                  'Original: ${originalMorning}-${originalAfternoon}-${originalNight}',
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(left: 4),
                                                child: Icon(Icons.edit,
                                                    size: 14,
                                                    color: accentColor),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$totalQuantity units',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      );
                    }).toList(),
                  );
                },
              ),

              SizedBox(height: 16),

              // Availability warning and modified dosage notice
              Column(
                children: [
                  if (_editedDosages.values
                      .any((dosages) => dosages.isNotEmpty))
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.edit_note,
                            color: accentColor,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dosage Modifications Applied',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'You have modified the original prescription dosages to better match available inventory.',
                                  style: TextStyle(
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedPrescriptions.any((p) =>
                      _medicineAvailabilityMap[p['medicineName']] == false))
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: warningColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: warningColor,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Some medicines may not have sufficient stock',
                                  style: TextStyle(
                                    color: warningColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Please verify inventory before proceeding, adjust the number of days, or modify dosages.',
                                  style: TextStyle(
                                    color: warningColor,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedTabIndex =
                                              1; // Switch to inventory tab
                                        });
                                      },
                                      icon: Icon(Icons.inventory_2, size: 14),
                                      label: Text('View Inventory'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    if (!_isEditingDosage)
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _isEditingDosage = true;
                                          });
                                        },
                                        icon: Icon(Icons.edit, size: 14),
                                        label: Text('Modify Dosages'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: accentColor,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All selected medicines are available in sufficient quantity.',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _convertToDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Success card
  Widget _buildSuccessCard() {
    if (_saleResponse == null) return SizedBox();

    final sale = _saleResponse!;
    final items = List<Map<String, dynamic>>.from(sale['items']);
    final customer = sale['customer'] as Map<String, dynamic>;

    return Container(
      margin: EdgeInsets.all(24),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sale Created Successfully',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Invoice #: ${sale['billNumber']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _launchPdf(sale['pdfLink']),
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('View Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green[700],
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            // Sale details
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sale info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          customer['contactNumber'],
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Date info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _formatDateTime(sale['createdAt']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 24),

                    // Items
                    Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Items table
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;

                        if (isWide) {
                          return DataTable(
                            columnSpacing: 16,
                            headingRowColor:
                                MaterialStateProperty.all(Colors.grey[100]),
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Medicine',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Batch',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Quantity',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Price',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: items.map((item) {
                              final medicine =
                                  item['medicine'] as Map<String, dynamic>;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          medicine['name'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${medicine['manufacturer']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(item['batchNumber']),
                                  ),
                                  DataCell(
                                    Text(
                                      item['quantity'].toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                        '₹${_convertToDouble(item['mrp']).toStringAsFixed(2)}'),
                                  ),
                                  DataCell(
                                    Text(
                                      '₹${_convertToDouble(item['totalAmount']).toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        } else {
                          return Column(
                            children: items.map((item) {
                              final medicine =
                                  item['medicine'] as Map<String, dynamic>;

                              return Card(
                                margin: EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Manufacturer:',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(medicine['manufacturer']),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Batch:',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(item['batchNumber']),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Quantity:',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            item['quantity'].toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Price:',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                              '₹${_convertToDouble(item['mrp']).toStringAsFixed(2)}'),
                                        ],
                                      ),
                                      Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '₹${_convertToDouble(item['totalAmount']).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),

                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 16),

                    // Summary
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal'),
                              Text(
                                  '₹${_convertToDouble(sale['subtotal']).toStringAsFixed(2)}'),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (sale['discount'] > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount'),
                                Text(
                                  '-₹${_convertToDouble(sale['discount']).toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                          ],
                          if (sale['tax'] > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax (${sale['tax']}%)'),
                                Text(
                                    '₹${(_convertToDouble(sale['subtotal']) * _convertToDouble(sale['tax']) / 100).toStringAsFixed(2)}'),
                              ],
                            ),
                            SizedBox(height: 8),
                          ],
                          Divider(),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '₹${_convertToDouble(sale['total']).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showSuccessCard = false;
                        _saleResponse = null;
                      });
                    },
                    icon: Icon(Icons.arrow_back),
                    label: Text('Back to Prescriptions'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Reset form and fetch fresh data
                      setState(() {
                        _showSuccessCard = false;
                        _saleResponse = null;
                        _selectedPatient = null;
                        _selectedPrescriptions = [];
                        _daysController.text = '3';
                        _doctorNotesController.clear();
                      });
                      _fetchPrescriptions();
                      _fetchInventory();
                    },
                    icon: Icon(Icons.add_shopping_cart),
                    label: Text('Create New Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
