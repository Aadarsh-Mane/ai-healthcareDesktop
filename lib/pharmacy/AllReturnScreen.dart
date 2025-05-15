import 'dart:async';

import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Model classes from paste.txt are reused
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

// Adding the providers for better state management
final returnsProvider =
    StateNotifierProvider<ReturnsNotifier, ReturnsState>((ref) {
  return ReturnsNotifier();
});

class ReturnsState {
  final List<Return> returns;
  final List<Return> filteredReturns;
  final bool isLoading;
  final int totalReturns;
  final int currentPage;
  final int pageSize;
  final bool hasMorePages;
  final bool hasAppliedFilters;
  final FilterOptions filterOptions;
  final Return? selectedReturn;
  final bool showReturnDetail;

  ReturnsState({
    this.returns = const [],
    this.filteredReturns = const [],
    this.isLoading = false,
    this.totalReturns = 0,
    this.currentPage = 1,
    this.pageSize = 10,
    this.hasMorePages = false,
    this.hasAppliedFilters = false,
    this.filterOptions = const FilterOptions(),
    this.selectedReturn,
    this.showReturnDetail = false,
  });

  ReturnsState copyWith({
    List<Return>? returns,
    List<Return>? filteredReturns,
    bool? isLoading,
    int? totalReturns,
    int? currentPage,
    int? pageSize,
    bool? hasMorePages,
    bool? hasAppliedFilters,
    FilterOptions? filterOptions,
    Return? selectedReturn,
    bool? showReturnDetail,
  }) {
    return ReturnsState(
      returns: returns ?? this.returns,
      filteredReturns: filteredReturns ?? this.filteredReturns,
      isLoading: isLoading ?? this.isLoading,
      totalReturns: totalReturns ?? this.totalReturns,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      hasAppliedFilters: hasAppliedFilters ?? this.hasAppliedFilters,
      filterOptions: filterOptions ?? this.filterOptions,
      selectedReturn: selectedReturn ?? this.selectedReturn,
      showReturnDetail: showReturnDetail ?? this.showReturnDetail,
    );
  }
}

class ReturnsNotifier extends StateNotifier<ReturnsState> {
  ReturnsNotifier() : super(ReturnsState());

  Future<void> loadReturns({bool resetPage = true}) async {
    if (resetPage) {
      state = state.copyWith(
        currentPage: 1,
        isLoading: true,
        returns: [],
        filteredReturns: [],
      );
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      // Build query parameters
      Map<String, String> queryParams = state.filterOptions.toQueryParameters();

      // Add pagination parameters
      queryParams['page'] = state.currentPage.toString();
      queryParams['limit'] = state.pageSize.toString();

      final Uri uri = Uri.parse('${KVM_URL}/pharma/getReturns')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final newReturns = List<Return>.from(
              data['data'].map((returnData) => Return.fromJson(returnData)));

          final updatedReturns =
              resetPage ? newReturns : [...state.returns, ...newReturns];

          state = state.copyWith(
            returns: updatedReturns,
            filteredReturns: updatedReturns,
            totalReturns: data['count'],
            hasMorePages: updatedReturns.length < data['count'],
            hasAppliedFilters: state.filterOptions.customerId != null ||
                state.filterOptions.returnNumber != null ||
                state.filterOptions.saleId != null,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      print('Error loading returns: $e');
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void loadNextPage() {
    if (state.hasMorePages && !state.isLoading) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      loadReturns(resetPage: false);
    }
  }

  void applyFilters(FilterOptions filterOptions) {
    state = state.copyWith(filterOptions: filterOptions);
    loadReturns();
  }

  void selectReturn(Return returnData) {
    state = state.copyWith(
      selectedReturn: returnData,
      showReturnDetail: true,
    );
  }

  void closeReturnDetail() {
    state = state.copyWith(
      showReturnDetail: false,
      selectedReturn: null,
    );
  }
}

// Customers provider
final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  return CustomersNotifier();
});

