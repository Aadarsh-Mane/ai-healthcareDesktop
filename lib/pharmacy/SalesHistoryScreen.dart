import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  // Color scheme
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color highlightColor = const Color(0xFFE1F5FE);

  // State variables
  bool _isLoading = false;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _filteredSales = [];
  Map<String, dynamic>? _selectedSale;

  // Filters
  String _searchQuery = '';
  String _selectedDateFilter = 'All';
  String _selectedCustomerFilter = 'All';
  String _selectedSortOption = 'Date (Newest First)';

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  // Fetch sales data from API
  Future<void> _fetchSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/pharma/getSales'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final salesData = List<Map<String, dynamic>>.from(data['data']);

          setState(() {
            _sales = salesData;
            _filteredSales = salesData;
          });
        }
      } else {
        _showErrorSnackBar('Failed to load sales data');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter sales based on search query and filters
  void _filterSales() {
    List<Map<String, dynamic>> filtered = List.from(_sales);

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((sale) {
        final billNumber = sale['billNumber'].toString().toLowerCase();
        final customerName = sale['customer']['name'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return billNumber.contains(query) || customerName.contains(query);
      }).toList();
    }

    // Apply date filter
    if (_selectedDateFilter != 'All') {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedDateFilter) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'Last 3 Months':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        default:
          startDate = DateTime(2000);
      }

      filtered = filtered.where((sale) {
        final saleDate = DateTime.parse(sale['createdAt']);
        return saleDate.isAfter(startDate);
      }).toList();
    }

    // Apply customer filter
    if (_selectedCustomerFilter != 'All') {
      filtered = filtered.where((sale) {
        return sale['customer']['name'] == _selectedCustomerFilter;
      }).toList();
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'Date (Newest First)':
        filtered.sort((a, b) => DateTime.parse(b['createdAt'])
            .compareTo(DateTime.parse(a['createdAt'])));
        break;
      case 'Date (Oldest First)':
        filtered.sort((a, b) => DateTime.parse(a['createdAt'])
            .compareTo(DateTime.parse(b['createdAt'])));
        break;
      case 'Bill Number':
        filtered.sort((a, b) => a['billNumber'].compareTo(b['billNumber']));
        break;
      case 'Amount (High to Low)':
        filtered.sort((a, b) => _convertToDouble(b['total'])
            .compareTo(_convertToDouble(a['total'])));
        break;
      case 'Amount (Low to High)':
        filtered.sort((a, b) => _convertToDouble(a['total'])
            .compareTo(_convertToDouble(b['total'])));
        break;
    }

    setState(() {
      _filteredSales = filtered;
      if (_filteredSales.isNotEmpty && _selectedSale == null) {
        _selectedSale = _filteredSales.first;
      } else if (_filteredSales.isEmpty) {
        _selectedSale = null;
      } else if (_selectedSale != null) {
        // Make sure the selected sale is still in the filtered list
        final stillExists =
            _filteredSales.any((sale) => sale['_id'] == _selectedSale!['_id']);
        if (!stillExists) {
          _selectedSale = _filteredSales.first;
        }
      }
    });
  }

  // Get a list of all unique customers
  List<String> _getUniqueCustomers() {
    final customers = _sales
        .map((sale) => sale['customer']['name'] as String)
        .toSet()
        .toList();
    customers.sort();
    return ['All', ...customers];
  }

  // Helper method to convert any numeric type to double
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

  // Format currency
  String _formatCurrency(dynamic amount) {
    return '₹${_convertToDouble(amount).toStringAsFixed(2)}';
  }

  // Format date
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy h:mm a').format(date);
  }

  // Format date (short)
  String _formatShortDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Launch PDF invoice
  void _launchPdf(String url) {
    // Using your existing openPdf method
    // Methods().openPdf(url);
    // For now, just print the URL to console
    print('Opening PDF: $url');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Text(
                'Sales History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchSales,
                tooltip: 'Refresh Sales Data',
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : Column(
              children: [
                // Filter bar
                _buildFilterBar(),

                // Main content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left panel - Sales table
                      Expanded(
                        flex: 3,
                        child: _buildSalesTable(),
                      ),

                      // Right panel - Sale details
                      Expanded(
                        flex: 2,
                        child: _selectedSale != null
                            ? _buildSaleDetails()
                            : Center(
                                child: Text(
                                  'Select a sale to view details',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Filter bar
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            flex: 3,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by invoice number or customer name...',
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterSales();
                },
              ),
            ),
          ),

          SizedBox(width: 16),

          // Date filter
          Expanded(
            flex: 2,
            child: Container(
              height: 46,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Date Range'),
                  value: _selectedDateFilter,
                  icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDateFilter = value;
                      });
                      _filterSales();
                    }
                  },
                  items: [
                    'All',
                    'Today',
                    'This Week',
                    'This Month',
                    'Last 3 Months',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          // Customer filter
          Expanded(
            flex: 2,
            child: Container(
              height: 46,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Customer'),
                  value: _selectedCustomerFilter,
                  icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCustomerFilter = value;
                      });
                      _filterSales();
                    }
                  },
                  items: _getUniqueCustomers().map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          // Sort option
          Expanded(
            flex: 2,
            child: Container(
              height: 46,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Sort By'),
                  value: _selectedSortOption,
                  icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSortOption = value;
                      });
                      _filterSales();
                    }
                  },
                  items: [
                    'Date (Newest First)',
                    'Date (Oldest First)',
                    'Bill Number',
                    'Amount (High to Low)',
                    'Amount (Low to High)',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced table display for the sales history screen
  Widget _buildSalesTable() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced table header
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                for (var column in [
                  {'label': 'Invoice #', 'flex': 2},
                  {'label': 'Customer', 'flex': 3},
                  {'label': 'Date', 'flex': 2},
                  {'label': 'Items', 'flex': 2},
                  {'label': 'Total', 'flex': 2, 'align': TextAlign.right},
                ])
                  Expanded(
                    flex: column['flex'] as int,
                    child: Text(
                      column['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor.withOpacity(0.8),
                        fontSize: 15,
                      ),
                      textAlign:
                          column['align'] as TextAlign? ?? TextAlign.left,
                    ),
                  ),
              ],
            ),
          ),

          // Enhanced table body
          Expanded(
            child: _filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No sales found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _tableScrollController,
                    itemCount: _filteredSales.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final sale = _filteredSales[index];
                      final isSelected = _selectedSale != null &&
                          _selectedSale!['_id'] == sale['_id'];

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSale = sale;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? highlightColor : Colors.white,
                              border: isSelected
                                  ? Border.all(
                                      color: primaryColor.withOpacity(0.3),
                                      width: 1.5)
                                  : null,
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    sale['billNumber'],
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: sale['customer']
                                                      ['isPatient'] ==
                                                  true
                                              ? Colors.green[50]
                                              : Colors.blue[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          sale['customer']['isPatient'] == true
                                              ? Icons.medical_services_outlined
                                              : Icons.person_outline,
                                          size: 14,
                                          color: sale['customer']
                                                      ['isPatient'] ==
                                                  true
                                              ? Colors.green[700]
                                              : primaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          sale['customer']['name'],
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? primaryColor
                                                : Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _formatShortDate(sale['createdAt']),
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor.withOpacity(0.8)
                                          : Colors.grey[700],
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor.withOpacity(0.1)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(sale['items'] as List).length} ${(sale['items'] as List).length == 1 ? 'item' : 'items'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.grey[800],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _formatCurrency(sale['total']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey[800],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Enhanced table footer
          Container(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Showing ${_filteredSales.length} of ${_sales.length} sales',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Text(
                  'Total: ${_formatCurrency(_filteredSales.fold(0.0, (sum, sale) => sum + _convertToDouble(sale['total'])))}',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: child,
        ),
      ],
    );
  }

