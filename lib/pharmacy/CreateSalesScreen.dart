import 'dart:convert';

import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/SalesHistoryScreen.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Define the providers
final createSaleProvider =
    StateNotifierProvider<CreateSaleNotifier, CreateSaleState>((ref) {
  return CreateSaleNotifier();
});

class CreateSaleState {
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> inventory;
  final List<Map<String, dynamic>> filteredInventory;
  final List<Map<String, dynamic>> selectedItems;
  final String? selectedCustomerId;
  final String? selectedPaymentMethod;
  final Map<String, dynamic>? saleResponse;
  final bool isLoading;
  final bool isSubmitting;
  final bool showSuccessCard;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;

  CreateSaleState({
    this.customers = const [],
    this.inventory = const [],
    this.filteredInventory = const [],
    this.selectedItems = const [],
    this.selectedCustomerId,
    this.selectedPaymentMethod = 'cash',
    this.saleResponse,
    this.isLoading = false,
    this.isSubmitting = false,
    this.showSuccessCard = false,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
  });

  CreateSaleState copyWith({
    List<Map<String, dynamic>>? customers,
    List<Map<String, dynamic>>? inventory,
    List<Map<String, dynamic>>? filteredInventory,
    List<Map<String, dynamic>>? selectedItems,
    String? selectedCustomerId,
    String? selectedPaymentMethod,
    Map<String, dynamic>? saleResponse,
    bool? isLoading,
    bool? isSubmitting,
    bool? showSuccessCard,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
  }) {
    return CreateSaleState(
      customers: customers ?? this.customers,
      inventory: inventory ?? this.inventory,
      filteredInventory: filteredInventory ?? this.filteredInventory,
      selectedItems: selectedItems ?? this.selectedItems,
      selectedCustomerId: selectedCustomerId ?? this.selectedCustomerId,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      saleResponse: saleResponse ?? this.saleResponse,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showSuccessCard: showSuccessCard ?? this.showSuccessCard,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
    );
  }
}

class CreateSaleNotifier extends StateNotifier<CreateSaleState> {
  CreateSaleNotifier() : super(CreateSaleState());

