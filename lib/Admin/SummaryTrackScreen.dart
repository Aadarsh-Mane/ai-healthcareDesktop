// discharge_summaries_screen.dart
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
class DischargeSummary {
  final String id;
  final String? patientId;
  final String? patientName;
  final String? summaryType;
  final int? version;
  final String fileName;
  final String driveLink;
  final int? pdfSize;
  final SummaryInfo? summaryInfo;
  final DateTime generatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isManuallyGenerated;

  const DischargeSummary({
    required this.id,
    this.patientId,
    this.patientName,
    this.summaryType,
    this.version,
    required this.fileName,
    required this.driveLink,
    this.pdfSize,
    this.summaryInfo,
    required this.generatedAt,
    this.createdAt,
    this.updatedAt,
    required this.isManuallyGenerated,
  });

  factory DischargeSummary.fromJson(Map<String, dynamic> json) {
    return DischargeSummary(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      patientName: json['patientName']?.toString(),
      summaryType: json['summaryType']?.toString(),
      version: json['version'] is int ? json['version'] : null,
      fileName: json['fileName']?.toString() ?? '',
      driveLink: json['driveLink']?.toString() ?? '',
      pdfSize: json['pdfSize'] is int ? json['pdfSize'] : null,
      summaryInfo: json['summaryInfo'] != null
          ? SummaryInfo.fromJson(json['summaryInfo'] as Map<String, dynamic>)
          : null,
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isManuallyGenerated: json['isManuallyGenerated'] == true,
    );
  }
}

class SummaryInfo {
  final String? finalDiagnosis;
  final String? conditionOnDischarge;
  final String? consultant;
  final String? consultantId;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? ipdNumber;
  final String? opdNumber;

  const SummaryInfo({
    this.finalDiagnosis,
    this.conditionOnDischarge,
    this.consultant,
    this.consultantId,
    this.admissionDate,
    this.dischargeDate,
    this.ipdNumber,
    this.opdNumber,
  });

  factory SummaryInfo.fromJson(Map<String, dynamic> json) {
    return SummaryInfo(
      finalDiagnosis: json['finalDiagnosis']?.toString(),
      conditionOnDischarge: json['conditionOnDischarge']?.toString(),
      consultant: json['consultant']?.toString(),
      consultantId: json['consultantId']?.toString(),
      admissionDate: json['admissionDate'] != null
          ? DateTime.tryParse(json['admissionDate'].toString())
          : null,
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.tryParse(json['dischargeDate'].toString())
          : null,
      ipdNumber: json['ipdNumber']?.toString(),
      opdNumber: json['opdNumber']?.toString(),
    );
  }
}

class DischargeSummariesResponse {
  final List<DischargeSummary> summaries;
  final Pagination pagination;
  final SummaryFilters filters;
  final String message;

  const DischargeSummariesResponse({
    required this.summaries,
    required this.pagination,
    required this.filters,
    required this.message,
  });

  factory DischargeSummariesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return DischargeSummariesResponse(
      summaries: (data['summaries'] as List<dynamic>? ?? [])
          .map(
              (item) => DischargeSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
          data['pagination'] as Map<String, dynamic>? ?? {}),
      filters: SummaryFilters.fromJson(
          data['filters'] as Map<String, dynamic>? ?? {}),
      message: json['message']?.toString() ?? '',
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool hasPrevPage;
  final int limit;
  final int skip;

  const Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    required this.hasPrevPage,
    required this.limit,
    required this.skip,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      totalCount: json['totalCount'] as int? ?? 0,
      hasNextPage: json['hasNextPage'] == true,
      hasPrevPage: json['hasPrevPage'] == true,
      limit: json['limit'] as int? ?? 10,
      skip: json['skip'] as int? ?? 0,
    );
  }
}

class SummaryFilters {
  final String? search;
  final String? patientId;
  final String? fileName;
  final bool? isManuallyGenerated;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String sortBy;
  final String sortOrder;
  final int page;
  final int limit;

  const SummaryFilters({
    this.search,
    this.patientId,
    this.fileName,
    this.isManuallyGenerated,
    this.dateFrom,
    this.dateTo,
    required this.sortBy,
    required this.sortOrder,
    this.page = 1,
    this.limit = 10,
  });

