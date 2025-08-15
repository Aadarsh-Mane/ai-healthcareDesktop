import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((event) => event.first);
});

final internetStatusProvider =
    StateNotifierProvider<InternetStatusNotifier, InternetStatus>((ref) {
  return InternetStatusNotifier(ref);
});

class InternetStatus {
  final bool isConnected;
  final String connectionType;
  final bool isInternetReachable;
  final bool isServerReachable;
  final int internetResponseTime;
  final int serverResponseTime;
  final DateTime lastChecked;
  final String connectionQuality;

  const InternetStatus({
    required this.isConnected,
    required this.connectionType,
    required this.isInternetReachable,
    required this.isServerReachable,
    required this.internetResponseTime,
    required this.serverResponseTime,
    required this.lastChecked,
    required this.connectionQuality,
  });

  InternetStatus copyWith({
    bool? isConnected,
    String? connectionType,
    bool? isInternetReachable,
    bool? isServerReachable,
    int? internetResponseTime,
    int? serverResponseTime,
    DateTime? lastChecked,
    String? connectionQuality,
  }) {
    return InternetStatus(
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
      isInternetReachable: isInternetReachable ?? this.isInternetReachable,
      isServerReachable: isServerReachable ?? this.isServerReachable,
      internetResponseTime: internetResponseTime ?? this.internetResponseTime,
      serverResponseTime: serverResponseTime ?? this.serverResponseTime,
      lastChecked: lastChecked ?? this.lastChecked,
      connectionQuality: connectionQuality ?? this.connectionQuality,
    );
  }
}

class InternetStatusNotifier extends StateNotifier<InternetStatus> {
  final Ref ref;
  Timer? _timer;
  Timer? _quickTimer;

  InternetStatusNotifier(this.ref)
      : super(InternetStatus(
          isConnected: false,
          connectionType: 'None',
          isInternetReachable: false,
          isServerReachable: false,
          internetResponseTime: 0,
          serverResponseTime: 0,
          lastChecked: DateTime.now(),
          connectionQuality: 'Unknown',
        )) {
    _startPeriodicCheck();
    _startQuickConnectivityCheck();
    _checkInternetStatus();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(Duration(seconds: 60), (_) {
      _checkInternetStatus();
    });
  }

  void _startQuickConnectivityCheck() {
    // Quick connectivity check every 10 seconds (no network requests)
    _quickTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _checkBasicConnectivity();
    });
  }

  Future<void> _checkBasicConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final firstResult = connectivityResult.isNotEmpty
          ? connectivityResult.first
          : ConnectivityResult.none;
      String connectionType = _getConnectionType(firstResult);

      state = state.copyWith(
        isConnected: firstResult != ConnectivityResult.none,
        connectionType: connectionType,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        connectionType: 'Error',
        lastChecked: DateTime.now(),
      );
    }
  }

  Future<void> _checkInternetStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final firstResult = connectivityResult.isNotEmpty
          ? connectivityResult.first
          : ConnectivityResult.none;
      String connectionType = _getConnectionType(firstResult);

      if (firstResult == ConnectivityResult.none) {
        state = state.copyWith(
          isConnected: false,
          connectionType: connectionType,
          isInternetReachable: false,
          isServerReachable: false,
          internetResponseTime: 0,
          serverResponseTime: 0,
          lastChecked: DateTime.now(),
          connectionQuality: 'No Connection',
        );
        return;
      }

      // Check internet connectivity using multiple reliable sources
      final internetCheck = await _checkInternetConnectivity();

      // Check your server connectivity
      final serverCheck = await _checkServerConnectivity();

      String quality = _determineConnectionQuality(
          internetCheck.responseTime, internetCheck.isReachable);

      state = state.copyWith(
        isConnected: firstResult != ConnectivityResult.none,
        connectionType: connectionType,
        isInternetReachable: internetCheck.isReachable,
        isServerReachable: serverCheck.isReachable,
        internetResponseTime: internetCheck.responseTime,
        serverResponseTime: serverCheck.responseTime,
        lastChecked: DateTime.now(),
        connectionQuality: quality,
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        connectionType: 'Error',
        isInternetReachable: false,
        isServerReachable: false,
        internetResponseTime: 0,
        serverResponseTime: 0,
        lastChecked: DateTime.now(),
        connectionQuality: 'Error',
      );
    }
  }

  Future<ConnectivityCheckResult> _checkInternetConnectivity() async {
    final List<String> testUrls = [
      'https://www.google.com',
      'https://www.cloudflare.com',
      'https://1.1.1.1',
    ];

    for (String url in testUrls) {
      try {
        final stopwatch = Stopwatch()..start();

        // Use DNS lookup first (faster than HTTP request)
        final host = Uri.parse(url).host;
        final addresses = await InternetAddress.lookup(host);

        if (addresses.isNotEmpty) {
          stopwatch.stop();
          return ConnectivityCheckResult(
              isReachable: true, responseTime: stopwatch.elapsedMilliseconds);
        }
      } catch (e) {
        // Continue to next URL
        continue;
      }
    }

    // If DNS lookups fail, try HTTP request as fallback
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.head(
        Uri.parse('https://www.google.com'),
        headers: {'Connection': 'close'},
      ).timeout(Duration(seconds: 3));

      stopwatch.stop();

      return ConnectivityCheckResult(
        isReachable: response.statusCode == 200,
        responseTime: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      return ConnectivityCheckResult(isReachable: false, responseTime: 0);
    }
  }

  Future<ConnectivityCheckResult> _checkServerConnectivity() async {
    try {
      final stopwatch = Stopwatch()..start();

      // First try DNS lookup for your server
      final host = Uri.parse(KVM_URL).host;
      final addresses = await InternetAddress.lookup(host);

      if (addresses.isEmpty) {
        return ConnectivityCheckResult(isReachable: false, responseTime: 0);
      }

      // Then try HTTP request to your server
      final response = await http.head(
        Uri.parse('$KVM_URL/health'),
        headers: {'Connection': 'close'},
      ).timeout(Duration(seconds: 5));

      stopwatch.stop();

      return ConnectivityCheckResult(
        isReachable: response.statusCode == 200,
        responseTime: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      return ConnectivityCheckResult(isReachable: false, responseTime: 0);
    }
  }

  String _determineConnectionQuality(int responseTime, bool isReachable) {
    if (!isReachable) return 'No Internet';

    if (responseTime < 100) return 'Excellent';
    if (responseTime < 300) return 'Good';
    if (responseTime < 600) return 'Fair';
    if (responseTime < 1000) return 'Poor';
    return 'Very Poor';
  }

  String _getConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  void forceCheck() {
    _checkInternetStatus();
  }

  void forceQuickCheck() {
    _checkBasicConnectivity();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quickTimer?.cancel();
    super.dispose();
  }
}

class ConnectivityCheckResult {
  final bool isReachable;
  final int responseTime;

  ConnectivityCheckResult({
    required this.isReachable,
    required this.responseTime,
  });
}
