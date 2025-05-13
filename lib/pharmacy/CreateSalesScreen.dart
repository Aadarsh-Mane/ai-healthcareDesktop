import 'dart:convert';

import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/pharmacy/SalesHistoryScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({Key? key}) : super(key: key);

  @override
  _CreateSaleScreenState createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  // Color scheme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);

  // Controllers
  final TextEditingController _searchMedicineController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showSuccessCard = false;

  // Selected values
  String? _selectedCustomerId;
  String? _selectedPaymentMethod = 'cash';
  Map<String, dynamic>? _saleResponse;

  // Data lists
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _filteredInventory = [];
  List<Map<String, dynamic>> _selectedItems = [];

  // Values for calculations
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _tax = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchInventory();
  }

  // Fetch customers from API
  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/pharma/getCustomers'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _customers = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      } else {
        _showErrorSnackBar('Failed to load customers');
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
  Future<void> _fetchInventory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/pharma/getInventory'),
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

          setState(() {
            _inventory = processedInventory;
            _filteredInventory = processedInventory;
          });
        }
      } else {
        _showErrorSnackBar('Failed to load inventory');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter inventory based on search term
  void _filterInventory(String searchTerm) {
    if (searchTerm.isEmpty) {
      setState(() {
        _filteredInventory = List<Map<String, dynamic>>.from(_inventory);
      });
      return;
    }

    final filtered = _inventory.where((item) {
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

    setState(() {
      _filteredInventory = filtered;
    });
  }

  // Add item to selected items
  void _addItemToCart(Map<String, dynamic> item) {
    // Check if item is already in cart
    final existingItemIndex = _selectedItems.indexWhere(
        (selectedItem) => selectedItem['inventoryId'] == item['_id']);

    if (existingItemIndex != -1) {
      // Update quantity if already in cart
      setState(() {
        _selectedItems[existingItemIndex]['quantity'] += 1;
        _recalculateTotals();
      });
    } else {
      // Add as new item if not in cart
      final medicine = item['medicine'] as Map<String, dynamic>;

      setState(() {
        _selectedItems.add({
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
        ;
        _recalculateTotals();
      });
    }
  }

  // Remove item from selected items
  void _removeItemFromCart(int index) {
    setState(() {
      _selectedItems.removeAt(index);
      _recalculateTotals();
    });
  }

  // Update item quantity
  void _updateItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeItemFromCart(index);
      return;
    }

    // Check if quantity is within available stock
    final availableQuantity = _selectedItems[index]['availableQuantity'] as int;
    if (quantity > availableQuantity) {
      _showErrorSnackBar(
          'Cannot exceed available quantity: $availableQuantity');
      return;
    }
    setState(() {
      _selectedItems[index]['quantity'] = quantity;
      final mrp = _selectedItems[index]['mrp'];
      final discount = _selectedItems[index]['discount'];
      _selectedItems[index]['totalAmount'] =
          (mrp is int ? mrp.toDouble() : mrp) *
              quantity *
              (1 - (discount / 100));
      _recalculateTotals();
    });
  }

  // Update item discount
  void _updateItemDiscount(int index, double discount) {
    if (discount < 0) discount = 0;
    if (discount > 100) discount = 100;

    setState(() {
      _selectedItems[index]['discount'] = discount;
      final quantity = _selectedItems[index]['quantity'];
      final mrp = _selectedItems[index]['mrp'];
      _selectedItems[index]['totalAmount'] =
          (mrp is int ? mrp.toDouble() : mrp) *
              quantity *
              (1 - (discount / 100));
      _recalculateTotals();
    });
  }

  // Recalculate all totals
  void _recalculateTotals() {
    double subtotal = 0;

    for (var item in _selectedItems) {
      subtotal += item['totalAmount'];
    }

    final discountValue = _discountController.text.isEmpty
        ? 0.0
        : double.tryParse(_discountController.text) ?? 0.0;

    final taxValue = _taxController.text.isEmpty
        ? 0.0
        : double.tryParse(_taxController.text) ?? 0.0;

    final discountAmount = subtotal * (discountValue / 100);
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = afterDiscount * (taxValue / 100);
    final total = afterDiscount + taxAmount;

    setState(() {
      _subtotal = subtotal;
      _discount = discountAmount;
      _tax = taxAmount;
      _total = total;
    });
  }

  // Create sale
  Future<void> _createSale() async {
    if (_selectedCustomerId == null) {
      _showErrorSnackBar('Please select a customer');
      return;
    }

    if (_selectedItems.isEmpty) {
      _showErrorSnackBar('Please add at least one item');
      return;
    }

    // Prepare items for API
    final items = _selectedItems
        .map((item) => {
              'inventoryId': item['inventoryId'],
              'quantity': item['quantity'],
              'discount': item['discount'],
            })
        .toList();

    // Prepare discount and tax
    final discountValue = _discountController.text.isEmpty
        ? 0.0
        : double.tryParse(_discountController.text) ?? 0.0;

    final taxValue = _taxController.text.isEmpty
        ? 0.0
        : double.tryParse(_taxController.text) ?? 0.0;

    // Prepare request body
    final requestBody = {
      'customerId': _selectedCustomerId,
      'items': items,
      'discount': discountValue,
      'tax': taxValue,
      'paymentMethod': _selectedPaymentMethod,
    };

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/pharma/createSale'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _saleResponse = data['data'];
            _showSuccessCard = true;
          });
          _clearForm();
        } else {
          _showErrorSnackBar('Failed to create sale');
        }
      } else {
        _showErrorSnackBar('Failed to create sale: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Clear form after successful sale
  void _clearForm() {
    setState(() {
      _selectedItems = [];
      _discountController.clear();
      _taxController.clear();
      _subtotal = 0.0;
      _discount = 0.0;
      _tax = 0.0;
      _total = 0.0;
    });
  }

  // Error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Format currency
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Sale'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : Row(
              children: [
                // Left side - Customer selection and cart
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer selection
                        _buildSectionTitle('Select Customer'),
                        _buildCustomerDropdown(),
                        SizedBox(height: 24),

                        // Cart items
                        _buildSectionTitle('Cart Items'),
                        Expanded(
                          child: _selectedItems.isEmpty
                              ? _buildEmptyCart()
                              : _buildCartItems(),
                        ),

                        // Cart summary
                        if (_selectedItems.isNotEmpty) _buildCartSummary(),
                      ],
                    ),
                  ),
                ),

                // Right side - Inventory search and selection
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        // Search bar
                        _buildSearchBar(),

                        // Inventory listing
                        Expanded(
                          child: _filteredInventory.isEmpty
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
      floatingActionButton: !_showSuccessCard
          ? FloatingActionButton.extended(
              onPressed: _isSubmitting ? null : _createSale,
              label: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Complete Sale'),
              icon: Icon(Icons.shopping_cart_checkout),
              backgroundColor: accentColor,
            )
          : null,

      // Success overlay
      bottomSheet: _showSuccessCard ? _buildSuccessCard() : null,
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  // Customer dropdown
  Widget _buildCustomerDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select a customer'),
          value: _selectedCustomerId,
          onChanged: (value) {
            setState(() {
              _selectedCustomerId = value;
            });
          },
          items: _customers.map((customer) {
            return DropdownMenuItem<String>(
              value: customer['_id'],
              child: Row(
                children: [
                  Icon(Icons.person, color: primaryColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customer['contactNumber'] != null)
                          Text(
                            customer['contactNumber'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  if (customer['isPatient'] == true)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Patient',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
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
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add items from the inventory on the right',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Cart items
  Widget _buildCartItems() {
    return ListView.separated(
      itemCount: _selectedItems.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final item = _selectedItems[index];
        final medicine = item['medicine'];
        final quantity = item['quantity'];
        final mrp = item['mrp'];
        final discount = item['discount'];
        final totalAmount = item['totalAmount'];

        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),

              // Medicine details
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
                      '${medicine['manufacturer']} • ${medicine['category']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Batch: ${item['batchNumber']} • Expires: ${_formatDate(item['expiryDate'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),

                    // Price and quantity
                    Row(
                      children: [
                        // MRP
                        Text(
                          _formatCurrency(mrp),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),

                        Spacer(),

                        // Quantity controls
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              // Decrease button
                              InkWell(
                                onTap: () =>
                                    _updateItemQuantity(index, quantity - 1),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.remove, size: 16),
                                ),
                              ),

                              // Quantity
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  quantity.toString(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              // Increase button
                              InkWell(
                                onTap: () =>
                                    _updateItemQuantity(index, quantity + 1),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.add, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 16),

                        // Discount field
                        Container(
                          width: 80,
                          height: 32,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                              hintText: 'Disc %',
                              hintStyle: TextStyle(fontSize: 12),
                            ),
                            controller: TextEditingController(
                              text: discount.toString(),
                            ),
                            onChanged: (value) {
                              _updateItemDiscount(
                                index,
                                double.tryParse(value) ?? 0.0,
                              );
                            },
                          ),
                        ),

                        SizedBox(width: 16),

                        // Total
                        Text(
                          _formatCurrency(totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(width: 8),

                        // Remove button
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeItemFromCart(index),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Summary header
          Row(
            children: [
              Text(
                'Cart Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '(${_selectedItems.length} items)',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Spacer(),

              // Payment method selection
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
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
                          Icon(icon, size: 16, color: primaryColor),
                          SizedBox(width: 8),
                          Text(method.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

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
                      _formatCurrency(_subtotal),
                    ),
                    SizedBox(height: 8),

                    // Discount row with input
                    Row(
                      children: [
                        Text('Discount'),
                        SizedBox(width: 8),
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
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                              hintText: '%',
                              hintStyle: TextStyle(fontSize: 12),
                            ),
                            onChanged: (value) {
                              _recalculateTotals();
                            },
                          ),
                        ),
                        Spacer(),
                        Text(
                          _formatCurrency(_discount),
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Tax row with input
                    Row(
                      children: [
                        Text('Tax'),
                        SizedBox(width: 8),
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
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                              hintText: '%',
                              hintStyle: TextStyle(fontSize: 12),
                            ),
                            onChanged: (value) {
                              _recalculateTotals();
                            },
                          ),
                        ),
                        Spacer(),
                        Text(_formatCurrency(_tax)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 24),

              // Right column with total
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatCurrency(_total),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
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
      padding: EdgeInsets.all(16),
      color: primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchMedicineController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _filterInventory,
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
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Inventory list
  // Inventory list
  Widget _buildInventoryList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredInventory.length,
      itemBuilder: (context, index) {
        final item = _filteredInventory[index];
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
        Color expiryColor = Colors.green;
        if (difference < 30) {
          expiryColor = Colors.orange;
        }
        if (difference < 7) {
          expiryColor = Colors.red;
        }

        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _addItemToCart(item),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine name and add button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: accentColor),
                        onPressed: () => _addItemToCart(item),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Medicine details
                  Text(
                    '$manufacturer • $category',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Batch and expiry
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Batch: $batchNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: expiryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: expiryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Price and stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(mrp),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$quantity in stock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
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
  // Update your _buildSuccessCard() method to handle potential integer values
  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top success bar
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Sale Completed Successfully',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Sale details
          Padding(
            padding: EdgeInsets.all(16),
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
                          'Invoice #: ${_saleResponse!['billNumber']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Date: ${_formatDate(_saleResponse!['createdAt'])}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // PDF button
                    if (_saleResponse!['pdfLink'] != null)
                      ElevatedButton.icon(
                        icon: Icon(Icons.receipt_long),
                        label: Text('View Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _launchPdf(_saleResponse!['pdfLink']);
                        },
                      ),
                  ],
                ),

                SizedBox(height: 16),

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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _saleResponse!['customer']['name'],
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          if (_saleResponse!['customer']['contactNumber'] !=
                              null)
                            Text(
                              _saleResponse!['customer']['contactNumber'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _selectedPaymentMethod == 'cash'
                                    ? Icons.money
                                    : _selectedPaymentMethod == 'card'
                                        ? Icons.credit_card
                                        : _selectedPaymentMethod == 'upi'
                                            ? Icons.account_balance
                                            : Icons.event_note,
                                size: 16,
                                color: primaryColor,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _selectedPaymentMethod!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                ),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            // Convert the total to double to avoid type issues
                            _formatCurrency(
                                _convertToDouble(_saleResponse!['total'])),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showSuccessCard = false;
                          _saleResponse = null;
                        });
                      },
                      child: Text('Close'),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_shopping_cart),
                      label: Text('New Sale'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _showSuccessCard = false;
                          _saleResponse = null;
                        });
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
}

// Add this to your main.dart file to run the application
void main() {
  runApp(PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Management',
      theme: ThemeData(
        primaryColor: Color(0xFF005F9E),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF005F9E),
          secondary: Color(0xFF00B8D4),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF005F9E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      home: CreateSaleScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