  factory SummaryFilters.fromJson(Map<String, dynamic> json) {
    return SummaryFilters(
      search: json['search']?.toString(),
      patientId: json['patientId']?.toString(),
      fileName: json['fileName']?.toString(),
      isManuallyGenerated: json['isManuallyGenerated'] as bool?,
      dateFrom: json['dateFrom'] != null
          ? DateTime.tryParse(json['dateFrom'].toString())
          : null,
      dateTo: json['dateTo'] != null
          ? DateTime.tryParse(json['dateTo'].toString())
          : null,
      sortBy: json['sortBy']?.toString() ?? 'generatedAt',
      sortOrder: json['sortOrder']?.toString() ?? 'desc',
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
    );
  }

  SummaryFilters copyWith({
    String? search,
    String? patientId,
    String? fileName,
    bool? isManuallyGenerated,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return SummaryFilters(
      search: search ?? this.search,
      patientId: patientId ?? this.patientId,
      fileName: fileName ?? this.fileName,
      isManuallyGenerated: isManuallyGenerated ?? this.isManuallyGenerated,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  // Convert filters to query parameters
  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (patientId != null && patientId!.isNotEmpty) {
      params['patientId'] = patientId;
    }
    if (fileName != null && fileName!.isNotEmpty) {
      params['fileName'] = fileName;
    }
    if (isManuallyGenerated != null) {
      params['isManuallyGenerated'] = isManuallyGenerated.toString();
    }
    if (dateFrom != null) {
      params['dateFrom'] = dateFrom!.toIso8601String();
    }
    if (dateTo != null) {
      params['dateTo'] = dateTo!.toIso8601String();
    }

    params['sortBy'] = sortBy;
    params['sortOrder'] = sortOrder;
    params['page'] = page.toString();
    params['limit'] = limit.toString();

    return params;
  }
}

// API Service
class DischargeSummaryService {
  static const String baseUrl = '${KVM_URL}';

  static Future<DischargeSummariesResponse> getAllDischargeSummaries(
      SummaryFilters filters) async {
    try {
      final queryParams = filters.toQueryParameters();
      final uri = Uri.parse('$baseUrl/doctors/getAllDischargeSummaries')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return DischargeSummariesResponse.fromJson(jsonData);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch summaries');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: Unable to connect to server');
      }
      rethrow;
    }
  }
}

// Providers
final summaryFiltersProvider = StateProvider<SummaryFilters>((ref) {
  return const SummaryFilters(
    sortBy: 'generatedAt',
    sortOrder: 'desc',
  );
});

final selectedSummaryProvider = StateProvider<DischargeSummary?>((ref) => null);

final dischargeSummariesProvider = FutureProvider.autoDispose
    .family<DischargeSummariesResponse, SummaryFilters>((ref, filters) async {
  return await DischargeSummaryService.getAllDischargeSummaries(filters);
});

// Current page provider for pagination
final currentPageProvider = StateProvider<int>((ref) => 1);

// Main Screen
class DischargeSummariesScreen extends ConsumerStatefulWidget {
  const DischargeSummariesScreen({super.key});

  @override
  ConsumerState<DischargeSummariesScreen> createState() =>
      _DischargeSummariesScreenState();
}