class CustomersState {
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final bool isLoading;
  final Customer? selectedCustomer;

  CustomersState({
    this.customers = const [],
    this.filteredCustomers = const [],
    this.isLoading = false,
    this.selectedCustomer,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    List<Customer>? filteredCustomers,
    bool? isLoading,
    Customer? selectedCustomer,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      isLoading: isLoading ?? this.isLoading,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  CustomersNotifier() : super(CustomersState());

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/pharma/getCustomers'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final customers = List<Customer>.from(
              data['data'].map((customer) => Customer.fromJson(customer)));

          state = state.copyWith(
            customers: customers,
            filteredCustomers: customers,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      print('Error loading customers: $e');
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void filterCustomers(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredCustomers: state.customers);
    } else {
      final filtered = state.customers
          .where((customer) =>
              customer.name.toLowerCase().contains(query.toLowerCase()) ||
              customer.contactNumber.contains(query))
          .toList();

      state = state.copyWith(filteredCustomers: filtered);
    }
  }

  void selectCustomer(Customer? customer) {
    state = state.copyWith(selectedCustomer: customer);
  }
}

// UI states provider for mobile layout
final uiStateProvider = StateProvider<UIState>((ref) {
  return UIState(
    showFilterPanel: true,
  );
});

class UIState {
  final bool showFilterPanel;

  const UIState({
    required this.showFilterPanel,
  });
}

// Update FilterOptions to be immutable
class FilterOptions {
  final String? startDate;
  final String? endDate;
  final String? customerId;
  final String? returnNumber;
  final String? saleId;

  const FilterOptions({
    this.startDate,
    this.endDate,
    this.customerId,
    this.returnNumber,
    this.saleId,
  });

  FilterOptions copyWith({
    String? startDate,
    String? endDate,
    String? customerId,
    String? returnNumber,
    String? saleId,
  }) {
    return FilterOptions(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      customerId: customerId ?? this.customerId,
      returnNumber: returnNumber ?? this.returnNumber,
      saleId: saleId ?? this.saleId,
    );
  }

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

class AllReturnsScreen extends ConsumerStatefulWidget {
  const AllReturnsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AllReturnsScreen> createState() => _AllReturnsScreenState();
}

class _AllReturnsScreenState extends ConsumerState<AllReturnsScreen> {
  // Controllers
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _returnNumberController = TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();

  Timer? _debounceTimer;
  bool _isMobile = false;

  // Key handler subscription
  late FocusNode _mainFocusNode;

  @override
  void initState() {
    super.initState();

    // Initialize date controllers with last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    _startDateController.text = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(now);

    // Add listener to return number controller for auto-filtering
    _returnNumberController.addListener(_onReturnNumberChanged);

    // Initialize the providers with default filter options
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnsProvider.notifier).applyFilters(
            FilterOptions(
              startDate: _startDateController.text,
              endDate: _endDateController.text,
            ),
          );

