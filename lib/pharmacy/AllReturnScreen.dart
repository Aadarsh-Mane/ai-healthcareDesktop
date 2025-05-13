import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Reusing model classes from CreateReturnScreen
class Return {
  final String id;
  final String returnNumber;
  final Sale originalSale;
  final Customer customer;
  final List<ReturnItem> items;
  final double totalAmount;
  final String createdAt;
  final String? pdfLink;

  Return({
    required this.id,
    required this.returnNumber,
    required this.originalSale,
    required this.customer,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.pdfLink,
  });

  factory Return.fromJson(Map<String, dynamic> json) {
    try {
      return Return(
        id: json['_id'] ?? '',
        returnNumber: json['returnNumber'] ?? '',
        originalSale: json['originalSale'] is Map<String, dynamic>
            ? Sale.fromJson(json['originalSale'])
            : Sale.fromJson({
                '_id': '',
                'billNumber': '',
                'customer': {},
                'items': [],
                'subtotal': 0,
                'discount': 0,
                'tax': 0,
                'total': 0,
                'paymentMethod': '',
                'createdAt': DateTime.now().toIso8601String(),
              }),
        customer: json['customer'] is Map<String, dynamic>
            ? Customer.fromJson(json['customer'])
            : Customer.fromJson({
                '_id': '',
                'name': '',
                'contactNumber': '',
                'isPatient': false,
              }),
        items: json['items'] is List
            ? List<ReturnItem>.from((json['items'] as List)
                .map((item) => ReturnItem.fromJson(item)))
            : [],
        totalAmount: (json['totalAmount'] ?? 0).toDouble(),
        createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
        pdfLink: json['pdfLink'],
      );
    } catch (e) {
      print('Error in Return.fromJson: $e for json: $json');
      // Return a default Return object in case of error
      return Return(
        id: json['_id'] ?? '',
        returnNumber: json['returnNumber'] ?? '',
        originalSale: Sale.fromJson({
          '_id': '',
          'billNumber': '',
          'customer': {},
          'items': [],
          'subtotal': 0,
          'discount': 0,
          'tax': 0,
          'total': 0,
          'paymentMethod': '',
          'createdAt': DateTime.now().toIso8601String(),
        }),
        customer: Customer.fromJson({
          '_id': '',
          'name': '',
          'contactNumber': '',
          'isPatient': false,
        }),
        items: [],
        totalAmount: 0.0,
        createdAt: DateTime.now().toIso8601String(),
        pdfLink: null,
      );
    }
  }
}

class Sale {
  final String id;
  final String billNumber;
  final Customer customer;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final String createdAt;
  final String? pdfLink;

  Sale({
    required this.id,
    required this.billNumber,
    required this.customer,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.pdfLink,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    try {
      return Sale(
        id: json['_id'] ?? '',
        billNumber: json['billNumber'] ?? '',
        customer: json['customer'] is Map<String, dynamic>
            ? Customer.fromJson(json['customer'])
            : Customer.fromJson({
                '_id': json['customer'] ?? '',
                'name': '',
                'contactNumber': '',
                'isPatient': false
              }),
        items: json['items'] is List
            ? List<SaleItem>.from(
                (json['items'] as List).map((item) => SaleItem.fromJson(item)))
            : [],
        subtotal: (json['subtotal'] ?? 0).toDouble(),
        discount: (json['discount'] ?? 0).toDouble(),
        tax: (json['tax'] ?? 0).toDouble(),
        total: (json['total'] ?? 0).toDouble(),
        paymentMethod: json['paymentMethod'] ?? 'cash',
        createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
        pdfLink: json['pdfLink'],
      );
    } catch (e) {
      print('Error in Sale.fromJson: $e for json: $json');
      // Return a default Sale object in case of error
      return Sale(
        id: '',
        billNumber: '',
        customer: Customer.fromJson(
            {'_id': '', 'name': '', 'contactNumber': '', 'isPatient': false}),
        items: [],
        subtotal: 0,
        discount: 0,
        tax: 0,
        total: 0,
        paymentMethod: 'cash',
        createdAt: DateTime.now().toIso8601String(),
        pdfLink: null,
      );
    }
  }
}

class SaleItem {
  final String id;
  final Medicine medicine;
  final String inventory;
  final String batchNumber;
  final String expiryDate;
  final int quantity;
  final double mrp;
  final double discount;
  final double totalAmount;