class _DischargeSummariesScreenState
    extends ConsumerState<DischargeSummariesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _patientIdController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      final currentFilters = ref.read(summaryFiltersProvider);
      ref.read(summaryFiltersProvider.notifier).state =
          currentFilters.copyWith(search: null, page: 1);
    }
  }

  void _performSearch() {
    final currentFilters = ref.read(summaryFiltersProvider);
    ref.read(summaryFiltersProvider.notifier).state = currentFilters.copyWith(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      page: 1,
    );
    ref.read(currentPageProvider.notifier).state = 1;
  }

  void _clearFilters() {
    _searchController.clear();
    _patientIdController.clear();
    _fileNameController.clear();
    ref.read(summaryFiltersProvider.notifier).state = const SummaryFilters(
      sortBy: 'generatedAt',
      sortOrder: 'desc',
    );
    ref.read(selectedSummaryProvider.notifier).state = null;
    ref.read(currentPageProvider.notifier).state = 1;
  }

  void _goToPage(int page) {
    final currentFilters = ref.read(summaryFiltersProvider);
    ref.read(summaryFiltersProvider.notifier).state =
        currentFilters.copyWith(page: page);
    ref.read(currentPageProvider.notifier).state = page;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _performSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _performSearch,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_showFilters) {
            setState(() => _showFilters = false);
          } else {
            ref.read(selectedSummaryProvider.notifier).state = null;
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: HospitalTheme.buildAppBar(
            context: context,
            title: 'Discharge Summaries',
            actions: [
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  ref.invalidate(dischargeSummariesProvider);
                },
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Search and Filters Section
              Container(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: HospitalTheme.border),
                  ),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Search by patient ID, name, or file name...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _performSearch();
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _performSearch,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Search'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),

                    // Filters Panel
                    if (_showFilters) ...[
                      const SizedBox(height: 16),
                      _SummaryFiltersPanel(
                        patientIdController: _patientIdController,
                        fileNameController: _fileNameController,
                      ),
                    ],
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Master List
        SizedBox(
          width: 400,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: HospitalTheme.border),
              ),
            ),
            child: SummaryMasterList(onPageChanged: _goToPage),
          ),
        ),

        // Detail View
        const Expanded(
          child: SummaryDetailView(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final selectedSummary = ref.watch(selectedSummaryProvider);

    return selectedSummary != null
        ? const SummaryDetailView()
        : SummaryMasterList(onPageChanged: _goToPage);
  }
}

// Summary Filters Panel
class _SummaryFiltersPanel extends ConsumerWidget {
  final TextEditingController patientIdController;
  final TextEditingController fileNameController;

