import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/AllMedicineScreen.dart';
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
import 'dart:async';

// Enhanced Models for API response
class MedicineSearchResult {
  final int index;
  final String medicineName;
  final String manufacturer;
  final double price;
  final String mrpOriginal;
  final String packageInfo;
  final String composition;
  final String letterCategory;
  final int pageNumber;
  final String scrapedDate;
  final String scrapedTime;

  MedicineSearchResult({
    required this.index,
    required this.medicineName,
    required this.manufacturer,
    required this.price,
    required this.mrpOriginal,
    required this.packageInfo,
    required this.composition,
    required this.letterCategory,
    required this.pageNumber,
    required this.scrapedDate,
    required this.scrapedTime,
  });

  factory MedicineSearchResult.fromJson(Map<String, dynamic> json) {
    return MedicineSearchResult(
      index: json['index'] ?? 0,
      medicineName: json['medicineName']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      price: _parseDouble(json['price']),
      mrpOriginal: json['mrpOriginal']?.toString() ?? '',
      packageInfo: json['packageInfo']?.toString() ?? '',
      composition: json['composition']?.toString() ?? '',
      letterCategory: json['letterCategory']?.toString() ?? '',
      pageNumber: json['pageNumber'] ?? 0,
      scrapedDate: json['scrapedDate']?.toString() ?? '',
      scrapedTime: json['scrapedTime']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class MedicineSearchResponse {
  final bool success;
  final String message;
  final String? searchNote;
  final List<MedicineSearchResult> data;
  final int? totalPages;
  final int? currentPage;
  final int? totalResults;

  MedicineSearchResponse({
    required this.success,
    required this.message,
    this.searchNote,
    required this.data,
    this.totalPages,
    this.currentPage,
    this.totalResults,
  });

  factory MedicineSearchResponse.fromJson(Map<String, dynamic> json) {
    return MedicineSearchResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      searchNote: json['searchNote']?.toString(),
      data: (json['data'] as List? ?? [])
          .map((item) => MedicineSearchResult.fromJson(item))
          .toList(),
      totalPages: json['totalPages'],
      currentPage: json['currentPage'],
      totalResults: json['totalResults'],
    );
  }
}

class ManufacturerSearchResult {
  final String name;
  final int count;

  ManufacturerSearchResult({
    required this.name,
    required this.count,
  });

  factory ManufacturerSearchResult.fromJson(Map<String, dynamic> json) {
    return ManufacturerSearchResult(
      name: json['name']?.toString() ?? '',
      count: json['count'] ?? 0,
    );
  }
}

// Enhanced Medicine Search Service
class MedicineSearchService {
  static const String _baseUrl = KVM_URL;

  Future<MedicineSearchResponse> searchMedicines({
    required String search,
    int page = 1,
    String? letterCategory,
    int limit = 20,
  }) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/api/medicines/search').replace(
        queryParameters: {
          'search': search,
          'page': page.toString(),
          if (letterCategory != null) 'letterCategory': letterCategory,
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MedicineSearchResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to search medicines: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching medicines: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<ManufacturerSearchResult>> searchManufacturers({
    required String search,
  }) async {
    try {
      final Uri uri =
          Uri.parse('$_baseUrl/api/medicines/manufacturers/').replace(
        queryParameters: {
          'search': search,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((item) => ManufacturerSearchResult.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching manufacturers: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    // Mock categories - you can implement this API call
    return [
      'Tablet',
      'Capsule',
      'Syrup',
      'Injection',
      'Ointment',
      'Drops',
      'Inhaler',
      'Patch',
      'Suspension',
      'Powder',
    ];
  }
}

// Enhanced Providers
final medicineSearchServiceProvider = Provider<MedicineSearchService>((ref) {
  return MedicineSearchService();
});

final medicineSearchProvider = StateNotifierProvider.family<
    MedicineSearchNotifier,
    AsyncValue<MedicineSearchResponse>,
    String>((ref, query) {
  return MedicineSearchNotifier(ref.watch(medicineSearchServiceProvider));
});

final manufacturerSearchProvider = StateNotifierProvider.family<
    ManufacturerSearchNotifier,
    AsyncValue<List<ManufacturerSearchResult>>,
    String>((ref, query) {
  return ManufacturerSearchNotifier(ref.watch(medicineSearchServiceProvider));
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(medicineSearchServiceProvider);
  return await service.getCategories();
});

// Search State Notifiers
class MedicineSearchNotifier
    extends StateNotifier<AsyncValue<MedicineSearchResponse>> {
  final MedicineSearchService _service;
  Timer? _debounceTimer;

  MedicineSearchNotifier(this._service)
      : super(AsyncValue.data(
            MedicineSearchResponse(success: true, message: '', data: [])));

  void searchMedicines(String query, {int page = 1, String? letterCategory}) {
    if (query.trim().isEmpty) {
      state = AsyncValue.data(
          MedicineSearchResponse(success: true, message: '', data: []));
      return;
    }

    // Debounce search requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        state = const AsyncValue.loading();
        final response = await _service.searchMedicines(
          search: query,
          page: page,
          letterCategory: letterCategory,
        );
        state = AsyncValue.data(response);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class ManufacturerSearchNotifier
    extends StateNotifier<AsyncValue<List<ManufacturerSearchResult>>> {
  final MedicineSearchService _service;
  Timer? _debounceTimer;

  ManufacturerSearchNotifier(this._service) : super(const AsyncValue.data([]));

  void searchManufacturers(String query) {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    // Debounce search requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        state = const AsyncValue.loading();
        final results = await _service.searchManufacturers(search: query);
        state = AsyncValue.data(results);
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Optimized Add Medicine Screen
class OptimizedAddMedicineScreen extends ConsumerStatefulWidget {
  final Medicine? medicineToEdit;

  const OptimizedAddMedicineScreen({Key? key, this.medicineToEdit})
      : super(key: key);

  @override
  ConsumerState<OptimizedAddMedicineScreen> createState() =>
      _OptimizedAddMedicineScreenState();
}

class _OptimizedAddMedicineScreenState
    extends ConsumerState<OptimizedAddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mrpController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _compositionController = TextEditingController();
  final _packageInfoController = TextEditingController();

  // Focus nodes for better navigation
  final _nameFocusNode = FocusNode();
  final _manufacturerFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _mrpFocusNode = FocusNode();
  final _purchasePriceFocusNode = FocusNode();
  final _compositionFocusNode = FocusNode();
  final _packageInfoFocusNode = FocusNode();

  // Search related state
  bool _showSuggestions = false;
  MedicineSearchResult? _selectedSuggestion;
  bool _isAutoFilling = false;
  bool _isLoading = false;

  // Overlay for suggestions
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
    _setupFocusListeners();

    if (widget.medicineToEdit != null) {
      _populateFields(widget.medicineToEdit!);
    }
  }

  void _setupKeyboardShortcuts() {
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        // Save (Ctrl+S or Cmd+S)
        if (event.logicalKey == LogicalKeyboardKey.keyS &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _saveMedicine();
          return true;
        }
        // Clear form (Ctrl+R or Cmd+R)
        if (event.logicalKey == LogicalKeyboardKey.keyR &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _clearForm();
          return true;
        }
        // Focus search (Ctrl+/ or Cmd+/)
        if (event.logicalKey == LogicalKeyboardKey.slash &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _nameFocusNode.requestFocus();
          return true;
        }
      }
      return false;
    });
  }

  void _setupFocusListeners() {
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        _hideSuggestions();
      }
    });
  }

  void _populateFields(Medicine medicine) {
    _nameController.text = medicine.name;
    _manufacturerController.text = medicine.manufacturer;
    _categoryController.text = medicine.category ?? '';
    _descriptionController.text = medicine.description ?? '';
    _mrpController.text = medicine.mrp.toString();
    _purchasePriceController.text = medicine.purchasePrice.toString();
  }

  @override
  void dispose() {
    _hideSuggestions();
    _nameController.dispose();
    _manufacturerController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _mrpController.dispose();
    _purchasePriceController.dispose();
    _compositionController.dispose();
    _packageInfoController.dispose();

    _nameFocusNode.dispose();
    _manufacturerFocusNode.dispose();
    _categoryFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _mrpFocusNode.dispose();
    _purchasePriceFocusNode.dispose();
    _compositionFocusNode.dispose();
    _packageInfoFocusNode.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _manufacturerController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _mrpController.clear();
    _purchasePriceController.clear();
    _compositionController.clear();
    _packageInfoController.clear();
    _selectedSuggestion = null;
    _hideSuggestions();
    setState(() {});
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showSuggestions = false;
    });
  }

  void _showSuggestionsOverlay() {
    _hideSuggestions();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 600,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HospitalTheme.border),
                boxShadow: HospitalTheme.shadow,
              ),
              child: _buildSuggestionsContent(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showSuggestions = true;
    });
  }

  Widget _buildSuggestionsContent() {
    final searchQuery = _nameController.text.trim();

    if (searchQuery.isEmpty) {
      return _buildEmptySuggestions();
    }

    final searchAsyncValue = ref.watch(medicineSearchProvider(searchQuery));

    return searchAsyncValue.when(
      data: (response) => _buildSuggestionsList(response.data),
      loading: () => _buildLoadingSuggestions(),
      error: (error, stack) => _buildErrorSuggestions(error.toString()),
    );
  }

  Widget _buildEmptySuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 8),
          Text(
            'Start typing to search medicines',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search from thousands of medicines in our database',
            style: TextStyle(
              color: HospitalTheme.textLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSuggestions() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Searching medicines...',
            style: TextStyle(
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSuggestions(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: HospitalTheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Search failed',
            style: TextStyle(
              color: HospitalTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please try again',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(List<MedicineSearchResult> suggestions) {
    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 8),
            Text(
              'No medicines found',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: HospitalTheme.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: suggestions.length.clamp(0, 10), // Limit to 10 suggestions
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: HospitalTheme.border,
      ),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return _SuggestionTile(
          suggestion: suggestion,
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  void _selectSuggestion(MedicineSearchResult suggestion) {
    setState(() {
      _isAutoFilling = true;
      _selectedSuggestion = suggestion;
    });

    // Auto-fill form fields
    _nameController.text = suggestion.medicineName;
    _manufacturerController.text = suggestion.manufacturer;
    _mrpController.text = suggestion.price.toString();
    _compositionController.text = suggestion.composition;
    _packageInfoController.text = suggestion.packageInfo;

    // Extract category from package info or composition
    final category = _extractCategory(suggestion);
    if (category.isNotEmpty) {
      _categoryController.text = category;
    }

    _hideSuggestions();
    _manufacturerFocusNode.requestFocus();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_fix_high, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Auto-filled from "${suggestion.medicineName}"'),
            ),
          ],
        ),
        backgroundColor: HospitalTheme.success,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _isAutoFilling = false;
    });
  }

  String _extractCategory(MedicineSearchResult suggestion) {
    final packageInfo = suggestion.packageInfo.toLowerCase();

    if (packageInfo.contains('tablet')) return 'Tablet';
    if (packageInfo.contains('capsule')) return 'Capsule';
    if (packageInfo.contains('syrup')) return 'Syrup';
    if (packageInfo.contains('injection')) return 'Injection';
    if (packageInfo.contains('ointment')) return 'Ointment';
    if (packageInfo.contains('drops')) return 'Drops';
    if (packageInfo.contains('inhaler')) return 'Inhaler';
    if (packageInfo.contains('suspension')) return 'Suspension';

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicineToEdit != null;
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 1200;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: isEditing ? 'Edit Medicine' : 'Add Medicine',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Medicine (Ctrl+S)',
            onPressed: _saveMedicine,
          ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Clear Form (Ctrl+R)',
              onPressed: _clearForm,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1000 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      // Smart Search Header
                      if (!isEditing) _buildSmartSearchHeader(),

                      const SizedBox(height: 24),

                      // Main Form
                      _buildMainForm(isDesktop),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSmartSearchHeader() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HospitalTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_fix_high,
                  color: HospitalTheme.accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Medicine Entry',
                      style: HospitalTheme.themeData.textTheme.headlineSmall,
                    ),
                    Text(
                      'Search our database to auto-fill medicine details',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedSuggestion != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: HospitalTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: HospitalTheme.success,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-filled',
                        style: TextStyle(
                          color: HospitalTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HospitalTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: HospitalTheme.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: HospitalTheme.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pro tip: Start typing in the medicine name field to see smart suggestions from our comprehensive database',
                    style: TextStyle(
                      color: HospitalTheme.info,
                      fontSize: 13,
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

  Widget _buildMainForm(bool isDesktop) {
    return HospitalTheme.buildCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.medicineToEdit != null
                  ? 'Medicine Details'
                  : 'Enter Medicine Information',
              style: HospitalTheme.themeData.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Medicine Name Field with Smart Search
            CompositedTransformTarget(
              link: _layerLink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Medicine Name *',
                            hintText: 'Start typing to search...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _nameController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _nameController.clear();
                                      _hideSuggestions();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter medicine name';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {});
                            if (value.trim().isNotEmpty && value.length >= 2) {
                              ref
                                  .read(medicineSearchProvider(value).notifier)
                                  .searchMedicines(value);
                              if (!_showSuggestions) {
                                _showSuggestionsOverlay();
                              }
                            } else {
                              _hideSuggestions();
                            }
                          },
                          onTap: () {
                            if (_nameController.text.trim().isNotEmpty &&
                                _nameController.text.length >= 2) {
                              _showSuggestionsOverlay();
                            }
                          },
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              _manufacturerFocusNode.requestFocus(),
                        ),
                      ),
                      if (_isAutoFilling) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HospitalTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_selectedSuggestion != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HospitalTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: HospitalTheme.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_fix_high,
                            color: HospitalTheme.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto-filled from database: ${_selectedSuggestion!.manufacturer}',
                              style: TextStyle(
                                color: HospitalTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedSuggestion = null;
                              });
                              _clearForm();
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: HospitalTheme.success,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Manufacturer and Category Row
            isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildManufacturerField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCategoryField()),
                    ],
                  )
                : Column(
                    children: [
                      _buildManufacturerField(),
                      const SizedBox(height: 16),
                      _buildCategoryField(),
                    ],
                  ),

            const SizedBox(height: 16),

            // Composition and Package Info
            isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildCompositionField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPackageInfoField()),
                    ],
                  )
                : Column(
                    children: [
                      _buildCompositionField(),
                      const SizedBox(height: 16),
                      _buildPackageInfoField(),
                    ],
                  ),

            const SizedBox(height: 16),

            // Description
            _buildDescriptionField(),

            const SizedBox(height: 16),

            // Price Fields
            isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildMRPField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPurchasePriceField()),
                    ],
                  )
                : Column(
                    children: [
                      _buildMRPField(),
                      const SizedBox(height: 16),
                      _buildPurchasePriceField(),
                    ],
                  ),

            const SizedBox(height: 24),

            // Profit Calculation
            _buildProfitCalculation(),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildManufacturerField() {
    return _SmartAutocompleteField(
      controller: _manufacturerController,
      focusNode: _manufacturerFocusNode,
      labelText: 'Manufacturer *',
      hintText: 'Enter manufacturer name',
      prefixIcon: Icons.business,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter manufacturer name';
        }
        return null;
      },
      onSearch: (query) async {
        final results = await ref
            .read(medicineSearchServiceProvider)
            .searchManufacturers(search: query);
        return results.map((r) => r.name).toList();
      },
      nextFocusNode: _categoryFocusNode,
    );
  }

  Widget _buildCategoryField() {
    return _SmartAutocompleteField(
      controller: _categoryController,
      focusNode: _categoryFocusNode,
      labelText: 'Category',
      hintText: 'Select or enter category',
      prefixIcon: Icons.category,
      onSearch: (query) async {
        final categories = await ref.read(categoriesProvider.future);
        return categories
            .where((cat) => cat.toLowerCase().contains(query.toLowerCase()))
            .toList();
      },
      nextFocusNode: _compositionFocusNode,
    );
  }

  Widget _buildCompositionField() {
    return TextFormField(
      controller: _compositionController,
      focusNode: _compositionFocusNode,
      decoration: const InputDecoration(
        labelText: 'Composition',
        hintText: 'Enter active ingredients',
        prefixIcon: Icon(Icons.science),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _packageInfoFocusNode.requestFocus(),
    );
  }

  Widget _buildPackageInfoField() {
    return TextFormField(
      controller: _packageInfoController,
      focusNode: _packageInfoFocusNode,
      decoration: const InputDecoration(
        labelText: 'Package Info',
        hintText: 'e.g., strip of 10 tablets',
        prefixIcon: Icon(Icons.inventory_2),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _descriptionFocusNode.requestFocus(),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Enter medicine description',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _mrpFocusNode.requestFocus(),
    );
  }

  Widget _buildMRPField() {
    return TextFormField(
      controller: _mrpController,
      focusNode: _mrpFocusNode,
      decoration: const InputDecoration(
        labelText: 'MRP (₹) *',
        hintText: 'Enter MRP',
        prefixIcon: Icon(Icons.currency_rupee),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter MRP';
        }
        if (double.tryParse(value) == null || double.parse(value) <= 0) {
          return 'Please enter a valid MRP';
        }
        return null;
      },
      onChanged: (value) => setState(() {}),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _purchasePriceFocusNode.requestFocus(),
    );
  }

  Widget _buildPurchasePriceField() {
    return TextFormField(
      controller: _purchasePriceController,
      focusNode: _purchasePriceFocusNode,
      decoration: const InputDecoration(
        labelText: 'Purchase Price (₹) *',
        hintText: 'Enter purchase price',
        prefixIcon: Icon(Icons.shopping_cart),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter purchase price';
        }
        if (double.tryParse(value) == null || double.parse(value) < 0) {
          return 'Please enter a valid purchase price';
        }
        return null;
      },
      onChanged: (value) => setState(() {}),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveMedicine(),
    );
  }

  Widget _buildProfitCalculation() {
    final mrp = double.tryParse(_mrpController.text) ?? 0;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final profit = mrp - purchasePrice;
    final profitPercentage =
        purchasePrice > 0 ? (profit / purchasePrice * 100) : 0;

    Color profitColor = HospitalTheme.textMedium;
    IconData profitIcon = Icons.trending_flat;

    if (profit > 0) {
      profitColor = HospitalTheme.success;
      profitIcon = Icons.trending_up;
    } else if (profit < 0) {
      profitColor = HospitalTheme.error;
      profitIcon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            profitColor.withOpacity(0.1),
            profitColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: profitColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(profitIcon, color: profitColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profit Analysis',
                      style: TextStyle(
                        color: profitColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Real-time calculation based on entered prices',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProfitMetric(
                  title: 'Profit Amount',
                  value: '₹${profit.toStringAsFixed(2)}',
                  color: profitColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProfitMetric(
                  title: 'Profit Margin',
                  value: '${profitPercentage.toStringAsFixed(1)}%',
                  color: profitColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProfitMetric(
                  title: 'Markup Ratio',
                  value: purchasePrice > 0
                      ? '${(mrp / purchasePrice).toStringAsFixed(2)}x'
                      : 'N/A',
                  color: profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isEditing = widget.medicineToEdit != null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _saveMedicine,
            icon: Icon(isEditing ? Icons.update : Icons.save),
            label: Text(isEditing ? 'Update Medicine' : 'Save Medicine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (!isEditing) ...[
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _saveMedicine(continueAdding: true);
              },
              icon: const Icon(Icons.add),
              label: const Text('Save & Add Another'),
              style: OutlinedButton.styleFrom(
                foregroundColor: HospitalTheme.primary,
                side: BorderSide(color: HospitalTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _saveMedicine({bool continueAdding = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medicine = Medicine(
        id: widget.medicineToEdit?.id ?? '',
        name: _nameController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        mrp: double.parse(_mrpController.text),
        purchasePrice: double.parse(_purchasePriceController.text),
        createdAt: widget.medicineToEdit?.createdAt ?? DateTime.now(),
      );

      final medicineService = ref.read(medicineServiceProvider);
      bool success;

      if (widget.medicineToEdit != null) {
        success = await medicineService.updateMedicine(
          widget.medicineToEdit!.id,
          medicine,
        );
      } else {
        final response = await medicineService.createMedicines([medicine]);
        success = response.success && response.created.isNotEmpty;
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    widget.medicineToEdit != null
                        ? 'Medicine updated successfully!'
                        : 'Medicine added successfully!',
                  ),
                ],
              ),
              backgroundColor: HospitalTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          if (continueAdding) {
            _clearForm();
            _nameFocusNode.requestFocus();
          } else {
            Navigator.pop(context, true);
          }
        }
      } else {
        throw Exception('Failed to save medicine');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: HospitalTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: HospitalTheme.primary),
            const SizedBox(width: 8),
            const Text('Smart Medicine Entry Help'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpSection(
                title: 'Smart Search Features',
                items: [
                  'Type medicine name to see auto-suggestions',
                  'Click any suggestion to auto-fill form fields',
                  'Search from thousands of medicines in database',
                  'Get accurate pricing and composition data',
                ],
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: 'Keyboard Shortcuts',
                items: [
                  'Ctrl+S or Cmd+S: Save medicine',
                  'Ctrl+R or Cmd+R: Clear form',
                  'Ctrl+/ or Cmd+/: Focus search field',
                  'Tab: Navigate between fields',
                ],
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: 'Pro Tips',
                items: [
                  'Use "Save & Add Another" for bulk entry',
                  'Auto-filled data can be edited before saving',
                  'Profit analysis updates in real-time',
                  'Required fields are marked with *',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets

class _SuggestionTile extends StatelessWidget {
  final MedicineSearchResult suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.medicineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '₹${suggestion.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: HospitalTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.manufacturer,
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 13,
              ),
            ),
            if (suggestion.composition.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                suggestion.composition,
                style: TextStyle(
                  color: HospitalTheme.textLight,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (suggestion.packageInfo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                suggestion.packageInfo,
                style: TextStyle(
                  color: HospitalTheme.textLight,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmartAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final Future<List<String>> Function(String) onSearch;
  final FocusNode? nextFocusNode;

  const _SmartAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    required this.onSearch,
    this.nextFocusNode,
  });

  @override
  State<_SmartAutocompleteField> createState() =>
      _SmartAutocompleteFieldState();
}

class _SmartAutocompleteFieldState extends State<_SmartAutocompleteField> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.controller.text),
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty || textEditingValue.text.length < 2) {
          return const Iterable<String>.empty();
        }
        return await widget.onSearch(textEditingValue.text);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
          ),
          validator: widget.validator,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            if (widget.nextFocusNode != null) {
              widget.nextFocusNode!.requestFocus();
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfitMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ProfitMetric({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: HospitalTheme.textMedium,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _HelpSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: HospitalTheme.themeData.textTheme.titleMedium?.copyWith(
            color: HospitalTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: HospitalTheme.primary),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
