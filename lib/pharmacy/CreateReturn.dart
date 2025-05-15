import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// Keeping the existing model classes
class Sale {
  final String id;
  final String billNumber;
  final Customer customer;
  final List<SaleItem> items;
  final double total;
  final String date;

  Sale({
    required this.id,
    required this.billNumber,
    required this.customer,
    required this.items,
    required this.total,
    required this.date,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    List<SaleItem> saleItems = [];
    if (json['items'] != null) {
      saleItems = List<SaleItem>.from(
          json['items'].map((item) => SaleItem.fromJson(item)));
    }

    return Sale(
      id: json['_id'],
      billNumber: json['billNumber'],
      customer: Customer.fromJson(json['customer']),
      items: saleItems,
      total: json['total'].toDouble(),
      date: DateTime.parse(json['createdAt']).toString(),
    );
  }
}

class SaleItem {
  final String id;
  final Medicine medicine;
  final String batchNumber;
  final String expiryDate;
  final int quantity;
  final double mrp;
  final double totalAmount;

  SaleItem({
    required this.id,
    required this.medicine,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.mrp,
    required this.totalAmount,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['_id'],
      medicine: Medicine.fromJson(json['medicine']),
      batchNumber: json['batchNumber'],
      expiryDate: DateTime.parse(json['expiryDate']).toString(),
      quantity: json['quantity'],
      mrp: json['mrp'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
    );
  }
}

class Medicine {
  final String id;
  final String name;
  final String manufacturer;
  final String category;
  final String description;
  final double mrp;

  Medicine({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.category,
    required this.description,
    required this.mrp,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'],
      name: json['name'],
      manufacturer: json['manufacturer'],
      category: json['category'],
      description: json['description'],
      mrp: json['mrp'].toDouble(),
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String contactNumber;
  final String? email;
  final String? address;
  final bool isPatient;

  Customer({
    required this.id,
    required this.name,
    required this.contactNumber,
    this.email,
    this.address,
    required this.isPatient,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'],
      name: json['name'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      address: json['address'],
      isPatient: json['isPatient'],
    );
  }
}

class ReturnItem {
  final String medicineId;
  final String batchNumber;
  int quantity;
  final double mrp;
  String reason;

  ReturnItem({
    required this.medicineId,
    required this.batchNumber,
    required this.quantity,
    required this.mrp,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicineId': medicineId,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'mrp': mrp,
      'reason': reason,
    };
  }
}

class CreateReturnScreen extends StatefulWidget {
  const CreateReturnScreen({Key? key}) : super(key: key);

  @override
  _CreateReturnScreenState createState() => _CreateReturnScreenState();
}

class _CreateReturnScreenState extends State<CreateReturnScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _billNumberController = TextEditingController();
  final TextEditingController _returnReasonController = TextEditingController();
  final TextEditingController _searchCustomerController =
      TextEditingController();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  List<Sale> _sales = [];
  Customer? _selectedCustomer;
  Sale? _selectedSale;
  List<ReturnItem> _returnItems = [];
  bool _isLoading = false;
  bool _isSalesLoading = false;
  String _searchMessage = '';
  bool _isMobile = false;
  bool _showCustomerPanel = true;

  // Return confirmation view variables
  bool _showReturnConfirmation = false;
  Map<String, dynamic>? _returnData;

  // Modern color palette
  final Color primaryColor = const Color(0xFF2D5AB9);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color cardColor = Colors.white;
  final Color textColorPrimary = const Color(0xFF333333);
  final Color textColorSecondary = const Color(0xFF7A869A);
  final Color borderColor = const Color(0xFFEAECF0);
  final Color errorColor = const Color(0xFFE53935);
  final Color successColor = const Color(0xFF43A047);

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    // Initialize date controllers with current date range (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    _startDateController.text = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(now);

    // Initially set filtered customers to all customers
    _filteredCustomers = _customers;
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers
            .where((customer) =>
                customer.name.toLowerCase().contains(query.toLowerCase()) ||
                customer.contactNumber.contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/pharma/getCustomers'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _customers = List<Customer>.from(
                data['data'].map((customer) => Customer.fromJson(customer)));
            _filteredCustomers = _customers;
          });
        } else {
          _showErrorSnackBar('Failed to load customers: ${data['message']}');
        }
      } else {
        _showErrorSnackBar('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _searchSales() async {
    if (_selectedCustomer == null) {
      setState(() {
        _searchMessage = 'Please select a customer first';
      });
      return;
    }

    setState(() {
      _isSalesLoading = true;
      _sales = [];
      _selectedSale = null;
      _returnItems = [];
      _searchMessage = '';
      _showReturnConfirmation = false; // Hide confirmation if visible
    });

    try {
      final Uri uri = Uri.parse('${BASE_URL}/pharma/getSales').replace(
        queryParameters: {
          'startDate': _startDateController.text,
          'endDate': _endDateController.text,
          'customerId': _selectedCustomer!.id,
          'billNumber': _billNumberController.text,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _sales = List<Sale>.from(
                data['data'].map((sale) => Sale.fromJson(sale)));

            if (_sales.isEmpty) {
              _searchMessage = 'No sales found for the selected criteria';
            }
          });
        } else {
          setState(() {
            _searchMessage = 'Failed to load sales: ${data['message']}';
          });
        }
      } else {
        setState(() {
          _searchMessage = 'Failed to load sales: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _searchMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isSalesLoading = false;
      });
    }
  }