      // Load customers
      ref.read(customersProvider.notifier).loadCustomers();
    });

    // Initialize focus node for keyboard shortcuts
    _mainFocusNode = FocusNode();

    // Setup keyboard shortcuts
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
    _mainFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        // Ctrl/Cmd + R = Refresh data
        if ((event.logicalKey == LogicalKeyboardKey.keyR) &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _refreshData();
          return KeyEventResult.handled;
        }

        // Ctrl/Cmd + F = Focus on filter/search
        if ((event.logicalKey == LogicalKeyboardKey.keyF) &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _returnNumberController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _returnNumberController.text.length,
          );
          FocusScope.of(context).requestFocus(FocusNode()..requestFocus());
          return KeyEventResult.handled;
        }

        // Escape = Close detail view or clear selection
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          final returnsState = ref.read(returnsProvider);
          if (returnsState.showReturnDetail) {
            ref.read(returnsProvider.notifier).closeReturnDetail();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
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
        backgroundColor: PharmaTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
        ),
        duration: PharmaTheme.transitionMedium,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PharmaTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
        ),
      ),
    );
  }

  void _refreshData() {
    ref.read(returnsProvider.notifier).loadReturns();
    _showSuccessSnackBar('Data refreshed');
  }

  void _resetFilters() {
    // Reset date to last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    _startDateController.text = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(now);

    // Reset other controllers
    _returnNumberController.clear();
    _customerSearchController.clear();

    // Reset selected customer
    ref.read(customersProvider.notifier).selectCustomer(null);

    // Reset filter options and load returns
    ref.read(returnsProvider.notifier).applyFilters(
          FilterOptions(
            startDate: _startDateController.text,
            endDate: _endDateController.text,
          ),
        );

    // Reset filtered customers
    ref.read(customersProvider.notifier).filterCustomers('');
  }

  void _applyFilters() {
    final customersState = ref.read(customersProvider);

    ref.read(returnsProvider.notifier).applyFilters(
          FilterOptions(
            startDate: _startDateController.text,
            endDate: _endDateController.text,
            customerId: customersState.selectedCustomer?.id,
            returnNumber: _returnNumberController.text.isEmpty
                ? null
                : _returnNumberController.text,
          ),
        );

    // Switch to returns list view on mobile
    if (_isMobile) {
      ref.read(uiStateProvider.notifier).state =
          UIState(showFilterPanel: false);
    }
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

  void _onReturnNumberChanged() {
    // Debounce the filtering to avoid too many API calls
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(PharmaTheme.transitionFast, () {
      final customersState = ref.read(customersProvider);

      ref.read(returnsProvider.notifier).applyFilters(
            FilterOptions(
              startDate: _startDateController.text,
              endDate: _endDateController.text,
              customerId: customersState.selectedCustomer?.id,
              returnNumber: _returnNumberController.text.isEmpty
                  ? null
                  : _returnNumberController.text,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile device using PharmaTheme helper
    _isMobile = PharmaTheme.isMobile(context);

    final returnsState = ref.watch(returnsProvider);
    final uiState = ref.watch(uiStateProvider);

    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Returns'),
          actions: [
            if (_isMobile)
              IconButton(
                icon: Icon(uiState.showFilterPanel
                    ? Icons.view_list
                    : Icons.filter_list),
                onPressed: () {
                  final currentState = ref.read(uiStateProvider);
                  ref.read(uiStateProvider.notifier).state = UIState(
                    showFilterPanel: !currentState.showFilterPanel,
                  );

                  // Close detail view if open when switching to filters
                  if (returnsState.showReturnDetail &&
                      !currentState.showFilterPanel) {
                    ref.read(returnsProvider.notifier).closeReturnDetail();
                  }
                },
                tooltip:
                    uiState.showFilterPanel ? 'Show Returns' : 'Show Filters',
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
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: PharmaTheme.primaryGradient,
            ),
          ),
        ),
        floatingActionButton: returnsState.showReturnDetail ||
                (_isMobile && uiState.showFilterPanel)
            ? null
            : FloatingActionButton(
                backgroundColor: PharmaTheme.accent,
                foregroundColor: PharmaTheme.textLight,
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
          color: PharmaTheme.background,
          child: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final returnsState = ref.watch(returnsProvider);
    final uiState = ref.watch(uiStateProvider);

    if (returnsState.showReturnDetail && returnsState.selectedReturn != null) {
      return _buildReturnDetailPanel();
    }

    return uiState.showFilterPanel
        ? _buildFilterPanel()
        : _buildReturnsListPanel();
  }

  Widget _buildDesktopLayout() {
    final returnsState = ref.watch(returnsProvider);

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
          child: returnsState.showReturnDetail &&
                  returnsState.selectedReturn != null
              ? _buildReturnDetailPanel()
              : _buildReturnsListPanel(),
        ),
      ],
    );
  }

  Widget _buildReturnsListPanel() {
    final returnsState = ref.watch(returnsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats and actions
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(PharmaTheme.spacingM),
          decoration: BoxDecoration(
            color: PharmaTheme.surface,
            boxShadow: PharmaTheme.shadowSmall,
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
                        style: PharmaTheme.headingSmall.copyWith(
                          color: PharmaTheme.primary,
                        ),
                      ),
                      SizedBox(height: PharmaTheme.spacingXxs),
                      Text(
                        'Showing ${returnsState.returns.length} of ${returnsState.totalReturns} returns',
                        style: PharmaTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (returnsState.hasAppliedFilters)
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PharmaTheme.accent,
                        side: BorderSide(color: PharmaTheme.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusCircular),
                        ),
                      ),
                    ),
                ],
              ),
              if (returnsState.hasAppliedFilters) ...[
                SizedBox(height: PharmaTheme.spacingM),
                Wrap(
                  spacing: PharmaTheme.spacingXs,
                  runSpacing: PharmaTheme.spacingXs,
                  children: [
                    if (returnsState.filterOptions.startDate != null &&
                        returnsState.filterOptions.endDate != null)
                      _buildFilterChip(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(returnsState.filterOptions.startDate!))} - ${DateFormat('dd/MM/yyyy').format(DateFormat('yyyy-MM-dd').parse(returnsState.filterOptions.endDate!))}',
                        Icons.calendar_today,
                      ),
                    if (ref.read(customersProvider).selectedCustomer != null)
                      _buildFilterChip(
                        'Customer: ${ref.read(customersProvider).selectedCustomer!.name}',
                        Icons.person,
                      ),
                    if (returnsState.filterOptions.returnNumber != null)
                      _buildFilterChip(
                        'Return #: ${returnsState.filterOptions.returnNumber}',
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
          child: returnsState.isLoading && returnsState.returns.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: PharmaTheme.primary),
                      SizedBox(height: PharmaTheme.spacingM),
                      Text(
                        'Loading returns...',
                        style: PharmaTheme.bodyMedium.copyWith(
                          color: PharmaTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : returnsState.returns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_return,
                            size: 64,
                            color: PharmaTheme.textSecondary.withOpacity(0.5),
                          ),
                          SizedBox(height: PharmaTheme.spacingM),
                          Text(
                            'No returns found',
                            style: PharmaTheme.headingSmall.copyWith(
                              color: PharmaTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: PharmaTheme.spacingXs),
                          Text(
                            'Try adjusting your filters or create a new return',
                            style: PharmaTheme.bodyMedium.copyWith(
                              color: PharmaTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: PharmaTheme.spacingL),
                          OutlinedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Filters'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PharmaTheme.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: PharmaTheme.spacingL,
                                vertical: PharmaTheme.spacingM,
                              ),
                              side: BorderSide(color: PharmaTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(PharmaTheme.radiusS),
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
                            returnsState.hasMorePages &&
                            !returnsState.isLoading) {
                          ref.read(returnsProvider.notifier).loadNextPage();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: EdgeInsets.all(PharmaTheme.spacingM),
                        itemCount: returnsState.returns.length +
                            (returnsState.hasMorePages ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: PharmaTheme.spacingM),
                        itemBuilder: (context, index) {
                          if (index == returnsState.returns.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(PharmaTheme.spacingM),
                                child: CircularProgressIndicator(
                                    color: PharmaTheme.primary),
                              ),
                            );
                          }

                          final returnData = returnsState.returns[index];
                          return _buildReturnCard(returnData);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildReturnDetailPanel() {
    final returnsState = ref.watch(returnsProvider);
    if (returnsState.selectedReturn == null) return const SizedBox.shrink();

    final returnData = returnsState.selectedReturn!;
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.parse(returnData.createdAt));
    final originalSaleDate = DateFormat('dd MMM yyyy')
        .format(DateTime.parse(returnData.originalSale.createdAt));

    return SingleChildScrollView(
      padding: EdgeInsets.all(PharmaTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation and actions row
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(returnsProvider.notifier).closeReturnDetail(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PharmaTheme.textPrimary,
                  side: BorderSide(color: PharmaTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
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
                    foregroundColor: PharmaTheme.textLight,
                    backgroundColor: PharmaTheme.warning,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
                    ),
                  ),
                ),
              SizedBox(width: PharmaTheme.spacingM),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to print receipt page
                },
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: PharmaTheme.textLight,
                  backgroundColor: PharmaTheme.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: PharmaTheme.spacingL),

          // Return header
          Container(
            padding: EdgeInsets.all(PharmaTheme.spacingL),
            decoration: BoxDecoration(
              gradient: PharmaTheme.primaryAccentGradient,
              borderRadius: BorderRadius.circular(PharmaTheme.radiusL),
              boxShadow: PharmaTheme.shadowMedium,
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
                    color: PharmaTheme.textLight,
                    size: 36,
                  ),
                ),
                SizedBox(width: PharmaTheme.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        returnData.returnNumber,
                        style: PharmaTheme.headingLarge.copyWith(
                          color: PharmaTheme.textLight,
                        ),
                      ),
                      SizedBox(height: PharmaTheme.spacingXs),
                      Text(
                        'Total Amount: ₹${returnData.totalAmount.toStringAsFixed(2)}',
                        style: PharmaTheme.headingSmall.copyWith(
                          color: PharmaTheme.textLight,
                        ),
                      ),
                      SizedBox(height: PharmaTheme.spacingXxs),
                      Text(
                        'Date: $formattedDate',
                        style: PharmaTheme.bodyMedium.copyWith(
                          color: PharmaTheme.textLight.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: PharmaTheme.spacingL),

          // Information cards
          Wrap(
            spacing: PharmaTheme.spacingL,
            runSpacing: PharmaTheme.spacingL,
            children: [
              // Customer details card
              SizedBox(
                width: _isMobile ? double.infinity : 320,
                child: Card(
                  color: PharmaTheme.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusL),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(PharmaTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: PharmaTheme.primary),
                            SizedBox(width: PharmaTheme.spacingXs),
                            Text(
                              'Customer Details',
                              style: PharmaTheme.headingSmall.copyWith(
                                color: PharmaTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: PharmaTheme.spacingM),
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
                  color: PharmaTheme.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusL),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(PharmaTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long,
                                color: PharmaTheme.primary),
                            SizedBox(width: PharmaTheme.spacingXs),
                            Text(
                              'Original Sale',
                              style: PharmaTheme.headingSmall.copyWith(
                                color: PharmaTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: PharmaTheme.spacingM),
                        _buildInfoItem(
                            'Bill Number', returnData.originalSale.billNumber),
                        _buildInfoItem('Date', originalSaleDate),
                        _buildInfoItem(
                          'Total Amount',
                          '₹${returnData.originalSale.total.toStringAsFixed(2)}',
                          valueColor: PharmaTheme.primary,
                          valueFontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: PharmaTheme.spacingXs),
                        if (returnData.originalSale.pdfLink != null)
                          TextButton.icon(
                            onPressed: () =>
                                _launchPDF(returnData.originalSale.pdfLink),
                            icon: Icon(Icons.picture_as_pdf,
                                color: PharmaTheme.accent, size: 18),
                            label: Text(
                              'View Original Invoice',
                              style: PharmaTheme.bodyMedium.copyWith(
                                color: PharmaTheme.accent,
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

          SizedBox(height: PharmaTheme.spacingL),

          // Returned items
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PharmaTheme.radiusL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(PharmaTheme.spacingL),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: PharmaTheme.primary),
                      SizedBox(width: PharmaTheme.spacingXs),
                      Text(
                        'Returned Items',
                        style: PharmaTheme.headingSmall.copyWith(
                          color: PharmaTheme.primary,
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
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = returnData.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: PharmaTheme.spacingL,
                        vertical: PharmaTheme.spacingM,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: PharmaTheme.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: PharmaTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: PharmaTheme.accent,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item.medicine.name,
                        style: PharmaTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: PharmaTheme.spacingXxs),
                          Text(
                            'Batch: ${item.batchNumber}',
                            style: PharmaTheme.bodySmall,
                          ),
                          SizedBox(height: PharmaTheme.spacingXxs),
                          Text(
                            'Reason: ${item.reason}',
                            style: PharmaTheme.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PharmaTheme.spacingM,
                              vertical: PharmaTheme.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              color: PharmaTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  PharmaTheme.radiusCircular),
                            ),
                            child: Text(
                              'Qty: ${item.quantity}',
                              style: PharmaTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: PharmaTheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: PharmaTheme.spacingXxs),
                          Text(
                            '₹${item.totalAmount.toStringAsFixed(2)}',
                            style: PharmaTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
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
      color: PharmaTheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
      ),
      child: InkWell(
        onTap: () =>
            ref.read(returnsProvider.notifier).selectReturn(returnData),
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        child: Padding(
          padding: EdgeInsets.all(PharmaTheme.spacingM),
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
                        padding: EdgeInsets.all(PharmaTheme.spacingXs),
                        decoration: BoxDecoration(
                          color: PharmaTheme.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusS),
                        ),
                        child: Icon(
                          Icons.assignment_return,
                          color: PharmaTheme.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: PharmaTheme.spacingM),
                      Text(
                        returnData.returnNumber,
                        style: PharmaTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PharmaTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: PharmaTheme.bodyMedium.copyWith(
                          color: PharmaTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: PharmaTheme.spacingXxs),
                      Text(
                        formattedTime,
                        style: PharmaTheme.caption.copyWith(
                          color: PharmaTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: PharmaTheme.spacingM),
              const Divider(height: 1),
              SizedBox(height: PharmaTheme.spacingM),

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
                          style: PharmaTheme.caption,
                        ),
                        SizedBox(height: PharmaTheme.spacingXxs),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: PharmaTheme.accent,
                              size: 16,
                            ),
                            SizedBox(width: PharmaTheme.spacingXs),
                            Flexible(
                              child: Text(
                                returnData.customer.name,
                                style: PharmaTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: PharmaTheme.spacingXxs),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: PharmaTheme.textSecondary,
                              size: 16,
                            ),
                            SizedBox(width: PharmaTheme.spacingXs),
                            Text(
                              returnData.customer.contactNumber,
                              style: PharmaTheme.bodySmall,
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
                    color: PharmaTheme.border,
                    margin:
                        EdgeInsets.symmetric(horizontal: PharmaTheme.spacingM),
                  ),

                  // Original sale info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Sale',
                          style: PharmaTheme.caption,
                        ),
                        SizedBox(height: PharmaTheme.spacingXxs),
                        Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              color: PharmaTheme.accent,
                              size: 16,
                            ),
                            SizedBox(width: PharmaTheme.spacingXs),
                            Text(
                              returnData.originalSale.billNumber,
                              style: PharmaTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: PharmaTheme.spacingXxs),
                        Text(
                          'Original Amount: ₹${returnData.originalSale.total.toStringAsFixed(2)}',
                          style: PharmaTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: PharmaTheme.spacingM),
              const Divider(height: 1),
              SizedBox(height: PharmaTheme.spacingM),

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
                        style: PharmaTheme.bodyMedium.copyWith(
                          color: PharmaTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: PharmaTheme.spacingXxs),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PharmaTheme.spacingM,
                          vertical: PharmaTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaTheme.accent.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusCircular),
                        ),
                        child: Text(
                          'Return Amount: ₹${returnData.totalAmount.toStringAsFixed(2)}',
                          style: PharmaTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: PharmaTheme.accent,
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
                            color: PharmaTheme.warning,
                          ),
                          tooltip: 'View PDF',
                        ),
                      IconButton(
                        onPressed: () {
                          // Print receipt functionality
                        },
                        icon: Icon(
                          Icons.print,
                          color: PharmaTheme.primary,
                        ),
                        tooltip: 'Print',
                      ),
                      IconButton(
                        onPressed: () => ref
                            .read(returnsProvider.notifier)
                            .selectReturn(returnData),
                        icon: Icon(
                          Icons.visibility,
                          color: PharmaTheme.accent,
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
      padding: EdgeInsets.symmetric(
        horizontal: PharmaTheme.spacingM,
        vertical: PharmaTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: PharmaTheme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PharmaTheme.radiusCircular),
        border: Border.all(color: PharmaTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: PharmaTheme.accent,
          ),
          SizedBox(width: PharmaTheme.spacingXs),
          Text(
            label,
            style: PharmaTheme.bodySmall.copyWith(
              color: PharmaTheme.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final customersState = ref.watch(customersProvider);

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: PharmaTheme.surface,
        boxShadow: _isMobile ? null : PharmaTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(PharmaTheme.spacingM),
            decoration: BoxDecoration(
              color: PharmaTheme.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: PharmaTheme.border),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: PharmaTheme.primary),
                SizedBox(width: PharmaTheme.spacingXs),
                Text(
                  'Filters',
                  style: PharmaTheme.headingSmall.copyWith(
                    color: PharmaTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Filter form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PharmaTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  Text(
                    'Date Range',
                    style: PharmaTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PharmaTheme.spacingXs),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(_startDateController, 'From'),
                      ),
                      SizedBox(width: PharmaTheme.spacingXs),
                      Expanded(
                        child: _buildDateField(_endDateController, 'To'),
                      ),
                    ],
                  ),

                  SizedBox(height: PharmaTheme.spacingL),

                  // Return Number
                  Text(
                    'Return Number',
                    style: PharmaTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PharmaTheme.spacingXs),
                  TextFormField(
                    controller: _returnNumberController,
                    decoration: InputDecoration(
                      hintText: 'Enter return number',
                      prefixIcon:
                          Icon(Icons.receipt, color: PharmaTheme.textSecondary),
                      fillColor: PharmaTheme.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                        borderSide: BorderSide(color: PharmaTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                        borderSide: BorderSide(color: PharmaTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                        borderSide: BorderSide(color: PharmaTheme.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: PharmaTheme.spacingM,
                        horizontal: PharmaTheme.spacingM,
                      ),
                    ),
                  ),

                  SizedBox(height: PharmaTheme.spacingL),

                  // Customer
                  Text(
                    'Customer',
                    style: PharmaTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PharmaTheme.spacingXs),
                  TextFormField(
                    controller: _customerSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon:
                          Icon(Icons.search, color: PharmaTheme.textSecondary),
                      fillColor: PharmaTheme.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                        borderSide: BorderSide(color: PharmaTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                        borderSide: BorderSide(color: PharmaTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusM),
                        borderSide: BorderSide(color: PharmaTheme.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: PharmaTheme.spacingM,
                        horizontal: PharmaTheme.spacingM,
                      ),
                    ),
                    onChanged: (query) => ref
                        .read(customersProvider.notifier)
                        .filterCustomers(query),
                  ),
                  SizedBox(height: PharmaTheme.spacingM),

                  // Customer list
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: PharmaTheme.border),
                      borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
                    ),
                    height: 200,
                    child: customersState.isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: PharmaTheme.primary,
                            ),
                          )
                        : customersState.filteredCustomers.isEmpty
                            ? Center(
                                child: Text(
                                  'No customers found',
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    color: PharmaTheme.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount:
                                    customersState.filteredCustomers.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: PharmaTheme.border,
                                ),
                                itemBuilder: (context, index) {
                                  final customer =
                                      customersState.filteredCustomers[index];
                                  final isSelected =
                                      customersState.selectedCustomer?.id ==
                                          customer.id;

                                  return Material(
                                    color: isSelected
                                        ? PharmaTheme.primary.withOpacity(
                                            PharmaTheme.selectedOpacity)
                                        : PharmaTheme.surface,
                                    child: InkWell(
                                      onTap: () {
                                        ref
                                            .read(customersProvider.notifier)
                                            .selectCustomer(
                                              isSelected ? null : customer,
                                            );

                                        // Auto-filter when customer is selected or deselected
                                        final filterOptions = FilterOptions(
                                          startDate: _startDateController.text,
                                          endDate: _endDateController.text,
                                          customerId:
                                              isSelected ? null : customer.id,
                                          returnNumber: _returnNumberController
                                                  .text.isEmpty
                                              ? null
                                              : _returnNumberController.text,
                                        );

                                        ref
                                            .read(returnsProvider.notifier)
                                            .applyFilters(filterOptions);

                                        // Switch to returns list view on mobile
                                        if (_isMobile) {
                                          ref
                                                  .read(uiStateProvider.notifier)
                                                  .state =
                                              UIState(showFilterPanel: false);
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: PharmaTheme.spacingM,
                                          horizontal: PharmaTheme.spacingM,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? PharmaTheme.primary
                                                    : PharmaTheme.accent
                                                        .withOpacity(0.2),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  customer.isPatient
                                                      ? Icons.personal_injury
                                                      : Icons.person,
                                                  color: isSelected
                                                      ? PharmaTheme.textLight
                                                      : PharmaTheme.accent,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                                width: PharmaTheme.spacingM),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    customer.name,
                                                    style: PharmaTheme
                                                        .bodyMedium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(
                                                      height: PharmaTheme
                                                          .spacingXxs),
                                                  Text(
                                                    customer.contactNumber,
                                                    style: PharmaTheme.caption,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: PharmaTheme.primary,
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
            padding: EdgeInsets.all(PharmaTheme.spacingM),
            decoration: BoxDecoration(
              color: PharmaTheme.surface,
              border: Border(
                top: BorderSide(color: PharmaTheme.border),
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
                      foregroundColor: PharmaTheme.textPrimary,
                      padding:
                          EdgeInsets.symmetric(vertical: PharmaTheme.spacingM),
                      side: BorderSide(color: PharmaTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusS),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                SizedBox(width: PharmaTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: PharmaTheme.textLight,
                      backgroundColor: PharmaTheme.primary,
                      padding:
                          EdgeInsets.symmetric(vertical: PharmaTheme.spacingM),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusS),
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

  Widget _buildDateField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
          borderSide: BorderSide(color: PharmaTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
          borderSide: BorderSide(color: PharmaTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
          borderSide: BorderSide(color: PharmaTheme.primary),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: PharmaTheme.spacingM,
          vertical: PharmaTheme.spacingS,
        ),
        suffixIcon:
            Icon(Icons.calendar_today, color: PharmaTheme.textSecondary),
        isDense: true,
        fillColor: PharmaTheme.surface,
        filled: true,
      ),
      readOnly: true,
      onTap: () async {
        await _selectDate(context, controller);

        // After date selection, update filter options and load returns
        final customersState = ref.read(customersProvider);

        ref.read(returnsProvider.notifier).applyFilters(
              FilterOptions(
                startDate: _startDateController.text,
                endDate: _endDateController.text,
                customerId: customersState.selectedCustomer?.id,
                returnNumber: _returnNumberController.text.isEmpty
                    ? null
                    : _returnNumberController.text,
              ),
            );
      },
    );
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
              primary: PharmaTheme.primary,
              onPrimary: PharmaTheme.textLight,
              onSurface: PharmaTheme.textPrimary,
            ),
            dialogBackgroundColor: PharmaTheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    Color? valueColor,
    FontWeight valueFontWeight = FontWeight.normal,
    double valueSize = 14,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: PharmaTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PharmaTheme.caption,
          ),
          SizedBox(height: PharmaTheme.spacingXxs),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? PharmaTheme.textPrimary,
              fontWeight: valueFontWeight,
              fontSize: valueSize,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _returnNumberController.removeListener(_onReturnNumberChanged);
    _returnNumberController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _customerSearchController.dispose();
    _mainFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