  // Fetch customers from API
  Future<void> fetchCustomers() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/pharma/getCustomers'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          state = state.copyWith(
            customers: List<Map<String, dynamic>>.from(data['data']),
            isLoading: false,
          );
        }
      }
    } catch (e) {
      print('Error fetching customers: $e');
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // Fetch inventory from API
  Future<void> fetchInventory() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/pharma/getInventory'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final inventoryData = List<Map<String, dynamic>>.from(data['data']);

          // Convert numeric values to proper types
          final processedInventory = inventoryData.map((item) {
            final medicine = item['medicine'] as Map<String, dynamic>;

            // Convert mrp to double if it's an int
            if (medicine['mrp'] is int) {
              medicine['mrp'] = (medicine['mrp'] as int).toDouble();
            }

            // Return the updated item
            return {
              ...item,
              'medicine': medicine,
            };
          }).toList();

          state = state.copyWith(
            inventory: processedInventory,
            filteredInventory: processedInventory,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      print('Error fetching inventory: $e');
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // Filter inventory based on search term
  void filterInventory(String searchTerm) {
    if (searchTerm.isEmpty) {
      state = state.copyWith(
        filteredInventory: List<Map<String, dynamic>>.from(state.inventory),
      );
      return;
    }

    final filtered = state.inventory.where((item) {
      final medicine = item['medicine'] as Map<String, dynamic>;
      final name = medicine['name'].toString().toLowerCase();
      final manufacturer = medicine['manufacturer'].toString().toLowerCase();
      final category = medicine['category'].toString().toLowerCase();
      final batchNumber = item['batchNumber'].toString().toLowerCase();

      return name.contains(searchTerm.toLowerCase()) ||
          manufacturer.contains(searchTerm.toLowerCase()) ||
          category.contains(searchTerm.toLowerCase()) ||
          batchNumber.contains(searchTerm.toLowerCase());
    }).toList();

    state = state.copyWith(filteredInventory: filtered);
  }

  // Set selected customer
  void setSelectedCustomer(String? customerId) {
    state = state.copyWith(selectedCustomerId: customerId);
  }

  // Set payment method
  void setPaymentMethod(String? method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  // Add item to cart
  void addItemToCart(Map<String, dynamic> item) {
    // Check if item is already in cart
    final currentItems = List<Map<String, dynamic>>.from(state.selectedItems);
    final existingItemIndex = currentItems.indexWhere(
      (selectedItem) => selectedItem['inventoryId'] == item['_id'],
    );

    if (existingItemIndex != -1) {
      // Update quantity if already in cart
      currentItems[existingItemIndex]['quantity'] += 1;
      final mrp = currentItems[existingItemIndex]['mrp'];
      final discount = currentItems[existingItemIndex]['discount'];
      final quantity = currentItems[existingItemIndex]['quantity'];
      currentItems[existingItemIndex]['totalAmount'] =
          (mrp is int ? mrp.toDouble() : mrp) *
              quantity *
              (1 - (discount / 100));
    } else {
      // Add as new item if not in cart
      final medicine = item['medicine'] as Map<String, dynamic>;

      currentItems.add({
        'inventoryId': item['_id'],
        'medicine': medicine,
        'batchNumber': item['batchNumber'],
        'expiryDate': item['expiryDate'],
        'mrp': medicine['mrp'] is int
            ? (medicine['mrp'] as int).toDouble()
            : medicine['mrp'],
        'quantity': 1,
        'discount': 0.0,
        'totalAmount': (medicine['mrp'] is int
                ? (medicine['mrp'] as int).toDouble()
                : medicine['mrp']) *
            1,
        'availableQuantity': item['quantity'],
      });
    }

    state = state.copyWith(selectedItems: currentItems);
    recalculateTotals();
  }

  // Remove item from cart
  void removeItemFromCart(int index) {
    final currentItems = List<Map<String, dynamic>>.from(state.selectedItems);
    currentItems.removeAt(index);
    state = state.copyWith(selectedItems: currentItems);
    recalculateTotals();
  }

  // Update item quantity
  void updateItemQuantity(int index, int quantity,
      {bool showError = true, Function(String)? errorCallback}) {
    if (quantity <= 0) {
      removeItemFromCart(index);
      return;
    }

    final currentItems = List<Map<String, dynamic>>.from(state.selectedItems);

    // Check if quantity is within available stock
    final availableQuantity = currentItems[index]['availableQuantity'] as int;
    if (quantity > availableQuantity) {
      if (showError && errorCallback != null) {
        errorCallback('Cannot exceed available quantity: $availableQuantity');
      }
      return;
    }

    currentItems[index]['quantity'] = quantity;
    final mrp = currentItems[index]['mrp'];
    final discount = currentItems[index]['discount'];
    currentItems[index]['totalAmount'] =
        (mrp is int ? mrp.toDouble() : mrp) * quantity * (1 - (discount / 100));

    state = state.copyWith(selectedItems: currentItems);
    recalculateTotals();
  }

  // Update item discount
  void updateItemDiscount(int index, double discount) {
    if (discount < 0) discount = 0;
    if (discount > 100) discount = 100;

    final currentItems = List<Map<String, dynamic>>.from(state.selectedItems);
    currentItems[index]['discount'] = discount;
    final quantity = currentItems[index]['quantity'];
    final mrp = currentItems[index]['mrp'];
    currentItems[index]['totalAmount'] =
        (mrp is int ? mrp.toDouble() : mrp) * quantity * (1 - (discount / 100));

    state = state.copyWith(selectedItems: currentItems);
    recalculateTotals();
  }

  // Recalculate totals
  void recalculateTotals({double? discountPercentage, double? taxPercentage}) {
    double subtotal = 0;

    for (var item in state.selectedItems) {
      subtotal += item['totalAmount'];
    }

    final discountValue = discountPercentage ?? 0.0;
    final taxValue = taxPercentage ?? 0.0;

    final discountAmount = subtotal * (discountValue / 100);
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = afterDiscount * (taxValue / 100);
    final total = afterDiscount + taxAmount;

    state = state.copyWith(
      subtotal: subtotal,
      discount: discountAmount,
      tax: taxAmount,
      total: total,
    );
  }

  // Create sale
  Future<void> createSale(double discountPercentage, double taxPercentage,
      {required Function(String) onError}) async {
    if (state.selectedCustomerId == null) {
      onError('Please select a customer');
      return;
    }

    if (state.selectedItems.isEmpty) {
      onError('Please add at least one item');
      return;
    }

    // Prepare items for API
    final items = state.selectedItems
        .map((item) => {
              'inventoryId': item['inventoryId'],
              'quantity': item['quantity'],
              'discount': item['discount'],
            })
        .toList();

    // Prepare request body
    final requestBody = {
      'customerId': state.selectedCustomerId,
      'items': items,
      'discount': discountPercentage,
      'tax': taxPercentage,
      'paymentMethod': state.selectedPaymentMethod,
    };

    state = state.copyWith(isSubmitting: true);

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}/pharma/createSale'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          state = state.copyWith(
            saleResponse: data['data'],
            showSuccessCard: true,
            isSubmitting: false,
          );
          clearForm();
        } else {
          onError('Failed to create sale');
          state = state.copyWith(isSubmitting: false);
        }
      } else {
        onError('Failed to create sale: ${response.body}');
        state = state.copyWith(isSubmitting: false);
      }
    } catch (e) {
      onError('Error: $e');
      state = state.copyWith(isSubmitting: false);
    }
  }

  // Clear form
  void clearForm() {
    state = state.copyWith(
      selectedItems: [],
      subtotal: 0.0,
      discount: 0.0,
      tax: 0.0,
      total: 0.0,
    );
  }

  // Close success card
  void closeSuccessCard() {
    state = state.copyWith(
      showSuccessCard: false,
      saleResponse: null,
    );
  }
}