  void _onSaleSelected(Sale sale) {
    setState(() {
      _selectedSale = sale;
      _returnItems = [];
      _showReturnConfirmation = false; // Hide confirmation if visible

      // Pre-populate return items from the selected sale
      for (var item in sale.items) {
        _returnItems.add(ReturnItem(
          medicineId: item.medicine.id,
          batchNumber: item.batchNumber,
          quantity: 1, // Default to 1, can be adjusted by user
          mrp: item.mrp,
          reason: '',
        ));
      }
    });
  }

  void _updateReturnItemQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _returnItems.length) {
      final maxQuantity = _selectedSale!.items[index].quantity;

      setState(() {
        _returnItems[index].quantity = newQuantity.clamp(1, maxQuantity);
      });
    }
  }

  void _updateReturnItemReason(int index, String reason) {
    if (index >= 0 && index < _returnItems.length) {
      setState(() {
        _returnItems[index].reason = reason;
      });
    }
  }

  // Show the return confirmation directly in the screen instead of a dialog
  void _showReturnConfirmationInline(Map<String, dynamic> returnData) {
    setState(() {
      _returnData = returnData;
      _showReturnConfirmation = true;
    });

    // Scroll to the top to show the confirmation
    if (_isMobile) {
      Future.delayed(Duration(milliseconds: 100), () {
        Scrollable.ensureVisible(
          _formKey.currentContext!,
          duration: Duration(milliseconds: 300),
        );
      });
    }

    _showSuccessSnackBar('Return created successfully');
  }

  void _startNewReturn() {
    setState(() {
      _showReturnConfirmation = false;
      _returnData = null;
      _selectedSale = null;
      _returnItems = [];
      _returnReasonController.clear();
    });
  }

  void _printReturnReceipt() {
    // Implementation for printing would go here
    _showSuccessSnackBar('Return receipt sent to printer');
  }

  Future<void> _submitReturn() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSale == null) {
        _showErrorSnackBar('Please select a sale');
        return;
      }

      if (_returnItems.isEmpty) {
        _showErrorSnackBar('Please add at least one item to return');
        return;
      }

      // Validate return items
      for (int i = 0; i < _returnItems.length; i++) {
        if (_returnItems[i].reason.isEmpty) {
          _showErrorSnackBar(
              'Please provide a reason for returning ${_selectedSale!.items[i].medicine.name}');
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final body = {
          'saleId': _selectedSale!.id,
          'customerId': _selectedCustomer!.id,
          'items': _returnItems.map((item) => item.toJson()).toList(),
          'reason': _returnReasonController.text,
        };

        final response = await http.post(
          Uri.parse('${BASE_URL}/pharma/createReturn'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            // Show return confirmation inline
            _showReturnConfirmationInline(data['data']);
          } else {
            _showErrorSnackBar('Failed to create return: ${data['message']}');
          }
        } else {
          _showErrorSnackBar('Failed to create return: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorSnackBar('Error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(controller.text)
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textColorPrimary,
            ),
            dialogBackgroundColor: cardColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile device
    _isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Return',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_isMobile)
            IconButton(
              icon: Icon(_showCustomerPanel ? Icons.view_list : Icons.people),
              onPressed: () {
                setState(() {
                  _showCustomerPanel = !_showCustomerPanel;
                });
              },
              tooltip: _showCustomerPanel ? 'Show Sales' : 'Show Customers',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh Data',
          ),
        ],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading data...',
                    style: TextStyle(
                      color: textColorSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              color: backgroundColor,
              child: Form(
                key: _formKey,
                child: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ),
    );
  }

  Widget _buildMobileLayout() {
    if (_showReturnConfirmation && _returnData != null) {
      return _buildReturnConfirmationPanel();
    }

    return _showCustomerPanel
        ? _buildCustomerListPanel()
        : _buildReturnFormPanel();
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - Customer List
        if (!_showReturnConfirmation) // Hide customer list when showing confirmation
          SizedBox(
            width: 320,
            child: _buildCustomerListPanel(),
          ),

        // Right panel - Return Form or Confirmation
        Expanded(
          child: _showReturnConfirmation && _returnData != null
              ? _buildReturnConfirmationPanel()
              : _buildReturnFormPanel(),
        ),
      ],
    );
  }

  Widget _buildReturnConfirmationPanel() {
    if (_returnData == null) return SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return Created Successfully',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Return Number: ${_returnData!['returnNumber']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now())}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Return details in cards
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              // Customer details card
              SizedBox(
                width: _isMobile ? double.infinity : 320,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Customer Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                            'Name', _returnData!['customer']['name']),
                        _buildInfoItem('Contact',
                            _returnData!['customer']['contactNumber']),
                        if (_returnData!['customer']['email'] != null)
                          _buildInfoItem(
                              'Email', _returnData!['customer']['email']),
                        if (_returnData!['customer']['address'] != null)
                          _buildInfoItem(
                              'Address', _returnData!['customer']['address']),
                      ],
                    ),
                  ),
                ),
              ),

              // Original sale details card
              SizedBox(
                width: _isMobile ? double.infinity : 320,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Original Sale',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem('Bill Number',
                            _returnData!['originalSale']['billNumber']),
                        _buildInfoItem(
                            'Date',
                            DateFormat('dd/MM/yyyy').format(DateTime.parse(
                                _returnData!['originalSale']['createdAt']))),
                        _buildInfoItem('Total Amount',
                            '₹${_returnData!['originalSale']['total']?.toStringAsFixed(2) ?? '0.00'}'),
                      ],
                    ),
                  ),
                ),
              ),

              // Return summary card
              SizedBox(
                width: _isMobile ? double.infinity : 320,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.summarize, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Return Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                            'Total Items', '${_returnData!['items'].length}'),
                        _buildInfoItem(
                          'Return Amount',
                          '₹${_returnData!['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                          valueColor: primaryColor,
                          valueFontWeight: FontWeight.bold,
                          valueSize: 18,
                        ),
                        const SizedBox(height: 8),
                        if (_returnData!['reason'] != null &&
                            _returnData!['reason'].toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Reason:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColorSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  _returnData!['reason'],
                                  style: TextStyle(color: textColorPrimary),
                                ),
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

          const SizedBox(height: 32),

          // Returned items
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Returned Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _returnData!['items'].length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _returnData!['items'][index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item['medicine']['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColorPrimary,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Batch: ${item['batchNumber']}',
                            style: TextStyle(color: textColorSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reason: ${item['reason']}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: textColorSecondary,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Qty: ${item['quantity']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${(item['mrp'] * item['quantity']).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColorPrimary,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _startNewReturn,
                icon: const Icon(Icons.refresh),
                label: const Text('Create New Return'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _printReturnReceipt,
                icon: const Icon(Icons.print),
                label: const Text('Print Receipt'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
              if (_returnData!['pdfLink'] != null) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Launch PDF link
                    // launchUrl(Uri.parse(_returnData!['pdfLink']));
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildCustomerListPanel() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Customer List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search field
                TextFormField(
                  controller: _searchCustomerController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: Icon(Icons.search, color: textColorSecondary),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  onChanged: _filterCustomers,
                ),

                // Date filters
                const SizedBox(height: 16),
                Text(
                  'Date Range',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColorPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(_startDateController, 'From'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateField(_endDateController, 'To'),
                    ),
                  ],
                ),

                // Bill number search
                const SizedBox(height: 16),
                TextFormField(
                  controller: _billNumberController,
                  decoration: InputDecoration(
                    labelText: 'Bill Number',
                    hintText: 'Enter bill #',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    prefixIcon: Icon(Icons.receipt, color: textColorSecondary),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),

                // Search button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _searchSales,
                    icon: const Icon(Icons.search),
                    label: const Text('Search Sales'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: primaryColor,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: _filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 48,
                          color: textColorSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: TextStyle(
                            color: textColorSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemCount: _filteredCustomers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: borderColor,
                    ),
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      final isSelected = _selectedCustomer?.id == customer.id;

                      return Material(
                        color: isSelected
                            ? primaryColor.withOpacity(0.1)
                            : cardColor,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCustomer = customer;
                              if (_isMobile) {
                                _showCustomerPanel = false;
                              }
                            });
                            // Auto-search sales when customer is selected
                            _searchSales();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? primaryColor
                                        : accentColor.withOpacity(0.2),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      customer.isPatient
                                          ? Icons.personal_injury
                                          : Icons.person,
                                      color: isSelected
                                          ? Colors.white
                                          : accentColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColorPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        customer.contactNumber,
                                        style: TextStyle(
                                          color: textColorSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnFormPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected customer card
          if (_selectedCustomer != null) ...[
            _buildSelectedCustomerCard(),
            const SizedBox(height: 24),
          ],

          // Sales selection
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Select Sale',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sales list
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _isSalesLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading sales...',
                                  style: TextStyle(
                                    color: textColorSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _sales.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 48,
                                      color:
                                          textColorSecondary.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchMessage.isEmpty
                                          ? _selectedCustomer == null
                                              ? 'Please select a customer first'
                                              : 'No sales found. Try adjusting the search criteria.'
                                          : _searchMessage,
                                      style: TextStyle(
                                        color: textColorSecondary,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_selectedCustomer != null) ...[
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _searchSales,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Try Again'),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: accentColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 250,
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _sales.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: borderColor,
                                ),
                                itemBuilder: (context, index) {
                                  final sale = _sales[index];
                                  final isSelected =
                                      _selectedSale?.id == sale.id;
                                  final formattedDate =
                                      DateFormat('dd MMM yyyy')
                                          .format(DateTime.parse(sale.date));

                                  return Material(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.1)
                                        : cardColor,
                                    child: InkWell(
                                      onTap: () => _onSaleSelected(sale),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // Sale icon with circular background
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? primaryColor
                                                    : accentColor
                                                        .withOpacity(0.1),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.shopping_bag,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : accentColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Sale details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Bill #${sale.billNumber}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: textColorPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Date: $formattedDate',
                                                    style: TextStyle(
                                                      color: textColorSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${sale.items.length} items',
                                                    style: TextStyle(
                                                      color: textColorSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Price and selection indicator
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: Text(
                                                    '₹${sale.total.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (isSelected)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: successColor
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.check_circle,
                                                          color: successColor,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'Selected',
                                                          style: TextStyle(
                                                            color: successColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
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
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),

          // Return Items
          if (_selectedSale != null) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.undo, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Return Items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Return items table
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade50,
                        ),
                        headingRowHeight: 50,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 80,
                        columns: [
                          DataColumn(
                            label: Text(
                              'Medicine',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Batch',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'MRP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Reason',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                        rows: List.generate(
                          _returnItems.length,
                          (index) {
                            final item = _returnItems[index];
                            final originalItem = _selectedSale!.items[index];
                            final medicineName = originalItem.medicine.name;

                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      medicineName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColorPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(item.batchNumber)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: item.quantity > 1
                                                ? primaryColor
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: item.quantity > 1
                                              ? () => _updateReturnItemQuantity(
                                                  index, item.quantity - 1)
                                              : null,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border:
                                                Border.all(color: borderColor),
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColorPrimary,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add_circle,
                                            color: item.quantity <
                                                    originalItem.quantity
                                                ? primaryColor
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: item.quantity <
                                                  originalItem.quantity
                                              ? () => _updateReturnItemQuantity(
                                                  index, item.quantity + 1)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '₹${item.mrp.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: textColorPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Enter reason',
                                        hintStyle: TextStyle(
                                          color: textColorSecondary
                                              .withOpacity(0.5),
                                          fontSize: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide:
                                              BorderSide(color: borderColor),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        isDense: true,
                                      ),
                                      onChanged: (value) =>
                                          _updateReturnItemReason(index, value),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Total amount calculation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Total Return Amount: ₹${_calculateTotalReturnAmount().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Overall Return Reason
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Return Reason',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _returnReasonController,
                          decoration: InputDecoration(
                            hintText:
                                'Enter the overall reason for this return',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon:
                                Icon(Icons.note_alt, color: textColorSecondary),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an overall reason for the return';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  // Submit Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _submitReturn,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Submit Return'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                _selectedCustomer!.isPatient
                    ? Icons.personal_injury
                    : Icons.person,
                color: primaryColor,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _selectedCustomer!.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColorPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedCustomer!.isPatient
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _selectedCustomer!.isPatient ? 'Patient' : 'Customer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedCustomer!.isPatient
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: textColorSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCustomer!.contactNumber,
                      style: TextStyle(
                        color: textColorSecondary,
                      ),
                    ),
                  ],
                ),
                if (_selectedCustomer!.email != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 16,
                        color: textColorSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCustomer!.email!,
                        style: TextStyle(
                          color: textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_isMobile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _showCustomerPanel = true;
                });
              },
              tooltip: 'Change Customer',
              color: accentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: Icon(Icons.calendar_today, color: textColorSecondary),
        isDense: true,
        fillColor: Colors.white,
        filled: true,
      ),
      readOnly: true,
      onTap: () => _selectDate(context, controller),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    Color? valueColor,
    FontWeight valueFontWeight = FontWeight.normal,
    double valueSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColorSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? textColorPrimary,
              fontWeight: valueFontWeight,
              fontSize: valueSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '${item['label']}:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColorSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['value'] ?? '',
                    style: TextStyle(color: textColorPrimary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  double _calculateTotalReturnAmount() {
    double total = 0;
    for (var item in _returnItems) {
      total += item.mrp * item.quantity;
    }
    return total;
  }
}
