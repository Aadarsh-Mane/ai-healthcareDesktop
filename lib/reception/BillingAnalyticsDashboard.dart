import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

// Models
class DateRange {
  final String startDate;
  final String endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
    );
  }
}

class QueryStats {
  final int recordsProcessed;
  final double queryTime;
  final bool useCache;

  const QueryStats({
    required this.recordsProcessed,
    required this.queryTime,
    required this.useCache,
  });

  factory QueryStats.fromJson(Map<String, dynamic> json) {
    return QueryStats(
      recordsProcessed:
          int.tryParse(json['recordsProcessed']?.toString() ?? '0') ?? 0,
      queryTime: double.tryParse(json['queryTime']?.toString() ?? '0') ?? 0.0,
      useCache: json['useCache'] ?? false,
    );
  }
}

class KpiSummary {
  final double totalRevenue;
  final double totalCollected;
  final double totalOutstanding;
  final int totalBills;
  final int uniquePatientCount;
  final double collectionRate;
  final double outstandingRate;
  final double averageTicketSize;
  final double averageCollectionAmount;
  final double averageBillsPerPatient;

  const KpiSummary({
    required this.totalRevenue,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.totalBills,
    required this.uniquePatientCount,
    required this.collectionRate,
    required this.outstandingRate,
    required this.averageTicketSize,
    required this.averageCollectionAmount,
    required this.averageBillsPerPatient,
  });

  factory KpiSummary.fromJson(Map<String, dynamic> json) {
    return KpiSummary(
      totalRevenue:
          double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
      totalCollected:
          double.tryParse(json['totalCollected']?.toString() ?? '0') ?? 0.0,
      totalOutstanding:
          double.tryParse(json['totalOutstanding']?.toString() ?? '0') ?? 0.0,
      totalBills: int.tryParse(json['totalBills']?.toString() ?? '0') ?? 0,
      uniquePatientCount:
          int.tryParse(json['uniquePatientCount']?.toString() ?? '0') ?? 0,
      collectionRate:
          double.tryParse(json['collectionRate']?.toString() ?? '0') ?? 0.0,
      outstandingRate:
          double.tryParse(json['outstandingRate']?.toString() ?? '0') ?? 0.0,
      averageTicketSize:
          double.tryParse(json['averageTicketSize']?.toString() ?? '0') ?? 0.0,
      averageCollectionAmount:
          double.tryParse(json['averageCollectionAmount']?.toString() ?? '0') ??
              0.0,
      averageBillsPerPatient:
          double.tryParse(json['averageBillsPerPatient']?.toString() ?? '0') ??
              0.0,
    );
  }
}

class TrendDataPoint {
  final String period;
  final double totalBilled;
  final double totalCollected;
  final double totalOutstanding;
  final int transactionCount;
  final double averageBillAmount;
  final double collectionRate;

