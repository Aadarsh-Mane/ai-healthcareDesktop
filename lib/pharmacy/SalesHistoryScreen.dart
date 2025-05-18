import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen(
      {Key? key // Add this to main.dart to run the application

      })
      : super(key: key);

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
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
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchSales();

    // Setup keyboard shortcuts
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

// Setup keyboard shortcuts for desktop
  void _setupKeyboardShortcuts() {
    // Focus on search field with Ctrl+F
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        // Check for Ctrl+F to focus on search
        if (event.logicalKey == LogicalKeyboardKey.keyF &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _searchFocusNode.requestFocus();
          return true;
        }

        // Refresh data with F5
        if (event.logicalKey == LogicalKeyboardKey.f5) {
          _fetchSales();
          return true;
        }

        // Navigate selected item with arrow keys
        if (_filteredSales.isNotEmpty && _selectedSale != null) {
          final currentIndex = _filteredSales
              .indexWhere((sale) => sale['_id'] == _selectedSale!['_id']);

          if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
              currentIndex < _filteredSales.length - 1) {
            setState(() {
              _selectedSale = _filteredSales[currentIndex + 1];

              // Auto-scroll to keep selected item visible
              if (_tableScrollController.hasClients) {
                final itemHeight = 60.0; // Approximate height of each row
                final viewportHeight =
                    _tableScrollController.position.viewportDimension;
                final scrollOffset = _tableScrollController.offset;

                final itemPosition = (currentIndex + 1) * itemHeight;
                final viewportBottom = scrollOffset + viewportHeight;

                if (itemPosition > viewportBottom - itemHeight) {
                  _tableScrollController.animateTo(
                    scrollOffset + itemHeight,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                }
              }
            });
            return true;
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
              currentIndex > 0) {
            setState(() {
              _selectedSale = _filteredSales[currentIndex - 1];

              // Auto-scroll to keep selected item visible
              if (_tableScrollController.hasClients) {
                final itemHeight = 60.0; // Approximate height of each row
                final scrollOffset = _tableScrollController.offset;

                final itemPosition = (currentIndex - 1) * itemHeight;

                if (itemPosition < scrollOffset) {
                  _tableScrollController.animateTo(
                    scrollOffset - itemHeight,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                  );
                }
              }
            });
            return true;
          }
        }
      }
      return false;
    });
  }

  // Fetch sales data from API
  Future<void> _fetchSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/pharma/getSales'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final salesData = List<Map<String, dynamic>>.from(data['data']);

          setState(() {
            _sales = salesData;
            _filteredSales = salesData;
            if (_filteredSales.isNotEmpty && _selectedSale == null) {
              _selectedSale = _filteredSales.first;
            }
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
        final billNumber = (sale['billNumber'] ?? '').toString().toLowerCase();
        final customer = sale['customer'] as Map<String, dynamic>?;
        final customerName = customer?['name'] ?? '';
        final query = _searchQuery.toLowerCase();

        return billNumber.contains(query) ||
            customerName.toLowerCase().contains(query);
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
        if (sale['createdAt'] == null) return false;

        try {
          final saleDate = DateTime.parse(sale['createdAt']);
          return saleDate.isAfter(startDate);
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Apply customer filter
    if (_selectedCustomerFilter != 'All') {
      filtered = filtered.where((sale) {
        final customer = sale['customer'] as Map<String, dynamic>?;
        return customer?['name'] == _selectedCustomerFilter;
      }).toList();
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'Date (Newest First)':
        filtered.sort((a, b) {
          if (a['createdAt'] == null) return 1;
          if (b['createdAt'] == null) return -1;

          try {
            return DateTime.parse(b['createdAt'])
                .compareTo(DateTime.parse(a['createdAt']));
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Date (Oldest First)':
        filtered.sort((a, b) {
          if (a['createdAt'] == null) return 1;
          if (b['createdAt'] == null) return -1;

          try {
            return DateTime.parse(a['createdAt'])
                .compareTo(DateTime.parse(b['createdAt']));
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Bill Number':
        filtered.sort(
            (a, b) => (a['billNumber'] ?? '').compareTo(b['billNumber'] ?? ''));
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
        final stillExists = _filteredSales.any((sale) =>
            sale['_id'] != null &&
            _selectedSale!['_id'] != null &&
            sale['_id'] == _selectedSale!['_id']);

        if (!stillExists) {
          _selectedSale = _filteredSales.first;
        }
      }
    });
  }

  // Get a list of all unique customers
  List<String> _getUniqueCustomers() {
    final customers = _sales
        .map((sale) {
          final customer = sale['customer'] as Map<String, dynamic>?;
          return customer?['name'] as String? ?? 'Unknown';
        })
        .where((name) => name.isNotEmpty)
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
  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy h:mm a').format(date);
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid date';
    }
  }

  // Format date (short)
  String _formatShortDate(String? dateString) {
    if (dateString == null) return 'No date';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid date';
    }
  }

  // Show error message
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
      backgroundColor: PharmaTheme.background,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: PharmaTheme.accent),
            )
          : Column(
              children: [
                // Filter bar
                _buildFilterBar(context),

                // Main content
                Expanded(
                  child: _buildResponsiveLayout(context),
                ),
              ],
            ),
    );
  }

  // App bar with refresh button
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Sales History'),
      backgroundColor: PharmaTheme.primary,
      elevation: 2,
      actions: [
        Tooltip(
          message: 'Refresh Sales Data (F5)',
          child: IconButton(
            icon: const Icon(Icons.refresh, color: PharmaTheme.textLight),
            onPressed: _fetchSales,
          ),
        ),
        const SizedBox(width: PharmaTheme.spacingS),
      ],
    );
  }

  // Filter bar with search, filters, and sorting
  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: PharmaTheme.surface,
        boxShadow: PharmaTheme.shadowSmall,
      ),
      child: PharmaTheme.isMobile(context)
          ? _buildCompactFilterBar(context)
          : _buildFullFilterBar(context),
    );
  }

  // Compact filter bar for mobile screens
  Widget _buildCompactFilterBar(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
            border: Border.all(color: PharmaTheme.border),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search by invoice or customer...',
              prefixIcon: Icon(Icons.search, color: PharmaTheme.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _filterSales();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterSales();
            },
          ),
        ),
        const SizedBox(height: PharmaTheme.spacingM),

        // Filters in a wrap layout
        Wrap(
          spacing: PharmaTheme.spacingM,
          runSpacing: PharmaTheme.spacingS,
          alignment: WrapAlignment.start,
          children: [
            // Date filter
            _buildFilterDropdown(
              context,
              icon: Icons.calendar_today,
              hint: 'Date Range',
              value: _selectedDateFilter,
              items: const [
                'All',
                'Today',
                'This Week',
                'This Month',
                'Last 3 Months'
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDateFilter = value;
                  });
                  _filterSales();
                }
              },
            ),

            // Customer filter
            _buildFilterDropdown(
              context,
              icon: Icons.person,
              hint: 'Customer',
              value: _selectedCustomerFilter,
              items: _getUniqueCustomers(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCustomerFilter = value;
                  });
                  _filterSales();
                }
              },
            ),

            // Sort option
            _buildFilterDropdown(
              context,
              icon: Icons.sort,
              hint: 'Sort By',
              value: _selectedSortOption,
              items: const [
                'Date (Newest First)',
                'Date (Oldest First)',
                'Bill Number',
                'Amount (High to Low)',
                'Amount (Low to High)',
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSortOption = value;
                  });
                  _filterSales();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // Full filter bar for larger screens
  Widget _buildFullFilterBar(BuildContext context) {
    return Row(
      children: [
        // Search bar
        Expanded(
          flex: 3,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
              border: Border.all(color: PharmaTheme.border),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText:
                    'Search by invoice number or customer name... (Ctrl+F)',
                prefixIcon: Icon(Icons.search, color: PharmaTheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterSales();
                        },
                      )
                    : null,
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

        const SizedBox(width: PharmaTheme.spacingM),

        // Date filter
        Expanded(
          flex: 2,
          child: _buildFilterDropdown(
            context,
            icon: Icons.calendar_today,
            hint: 'Date Range',
            value: _selectedDateFilter,
            items: const [
              'All',
              'Today',
              'This Week',
              'This Month',
              'Last 3 Months'
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDateFilter = value;
                });
                _filterSales();
              }
            },
          ),
        ),

        const SizedBox(width: PharmaTheme.spacingM),

        // Customer filter
        Expanded(
          flex: 2,
          child: _buildFilterDropdown(
            context,
            icon: Icons.person,
            hint: 'Customer',
            value: _selectedCustomerFilter,
            items: _getUniqueCustomers(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCustomerFilter = value;
                });
                _filterSales();
              }
            },
          ),
        ),

        const SizedBox(width: PharmaTheme.spacingM),

        // Sort option
        Expanded(
          flex: 2,
          child: _buildFilterDropdown(
            context,
            icon: Icons.sort,
            hint: 'Sort By',
            value: _selectedSortOption,
            items: const [
              'Date (Newest First)',
              'Date (Oldest First)',
              'Bill Number',
              'Amount (High to Low)',
              'Amount (Low to High)',
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSortOption = value;
                });
                _filterSales();
              }
            },
          ),
        ),
      ],
    );
  }

  // Reusable filter dropdown
  Widget _buildFilterDropdown(
    BuildContext context, {
    required IconData icon,
    required String hint,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: PharmaTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
        border: Border.all(color: PharmaTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: PharmaTheme.primary, size: 18),
              const SizedBox(width: PharmaTheme.spacingXs),
              Text(hint),
            ],
          ),
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: PharmaTheme.primary),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: item == value
                      ? PharmaTheme.primary
                      : PharmaTheme.textPrimary,
                  fontWeight:
                      item == value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Responsive layout helper for different screen sizes
  Widget _buildResponsiveLayout(BuildContext context) {
    // Determine layout based on screen width
    if (PharmaTheme.isMobile(context)) {
      // Compact layout for smaller screens
      return Column(
        children: [
          // Sales table takes full width
          Expanded(
            flex: 3,
            child: _buildSalesTable(context),
          ),

          // Details shown at bottom if selected
          if (_selectedSale != null)
            Expanded(
              flex: 4,
              child: _buildSaleDetails(context),
            ),
        ],
      );
    } else {
      // Regular side-by-side layout for larger screens
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel - Sales table
          Expanded(
            flex: 3,
            child: _buildSalesTable(context),
          ),

          // Right panel - Sale details
          Expanded(
            flex: 2,
            child: _selectedSale != null
                ? _buildSaleDetails(context)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: PharmaTheme.spacingM),
                        Text(
                          'Select a sale to view details',
                          style: TextStyle(
                            color: PharmaTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: PharmaTheme.spacingXs),
                        const Text(
                          'Use arrow keys ↑/↓ to navigate sales',
                          style: TextStyle(
                            color: PharmaTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );
    }
  }

  // Enhanced table display for the sales history
  Widget _buildSalesTable(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: PharmaTheme.surface,
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        boxShadow: PharmaTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced table header
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: PharmaTheme.spacingM,
              horizontal: PharmaTheme.spacingL,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(PharmaTheme.radiusM),
                topRight: Radius.circular(PharmaTheme.radiusM),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                for (var column in _getTableColumns(context))
                  Expanded(
                    flex: column['flex'] as int,
                    child: Text(
                      column['label'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: PharmaTheme.primary,
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
                ? _buildEmptyTableView()
                : _buildSalesListView(context),
          ),

          // Enhanced table footer
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: PharmaTheme.spacingM,
              horizontal: PharmaTheme.spacingL,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(PharmaTheme.radiusM),
                bottomRight: Radius.circular(PharmaTheme.radiusM),
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
                    color: PharmaTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${_formatCurrency(_filteredSales.fold(0.0, (sum, sale) => sum + _convertToDouble(sale['total'])))}',
                  style: const TextStyle(
                    color: PharmaTheme.primary,
                    fontWeight: FontWeight.bold,
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

  // Generate table columns based on screen size
  List<Map<String, dynamic>> _getTableColumns(BuildContext context) {
    if (PharmaTheme.isMobile(context)) {
      return [
        {'label': 'Invoice #', 'flex': 2},
        {'label': 'Customer', 'flex': 3},
        {'label': 'Total', 'flex': 2, 'align': TextAlign.right},
      ];
    } else {
      return [
        {'label': 'Invoice #', 'flex': 2},
        {'label': 'Customer', 'flex': 3},
        {'label': 'Date', 'flex': 2},
        {'label': 'Items', 'flex': 1},
        {'label': 'Total', 'flex': 2, 'align': TextAlign.right},
      ];
    }
  }

  // Empty state for no sales data
  Widget _buildEmptyTableView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: PharmaTheme.spacingM),
          Text(
            'No sales found',
            style: TextStyle(
              color: PharmaTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: PharmaTheme.spacingXs),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: PharmaTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // List view of sales data
  Widget _buildSalesListView(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ListView.separated(
        controller: _tableScrollController,
        itemCount: _filteredSales.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final sale = _filteredSales[index];
          final isSelected =
              _selectedSale != null && _selectedSale!['_id'] == sale['_id'];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSale = sale;
                });
              },
              highlightColor:
                  PharmaTheme.primary.withOpacity(PharmaTheme.hoverOpacity),
              hoverColor: PharmaTheme.primary
                  .withOpacity(PharmaTheme.hoverOpacity * 0.5),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? PharmaTheme.primary
                          .withOpacity(PharmaTheme.selectedOpacity)
                      : PharmaTheme.surface,
                  border: isSelected
                      ? Border.all(
                          color: PharmaTheme.primary.withOpacity(0.3),
                          width: 1.5)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: PharmaTheme.spacingM,
                  horizontal: PharmaTheme.spacingL,
                ),
                child: _buildSaleRow(context, sale, isSelected),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build a single sale row based on screen size
  Widget _buildSaleRow(
      BuildContext context, Map<String, dynamic> sale, bool isSelected) {
    // Handle potentially null customer with defaults
    final customer = sale['customer'] as Map<String, dynamic>? ??
        {'name': 'Unknown Customer', 'isPatient': false};

    if (PharmaTheme.isMobile(context)) {
      // Mobile view with fewer columns
      return Row(
        children: [
          // Invoice Number
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale['billNumber'] ?? 'No ID',
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? PharmaTheme.primary
                        : PharmaTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sale['createdAt'] != null
                      ? _formatShortDate(sale['createdAt'])
                      : 'No date',
                  style: TextStyle(
                    fontSize: 12,
                    color: PharmaTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Customer
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: customer['isPatient'] == true
                        ? Colors.green[50]
                        : PharmaTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    customer['isPatient'] == true
                        ? Icons.medical_services_outlined
                        : Icons.person_outline,
                    size: 14,
                    color: customer['isPatient'] == true
                        ? Colors.green[700]
                        : PharmaTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customer['name'] ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? PharmaTheme.primary
                          : PharmaTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(sale['total'] ?? 0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color:
                    isSelected ? PharmaTheme.primary : PharmaTheme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    } else {
      // Desktop/tablet view with more columns
      return Row(
        children: [
          // Invoice number
          Expanded(
            flex: 2,
            child: Text(
              sale['billNumber'] ?? 'No ID',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? PharmaTheme.primary : PharmaTheme.textPrimary,
              ),
            ),
          ),

          // Customer
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: customer['isPatient'] == true
                        ? Colors.green[50]
                        : PharmaTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    customer['isPatient'] == true
                        ? Icons.medical_services_outlined
                        : Icons.person_outline,
                    size: 14,
                    color: customer['isPatient'] == true
                        ? Colors.green[700]
                        : PharmaTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customer['name'] ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? PharmaTheme.primary
                          : PharmaTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              sale['createdAt'] != null
                  ? _formatShortDate(sale['createdAt'])
                  : 'No date',
              style: TextStyle(
                color: isSelected
                    ? PharmaTheme.primary.withOpacity(0.8)
                    : PharmaTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // Items count
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? PharmaTheme.primary.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
              ),
              child: Text(
                sale['items'] != null
                    ? '${(sale['items'] as List).length}'
                    : '0',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? PharmaTheme.primary
                      : PharmaTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Total amount
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(sale['total'] ?? 0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color:
                    isSelected ? PharmaTheme.primary : PharmaTheme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }
  }

  // Sale details panel
  Widget _buildSaleDetails(BuildContext context) {
    if (_selectedSale == null) return const SizedBox();

    final sale = _selectedSale!;
    final items = List<Map<String, dynamic>>.from(sale['items']);
    final customer = sale['customer'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: PharmaTheme.surface,
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        boxShadow: PharmaTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          Container(
            padding: const EdgeInsets.all(PharmaTheme.spacingL),
            decoration: BoxDecoration(
              color: PharmaTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(PharmaTheme.radiusM),
                topRight: Radius.circular(PharmaTheme.radiusM),
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
                        style: const TextStyle(
                          color: PharmaTheme.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: PharmaTheme.textLight.withOpacity(0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(sale['createdAt']),
                            style: TextStyle(
                              color: PharmaTheme.textLight.withOpacity(0.9),
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
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('View Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaTheme.surface,
                      foregroundColor: PharmaTheme.primary,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: PharmaTheme.spacingM,
                        vertical: PharmaTheme.spacingS,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusS),
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
                  padding: const EdgeInsets.all(PharmaTheme.spacingL),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - (PharmaTheme.spacingL * 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Customer information
                        _buildDetailSection(
                          title: 'Customer Information',
                          icon: Icons.person_outline,
                          child: _buildCustomerInfo(customer),
                        ),

                        const SizedBox(height: PharmaTheme.spacingXl),

                        // Enhanced Payment information
                        _buildDetailSection(
                          title: 'Payment Information',
                          icon: Icons.payment,
                          child: _buildPaymentInfo(sale),
                        ),

                        const SizedBox(height: PharmaTheme.spacingXl),

                        // Enhanced Items list
                        _buildDetailSection(
                          title: 'Items',
                          icon: Icons.shopping_cart_outlined,
                          child: _buildItemsTable(items),
                        ),

                        const SizedBox(height: PharmaTheme.spacingXl),

                        // Enhanced summary
                        _buildDetailSection(
                          title: 'Summary',
                          icon: Icons.summarize_outlined,
                          child: _buildSummary(sale),
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

  // Customer information section
  Widget _buildCustomerInfo(Map<String, dynamic>? customer) {
    // Handle the case where customer might be null
    if (customer == null) {
      return Container(
        padding: const EdgeInsets.all(PharmaTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        ),
        child: const Center(
          child: Text(
            'Customer information not available',
            style: TextStyle(color: PharmaTheme.textSecondary),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: customer['isPatient'] == true
                ? Colors.green[50]
                : PharmaTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: customer['isPatient'] == true
                  ? Colors.green[200]!
                  : PharmaTheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            customer['isPatient'] == true
                ? Icons.medical_services
                : Icons.person,
            color: customer['isPatient'] == true
                ? Colors.green[700]
                : PharmaTheme.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: PharmaTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      customer['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (customer['isPatient'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusCircular),
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
              const SizedBox(height: PharmaTheme.spacingS),

              // Customer details in responsive grid
              Wrap(
                spacing: PharmaTheme.spacingM,
                runSpacing: PharmaTheme.spacingS,
                children: [
                  if (customer['contactNumber'] != null)
                    _buildContactInfo(
                      icon: Icons.phone,
                      label: customer['contactNumber'],
                    ),
                  if (customer['email'] != null)
                    _buildContactInfo(
                      icon: Icons.email_outlined,
                      label: customer['email'],
                    ),
                ],
              ),

              if (customer['address'] != null) ...[
                const SizedBox(height: PharmaTheme.spacingS),
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
    );
  }

  // Payment information section
  Widget _buildPaymentInfo(Map<String, dynamic> sale) {
    return Wrap(
      spacing: 30,
      runSpacing: 20,
      children: [
        // Payment method
        _buildPaymentInfoItem(
          label: 'Payment Method',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _getPaymentMethodColor(sale['paymentMethod'])
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
              border: Border.all(
                color: _getPaymentMethodColor(sale['paymentMethod'])
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPaymentMethodIcon(sale['paymentMethod']),
                  size: 18,
                  color: _getPaymentMethodColor(sale['paymentMethod']),
                ),
                const SizedBox(width: 8),
                Text(
                  (sale['paymentMethod'] as String).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getPaymentMethodColor(sale['paymentMethod']),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Date
        _buildPaymentInfoItem(
          label: 'Sale Date',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: PharmaTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
              border: Border.all(
                color: PharmaTheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event,
                  size: 18,
                  color: PharmaTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatShortDate(sale['createdAt']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PharmaTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Invoice Number
        _buildPaymentInfoItem(
          label: 'Invoice Number',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
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
                const SizedBox(width: 8),
                Text(
                  sale['billNumber'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PharmaTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Items table
  // Items table with improved responsive alignment
  Widget _buildItemsTable(List<Map<String, dynamic>>? items) {
    // If items is null or empty, show a message
    if (items == null || items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(PharmaTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'No items available',
            style: TextStyle(color: PharmaTheme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Items table header with better alignment
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: PharmaTheme.spacingS,
            horizontal: PharmaTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: PharmaTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(PharmaTheme.radiusS),
              topRight: Radius.circular(PharmaTheme.radiusS),
            ),
            border: Border(
              bottom: BorderSide(
                color: PharmaTheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Item name column
              Expanded(
                flex: 4,
                child: Text(
                  'Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: PharmaTheme.primary,
                  ),
                ),
              ),
              // Quantity column
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: PharmaTheme.primary,
                    ),
                  ),
                ),
              ),
              // Price column
              Expanded(
                flex: 2,
                child: Text(
                  'Price',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: PharmaTheme.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              // Discount column
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Disc',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: PharmaTheme.primary,
                    ),
                  ),
                ),
              ),
              // Total column
              Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: PharmaTheme.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Items list with responsive alignment
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(PharmaTheme.radiusS),
              bottomRight: Radius.circular(PharmaTheme.radiusS),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) => _buildItemRow(items[index], index),
          ),
        ),

        // Item summary with improved spacing and alignment
        Container(
          padding: const EdgeInsets.only(top: PharmaTheme.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PharmaTheme.spacingS,
                  vertical: PharmaTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: PharmaTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
                ),
                child: Text(
                  'Total Items: ${items.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PharmaTheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: PharmaTheme.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PharmaTheme.spacingS,
                  vertical: PharmaTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: PharmaTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
                ),
                child: Text(
                  'Total Quantity: ${items.fold(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PharmaTheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Single item row with improved responsive alignment
  Widget _buildItemRow(Map<String, dynamic> item, int index) {
    // Handle potentially null medicine with defaults
    final medicine = item['medicine'] as Map<String, dynamic>? ??
        {
          'name': 'Unknown Medicine',
          'manufacturer': 'Unknown',
          'category': 'Uncategorized'
        };
    final hasDiscount = _convertToDouble(item['discount']) > 0;

    // Check for expiry info
    bool isExpired = false;
    String expiryStatus = '';
    if (item.containsKey('expiryDate') && item['expiryDate'] != null) {
      try {
        final expiry = DateTime.parse(item['expiryDate']);
        final now = DateTime.now();
        final difference = expiry.difference(now).inDays;

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
      color: index % 2 == 0 ? Colors.grey[50] : PharmaTheme.surface,
      padding: const EdgeInsets.symmetric(
        vertical: PharmaTheme.spacingS,
        horizontal: PharmaTheme.spacingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item details column - left aligned
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PharmaTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: PharmaTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine['name'] ?? 'Unknown Medicine',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${medicine['manufacturer'] ?? 'Unknown'} • ${medicine['category'] ?? 'Uncategorized'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: PharmaTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Batch and expiry info
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius:
                                  BorderRadius.circular(PharmaTheme.radiusXs),
                            ),
                            child: Text(
                              'Batch: ${item['batchNumber'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: PharmaTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (expiryStatus.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isExpired
                                    ? Colors.red[50]
                                    : Colors.amber[50],
                                borderRadius:
                                    BorderRadius.circular(PharmaTheme.radiusXs),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isExpired
                                        ? Icons.error_outline
                                        : Icons.warning_amber_outlined,
                                    size: 10,
                                    color: isExpired
                                        ? Colors.red[700]
                                        : Colors.amber[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    expiryStatus,
                                    style: TextStyle(
                                      fontSize: 11,
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quantity column - center aligned
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PharmaTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
                ),
                child: Text(
                  (item['quantity'] ?? 0).toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PharmaTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Unit price column - right aligned
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(item['mrp'] ?? 0),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Discount column - center aligned
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasDiscount ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
                ),
                child: Text(
                  '${item['discount'] ?? 0}%',
                  style: TextStyle(
                    color: hasDiscount
                        ? Colors.green[700]
                        : PharmaTheme.textSecondary,
                    fontWeight:
                        hasDiscount ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Total amount column - right aligned
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(item['totalAmount'] ?? 0),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: PharmaTheme.primary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Sale summary section
  Widget _buildSummary(Map<String, dynamic> sale) {
    return Container(
      padding: const EdgeInsets.all(PharmaTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Subtotal',
            _formatCurrency(sale['subtotal']),
          ),
          if (_convertToDouble(sale['discount']) > 0)
            _buildSummaryRow(
              'Discount',
              '- ${_formatCurrency(sale['discount'])}',
              valueColor: PharmaTheme.error,
              valueIcon: Icons.discount_outlined,
            ),
          if (_convertToDouble(sale['tax']) > 0)
            _buildSummaryRow(
              'Tax',
              _formatCurrency(sale['tax']),
              valueIcon: Icons.receipt_outlined,
            ),
          const Divider(thickness: 1.5, height: 24),
          _buildSummaryRow(
            'Total',
            _formatCurrency(sale['total']),
            isBold: true,
            fontSize: 18,
            labelColor: PharmaTheme.primary,
            valueColor: PharmaTheme.primary,
            valueIcon: Icons.payments_outlined,
            iconColor: PharmaTheme.primary,
          ),
        ],
      ),
    );
  }

  // Helper method for detail sections
  Widget _buildDetailSection({
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
              Icon(icon, size: 16, color: PharmaTheme.primary),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: PharmaTheme.primary,
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: PharmaTheme.spacingS),
          width: double.infinity,
          padding: const EdgeInsets.all(PharmaTheme.spacingM),
          decoration: BoxDecoration(
            color: PharmaTheme.surface,
            borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: PharmaTheme.shadowSmall,
          ),
          child: child,
        ),
      ],
    );
  }

  // Payment info item with label and custom child
  Widget _buildPaymentInfoItem({
    required String label,
    required Widget child,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: PharmaTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // Contact info with icon and label
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
            color: PharmaTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: PharmaTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isFullWidth ? 2 : 1,
            ),
          ),
        ],
      ),
    );
  }

  // Summary row
  Widget _buildSummaryRow(
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
              color: labelColor ?? PharmaTheme.textSecondary,
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
                      (isBold
                          ? PharmaTheme.primary
                          : PharmaTheme.textSecondary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor ??
                      (isBold ? PharmaTheme.primary : PharmaTheme.textPrimary),
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
        return PharmaTheme.primary;
    }
  }
}