class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  // Controllers
  final TextEditingController _searchMedicineController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  late FocusNode _mainFocusNode;

  @override
  void initState() {
    super.initState();

    _mainFocusNode = FocusNode();
    _setupKeyboardShortcuts();

    // Initial loading of data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createSaleProvider.notifier).fetchCustomers();
      ref.read(createSaleProvider.notifier).fetchInventory();
    });

    // Add listeners for tax and discount controllers
    _discountController.addListener(_onDiscountChanged);
    _taxController.addListener(_onTaxChanged);
  }

  void _setupKeyboardShortcuts() {
    _mainFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        // Ctrl/Cmd + F = Focus on search
        if ((event.logicalKey == LogicalKeyboardKey.keyF) &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          FocusScope.of(context).requestFocus(FocusNode()..requestFocus());
          _searchMedicineController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchMedicineController.text.length,
          );
          return KeyEventResult.handled;
        }

        // Ctrl/Cmd + S = Submit sale
        if ((event.logicalKey == LogicalKeyboardKey.keyS) &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _createSale();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _onDiscountChanged() {
    final discountValue = double.tryParse(_discountController.text) ?? 0.0;
    final taxValue = double.tryParse(_taxController.text) ?? 0.0;
    ref.read(createSaleProvider.notifier).recalculateTotals(
          discountPercentage: discountValue,
          taxPercentage: taxValue,
        );
  }

  void _onTaxChanged() {
    final discountValue = double.tryParse(_discountController.text) ?? 0.0;
    final taxValue = double.tryParse(_taxController.text) ?? 0.0;
    ref.read(createSaleProvider.notifier).recalculateTotals(
          discountPercentage: discountValue,
          taxPercentage: taxValue,
        );
  }

  void _createSale() {
    final discountValue = double.tryParse(_discountController.text) ?? 0.0;
    final taxValue = double.tryParse(_taxController.text) ?? 0.0;

    ref.read(createSaleProvider.notifier).createSale(
          discountValue,
          taxValue,
          onError: _showErrorSnackBar,
        );
  }

  // Error message
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

  // Format currency with improved type handling
  String _formatCurrency(dynamic amount) {
    double value = 0.0;

    if (amount is int) {
      value = amount.toDouble();
    } else if (amount is double) {
      value = amount;
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }

    return '₹${value.toStringAsFixed(2)}';
  }

  // Format date
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Launch PDF invoice
  void _launchPdf(String url) async {
    Methods().openPdf(url);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSaleProvider);

    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create Sale'),
          backgroundColor: PharmaTheme.primary,
          foregroundColor: PharmaTheme.textLight,
          elevation: 0,
        ),
        body: state.isLoading
            ? Center(
                child: CircularProgressIndicator(color: PharmaTheme.accent))
            : Row(
                children: [
                  // Left side - Customer selection and cart
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: PharmaTheme.surface,
                      padding: EdgeInsets.all(PharmaTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer selection
                          _buildSectionTitle('Select Customer'),
                          _buildCustomerDropdown(),
                          SizedBox(height: PharmaTheme.spacingL),

                          // Cart items
                          _buildSectionTitle('Cart Items'),
                          Expanded(
                            child: state.selectedItems.isEmpty
                                ? _buildEmptyCart()
                                : _buildCartItems(),
                          ),

                          // Cart summary
                          if (state.selectedItems.isNotEmpty)
                            _buildCartSummary(),
                        ],
                      ),
                    ),
                  ),

                  // Right side - Inventory search and selection
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: PharmaTheme.background,
                      child: Column(
                        children: [
                          // Search bar
                          _buildSearchBar(),

                          // Inventory listing
                          Expanded(
                            child: state.filteredInventory.isEmpty
                                ? _buildEmptyInventory()
                                : _buildInventoryList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

        // Success overlay
        floatingActionButton: !state.showSuccessCard
            ? FloatingActionButton.extended(
                onPressed: state.isSubmitting ? null : _createSale,
                label: state.isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: PharmaTheme.textLight,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Complete Sale'),
                icon: Icon(Icons.shopping_cart_checkout),
                backgroundColor: PharmaTheme.accent,
              )
            : null,

        // Success overlay
        bottomSheet: state.showSuccessCard ? _buildSuccessCard() : null,
      ),
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: PharmaTheme.spacingM),
      child: Text(
        title,
        style: PharmaTheme.headingSmall.copyWith(
          color: PharmaTheme.primary,
        ),
      ),
    );
  }

  // Customer dropdown
  Widget _buildCustomerDropdown() {
    final state = ref.watch(createSaleProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: PharmaTheme.border),
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
      ),
      padding: EdgeInsets.symmetric(horizontal: PharmaTheme.spacingM),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select a customer'),
          value: state.selectedCustomerId,
          onChanged: (value) {
            ref.read(createSaleProvider.notifier).setSelectedCustomer(value);
          },
          items: state.customers.map((customer) {
            return DropdownMenuItem<String>(
              value: customer['_id'],
              child: Row(
                children: [
                  Icon(Icons.person, color: PharmaTheme.primary, size: 20),
                  SizedBox(width: PharmaTheme.spacingXs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer['name'],
                          style: PharmaTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer['contactNumber'] != null)
                          Text(
                            customer['contactNumber'],
                            style: PharmaTheme.caption.copyWith(
                              color: PharmaTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (customer['isPatient'] == true)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: PharmaTheme.spacingXs,
                        vertical: PharmaTheme.spacingXxs,
                      ),
                      decoration: BoxDecoration(
                        color: PharmaTheme.success.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusXs),
                      ),
                      child: Text(
                        'Patient',
                        style: PharmaTheme.caption.copyWith(
                          color: PharmaTheme.success,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Empty cart
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: PharmaTheme.textSecondary.withOpacity(0.4),
          ),
          SizedBox(height: PharmaTheme.spacingM),
          Text(
            'Your cart is empty',
            style: PharmaTheme.headingSmall.copyWith(
              color: PharmaTheme.textSecondary,
            ),
          ),
          SizedBox(height: PharmaTheme.spacingXs),
          Text(
            'Add items from the inventory on the right',
            style: PharmaTheme.bodyMedium.copyWith(
              color: PharmaTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Cart items
  Widget _buildCartItems() {
    final state = ref.watch(createSaleProvider);

    return ListView.separated(
      itemCount: state.selectedItems.length,
      separatorBuilder: (context, index) => Divider(color: PharmaTheme.border),
      itemBuilder: (context, index) {
        final item = state.selectedItems[index];
        final medicine = item['medicine'];
        final quantity = item['quantity'];
        final mrp = item['mrp'];
        final discount = item['discount'];
        final totalAmount = item['totalAmount'];

        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: PharmaTheme.spacingXs),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PharmaTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: PharmaTheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: PharmaTheme.spacingM),

              // Medicine details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name'],
                      style: PharmaTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: PharmaTheme.spacingXxs),
                    Text(
                      '${medicine['manufacturer']} • ${medicine['category']}',
                      style: PharmaTheme.caption.copyWith(
                        color: PharmaTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: PharmaTheme.spacingXxs),
                    Text(
                      'Batch: ${item['batchNumber']} • Expires: ${_formatDate(item['expiryDate'])}',
                      style: PharmaTheme.caption.copyWith(
                        color: PharmaTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: PharmaTheme.spacingXs),

                    // Price and quantity
                    Row(
                      children: [
                        // MRP
                        Text(
                          _formatCurrency(mrp),
                          style: PharmaTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: PharmaTheme.textPrimary,
                          ),
                        ),

                        Spacer(),

                        // Quantity controls
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: PharmaTheme.border),
                            borderRadius:
                                BorderRadius.circular(PharmaTheme.radiusXs),
                          ),
                          child: Row(
                            children: [
                              // Decrease button
                              InkWell(
                                onTap: () => ref
                                    .read(createSaleProvider.notifier)
                                    .updateItemQuantity(
                                      index,
                                      quantity - 1,
                                      errorCallback: _showErrorSnackBar,
                                    ),
                                child: Container(
                                  padding:
                                      EdgeInsets.all(PharmaTheme.spacingXxs),
                                  child: Icon(Icons.remove, size: 16),
                                ),
                              ),

                              // Quantity
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: PharmaTheme.spacingXs),
                                child: Text(
                                  quantity.toString(),
                                  style: PharmaTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Increase button
                              InkWell(
                                onTap: () => ref
                                    .read(createSaleProvider.notifier)
                                    .updateItemQuantity(
                                      index,
                                      quantity + 1,
                                      errorCallback: _showErrorSnackBar,
                                    ),
                                child: Container(
                                  padding:
                                      EdgeInsets.all(PharmaTheme.spacingXxs),
                                  child: Icon(Icons.add, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: PharmaTheme.spacingM),

                        // Discount field
                        Container(
                          width: 80,
                          height: 32,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: PharmaTheme.spacingXs,
                                vertical: PharmaTheme.spacingXs,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(PharmaTheme.radiusXs),
                              ),
                              hintText: 'Disc %',
                              hintStyle: PharmaTheme.caption,
                            ),
                            controller: TextEditingController(
                              text: discount.toString(),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(createSaleProvider.notifier)
                                  .updateItemDiscount(
                                    index,
                                    double.tryParse(value) ?? 0.0,
                                  );
                            },
                          ),
                        ),

                        SizedBox(width: PharmaTheme.spacingM),

                        // Total
                        Text(
                          _formatCurrency(totalAmount),
                          style: PharmaTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(width: PharmaTheme.spacingXs),

                        // Remove button
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: PharmaTheme.error),
                          onPressed: () => ref
                              .read(createSaleProvider.notifier)
                              .removeItemFromCart(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Cart summary
  Widget _buildCartSummary() {
    final state = ref.watch(createSaleProvider);

    return Container(
      padding: EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: PharmaTheme.background,
        borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
        border: Border.all(color: PharmaTheme.border),
      ),
      child: Column(
        children: [
          // Summary header
          Row(
            children: [
              Text(
                'Cart Summary',
                style: PharmaTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: PharmaTheme.spacingXs),
              Text(
                '(${state.selectedItems.length} items)',
                style: PharmaTheme.bodyMedium.copyWith(
                  color: PharmaTheme.textSecondary,
                ),
              ),
              Spacer(),

              // Payment method selection
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.selectedPaymentMethod,
                  onChanged: (value) {
                    ref
                        .read(createSaleProvider.notifier)
                        .setPaymentMethod(value);
                  },
                  items: [
                    'cash',
                    'card',
                    'upi',
                    'credit',
                  ].map((method) {
                    IconData icon;
                    switch (method) {
                      case 'card':
                        icon = Icons.credit_card;
                        break;
                      case 'upi':
                        icon = Icons.account_balance;
                        break;
                      case 'credit':
                        icon = Icons.event_note;
                        break;
                      default:
                        icon = Icons.money;
                    }

                    return DropdownMenuItem<String>(
                      value: method,
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: PharmaTheme.primary),
                          SizedBox(width: PharmaTheme.spacingXs),
                          Text(method.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          SizedBox(height: PharmaTheme.spacingM),

          // Summary details
          Row(
            children: [
              // Left column
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Subtotal',
                      _formatCurrency(state.subtotal),
                    ),
                    SizedBox(height: PharmaTheme.spacingXs),

                    // Discount row with input
                    Row(
                      children: [
                        Text('Discount'),
                        SizedBox(width: PharmaTheme.spacingXs),
                        Container(
                          width: 60,
                          height: 32,
                          child: TextField(
                            controller: _discountController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: PharmaTheme.spacingXs,
                                vertical: PharmaTheme.spacingXs,
                              ),
                              border: OutlineInputBorder(),
                              hintText: '%',
                              hintStyle: PharmaTheme.caption,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          _formatCurrency(state.discount),
                          style: TextStyle(
                            color: PharmaTheme.error,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: PharmaTheme.spacingXs),

                    // Tax row with input
                    Row(
                      children: [
                        Text('Tax'),
                        SizedBox(width: PharmaTheme.spacingXs),
                        Container(
                          width: 60,
                          height: 32,
                          child: TextField(
                            controller: _taxController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: PharmaTheme.spacingXs,
                                vertical: PharmaTheme.spacingXs,
                              ),
                              border: OutlineInputBorder(),
                              hintText: '%',
                              hintStyle: PharmaTheme.caption,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(_formatCurrency(state.tax)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: PharmaTheme.spacingL),

              // Right column with total
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(PharmaTheme.spacingM),
                  decoration: BoxDecoration(
                    gradient: PharmaTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: PharmaTheme.bodyMedium.copyWith(
                          color: PharmaTheme.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: PharmaTheme.spacingXs),
                      Text(
                        _formatCurrency(state.total),
                        style: PharmaTheme.headingLarge.copyWith(
                          color: PharmaTheme.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Summary row
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value),
      ],
    );
  }

  // Search bar
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(PharmaTheme.spacingM),
      color: PharmaTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory',
            style: PharmaTheme.headingSmall.copyWith(
              color: PharmaTheme.textLight,
            ),
          ),
          SizedBox(height: PharmaTheme.spacingM),
          Container(
            decoration: BoxDecoration(
              color: PharmaTheme.surface,
              borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
            ),
            child: TextField(
              controller: _searchMedicineController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: PharmaTheme.spacingM),
              ),
              onChanged: (value) =>
                  ref.read(createSaleProvider.notifier).filterInventory(value),
            ),
          ),
        ],
      ),
    );
  }

  // Empty inventory
  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: PharmaTheme.textSecondary.withOpacity(0.4),
          ),
          SizedBox(height: PharmaTheme.spacingM),
          Text(
            'No items found',
            style: PharmaTheme.headingSmall.copyWith(
              color: PharmaTheme.textSecondary,
            ),
          ),
          SizedBox(height: PharmaTheme.spacingXs),
          Text(
            'Try a different search term',
            style: PharmaTheme.bodyMedium.copyWith(
              color: PharmaTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Inventory list
  Widget _buildInventoryList() {
    final state = ref.watch(createSaleProvider);

    return ListView.builder(
      padding: EdgeInsets.all(PharmaTheme.spacingM),
      itemCount: state.filteredInventory.length,
      itemBuilder: (context, index) {
        final item = state.filteredInventory[index];
        final medicine = item['medicine'] as Map<String, dynamic>;
        final name = medicine['name'];
        final manufacturer = medicine['manufacturer'];
        final category = medicine['category'];
        final mrp = medicine['mrp'];
        final batchNumber = item['batchNumber'];
        final expiryDate = _formatDate(item['expiryDate']);
        final quantity = item['quantity'];

        // Get expiry date for color coding
        final expiry = DateTime.parse(item['expiryDate']);
        final now = DateTime.now();
        final difference = expiry.difference(now).inDays;

        // Define color for expiry indicator
        Color expiryColor = PharmaTheme.success;
        if (difference < 30) {
          expiryColor = PharmaTheme.warning;
        }
        if (difference < 7) {
          expiryColor = PharmaTheme.error;
        }

        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: PharmaTheme.spacingXs),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
            side: BorderSide(color: PharmaTheme.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
            onTap: () =>
                ref.read(createSaleProvider.notifier).addItemToCart(item),
            child: Padding(
              padding: EdgeInsets.all(PharmaTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name and add button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: PharmaTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: PharmaTheme.accent),
                        onPressed: () => ref
                            .read(createSaleProvider.notifier)
                            .addItemToCart(item),
                      ),
                    ],
                  ),

                  SizedBox(height: PharmaTheme.spacingXs),

                  // Medicine details
                  Text(
                    '$manufacturer • $category',
                    style: PharmaTheme.caption.copyWith(
                      color: PharmaTheme.textSecondary,
                    ),
                  ),

                  SizedBox(height: PharmaTheme.spacingXs),

                  // Batch and expiry
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PharmaTheme.spacingXs,
                          vertical: PharmaTheme.spacingXxs,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaTheme.background,
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusXs),
                        ),
                        child: Text(
                          'Batch: $batchNumber',
                          style: PharmaTheme.caption.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: PharmaTheme.spacingXs),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PharmaTheme.spacingXs,
                          vertical: PharmaTheme.spacingXxs,
                        ),
                        decoration: BoxDecoration(
                          color: expiryColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusXs),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: expiryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Exp: $expiryDate',
                              style: PharmaTheme.caption.copyWith(
                                fontWeight: FontWeight.w500,
                                color: expiryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: PharmaTheme.spacingM),

                  // Price and stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(mrp),
                        style: PharmaTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PharmaTheme.primary,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PharmaTheme.spacingXs,
                          vertical: PharmaTheme.spacingXxs,
                        ),
                        decoration: BoxDecoration(
                          color: PharmaTheme.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusXs),
                        ),
                        child: Text(
                          '$quantity in stock',
                          style: PharmaTheme.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: PharmaTheme.primary,
                          ),
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
    );
  }

  // Success card
  Widget _buildSuccessCard() {
    final state = ref.watch(createSaleProvider);
    if (state.saleResponse == null) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PharmaTheme.surface,
        boxShadow: PharmaTheme.shadowLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top success bar
          Container(
            padding: EdgeInsets.symmetric(vertical: PharmaTheme.spacingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PharmaTheme.success,
                  PharmaTheme.success.withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: PharmaTheme.textLight),
                SizedBox(width: PharmaTheme.spacingXs),
                Text(
                  'Sale Completed Successfully',
                  style: PharmaTheme.bodyLarge.copyWith(
                    color: PharmaTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Sale details
          Padding(
            padding: EdgeInsets.all(PharmaTheme.spacingM),
            child: Column(
              children: [
                // Invoice details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice #: ${state.saleResponse!['billNumber']}',
                          style: PharmaTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: PharmaTheme.spacingXxs),
                        Text(
                          'Date: ${_formatDate(state.saleResponse!['createdAt'])}',
                          style: PharmaTheme.caption.copyWith(
                            color: PharmaTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // PDF button
                    if (state.saleResponse!['pdfLink'] != null)
                      ElevatedButton.icon(
                        icon: Icon(Icons.receipt_long),
                        label: Text('View Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmaTheme.primary,
                          foregroundColor: PharmaTheme.textLight,
                        ),
                        onPressed: () {
                          _launchPdf(state.saleResponse!['pdfLink']);
                        },
                      ),
                  ],
                ),

                SizedBox(height: PharmaTheme.spacingM),

                // Customer info and amount
                Row(
                  children: [
                    // Customer info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: PharmaTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: PharmaTheme.spacingXxs),
                          Text(
                            state.saleResponse!['customer']['name'],
                            style: PharmaTheme.bodyMedium,
                          ),
                          if (state.saleResponse!['customer']
                                  ['contactNumber'] !=
                              null)
                            Text(
                              state.saleResponse!['customer']['contactNumber'],
                              style: PharmaTheme.caption.copyWith(
                                color: PharmaTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Payment info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: PharmaTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: PharmaTheme.spacingXxs),
                          Row(
                            children: [
                              Icon(
                                state.selectedPaymentMethod == 'cash'
                                    ? Icons.money
                                    : state.selectedPaymentMethod == 'card'
                                        ? Icons.credit_card
                                        : state.selectedPaymentMethod == 'upi'
                                            ? Icons.account_balance
                                            : Icons.event_note,
                                size: 16,
                                color: PharmaTheme.primary,
                              ),
                              SizedBox(width: PharmaTheme.spacingXs),
                              Text(
                                state.selectedPaymentMethod!.toUpperCase(),
                                style: PharmaTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Total amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Amount',
                            style: PharmaTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: PharmaTheme.spacingXxs),
                          Text(
                            _formatCurrency(
                                _convertToDouble(state.saleResponse!['total'])),
                            style: PharmaTheme.headingMedium.copyWith(
                              color: PharmaTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: PharmaTheme.spacingL),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ref
                            .read(createSaleProvider.notifier)
                            .closeSuccessCard();
                      },
                      child: Text('Close'),
                    ),
                    SizedBox(width: PharmaTheme.spacingM),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_shopping_cart),
                      label: Text('New Sale'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PharmaTheme.accent,
                        foregroundColor: PharmaTheme.textLight,
                      ),
                      onPressed: () {
                        ref
                            .read(createSaleProvider.notifier)
                            .closeSuccessCard();
                      },
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

  // Add this helper method to handle conversion between int and double
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

  @override
  void dispose() {
    _searchMedicineController.dispose();
    _discountController.removeListener(_onDiscountChanged);
    _taxController.removeListener(_onTaxChanged);
    _discountController.dispose();
    _taxController.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }
}