  const TrendDataPoint({
    required this.period,
    required this.totalBilled,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.transactionCount,
    required this.averageBillAmount,
    required this.collectionRate,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      period: json['period']?.toString() ?? '',
      totalBilled:
          double.tryParse(json['totalBilled']?.toString() ?? '0') ?? 0.0,
      totalCollected:
          double.tryParse(json['totalCollected']?.toString() ?? '0') ?? 0.0,
      totalOutstanding:
          double.tryParse(json['totalOutstanding']?.toString() ?? '0') ?? 0.0,
      transactionCount:
          int.tryParse(json['transactionCount']?.toString() ?? '0') ?? 0,
      averageBillAmount:
          double.tryParse(json['averageBillAmount']?.toString() ?? '0') ?? 0.0,
      collectionRate:
          double.tryParse(json['collectionRate']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class TrendAnalysis {
  final String timeframe;
  final bool samplingUsed;
  final int dataPoints;
  final List<TrendDataPoint> data;

  const TrendAnalysis({
    required this.timeframe,
    required this.samplingUsed,
    required this.dataPoints,
    required this.data,
  });

  factory TrendAnalysis.fromJson(Map<String, dynamic> json) {
    return TrendAnalysis(
      timeframe: json['timeframe']?.toString() ?? 'month',
      samplingUsed: json['samplingUsed'] ?? false,
      dataPoints: int.tryParse(json['dataPoints']?.toString() ?? '0') ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => TrendDataPoint.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class AgingAnalysis {
  final String id;
  final double totalOutstanding;
  final int count;
  final double averageDaysOutstanding;

  const AgingAnalysis({
    required this.id,
    required this.totalOutstanding,
    required this.count,
    required this.averageDaysOutstanding,
  });

  factory AgingAnalysis.fromJson(Map<String, dynamic> json) {
    return AgingAnalysis(
      id: json['_id']?.toString() ?? '',
      totalOutstanding:
          double.tryParse(json['totalOutstanding']?.toString() ?? '0') ?? 0.0,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      averageDaysOutstanding:
          double.tryParse(json['averageDaysOutstanding']?.toString() ?? '0') ??
              0.0,
    );
  }
}

class ArAnalysis {
  final List<AgingAnalysis> agingAnalysis;
  final double totalAccountsReceivable;
  final int totalOutstandingBills;
  final double averageOutstandingAmount;

  const ArAnalysis({
    required this.agingAnalysis,
    required this.totalAccountsReceivable,
    required this.totalOutstandingBills,
    required this.averageOutstandingAmount,
  });

  factory ArAnalysis.fromJson(Map<String, dynamic> json) {
    return ArAnalysis(
      agingAnalysis: (json['agingAnalysis'] as List<dynamic>?)
              ?.map((item) => AgingAnalysis.fromJson(item))
              .toList() ??
          [],
      totalAccountsReceivable:
          double.tryParse(json['totalAccountsReceivable']?.toString() ?? '0') ??
              0.0,
      totalOutstandingBills:
          int.tryParse(json['totalOutstandingBills']?.toString() ?? '0') ?? 0,
      averageOutstandingAmount: double.tryParse(
              json['averageOutstandingAmount']?.toString() ?? '0') ??
          0.0,
    );
  }
}

class BillingAnalyticsData {
  final String message;
  final DateRange dateRange;
  final QueryStats queryStats;
  final KpiSummary kpiSummary;
  final TrendAnalysis trendAnalysis;
  final ArAnalysis arAnalysis;

  const BillingAnalyticsData({
    required this.message,
    required this.dateRange,
    required this.queryStats,
    required this.kpiSummary,
    required this.trendAnalysis,
    required this.arAnalysis,
  });

  factory BillingAnalyticsData.fromJson(Map<String, dynamic> json) {
    return BillingAnalyticsData(
      message: json['message']?.toString() ?? '',
      dateRange: DateRange.fromJson(json['dateRange'] ?? {}),
      queryStats: QueryStats.fromJson(json['queryStats'] ?? {}),
      kpiSummary: KpiSummary.fromJson(json['kpiSummary'] ?? {}),
      trendAnalysis: TrendAnalysis.fromJson(json['trendAnalysis'] ?? {}),
      arAnalysis: ArAnalysis.fromJson(json['arAnalysis'] ?? {}),
    );
  }
}

// Providers
final billingAnalyticsProvider =
    FutureProvider<BillingAnalyticsData>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('$KVM_URL/reception/getBillingAnalyticsDashboard'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return BillingAnalyticsData.fromJson(jsonData);
    } else {
      throw Exception('Failed to load analytics data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
});

final selectedAnalyticsViewProvider =
    StateProvider<String>((ref) => 'overview');
final dateRangeFilterProvider = StateProvider<String>((ref) => 'last30days');

// Main Dashboard Screen
class BillingAnalyticsDashboard extends ConsumerStatefulWidget {
  const BillingAnalyticsDashboard({super.key});

  @override
  ConsumerState<BillingAnalyticsDashboard> createState() =>
      _BillingAnalyticsDashboardState();
}

class _BillingAnalyticsDashboardState
    extends ConsumerState<BillingAnalyticsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Billing Analytics Dashboard',
        actions: [
          _buildDateRangeFilter(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(billingAnalyticsProvider);
              _animationController.reset();
              _animationController.forward();
            },
            tooltip: 'Refresh Analytics (Ctrl+R)',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAnalytics,
            tooltip: 'Export Analytics (Ctrl+E)',
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _toggleFullscreen,
            tooltip: 'Fullscreen (F11)',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyPress,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: screenSize.width > 1200
              ? _buildDesktopLayout(screenSize)
              : _buildTabletLayout(screenSize),
        ),
      ),
    );
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isCtrlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyR:
            ref.invalidate(billingAnalyticsProvider);
            break;
          case LogicalKeyboardKey.keyE:
            _exportAnalytics();
            break;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f11) {
        _toggleFullscreen();
      }
    }
  }

  Widget _buildDateRangeFilter() {
    final selectedRange = ref.watch(dateRangeFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: DropdownButton<String>(
        value: selectedRange,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'last7days', child: Text('Last 7 Days')),
          DropdownMenuItem(value: 'last30days', child: Text('Last 30 Days')),
          DropdownMenuItem(value: 'last90days', child: Text('Last 90 Days')),
          DropdownMenuItem(value: 'thisyear', child: Text('This Year')),
          DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
        ],
        onChanged: (value) {
          if (value != null) {
            ref.read(dateRangeFilterProvider.notifier).state = value;
          }
        },
      ),
    );
  }

  void _exportAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Analytics export functionality would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleFullscreen() {
    // Fullscreen toggle would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fullscreen toggle functionality'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildDesktopLayout(Size screenSize) {
    return Row(
      children: [
        // Sidebar Navigation
        SizedBox(
          width: 280,
          child: _buildSidebarNavigation(),
        ),
        // Main Content Area
        Expanded(
          child: _buildMainContent(screenSize),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(Size screenSize) {
    return _buildMainContent(screenSize);
  }

  Widget _buildSidebarNavigation() {
    final selectedView = ref.watch(selectedAnalyticsViewProvider);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: HospitalTheme.primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Analytics Views',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildNavItem(
                  'overview',
                  'Overview',
                  Icons.dashboard,
                  selectedView,
                ),
                _buildNavItem(
                  'revenue',
                  'Revenue Analysis',
                  Icons.trending_up,
                  selectedView,
                ),
                _buildNavItem(
                  'collections',
                  'Collections',
                  Icons.account_balance_wallet,
                  selectedView,
                ),
                _buildNavItem(
                  'outstanding',
                  'Outstanding Analysis',
                  Icons.warning_amber,
                  selectedView,
                ),
                _buildNavItem(
                  'trends',
                  'Trend Analysis',
                  Icons.show_chart,
                  selectedView,
                ),
                _buildNavItem(
                  'aging',
                  'Aging Analysis',
                  Icons.schedule,
                  selectedView,
                ),
                _buildNavItem(
                  'performance',
                  'Performance Metrics',
                  Icons.speed,
                  selectedView,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      String value, String label, IconData icon, String selectedView) {
    final isSelected = selectedView == value;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? HospitalTheme.primary : HospitalTheme.textMedium,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? HospitalTheme.primary : HospitalTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: HospitalTheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          ref.read(selectedAnalyticsViewProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildMainContent(Size screenSize) {
    final selectedView = ref.watch(selectedAnalyticsViewProvider);

    return Container(
      color: HospitalTheme.background,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContentHeader(selectedView),
            const SizedBox(height: 24),
            _buildAnalyticsContent(selectedView, screenSize),
          ],
        ),
      ),
    );
  }

  Widget _buildContentHeader(String selectedView) {
    String title;
    String subtitle;
    IconData icon;

    switch (selectedView) {
      case 'revenue':
        title = 'Revenue Analysis';
        subtitle = 'Comprehensive revenue metrics and trends';
        icon = Icons.trending_up;
        break;
      case 'collections':
        title = 'Collections Analysis';
        subtitle = 'Payment collection patterns and efficiency';
        icon = Icons.account_balance_wallet;
        break;
      case 'outstanding':
        title = 'Outstanding Analysis';
        subtitle = 'Unpaid bills and collection opportunities';
        icon = Icons.warning_amber;
        break;
      case 'trends':
        title = 'Trend Analysis';
        subtitle = 'Historical patterns and forecasting';
        icon = Icons.show_chart;
        break;
      case 'aging':
        title = 'Aging Analysis';
        subtitle = 'Accounts receivable aging breakdown';
        icon = Icons.schedule;
        break;
      case 'performance':
        title = 'Performance Metrics';
        subtitle = 'Key performance indicators and benchmarks';
        icon = Icons.speed;
        break;
      default:
        title = 'Analytics Overview';
        subtitle = 'Complete billing and revenue dashboard';
        icon = Icons.dashboard;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HospitalTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: HospitalTheme.primary, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsContent(String selectedView, Size screenSize) {
    final analyticsData = ref.watch(billingAnalyticsProvider);

    return analyticsData.when(
      data: (data) {
        switch (selectedView) {
          case 'revenue':
            return _buildRevenueAnalysis(data, screenSize);
          case 'collections':
            return _buildCollectionsAnalysis(data, screenSize);
          case 'outstanding':
            return _buildOutstandingAnalysis(data, screenSize);
          case 'trends':
            return _buildTrendAnalysis(data, screenSize);
          case 'aging':
            return _buildAgingAnalysis(data, screenSize);
          case 'performance':
            return _buildPerformanceMetrics(data, screenSize);
          default:
            return _buildOverviewAnalysis(data, screenSize);
        }
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildOverviewAnalysis(BillingAnalyticsData data, Size screenSize) {
    return Column(
      children: [
        // KPI Summary Cards
        _buildKpiSummaryGrid(data.kpiSummary, screenSize),
        const SizedBox(height: 32),

        // Quick Insights Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildRevenueOverviewChart(data),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildCollectionRateGauge(data.kpiSummary.collectionRate),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Trend and Aging Analysis
        Row(
          children: [
            Expanded(
              child: _buildMiniTrendChart(data.trendAnalysis),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildAgingBreakdownChart(data.arAnalysis),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Performance Indicators
        _buildPerformanceIndicators(data),
      ],
    );
  }

  Widget _buildKpiSummaryGrid(KpiSummary kpi, Size screenSize) {
    final cardWidth =
        (screenSize.width - 300) / 4 - 18; // Accounting for sidebar and padding

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        SizedBox(
          width: cardWidth,
          child: _buildAnimatedStatCard(
            title: 'Total Revenue',
            value: '₹${kpi.totalRevenue.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet,
            color: HospitalTheme.primary,
            trend: '+12.5%',
            isPositive: true,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _buildAnimatedStatCard(
            title: 'Collected',
            value: '₹${kpi.totalCollected.toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: HospitalTheme.success,
            trend: '+8.2%',
            isPositive: true,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _buildAnimatedStatCard(
            title: 'Outstanding',
            value: '₹${kpi.totalOutstanding.toStringAsFixed(0)}',
            icon: Icons.warning_amber,
            color: HospitalTheme.warning,
            trend: '-3.1%',
            isPositive: false,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _buildAnimatedStatCard(
            title: 'Collection Rate',
            value: '${kpi.collectionRate.toStringAsFixed(1)}%',
            icon: Icons.speed,
            color: HospitalTheme.info,
            trend: '+5.7%',
            isPositive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool isPositive = true,
  }) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive
                            ? HospitalTheme.success
                            : HospitalTheme.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isPositive
                            ? HospitalTheme.success
                            : HospitalTheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? HospitalTheme.success
                              : HospitalTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueOverviewChart(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: data.kpiSummary.totalCollected,
                    title:
                        'Collected\n₹${data.kpiSummary.totalCollected.toStringAsFixed(0)}',
                    color: HospitalTheme.success,
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: data.kpiSummary.totalOutstanding,
                    title:
                        'Outstanding\n₹${data.kpiSummary.totalOutstanding.toStringAsFixed(0)}',
                    color: HospitalTheme.warning,
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 60,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(HospitalTheme.success, 'Collected',
                  '${data.kpiSummary.collectionRate.toStringAsFixed(1)}%'),
              _buildLegendItem(HospitalTheme.warning, 'Outstanding',
                  '${data.kpiSummary.outstandingRate.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String percentage) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 12,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollectionRateGauge(double collectionRate) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Rate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: collectionRate / 100,
                    strokeWidth: 20,
                    backgroundColor: HospitalTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      collectionRate > 80
                          ? HospitalTheme.success
                          : collectionRate > 60
                              ? HospitalTheme.warning
                              : HospitalTheme.error,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${collectionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Collection Rate',
                      style: TextStyle(
                        fontSize: 14,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                collectionRate > 80
                    ? Icons.trending_up
                    : collectionRate > 60
                        ? Icons.trending_flat
                        : Icons.trending_down,
                color: collectionRate > 80
                    ? HospitalTheme.success
                    : collectionRate > 60
                        ? HospitalTheme.warning
                        : HospitalTheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                collectionRate > 80
                    ? 'Excellent'
                    : collectionRate > 60
                        ? 'Good'
                        : 'Needs Improvement',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: collectionRate > 80
                      ? HospitalTheme.success
                      : collectionRate > 60
                          ? HospitalTheme.warning
                          : HospitalTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTrendChart(TrendAnalysis trendAnalysis) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: HospitalTheme.border,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: HospitalTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < trendAnalysis.data.length) {
                          return Text(
                            trendAnalysis.data[value.toInt()].period
                                .split('-')
                                .last,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendAnalysis.data.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.totalBilled);
                    }).toList(),
                    isCurved: true,
                    color: HospitalTheme.primary,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: HospitalTheme.primary.withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: HospitalTheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingBreakdownChart(ArAnalysis arAnalysis) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aging Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: arAnalysis.agingAnalysis.isNotEmpty
                    ? arAnalysis.agingAnalysis
                            .map((e) => e.totalOutstanding)
                            .reduce(math.max) *
                        1.2
                    : 100,
                barGroups:
                    arAnalysis.agingAnalysis.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.totalOutstanding,
                        color: _getAgingColor(entry.value.id),
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < arAnalysis.agingAnalysis.length) {
                          return Text(
                            arAnalysis.agingAnalysis[value.toInt()].id,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAgingColor(String ageGroup) {
    switch (ageGroup) {
      case '0-30 days':
        return HospitalTheme.success;
      case '31-60 days':
        return HospitalTheme.warning;
      case '61-90 days':
        return HospitalTheme.error;
      case '90+ days':
        return HospitalTheme.error.withOpacity(0.8);
      default:
        return HospitalTheme.primary;
    }
  }

  Widget _buildPerformanceIndicators(BillingAnalyticsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Indicators',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPerformanceCard(
                'Average Ticket Size',
                '₹${data.kpiSummary.averageTicketSize.toStringAsFixed(0)}',
                Icons.receipt_long,
                HospitalTheme.primary,
                'Per transaction',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPerformanceCard(
                'Bills per Patient',
                data.kpiSummary.averageBillsPerPatient.toStringAsFixed(1),
                Icons.person,
                HospitalTheme.secondary,
                'Average ratio',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPerformanceCard(
                'Total Patients',
                data.kpiSummary.uniquePatientCount.toString(),
                Icons.people,
                HospitalTheme.medical,
                'Unique count',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPerformanceCard(
                'Total Bills',
                data.kpiSummary.totalBills.toString(),
                Icons.description,
                HospitalTheme.info,
                'Generated',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return HospitalTheme.buildCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Revenue Analysis View
  Widget _buildRevenueAnalysis(BillingAnalyticsData data, Size screenSize) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildRevenueMetricsChart(data),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildRevenueBreakdown(data),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildRevenueAnalysisTable(data),
      ],
    );
  }

  Widget _buildRevenueMetricsChart(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Metrics Over Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: HospitalTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.trendAnalysis.data.length) {
                          return Text(
                            data.trendAnalysis.data[value.toInt()].period,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.trendAnalysis.data.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.totalBilled);
                    }).toList(),
                    isCurved: true,
                    color: HospitalTheme.primary,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: HospitalTheme.primary.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: data.trendAnalysis.data.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.totalCollected);
                    }).toList(),
                    isCurved: true,
                    color: HospitalTheme.success,
                    barWidth: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(HospitalTheme.primary, 'Total Billed', ''),
              _buildLegendItem(HospitalTheme.success, 'Total Collected', ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildBreakdownItem(
            'Total Revenue',
            data.kpiSummary.totalRevenue,
            HospitalTheme.primary,
            isMainItem: true,
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem(
            'Collected Amount',
            data.kpiSummary.totalCollected,
            HospitalTheme.success,
          ),
          const SizedBox(height: 12),
          _buildBreakdownItem(
            'Outstanding Amount',
            data.kpiSummary.totalOutstanding,
            HospitalTheme.warning,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Collection Efficiency',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${data.kpiSummary.collectionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: data.kpiSummary.collectionRate > 80
                        ? HospitalTheme.success
                        : HospitalTheme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String title, double amount, Color color,
      {bool isMainItem = false}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: isMainItem ? 40 : 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMainItem ? 16 : 14,
                  fontWeight: isMainItem ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isMainItem ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueAnalysisTable(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Revenue Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Metric',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Percentage',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              _buildTableRow(
                'Total Revenue',
                data.kpiSummary.totalRevenue,
                100.0,
                'Excellent',
                HospitalTheme.primary,
              ),
              _buildTableRow(
                'Collected Amount',
                data.kpiSummary.totalCollected,
                data.kpiSummary.collectionRate,
                data.kpiSummary.collectionRate > 80
                    ? 'Good'
                    : 'Needs Improvement',
                HospitalTheme.success,
              ),
              _buildTableRow(
                'Outstanding Amount',
                data.kpiSummary.totalOutstanding,
                data.kpiSummary.outstandingRate,
                data.kpiSummary.outstandingRate < 20 ? 'Good' : 'High',
                HospitalTheme.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String metric, double amount, double percentage,
      String status, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(metric),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '₹${amount.toStringAsFixed(0)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Collections Analysis View
  Widget _buildCollectionsAnalysis(BillingAnalyticsData data, Size screenSize) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCollectionEfficiencyChart(data),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildCollectionMetrics(data),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildCollectionTimeline(data),
      ],
    );
  }

  Widget _buildCollectionEfficiencyChart(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Efficiency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: data.kpiSummary.collectionRate / 100,
                    strokeWidth: 25,
                    backgroundColor: HospitalTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      data.kpiSummary.collectionRate > 80
                          ? HospitalTheme.success
                          : data.kpiSummary.collectionRate > 60
                              ? HospitalTheme.warning
                              : HospitalTheme.error,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${data.kpiSummary.collectionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Collection Rate',
                      style: TextStyle(
                        fontSize: 16,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${data.kpiSummary.totalCollected.toStringAsFixed(0)} / ₹${data.kpiSummary.totalRevenue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
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

  Widget _buildCollectionMetrics(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildMetricRow(
            'Average Collection Amount',
            '₹${data.kpiSummary.averageCollectionAmount.toStringAsFixed(0)}',
            Icons.account_balance_wallet,
            HospitalTheme.primary,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Average Ticket Size',
            '₹${data.kpiSummary.averageTicketSize.toStringAsFixed(0)}',
            Icons.receipt_long,
            HospitalTheme.secondary,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Total Bills',
            data.kpiSummary.totalBills.toString(),
            Icons.description,
            HospitalTheme.info,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Unique Patients',
            data.kpiSummary.uniquePatientCount.toString(),
            Icons.people,
            HospitalTheme.medical,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: HospitalTheme.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection Performance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        data.kpiSummary.collectionRate > 80
                            ? 'Excellent collection rate! Keep up the good work.'
                            : data.kpiSummary.collectionRate > 60
                                ? 'Good collection rate, room for improvement.'
                                : 'Collection rate needs attention and improvement.',
                        style: TextStyle(
                          fontSize: 13,
                          color: HospitalTheme.textDark,
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
    );
  }

  Widget _buildMetricRow(
      String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: HospitalTheme.textMedium,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionTimeline(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Collection Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildTimelineButton('Daily', false),
                  const SizedBox(width: 8),
                  _buildTimelineButton('Weekly', false),
                  const SizedBox(width: 8),
                  _buildTimelineButton('Monthly', true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: HospitalTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.trendAnalysis.data.length) {
                          return Text(
                            data.trendAnalysis.data[value.toInt()].period,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.trendAnalysis.data.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.totalCollected);
                    }).toList(),
                    isCurved: true,
                    color: HospitalTheme.success,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: HospitalTheme.success.withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: HospitalTheme.success,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : HospitalTheme.textMedium,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  // Outstanding Analysis View
  Widget _buildOutstandingAnalysis(BillingAnalyticsData data, Size screenSize) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOutstandingBreakdown(data),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildOutstandingTrends(data),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildOutstandingActionItems(data),
      ],
    );
  }

  Widget _buildOutstandingBreakdown(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outstanding Amount Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: data.arAnalysis.agingAnalysis.map((aging) {
                  return PieChartSectionData(
                    value: aging.totalOutstanding,
                    title:
                        '${aging.id}\n₹${aging.totalOutstanding.toStringAsFixed(0)}',
                    color: _getAgingColor(aging.id),
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...data.arAnalysis.agingAnalysis.map((aging) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getAgingColor(aging.id),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${aging.id}: ${aging.count} bills',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹${aging.totalOutstanding.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOutstandingTrends(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outstanding Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: data.trendAnalysis.data.isNotEmpty
                    ? data.trendAnalysis.data
                            .map((e) => e.totalOutstanding)
                            .reduce(math.max) *
                        1.2
                    : 100,
                barGroups: data.trendAnalysis.data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.totalOutstanding,
                        color: HospitalTheme.warning,
                        width: 25,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.trendAnalysis.data.length) {
                          return Text(
                            data.trendAnalysis.data[value.toInt()].period
                                .split('-')
                                .last,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: HospitalTheme.warning),
                    const SizedBox(width: 8),
                    const Text(
                      'Outstanding Summary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Outstanding: ₹${data.arAnalysis.totalAccountsReceivable.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Average per Bill: ₹${data.arAnalysis.averageOutstandingAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingActionItems(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Action Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Send Reminders',
                  'Follow up on overdue payments',
                  Icons.notification_important,
                  HospitalTheme.warning,
                  '${data.arAnalysis.totalOutstandingBills} bills',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Collection Calls',
                  'Contact high-value outstanding patients',
                  Icons.phone,
                  HospitalTheme.info,
                  'Priority action',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Payment Plans',
                  'Offer installment options',
                  Icons.schedule,
                  HospitalTheme.primary,
                  'Flexible options',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Review Process',
                  'Analyze collection efficiency',
                  Icons.analytics,
                  HospitalTheme.secondary,
                  'Process improvement',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String badge,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleActionItemClick(title),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Execute',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleActionItemClick(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action functionality would be implemented here'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Trend Analysis View
  Widget _buildTrendAnalysis(BillingAnalyticsData data, Size screenSize) {
    return Column(
      children: [
        _buildComprehensiveTrendChart(data),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildTrendMetrics(data),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildTrendInsights(data),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComprehensiveTrendChart(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comprehensive Trend Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildTrendToggle('Revenue', true),
                  const SizedBox(width: 8),
                  _buildTrendToggle('Collections', true),
                  const SizedBox(width: 8),
                  _buildTrendToggle('Outstanding', true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 400,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: HospitalTheme.border,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: HospitalTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.trendAnalysis.data.length) {
                          return Text(
                            data.trendAnalysis.data[value.toInt()].period,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.trendAnalysis.data.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.totalBilled);
                    }).toList(),
                    isCurved: true,
                    color: HospitalTheme.primary,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: HospitalTheme.primary.withOpacity(0.1),
                    ),
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: data.trendAnalysis.data.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.totalCollected);
                    }).toList(),
                    isCurved: true,
                    color: HospitalTheme.success,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: data.trendAnalysis.data.asMap().entries.map((entry) {
                      return FlSpot(
                          entry.key.toDouble(), entry.value.totalOutstanding);
                    }).toList(),
                    isCurved: true,
                    color: HospitalTheme.warning,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(HospitalTheme.primary, 'Total Billed', ''),
              _buildLegendItem(HospitalTheme.success, 'Total Collected', ''),
              _buildLegendItem(HospitalTheme.warning, 'Total Outstanding', ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendToggle(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : HospitalTheme.textMedium,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTrendMetrics(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTrendMetricItem(
            'Growth Rate',
            '+12.5%',
            Icons.trending_up,
            HospitalTheme.success,
            'Month over month',
          ),
          const SizedBox(height: 16),
          _buildTrendMetricItem(
            'Collection Efficiency',
            '${data.kpiSummary.collectionRate.toStringAsFixed(1)}%',
            Icons.speed,
            HospitalTheme.primary,
            'Current rate',
          ),
          const SizedBox(height: 16),
          _buildTrendMetricItem(
            'Outstanding Ratio',
            '${data.kpiSummary.outstandingRate.toStringAsFixed(1)}%',
            Icons.warning_amber,
            HospitalTheme.warning,
            'Of total revenue',
          ),
          const SizedBox(height: 16),
          _buildTrendMetricItem(
            'Average Transaction',
            '₹${data.kpiSummary.averageTicketSize.toStringAsFixed(0)}',
            Icons.receipt_long,
            HospitalTheme.info,
            'Per bill',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendMetricItem(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendInsights(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildInsightItem(
            Icons.trending_up,
            HospitalTheme.success,
            'Revenue Growth',
            'Revenue has shown consistent growth with a positive trend over the analysis period.',
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.account_balance_wallet,
            HospitalTheme.primary,
            'Collection Performance',
            'Collection rate of ${data.kpiSummary.collectionRate.toStringAsFixed(1)}% indicates ${data.kpiSummary.collectionRate > 80 ? 'excellent' : 'room for improvement'} performance.',
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.warning_amber,
            HospitalTheme.warning,
            'Outstanding Management',
            'Outstanding amount represents ${data.kpiSummary.outstandingRate.toStringAsFixed(1)}% of total revenue, requiring attention.',
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.analytics,
            HospitalTheme.info,
            'Predictive Analysis',
            'Based on current trends, projected monthly revenue could reach ₹${(data.kpiSummary.totalRevenue * 1.125).toStringAsFixed(0)}.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
      IconData icon, Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Aging Analysis View
  Widget _buildAgingAnalysis(BillingAnalyticsData data, Size screenSize) {
    return Column(
      children: [
        _buildDetailedAgingChart(data),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildAgingMetrics(data),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildAgingRecommendations(data),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedAgingChart(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accounts Receivable Aging Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: data.arAnalysis.agingAnalysis.isNotEmpty
                          ? data.arAnalysis.agingAnalysis
                                  .map((e) => e.totalOutstanding)
                                  .reduce(math.max) *
                              1.2
                          : 100,
                      barGroups: data.arAnalysis.agingAnalysis
                          .asMap()
                          .entries
                          .map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.totalOutstanding,
                              color: _getAgingColor(entry.value.id),
                              width: 40,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() <
                                  data.arAnalysis.agingAnalysis.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    data.arAnalysis.agingAnalysis[value.toInt()]
                                        .id,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₹${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: HospitalTheme.border,
                          strokeWidth: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aging Breakdown',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...data.arAnalysis.agingAnalysis.map((aging) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getAgingColor(aging.id).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    _getAgingColor(aging.id).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      aging.id,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${aging.totalOutstanding.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _getAgingColor(aging.id),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${aging.count} bills • Avg: ${aging.averageDaysOutstanding.toStringAsFixed(0)} days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: HospitalTheme.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingMetrics(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aging Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildAgingMetricCard(
            'Total AR',
            '₹${data.arAnalysis.totalAccountsReceivable.toStringAsFixed(0)}',
            Icons.account_balance,
            HospitalTheme.primary,
          ),
          const SizedBox(height: 16),
          _buildAgingMetricCard(
            'Outstanding Bills',
            data.arAnalysis.totalOutstandingBills.toString(),
            Icons.description,
            HospitalTheme.warning,
          ),
          const SizedBox(height: 16),
          _buildAgingMetricCard(
            'Average Outstanding',
            '₹${data.arAnalysis.averageOutstandingAmount.toStringAsFixed(0)}',
            Icons.calculate,
            HospitalTheme.info,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HospitalTheme.primary.withOpacity(0.1),
                  HospitalTheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AR Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (data.kpiSummary.collectionRate / 100).clamp(0.0, 1.0),
                  backgroundColor: HospitalTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    data.kpiSummary.collectionRate > 80
                        ? HospitalTheme.success
                        : HospitalTheme.warning,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.kpiSummary.collectionRate.toStringAsFixed(1)}% Collection Rate',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingRecommendations(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildRecommendationItem(
            Icons.notification_important,
            HospitalTheme.error,
            'Immediate Action Required',
            'Follow up on 90+ day outstanding accounts immediately to prevent write-offs.',
            'High Priority',
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            Icons.phone,
            HospitalTheme.warning,
            'Contact Overdue Accounts',
            'Send payment reminders for 31-60 day outstanding accounts.',
            'Medium Priority',
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            Icons.schedule,
            HospitalTheme.info,
            'Payment Plan Options',
            'Offer flexible payment plans for high-value outstanding amounts.',
            'Consider',
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            Icons.analytics,
            HospitalTheme.primary,
            'Process Improvement',
            'Review billing processes to reduce future aging of accounts.',
            'Long Term',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    IconData icon,
    Color color,
    String title,
    String description,
    String priority,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Performance Metrics View
  Widget _buildPerformanceMetrics(BillingAnalyticsData data, Size screenSize) {
    return Column(
      children: [
        _buildPerformanceOverview(data),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildPerformanceGauges(data),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildPerformanceBenchmarks(data),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildPerformanceActionPlan(data),
      ],
    );
  }

  Widget _buildPerformanceOverview(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceScoreCard(
                  'Collection Score',
                  _calculateCollectionScore(data.kpiSummary.collectionRate),
                  data.kpiSummary.collectionRate,
                  Icons.account_balance_wallet,
                  HospitalTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceScoreCard(
                  'Efficiency Score',
                  _calculateEfficiencyScore(data.kpiSummary.averageTicketSize),
                  85.0,
                  Icons.speed,
                  HospitalTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceScoreCard(
                  'AR Management Score',
                  _calculateARScore(data.kpiSummary.outstandingRate),
                  78.0,
                  Icons.manage_accounts,
                  HospitalTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceScoreCard(
                  'Overall Score',
                  _calculateOverallScore(data.kpiSummary),
                  82.0,
                  Icons.star,
                  HospitalTheme.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateCollectionScore(double collectionRate) {
    return math.min(100, collectionRate * 1.2);
  }

  double _calculateEfficiencyScore(double averageTicketSize) {
    return math.min(100, (averageTicketSize / 300) * 100);
  }

  double _calculateARScore(double outstandingRate) {
    return math.max(0, 100 - (outstandingRate * 2));
  }

  double _calculateOverallScore(KpiSummary kpi) {
    return (_calculateCollectionScore(kpi.collectionRate) +
            _calculateEfficiencyScore(kpi.averageTicketSize) +
            _calculateARScore(kpi.outstandingRate)) /
        3;
  }

  Widget _buildPerformanceScoreCard(
    String title,
    double score,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            '${score.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _getScoreGrade(score),
            style: TextStyle(
              fontSize: 12,
              color: _getScoreColor(score),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreGrade(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Average';
    if (score >= 60) return 'Below Average';
    return 'Poor';
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return HospitalTheme.success;
    if (score >= 80) return HospitalTheme.primary;
    if (score >= 70) return HospitalTheme.info;
    if (score >= 60) return HospitalTheme.warning;
    return HospitalTheme.error;
  }

  Widget _buildPerformanceGauges(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Gauges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildGaugeRow(
            'Collection Rate',
            data.kpiSummary.collectionRate,
            100,
            HospitalTheme.success,
            '%',
          ),
          const SizedBox(height: 20),
          _buildGaugeRow(
            'Outstanding Rate',
            data.kpiSummary.outstandingRate,
            100,
            HospitalTheme.warning,
            '%',
          ),
          const SizedBox(height: 20),
          _buildGaugeRow(
            'Average Bills per Patient',
            data.kpiSummary.averageBillsPerPatient,
            5.0,
            HospitalTheme.primary,
            '',
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeRow(
      String title, double value, double max, Color color, String suffix) {
    final percentage = (value / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$suffix',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: HospitalTheme.border,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildPerformanceBenchmarks(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Industry Benchmarks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildBenchmarkItem(
            'Collection Rate',
            data.kpiSummary.collectionRate,
            85.0,
            '%',
            HospitalTheme.success,
          ),
          const SizedBox(height: 16),
          _buildBenchmarkItem(
            'Outstanding Rate',
            data.kpiSummary.outstandingRate,
            15.0,
            '%',
            HospitalTheme.warning,
          ),
          const SizedBox(height: 16),
          _buildBenchmarkItem(
            'Average Ticket Size',
            data.kpiSummary.averageTicketSize,
            300.0,
            '₹',
            HospitalTheme.primary,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HospitalTheme.info.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: HospitalTheme.info, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Benchmark Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your performance is ${_getBenchmarkAnalysis(data.kpiSummary)} compared to industry standards.',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBenchmarkAnalysis(KpiSummary kpi) {
    int aboveBenchmark = 0;
    if (kpi.collectionRate >= 85.0) aboveBenchmark++;
    if (kpi.outstandingRate <= 15.0) aboveBenchmark++;
    if (kpi.averageTicketSize >= 300.0) aboveBenchmark++;

    switch (aboveBenchmark) {
      case 3:
        return 'excellent';
      case 2:
        return 'above average';
      case 1:
        return 'mixed';
      default:
        return 'below industry standards';
    }
  }

  Widget _buildBenchmarkItem(
    String title,
    double currentValue,
    double benchmarkValue,
    String suffix,
    Color color,
  ) {
    final isAboveBenchmark = suffix == '%'
        ? (title.contains('Outstanding')
            ? currentValue <= benchmarkValue
            : currentValue >= benchmarkValue)
        : currentValue >= benchmarkValue;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Current: ${currentValue.toStringAsFixed(1)}$suffix',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Benchmark: ${benchmarkValue.toStringAsFixed(1)}$suffix',
                    style: TextStyle(
                      fontSize: 13,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          isAboveBenchmark ? Icons.trending_up : Icons.trending_down,
          color: isAboveBenchmark ? HospitalTheme.success : HospitalTheme.error,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildPerformanceActionPlan(BillingAnalyticsData data) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Action Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildActionPlanColumn(
                  'Immediate Actions (0-30 days)',
                  [
                    'Follow up on overdue accounts',
                    'Send payment reminders',
                    'Review billing process',
                    'Update patient contact info',
                  ],
                  HospitalTheme.error,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildActionPlanColumn(
                  'Short Term Goals (1-3 months)',
                  [
                    'Implement payment plans',
                    'Automate reminder system',
                    'Staff training program',
                    'Process optimization',
                  ],
                  HospitalTheme.warning,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildActionPlanColumn(
                  'Long Term Strategy (3+ months)',
                  [
                    'Predictive analytics setup',
                    'Patient portal integration',
                    'Advanced reporting tools',
                    'Benchmark monitoring',
                  ],
                  HospitalTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlanColumn(
      String title, List<String> actions, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Loading and Error States
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Analytics Dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing billing data and generating insights',
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: HospitalTheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to Load Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(billingAnalyticsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate back or show help
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Get Help'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Usage Example
class BillingAnalyticsApp extends StatelessWidget {
  const BillingAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Billing Analytics Dashboard',
        theme: HospitalTheme.themeData,
        home: const BillingAnalyticsDashboard(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