  SaleItem({
    required this.id,
    required this.medicine,
    required this.inventory,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.mrp,
    required this.discount,
    required this.totalAmount,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['_id'] ?? '',
      medicine: json['medicine'] is Map<String, dynamic>
          ? Medicine.fromJson(json['medicine'])
          : Medicine.fromJson({
              '_id': json['medicine'],
              'name': '',
              'manufacturer': '',
              'category': '',
              'description': '',
              'mrp': 0.0,
              'purchasePrice': 0.0
            }),
      inventory: json['inventory'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] ?? DateTime.now().toIso8601String(),
      quantity: json['quantity'] ?? 0,
      mrp: (json['mrp'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class ReturnItem {
  final String id;
  final Medicine medicine;
  final String inventory;
  final String batchNumber;
  final int quantity;
  final double mrp;
  final double totalAmount;
  final String reason;

  ReturnItem({
    required this.id,
    required this.medicine,
    required this.inventory,
    required this.batchNumber,
    required this.quantity,
    required this.mrp,
    required this.totalAmount,
    required this.reason,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      id: json['_id'],
      medicine: json['medicine'] is Map<String, dynamic>
          ? Medicine.fromJson(json['medicine'])
          : Medicine.fromJson({
              '_id': json['medicine'],
              'name': '',
              'manufacturer': '',
              'category': '',
              'description': '',
              'mrp': 0.0,
              'purchasePrice': 0.0
            }),
      inventory: json['inventory'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      quantity: json['quantity'] ?? 0,
      mrp: (json['mrp'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
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
  final double purchasePrice;

  Medicine({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.category,
    required this.description,
    required this.mrp,
    required this.purchasePrice,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'],
      name: json['name'],
      manufacturer: json['manufacturer'],
      category: json['category'],
      description: json['description'],
      mrp: json['mrp'].toDouble(),
      purchasePrice: json['purchasePrice'].toDouble(),
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
    try {
      return Customer(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        contactNumber: json['contactNumber'] ?? '',
        email: json['email'],
        address: json['address'],
        isPatient: json['isPatient'] ?? false,
      );
    } catch (e) {
      print('Error in Customer.fromJson: $e for json: $json');
      // Return a default Customer object in case of error
      return Customer(
        id: '',
        name: '',
        contactNumber: '',
        isPatient: false,
      );
    }
  }
}

class FilterOptions {
  String? startDate;
  String? endDate;
  String? customerId;
  String? returnNumber;
  String? saleId;

  FilterOptions({
    this.startDate,
    this.endDate,
    this.customerId,
    this.returnNumber,
    this.saleId,
  });

  Map<String, String> toQueryParameters() {
    Map<String, String> params = {};
    if (startDate != null && startDate!.isNotEmpty)
      params['startDate'] = startDate!;
    if (endDate != null && endDate!.isNotEmpty) params['endDate'] = endDate!;
    if (customerId != null && customerId!.isNotEmpty)
      params['customerId'] = customerId!;
    if (returnNumber != null && returnNumber!.isNotEmpty)
      params['returnNumber'] = returnNumber!;
    if (saleId != null && saleId!.isNotEmpty) params['saleId'] = saleId!;
    return params;
  }
}

class AllReturnsScreen extends StatefulWidget {
  const AllReturnsScreen({Key? key}) : super(key: key);

  @override
  _AllReturnsScreenState createState() => _AllReturnsScreenState();
}

class _AllReturnsScreenState extends State<AllReturnsScreen> {
  // Colors
  final Color primaryColor = const Color(0xFF2D5AB9);
  final Color accentColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFF7F9FB);
  final Color cardColor = Colors.white;
  final Color textColorPrimary = const Color(0xFF333333);
  final Color textColorSecondary = const Color(0xFF7A869A);
  final Color borderColor = const Color(0xFFEAECF0);
  final Color errorColor = const Color(0xFFE53935);
  final Color successColor = const Color(0xFF43A047);

  // Controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _returnNumberController = TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();
  Timer? _debounceTimer;
  // Data state
  List<Return> _returns = [];
  List<Return> _filteredReturns = [];
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];

  // UI state
  bool _isLoading = false;
  bool _isLoadingCustomers = false;
  bool _isMobile = false;
  bool _showFilterPanel = true;
  bool _hasAppliedFilters = false;

  // Selected data
  Customer? _selectedCustomer;
  Return? _selectedReturn;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalReturns = 0;
  bool _hasMorePages = false;

  // Filter options
  FilterOptions _filterOptions = FilterOptions();

  // Return detail view
  bool _showReturnDetail = false;

  void initState() {
    super.initState();

    // Initialize date controllers with last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    _startDateController.text = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(now);

    _filterOptions.startDate = _startDateController.text;
    _filterOptions.endDate = _endDateController.text;

    // Add listener to return number controller for auto-filtering
    _returnNumberController.addListener(_onReturnNumberChanged);

    // Load initial data
    _loadCustomers();
    _loadReturns();
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

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/pharma/getCustomers'),
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
      _showErrorSnackBar('Error loading customers: $e');
    } finally {
      setState(() {
        _isLoadingCustomers = false;
      });
    }
  }

  Future<void> _loadReturns({bool resetPage = true}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
      if (resetPage) {
        _returns = [];
        _filteredReturns = [];
      }
    });

    try {
      // Build query parameters
      Map<String, String> queryParams = _filterOptions.toQueryParameters();

      // Add pagination parameters
      queryParams['page'] = _currentPage.toString();
      queryParams['limit'] = _pageSize.toString();

      final Uri uri = Uri.parse('http://localhost:5001/pharma/getReturns')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final newReturns = List<Return>.from(
              data['data'].map((returnData) => Return.fromJson(returnData)));

          setState(() {
            if (resetPage) {
              _returns = newReturns;
            } else {
              _returns.addAll(newReturns);
            }

            _filteredReturns = List.from(_returns);
            _totalReturns = data['count'];
            _hasMorePages = _returns.length < _totalReturns;
            _hasAppliedFilters = _filterOptions.customerId != null ||
                _filterOptions.returnNumber != null ||
                _filterOptions.saleId != null;
          });
        } else {
          _showErrorSnackBar('Failed to load returns: ${data['message']}');
        }
      } else {
        _showErrorSnackBar('Failed to load returns: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading returns: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadNextPage() {
    if (_hasMorePages && !_isLoading) {
      _currentPage++;
      _loadReturns(resetPage: false);
    }
  }

  void _refreshData() {
    _loadReturns();
    _showSuccessSnackBar('Data refreshed');
  }

  void _resetFilters() {
    setState(() {
      // Reset date to last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      _startDateController.text =
          DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(now);

      // Reset other controllers
      _returnNumberController.clear();
      _customerSearchController.clear();

      // Reset selected customer
      _selectedCustomer = null;

      // Reset filter options
      _filterOptions = FilterOptions(
        startDate: _startDateController.text,
        endDate: _endDateController.text,
      );

      // Reset filtered customers
      _filteredCustomers = _customers;

      _hasAppliedFilters = false;
    });

    // Load returns with reset filters
    _loadReturns();
  }

  void _applyFilters() {
    setState(() {
      _filterOptions = FilterOptions(
        startDate: _startDateController.text,
        endDate: _endDateController.text,
        customerId: _selectedCustomer?.id,
        returnNumber: _returnNumberController.text.isEmpty
            ? null
            : _returnNumberController.text,
      );
    });

    _loadReturns();

    // Switch to returns list view on mobile
    if (_isMobile) {
      setState(() {
        _showFilterPanel = false;
      });
    }
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

  void _selectReturn(Return returnData) {
    setState(() {
      _selectedReturn = returnData;
      _showReturnDetail = true;
    });
  }

  void _closeReturnDetail() {
    setState(() {
      _showReturnDetail = false;
      _selectedReturn = null;
    });
  }

  void _exportReturns() {
    // This would be implemented to export returns data
    _showSuccessSnackBar('Export feature will be implemented here');
  }

  Future<void> _launchPDF(String? url) async {
    if (url == null || url.isEmpty) {
      _showErrorSnackBar('PDF link not available');
      return;
    }

    try {
      final Uri uri = Uri.parse(url);
      // if (await canLaunchUrl(uri)) {
      //   await launchUrl(uri);
      // } else {
      //   _showErrorSnackBar('Could not open PDF');
      // }
    } catch (e) {
      _showErrorSnackBar('Error opening PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile device
    _isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Returns',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_isMobile)
            IconButton(
              icon:
                  Icon(_showFilterPanel ? Icons.view_list : Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilterPanel = !_showFilterPanel;
                  if (_showReturnDetail) {
                    _showReturnDetail = false;
                  }
                });
              },
              tooltip: _showFilterPanel ? 'Show Returns' : 'Show Filters',
            ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReturns,
            tooltip: 'Export Returns',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
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
      floatingActionButton: _showReturnDetail || (_isMobile && _showFilterPanel)
          ? null
          : FloatingActionButton(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              onPressed: () {
                // Navigate to create return screen
                Navigator.pushNamed(context, '/create-return').then((_) {
                  // Refresh data when returning from create screen
                  _refreshData();
                });
              },
              child: const Icon(Icons.add),
              tooltip: 'Create New Return',
            ),
      body: Container(
        color: backgroundColor,
        child: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (_showReturnDetail && _selectedReturn != null) {
      return _buildReturnDetailPanel();
    }

    return _showFilterPanel ? _buildFilterPanel() : _buildReturnsListPanel();
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - Filters
        SizedBox(
          width: 320,
          child: _buildFilterPanel(),
        ),

        // Right panel - Returns list or Return detail
        Expanded(
          child: _showReturnDetail && _selectedReturn != null
              ? _buildReturnDetailPanel()
              : _buildReturnsListPanel(),
        ),
      ],
    );
  }

  Widget _buildReturnsListPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats and actions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Returns',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Showing ${_returns.length} of $_totalReturns returns',
                        style: TextStyle(
                          color: textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (_hasAppliedFilters)
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        side: BorderSide(color: accentColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
              if (_hasAppliedFilters) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_filterOptions.startDate != null &&
                        _filterOptions.endDate != null)
                      _buildFilterChip(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(_filterOptions.startDate!))} - ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(_filterOptions.endDate!))}',
                        Icons.calendar_today,
                      ),
                    if (_selectedCustomer != null)
                      _buildFilterChip(
                        'Customer: ${_selectedCustomer!.name}',
                        Icons.person,
                      ),
                    if (_filterOptions.returnNumber != null)
                      _buildFilterChip(
                        'Return #: ${_filterOptions.returnNumber}',
                        Icons.receipt,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Returns list
        Expanded(
          child: _isLoading && _returns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Loading returns...',
                        style: TextStyle(
                          color: textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _returns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_return,
                            size: 64,
                            color: textColorSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No returns found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColorSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters or create a new return',
                            style: TextStyle(
                              color: textColorSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Filters'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent &&
                            _hasMorePages &&
                            !_isLoading) {
                          _loadNextPage();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _returns.length + (_hasMorePages ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == _returns.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                    color: primaryColor),
                              ),
                            );
                          }

                          final returnData = _returns[index];
                          return _buildReturnCard(returnData);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildReturnDetailPanel() {
    if (_selectedReturn == null) return const SizedBox.shrink();

    final returnData = _selectedReturn!;
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.parse(returnData.createdAt));
    final originalSaleDate = DateFormat('dd MMM yyyy')
        .format(DateTime.parse(returnData.originalSale.createdAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation and actions row
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _closeReturnDetail,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColorPrimary,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const Spacer(),
              if (returnData.pdfLink != null)
                ElevatedButton.icon(
                  onPressed: () => _launchPDF(returnData.pdfLink),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to print receipt page
                },
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Return header
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
                    Icons.assignment_return,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        returnData.returnNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount: ₹${returnData.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $formattedDate',
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

          const SizedBox(height: 24),

          // Information cards
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
                        _buildInfoItem('Name', returnData.customer.name),
                        _buildInfoItem(
                            'Contact', returnData.customer.contactNumber),
                        if (returnData.customer.email != null)
                          _buildInfoItem('Email', returnData.customer.email!),
                        if (returnData.customer.address != null)
                          _buildInfoItem(
                              'Address', returnData.customer.address!),
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
                        _buildInfoItem(
                            'Bill Number', returnData.originalSale.billNumber),
                        _buildInfoItem('Date', originalSaleDate),
                        _buildInfoItem(
                          'Total Amount',
                          '₹${returnData.originalSale.total.toStringAsFixed(2)}',
                          valueColor: primaryColor,
                          valueFontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 8),
                        if (returnData.originalSale.pdfLink != null)
                          TextButton.icon(
                            onPressed: () =>
                                _launchPDF(returnData.originalSale.pdfLink),
                            icon: Icon(Icons.picture_as_pdf,
                                color: accentColor, size: 18),
                            label: Text(
                              'View Original Invoice',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

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
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: returnData.items.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = returnData.items[index];
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
                        item.medicine.name,
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
                            'Batch: ${item.batchNumber}',
                            style: TextStyle(color: textColorSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reason: ${item.reason}',
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
                              'Qty: ${item.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item.totalAmount.toStringAsFixed(2)}',
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
        ],
      ),
    );
  }

  Widget _buildReturnCard(Return returnData) {
    final formattedDate =
        DateFormat('dd MMM yyyy').format(DateTime.parse(returnData.createdAt));
    final formattedTime =
        DateFormat('hh:mm a').format(DateTime.parse(returnData.createdAt));

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectReturn(returnData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with return number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.assignment_return,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        returnData.returnNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: textColorSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: textColorSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Middle section with customer and original sale info
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
                            color: textColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                returnData.customer.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColorPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: textColorSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              returnData.customer.contactNumber,
                              style: TextStyle(
                                color: textColorSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Vertical divider
                  Container(
                    height: 60,
                    width: 1,
                    color: borderColor,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),

                  // Original sale info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Sale',
                          style: TextStyle(
                            color: textColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              color: accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              returnData.originalSale.billNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColorPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Original Amount: ₹${returnData.originalSale.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: textColorSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Bottom section with returned items summary and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Items summary
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${returnData.items.length} ${returnData.items.length == 1 ? 'item' : 'items'} returned',
                        style: TextStyle(
                          color: textColorSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Return Amount: ₹${returnData.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Action buttons
                  Row(
                    children: [
                      if (returnData.pdfLink != null)
                        IconButton(
                          onPressed: () => _launchPDF(returnData.pdfLink),
                          icon: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.orange,
                          ),
                          tooltip: 'View PDF',
                        ),
                      IconButton(
                        onPressed: () {
                          // Print receipt functionality
                        },
                        icon: Icon(
                          Icons.print,
                          color: primaryColor,
                        ),
                        tooltip: 'Print',
                      ),
                      IconButton(
                        onPressed: () => _selectReturn(returnData),
                        icon: Icon(
                          Icons.visibility,
                          color: accentColor,
                        ),
                        tooltip: 'View Details',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          if (!_isMobile)
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
            child: Row(
              children: [
                Icon(Icons.filter_list, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Filter form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
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

                  const SizedBox(height: 24),

                  // Return Number
                  Text(
                    'Return Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _returnNumberController,
                    decoration: InputDecoration(
                      hintText: 'Enter return number',
                      prefixIcon:
                          Icon(Icons.receipt, color: textColorSecondary),
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
                  ),

                  const SizedBox(height: 24),

                  // Customer
                  Text(
                    'Customer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerSearchController,
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
                  const SizedBox(height: 12),

                  // Customer list
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: 200,
                    child: _isLoadingCustomers
                        ? Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          )
                        : _filteredCustomers.isEmpty
                            ? Center(
                                child: Text(
                                  'No customers found',
                                  style: TextStyle(
                                    color: textColorSecondary,
                                  ),
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
                                  final isSelected =
                                      _selectedCustomer?.id == customer.id;

                                  return Material(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.1)
                                        : cardColor,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedCustomer =
                                              isSelected ? null : customer;

                                          // Auto-filter when customer is selected or deselected
                                          _filterOptions = FilterOptions(
                                            startDate:
                                                _startDateController.text,
                                            endDate: _endDateController.text,
                                            customerId:
                                                isSelected ? null : customer.id,
                                            returnNumber:
                                                _returnNumberController
                                                        .text.isEmpty
                                                    ? null
                                                    : _returnNumberController
                                                        .text,
                                          );
                                        });

                                        // Load returns automatically
                                        _loadReturns();

                                        // Switch to returns list view on mobile
                                        if (_isMobile) {
                                          setState(() {
                                            _showFilterPanel = false;
                                          });
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? primaryColor
                                                    : accentColor
                                                        .withOpacity(0.2),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  customer.isPatient
                                                      ? Icons.personal_injury
                                                      : Icons.person,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : accentColor,
                                                  size: 18,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textColorPrimary,
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    customer.contactNumber,
                                                    style: TextStyle(
                                                      color: textColorSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: primaryColor,
                                                size: 20,
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
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: borderColor),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColorPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Modify the date field selection to also trigger auto-update
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
      onTap: () async {
        await _selectDate(context, controller);

        // After date selection, update filter options and load returns
        setState(() {
          _filterOptions = FilterOptions(
            startDate: _startDateController.text,
            endDate: _endDateController.text,
            customerId: _selectedCustomer?.id,
            returnNumber: _returnNumberController.text.isEmpty
                ? null
                : _returnNumberController.text,
          );
        });

        // Load returns automatically
        _loadReturns();
      },
    );
  }

// Modify the _selectDate method to return the selected date
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

// Add auto-filtering for the return number input

// Dispose listeners when the widget is disposed
  @override
  void dispose() {
    _returnNumberController.removeListener(_onReturnNumberChanged);
    _returnNumberController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

// Method to handle return number changes
  void _onReturnNumberChanged() {
    // Debounce the filtering to avoid too many API calls
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _filterOptions = FilterOptions(
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          customerId: _selectedCustomer?.id,
          returnNumber: _returnNumberController.text.isEmpty
              ? null
              : _returnNumberController.text,
        );
      });

      // Load returns automatically
      _loadReturns();
    });
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
}