  const _SummaryFiltersPanel({
    required this.patientIdController,
    required this.fileNameController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(summaryFiltersProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Filters'),
          if (isDesktop)
            _buildDesktopFilters(context, ref, filters)
          else
            _buildMobileFilters(context, ref, filters),
        ],
      ),
    );
  }

  Widget _buildDesktopFilters(
      BuildContext context, WidgetRef ref, SummaryFilters filters) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: patientIdController,
                decoration: const InputDecoration(
                  labelText: 'Patient ID',
                  hintText: 'Filter by Patient ID',
                ),
                onChanged: (value) {
                  final newFilters = filters.copyWith(
                    patientId: value.isEmpty ? null : value,
                    page: 1,
                  );
                  ref.read(summaryFiltersProvider.notifier).state = newFilters;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: fileNameController,
                decoration: const InputDecoration(
                  labelText: 'File Name',
                  hintText: 'Filter by File Name',
                ),
                onChanged: (value) {
                  final newFilters = filters.copyWith(
                    fileName: value.isEmpty ? null : value,
                    page: 1,
                  );
                  ref.read(summaryFiltersProvider.notifier).state = newFilters;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<bool?>(
                value: filters.isManuallyGenerated,
                decoration: const InputDecoration(
                  labelText: 'Summary Type',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: true, child: Text('Manual')),
                  DropdownMenuItem(value: false, child: Text('Automatic')),
                ],
                onChanged: (value) {
                  final newFilters = filters.copyWith(
                    isManuallyGenerated: value,
                    page: 1,
                  );
                  ref.read(summaryFiltersProvider.notifier).state = newFilters;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: filters.sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sort By',
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'generatedAt', child: Text('Generated Date')),
                  DropdownMenuItem(
                      value: 'patientId', child: Text('Patient ID')),
                  DropdownMenuItem(value: 'fileName', child: Text('File Name')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    final newFilters = filters.copyWith(sortBy: value);
                    ref.read(summaryFiltersProvider.notifier).state =
                        newFilters;
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: filters.sortOrder,
                decoration: const InputDecoration(
                  labelText: 'Sort Order',
                ),
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    final newFilters = filters.copyWith(sortOrder: value);
                    ref.read(summaryFiltersProvider.notifier).state =
                        newFilters;
                  }
                },
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFilters(
      BuildContext context, WidgetRef ref, SummaryFilters filters) {
    return Column(
      children: [
        TextField(
          controller: patientIdController,
          decoration: const InputDecoration(
            labelText: 'Patient ID',
            hintText: 'Filter by Patient ID',
          ),
          onChanged: (value) {
            final newFilters = filters.copyWith(
              patientId: value.isEmpty ? null : value,
              page: 1,
            );
            ref.read(summaryFiltersProvider.notifier).state = newFilters;
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: fileNameController,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'Filter by File Name',
          ),
          onChanged: (value) {
            final newFilters = filters.copyWith(
              fileName: value.isEmpty ? null : value,
              page: 1,
            );
            ref.read(summaryFiltersProvider.notifier).state = newFilters;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<bool?>(
                value: filters.isManuallyGenerated,
                decoration: const InputDecoration(
                  labelText: 'Summary Type',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: true, child: Text('Manual')),
                  DropdownMenuItem(value: false, child: Text('Automatic')),
                ],
                onChanged: (value) {
                  final newFilters = filters.copyWith(
                    isManuallyGenerated: value,
                    page: 1,
                  );
                  ref.read(summaryFiltersProvider.notifier).state = newFilters;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Summary Master List
class SummaryMasterList extends ConsumerWidget {
  final Function(int) onPageChanged;

  const SummaryMasterList({
    super.key,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(summaryFiltersProvider);
    final summariesAsync = ref.watch(dischargeSummariesProvider(filters));
    final selectedSummary = ref.watch(selectedSummaryProvider);

    return summariesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: HospitalTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load summaries',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(dischargeSummariesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (response) => Column(
        children: [
          // Header with count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: HospitalTheme.surfaceLight,
              border: Border(
                bottom: BorderSide(color: HospitalTheme.border),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${response.pagination.totalCount} Summaries',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (response.summaries.isNotEmpty)
                  HospitalTheme.buildStatusBadge(
                    '${response.pagination.currentPage} of ${response.pagination.totalPages}',
                    color: HospitalTheme.info,
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child: response.summaries.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: response.summaries.length,
                    itemBuilder: (context, index) {
                      final summary = response.summaries[index];
                      final isSelected = selectedSummary?.id == summary.id;

                      return SummaryListItem(
                        summary: summary,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedSummaryProvider.notifier).state =
                              summary;
                        },
                      );
                    },
                  ),
          ),

          // Pagination
          if (response.pagination.totalPages > 1)
            _buildPagination(context, response.pagination),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No summaries found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: HospitalTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context, Pagination pagination) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: pagination.hasPrevPage
                ? () => onPageChanged(pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text(
            'Page ${pagination.currentPage} of ${pagination.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ElevatedButton.icon(
            onPressed: pagination.hasNextPage
                ? () => onPageChanged(pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// Summary List Item
class SummaryListItem extends StatelessWidget {
  final DischargeSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  const SummaryListItem({
    super.key,
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
        border: const Border(
          bottom: BorderSide(color: HospitalTheme.border, width: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.patientName ??
                          summary.patientId ??
                          'Unknown Patient',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? HospitalTheme.primary
                                : HospitalTheme.textDark,
                          ),
                    ),
                  ),
                  HospitalTheme.buildStatusBadge(
                    summary.isManuallyGenerated ? 'Manual' : 'Auto',
                    color: summary.isManuallyGenerated
                        ? HospitalTheme.warning
                        : HospitalTheme.info,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Patient ID if different from name
              if (summary.patientName != null && summary.patientId != null)
                Text(
                  'ID: ${summary.patientId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HospitalTheme.textMedium,
                      ),
                ),

              const SizedBox(height: 4),

              // Generated date
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: HospitalTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(summary.generatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HospitalTheme.textMedium,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // File info
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 14,
                    color: HospitalTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      summary.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HospitalTheme.textMedium,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Summary info preview
              if (summary.summaryInfo?.finalDiagnosis != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HospitalTheme.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_information,
                        size: 14,
                        color: HospitalTheme.medical,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          summary.summaryInfo!.finalDiagnosis!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: HospitalTheme.textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Summary Detail View
class SummaryDetailView extends ConsumerWidget {
  const SummaryDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSummary = ref.watch(selectedSummaryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (selectedSummary == null) {
      return _buildEmptyDetailState(context, isMobile);
    }

    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Detail Header
          if (isMobile)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: HospitalTheme.border),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      ref.read(selectedSummaryProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Summary Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),

          // Detail Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: SummaryDetailContent(summary: selectedSummary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailState(BuildContext context, bool isMobile) {
    return Container(
      color: HospitalTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: isMobile ? 48 : 64,
                color: HospitalTheme.textLight,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Select a Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HospitalTheme.textMedium,
                    ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                'Choose a discharge summary from the list to view details',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HospitalTheme.textLight,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Summary Detail Content
class SummaryDetailContent extends StatelessWidget {
  final DischargeSummary summary;

  const SummaryDetailContent({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient Information Card
        _buildPatientInfoCard(context),

        const SizedBox(height: 16),

        // Summary Information Card
        if (summary.summaryInfo != null) _buildSummaryInfoCard(context),

        const SizedBox(height: 16),

        // File Information Card
        _buildFileInfoCard(context),

        const SizedBox(height: 16),

        // Actions Card
        _buildActionsCard(context),
      ],
    );
  }

  Widget _buildPatientInfoCard(BuildContext context) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Patient Information'),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: HospitalTheme.surfaceLight,
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: HospitalTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.patientName ?? 'Unknown Patient',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient ID: ${summary.patientId ?? 'Not provided'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HospitalTheme.textMedium,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryInfoCard(BuildContext context) {
    final summaryInfo = summary.summaryInfo!;

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Medical Information'),
          _buildInfoRow(
            'Final Diagnosis',
            summaryInfo.finalDiagnosis ?? 'Not provided',
            Icons.medical_information,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Condition on Discharge',
            summaryInfo.conditionOnDischarge ?? 'Not provided',
            Icons.healing,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Consultant',
            summaryInfo.consultant ?? 'Not provided',
            Icons.person_outline,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn(
                  'IPD Number',
                  summaryInfo.ipdNumber ?? 'N/A',
                  Icons.local_hospital,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoColumn(
                  'OPD Number',
                  summaryInfo.opdNumber ?? 'N/A',
                  Icons.assignment,
                ),
              ),
            ],
          ),
          if (summaryInfo.admissionDate != null ||
              summaryInfo.dischargeDate != null) ...[
            const SizedBox(height: 16),
            HospitalTheme.buildDividerWithLabel('Treatment Period'),
            const SizedBox(height: 16),
            Row(
              children: [
                if (summaryInfo.admissionDate != null)
                  Expanded(
                    child: _buildInfoColumn(
                      'Admission Date',
                      _formatDateTime(summaryInfo.admissionDate!),
                      Icons.login,
                    ),
                  ),
                if (summaryInfo.admissionDate != null &&
                    summaryInfo.dischargeDate != null)
                  const SizedBox(width: 16),
                if (summaryInfo.dischargeDate != null)
                  Expanded(
                    child: _buildInfoColumn(
                      'Discharge Date',
                      _formatDateTime(summaryInfo.dischargeDate!),
                      Icons.logout,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileInfoCard(BuildContext context) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('File Information'),
          _buildInfoRow(
            'File Name',
            summary.fileName,
            Icons.description,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Summary Type',
            summary.isManuallyGenerated ? 'Manual' : 'Automatic',
            Icons.build,
            valueColor: summary.isManuallyGenerated
                ? HospitalTheme.warning
                : HospitalTheme.info,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Generated At',
            _formatDateTime(summary.generatedAt),
            Icons.schedule,
          ),
          if (summary.version != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Version',
              'v${summary.version}',
              Icons.update,
            ),
          ],
          if (summary.pdfSize != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'File Size',
              _formatFileSize(summary.pdfSize!),
              Icons.storage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Actions'),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Methods().openPdf(summary.driveLink);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View PDF'),
                ),
              ),
              const SizedBox(width: 12),
              //     Expanded(
              //       child: OutlinedButton.icon(
              //         onPressed: () {
              //           // TODO: Download PDF
              //         },
              //         icon: const Icon(Icons.download),
              //         label: const Text('Download'),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 12),
              // Row(
              //   children: [
              //     Expanded(
              //       child: OutlinedButton.icon(
              //         onPressed: () {
              //           // TODO: Share
              //         },
              //         icon: const Icon(Icons.share),
              //         label: const Text('Share'),
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       child: OutlinedButton.icon(
              //         onPressed: () {
              //           // TODO: Print
              //         },
              //         icon: const Icon(Icons.print),
              //         label: const Text('Print'),
              //       ),
              //     ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: HospitalTheme.textMedium,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? HospitalTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: HospitalTheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? HospitalTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