// Enhanced item details in sales details panel
  Widget _buildItemsSection(List<Map<String, dynamic>> items) {
    return _buildDetailSection(
      title: 'Items',
      child: Column(
        children: [
          // Enhanced items table header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Item',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Price',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Disc',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Enhanced items list
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final medicine = item['medicine'] as Map<String, dynamic>;

                // Check if item is expired
                bool isExpired = false;
                String expiryStatus = '';
                if (item.containsKey('expiryDate')) {
                  final expiry = DateTime.parse(item['expiryDate']);
                  final now = DateTime.now();
                  final difference = expiry.difference(now).inDays;

                  if (difference < 0) {
                    isExpired = true;
                    expiryStatus = 'Expired';
                  } else if (difference < 30) {
                    expiryStatus = 'Expiring soon';
                  }
                }

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Medicine icon
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.medication_outlined,
                                    color: primaryColor,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 10),
                                // Medicine name
                                Expanded(
                                  child: Text(
                                    medicine['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Padding(
                              padding: EdgeInsets.only(left: 38),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Manufacturer and category
                                  Text(
                                    '${medicine['manufacturer']} • ${medicine['category']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  // Batch number and expiry status
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Batch: ${item['batchNumber']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (expiryStatus.isNotEmpty) ...[
                                        SizedBox(width: 6),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isExpired
                                                ? Colors.red[50]
                                                : Colors.amber[50],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isExpired
                                                    ? Icons.error_outline
                                                    : Icons
                                                        .warning_amber_outlined,
                                                size: 12,
                                                color: isExpired
                                                    ? Colors.red[700]
                                                    : Colors.amber[700],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                expiryStatus,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isExpired
                                                      ? Colors.red[700]
                                                      : Colors.amber[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['quantity'].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCurrency(item['mrp']),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: _convertToDouble(item['discount']) > 0
                                ? Colors.green[50]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['discount']}%',
                            style: TextStyle(
                              color: _convertToDouble(item['discount']) > 0
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                              fontWeight: _convertToDouble(item['discount']) > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCurrency(item['totalAmount']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add item totals summary
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Items: ${items.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Total Quantity: ${items.fold(0, (sum, item) => sum + (item['quantity'] as int))}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Responsive layout helper for different screen sizes
  Widget _buildResponsiveLayout(BuildContext context) {
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine layout based on screen width
    if (screenWidth < 1000) {
      // Compact layout for smaller screens
      return Column(
        children: [
          // Filter bar at the top
          _buildFilterBar(),

          // Sales table takes full width
          Expanded(
            child: _buildSalesTable(),
          ),

          // Details shown at bottom if selected
          if (_selectedSale != null)
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: _buildSaleDetails(),
            ),
        ],
      );
    } else {
      // Regular side-by-side layout for larger screens
      return Column(
        children: [
          // Filter bar
          _buildFilterBar(),

          // Main content with table and details side-by-side
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel - Sales table
                Expanded(
                  flex: 3,
                  child: _buildSalesTable(),
                ),

                // Right panel - Sale details
                Expanded(
                  flex: 2,
                  child: _selectedSale != null
                      ? _buildSaleDetails()
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Select a sale to view details',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Sale details panel
  Widget _buildSaleDetails() {
    if (_selectedSale == null) return SizedBox();

    final sale = _selectedSale!;
    final items = List<Map<String, dynamic>>.from(sale['items']);
    final customer = sale['customer'] as Map<String, dynamic>;

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice #: ${sale['billNumber']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _formatDate(sale['createdAt']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (sale['pdfLink'] != null)
                  ElevatedButton.icon(
                    onPressed: () => _launchPdf(sale['pdfLink']),
                    icon: Icon(Icons.picture_as_pdf, size: 18),
                    label: Text('View Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      elevation: 2,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content area with scrolling
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - 40, // Accounting for padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Customer information
                        _buildEnhancedDetailSection(
                          title: 'Customer Information',
                          icon: Icons.person_outline,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: customer['isPatient'] == true
                                          ? Colors.green[50]
                                          : primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(27),
                                      border: Border.all(
                                        color: customer['isPatient'] == true
                                            ? Colors.green[200]!
                                            : primaryColor.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      customer['isPatient'] == true
                                          ? Icons.medical_services
                                          : Icons.person,
                                      color: customer['isPatient'] == true
                                          ? Colors.green[700]
                                          : primaryColor,
                                      size: 26,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                customer['name'] ?? 'Unknown',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            if (customer['isPatient'] == true)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[100],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.green[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Patient',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green[800],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        // Customer details in responsive grid
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          children: [
                                            if (customer['contactNumber'] !=
                                                null)
                                              _buildContactInfo(
                                                icon: Icons.phone,
                                                label:
                                                    customer['contactNumber'],
                                              ),
                                            if (customer['email'] != null)
                                              _buildContactInfo(
                                                icon: Icons.email_outlined,
                                                label: customer['email'],
                                              ),
                                          ],
                                        ),
                                        if (customer['address'] != null) ...[
                                          SizedBox(height: 8),
                                          _buildContactInfo(
                                            icon: Icons.location_on_outlined,
                                            label: customer['address'],
                                            isFullWidth: true,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Enhanced Payment information
                        _buildEnhancedDetailSection(
                          title: 'Payment Information',
                          icon: Icons.payment,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Wrap(
                              spacing: 30,
                              runSpacing: 20,
                              children: [
                                // Payment method
                                Container(
                                  constraints: BoxConstraints(minWidth: 150),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Payment Method',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getPaymentMethodColor(
                                                  sale['paymentMethod'])
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _getPaymentMethodColor(
                                                    sale['paymentMethod'])
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getPaymentMethodIcon(
                                                  sale['paymentMethod']),
                                              size: 18,
                                              color: _getPaymentMethodColor(
                                                  sale['paymentMethod']),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              (sale['paymentMethod'] as String)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _getPaymentMethodColor(
                                                    sale['paymentMethod']),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Date
                                Container(
                                  constraints: BoxConstraints(minWidth: 150),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sale Date',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color:
                                                primaryColor.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event,
                                              size: 18,
                                              color: primaryColor,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              _formatShortDate(
                                                  sale['createdAt']),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Invoice Number
                                Container(
                                  constraints: BoxConstraints(minWidth: 150),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Invoice Number',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.orange.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color:
                                                Colors.orange.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.receipt_long,
                                              size: 18,
                                              color: Colors.orange[700],
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              sale['billNumber'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
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
                          ),
                        ),

                        SizedBox(height: 24),

                        // Enhanced Items list
                        _buildEnhancedDetailSection(
                          title: 'Items',
                          icon: Icons.shopping_cart_outlined,
                          child: Column(
                            children: [
                              // Items table header
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: primaryColor.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Item',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Price',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Disc',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Items list with better styling
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey[200],
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    final medicine = item['medicine']
                                        as Map<String, dynamic>;
                                    final hasDiscount =
                                        _convertToDouble(item['discount']) > 0;

                                    // Check for expiry info
                                    bool isExpired = false;
                                    String expiryStatus = '';
                                    if (item.containsKey('expiryDate')) {
                                      try {
                                        final expiry =
                                            DateTime.parse(item['expiryDate']);
                                        final now = DateTime.now();
                                        final difference =
                                            expiry.difference(now).inDays;

                                        if (difference < 0) {
                                          isExpired = true;
                                          expiryStatus = 'Expired';
                                        } else if (difference < 30) {
                                          expiryStatus = 'Expiring soon';
                                        }
                                      } catch (e) {
                                        // Handle parsing error
                                        print('Error parsing expiry date: $e');
                                      }
                                    }

                                    return Container(
                                      color: index % 2 == 0
                                          ? Colors.grey[50]
                                          : Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      child: Row(
                                        children: [
                                          // Item details
                                          Expanded(
                                            flex: 4,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Medicine icon
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: primaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    Icons.medication_outlined,
                                                    color: primaryColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                // Item info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        medicine['name'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        '${medicine['manufacturer']} • ${medicine['category']}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      // Batch and expiry info
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 6,
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .grey[200],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: Text(
                                                              'Batch: ${item['batchNumber']}',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey[800],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                          if (expiryStatus
                                                              .isNotEmpty)
                                                            Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: isExpired
                                                                    ? Colors
                                                                        .red[50]
                                                                    : Colors
                                                                        .amber[50],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    isExpired
                                                                        ? Icons
                                                                            .error_outline
                                                                        : Icons
                                                                            .warning_amber_outlined,
                                                                    size: 10,
                                                                    color: isExpired
                                                                        ? Colors.red[
                                                                            700]
                                                                        : Colors
                                                                            .amber[700],
                                                                  ),
                                                                  SizedBox(
                                                                      width: 4),
                                                                  Text(
                                                                    expiryStatus,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: isExpired
                                                                          ? Colors.red[
                                                                              700]
                                                                          : Colors
                                                                              .amber[700],
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
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
                                            ),
                                          ),

                                          // Quantity
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item['quantity'].toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),

                                          // Unit price
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _formatCurrency(item['mrp']),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),

                                          // Discount
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: hasDiscount
                                                    ? Colors.green[50]
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${item['discount']}%',
                                                style: TextStyle(
                                                  color: hasDiscount
                                                      ? Colors.green[700]
                                                      : Colors.grey[600],
                                                  fontWeight: hasDiscount
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),

                                          // Total amount
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _formatCurrency(
                                                  item['totalAmount']),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Item summary
                              Container(
                                padding: EdgeInsets.only(top: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Total Items: ${items.length}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Total Quantity: ${items.fold(0, (sum, item) => sum + (item['quantity'] as int))}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Enhanced summary
                        _buildEnhancedDetailSection(
                          title: 'Summary',
                          icon: Icons.summarize_outlined,
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                _buildEnhancedSummaryRow(
                                  'Subtotal',
                                  _formatCurrency(sale['subtotal']),
                                ),
                                if (_convertToDouble(sale['discount']) > 0)
                                  _buildEnhancedSummaryRow(
                                    'Discount',
                                    '- ${_formatCurrency(sale['discount'])}',
                                    valueColor: Colors.red[700],
                                    valueIcon: Icons.discount_outlined,
                                  ),
                                if (_convertToDouble(sale['tax']) > 0)
                                  _buildEnhancedSummaryRow(
                                    'Tax',
                                    _formatCurrency(sale['tax']),
                                    valueIcon: Icons.receipt_outlined,
                                  ),
                                Divider(thickness: 1.5, height: 24),
                                _buildEnhancedSummaryRow(
                                  'Total',
                                  _formatCurrency(sale['total']),
                                  isBold: true,
                                  fontSize: 18,
                                  labelColor: primaryColor,
                                  valueColor: primaryColor,
                                  valueIcon: Icons.payments_outlined,
                                  iconColor: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

// Helper method for enhanced detail sections
  Widget _buildEnhancedDetailSection({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: primaryColor),
              SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 12),
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.account_balance;
      case 'credit':
        return Icons.event_note;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green[700]!;
      case 'card':
        return Colors.blue[700]!;
      case 'upi':
        return Colors.purple[700]!;
      case 'credit':
        return Colors.orange[700]!;
      default:
        return primaryColor;
    }
  }

// Helper method for contact info display
  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isFullWidth ? 2 : 1,
            ),
          ),
        ],
      ),
    );
  }

// Enhanced summary row with better styling
  Widget _buildEnhancedSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? labelColor,
    Color? valueColor,
    double fontSize = 14,
    IconData? valueIcon,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
              color: labelColor ?? Colors.grey[700],
            ),
          ),
          Row(
            children: [
              if (valueIcon != null) ...[
                Icon(
                  valueIcon,
                  size: fontSize,
                  color: iconColor ??
                      valueColor ??
                      (isBold ? primaryColor : Colors.grey[600]),
                ),
                SizedBox(width: 6),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color:
                      valueColor ?? (isBold ? primaryColor : Colors.grey[800]),
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Helper methods for payment method icons and colors

  // Summary row with label and value
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 14,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? (isBold ? primaryColor : null),
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

// Add this to main.dart to run the application
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      home: SalesHistoryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
