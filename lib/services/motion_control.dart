// lib/services/motion_control_server.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to maintain the current selected index across the app
final selectedMenuIndexProvider = StateProvider<int>((ref) => 0);

// Provider for connection status
final connectionStatusProvider = StateProvider<bool>((ref) => false);

// Provider for connected device information
final connectedDeviceProvider = StateProvider<String?>((ref) => null);

class MotionControlServer {
  WebSocket? _socket;
  HttpServer? _server;
  bool _isServerRunning = false;
  final WidgetRef _ref;
  final Function(String)? onLog;
  final Function(int)? onIndexChanged;
  final Function()? onSelectCurrentOption;

  MotionControlServer(this._ref,
      {this.onLog, this.onIndexChanged, this.onSelectCurrentOption});

  // Get the local IP address to display for connection
  Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Filter out localhost
      final filteredInterfaces = interfaces.where(
        (interface) => interface.addresses.any(
          (address) => !address.address.startsWith('127.'),
        ),
      );

      if (filteredInterfaces.isNotEmpty) {
        // Prefer WiFi or Ethernet interfaces
        for (var interface in filteredInterfaces) {
          if (interface.name.toLowerCase().contains('wi') ||
              interface.name.toLowerCase().contains('eth')) {
            return interface.addresses.first.address;
          }
        }
        // Fallback to first non-localhost
        return filteredInterfaces.first.addresses.first.address;
      }
      return 'Unknown';
    } catch (e) {
      logMessage('Error getting IP: $e');
      return 'Error: $e';
    }
  }

  void logMessage(String message) {
    if (onLog != null) {
      onLog!(message);
    }
    print('[Motion Control Server] $message');
  }

  // Start the WebSocket server
  Future<bool> startServer() async {
    if (_isServerRunning) {
      logMessage('Server is already running');
      return true;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _isServerRunning = true;
      _ref.read(connectionStatusProvider.notifier).state = true;

      String ip = await getLocalIpAddress();
      logMessage('Server started on $ip:8080');

      _server!.listen((HttpRequest request) async {
        if (request.uri.path == '/') {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            handleWebSocketConnection(request);
          } else {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write('Doctor Desktop WebSocket Server Running')
              ..close();
          }
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });

      return true;
    } catch (e) {
      logMessage('Error starting server: $e');
      _isServerRunning = false;
      _ref.read(connectionStatusProvider.notifier).state = false;
      return false;
    }
  }

  // Handle incoming WebSocket connections
  void handleWebSocketConnection(HttpRequest request) async {
    try {
      _socket = await WebSocketTransformer.upgrade(request);
      logMessage('Device connected');

      // Send connection confirmation
      _socket!.add(jsonEncode({
        'type': 'connection_status',
        'connected': true,
        'current_selection': _ref.read(selectedMenuIndexProvider),
      }));

      _socket!.listen(
        (message) {
          handleMessage(message);
        },
        onDone: () {
          logMessage('Device disconnected');
          _ref.read(connectedDeviceProvider.notifier).state = null;
        },
        onError: (error) {
          logMessage('Error: $error');
          _ref.read(connectedDeviceProvider.notifier).state = null;
        },
      );
    } catch (e) {
      logMessage('WebSocket error: $e');
    }
  }

  // Handle incoming WebSocket messages
  void handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      if (data['type'] == 'connect') {
        _ref.read(connectedDeviceProvider.notifier).state =
            data['device'] ?? 'Unknown device';
        logMessage('Device identified as: ${data['device']}');
      } else if (data['type'] == 'motion_data') {
        // Process motion data
        handleMotionData(data);
      } else if (data['type'] == 'action') {
        // Process action commands
        handleAction(data['action']);
      }
    } catch (e) {
      logMessage('Error parsing message: $e');
    }
  }

  // Process motion data
  void handleMotionData(Map<String, dynamic> data) {
    double x = data['x'] ?? 0.0;

    // Detect left/right tilting for navigation
    if (x < -2.0) {
      // Tilted left
      _navigateToNext();
    } else if (x > 2.0) {
      // Tilted right
      _navigateToPrevious();
    }

    // Could add forward tilt detection for selection using z value
    double z = data['z'] ?? 0.0;
    if (z < -6.0) {
      // Tilted forward significantly
      _selectCurrentOption();
    }
  }

  // Process action commands
  void handleAction(String action) {
    switch (action) {
      case 'next':
        _navigateToNext();
        break;
      case 'previous':
        _navigateToPrevious();
        break;
      case 'select':
        _selectCurrentOption();
        break;
    }
  }

  // Navigation methods
  void _navigateToNext() {
    int currentIndex = _ref.read(selectedMenuIndexProvider);
    // You will need to know the total number of menu items
    // This should be passed in or derived from your UI
    int maxIndex = 4; // Adjust based on your actual menu size

    int newIndex = (currentIndex + 1) % (maxIndex + 1);
    _ref.read(selectedMenuIndexProvider.notifier).state = newIndex;

    if (onIndexChanged != null) {
      onIndexChanged!(newIndex);
    }

    _sendSelectionUpdate(newIndex);
    logMessage('Navigated to option: $newIndex');
  }

  void _navigateToPrevious() {
    int currentIndex = _ref.read(selectedMenuIndexProvider);
    // You will need to know the total number of menu items
    int maxIndex = 4; // Adjust based on your actual menu size

    int newIndex = (currentIndex - 1 < 0) ? maxIndex : currentIndex - 1;
    _ref.read(selectedMenuIndexProvider.notifier).state = newIndex;

    if (onIndexChanged != null) {
      onIndexChanged!(newIndex);
    }

    _sendSelectionUpdate(newIndex);
    logMessage('Navigated to option: $newIndex');
  }

  void _selectCurrentOption() {
    if (onSelectCurrentOption != null) {
      onSelectCurrentOption!();
    }
    logMessage('Selected current option');
  }

  // Send updates back to the mobile client
  void _sendSelectionUpdate(int index) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(
          jsonEncode({'type': 'selection_update', 'selected_index': index}));
    }
  }

  // Stop the server
  Future<void> stopServer() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    if (_server != null) {
      await _server!.close();
      _server = null;
    }

    _isServerRunning = false;
    _ref.read(connectionStatusProvider.notifier).state = false;
    _ref.read(connectedDeviceProvider.notifier).state = null;
    logMessage('Server stopped');
  }

  bool get isRunning => _isServerRunning;
}
