import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:doctordesktop/constants/ToastMessage.dart';

/// A simple singleton class to manage network connectivity
/// throughout the application
class NetworkManager {
  // Singleton instance
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  // Connection state
  bool _isConnected = true;
  StreamSubscription<ConnectivityResult>? _subscription;
  final _connectionChangeController = StreamController<bool>.broadcast();

  // Stream to listen to connection changes
  Stream<bool> get connectionChange => _connectionChangeController.stream;

  // Current connection status
  bool get isConnected => _isConnected;

  // Initialize the manager
  void initialize() {
    _checkConnection();
    _subscription = Connectivity().onConnectivityChanged.listen(
            _updateConnectionStatus as void Function(
                List<ConnectivityResult> event)?)
        as StreamSubscription<ConnectivityResult>?;
  }

  // Check current connection status
  Future<bool> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult as ConnectivityResult);
    return _isConnected;
  }

  // Update the connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    _connectionChangeController.add(_isConnected);
  }

  // Manual check for connection status
  Future<bool> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult as ConnectivityResult);
    return _isConnected;
  }

  // Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _connectionChangeController.close();
  }
}

/// A simple widget that displays a banner when there's no internet connection
class OfflineBanner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final TextStyle textStyle;
  final double height;
  final Widget? icon;

  const OfflineBanner({
    Key? key,
    this.message = 'No Internet Connection',
    this.backgroundColor = const Color(0xFFE53935),
    this.height = 50,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: NetworkManager().connectionChange,
      initialData: NetworkManager().isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          height: height,
          color: backgroundColor,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon ?? const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 10),
              Text(message, style: textStyle),
            ],
          ),
        );
      },
    );
  }
}

/// A widget that wraps your entire app or specific screen to provide
/// network awareness with minimal code
class NetworkAwarenessWrapper extends StatefulWidget {
  final Widget child;
  final Widget? offlineScreen;
  final bool showOfflineBanner;
  final String offlineBannerMessage;
  final bool blockInteractionWhenOffline;

  const NetworkAwarenessWrapper({
    Key? key,
    required this.child,
    this.offlineScreen,
    this.showOfflineBanner = true,
    this.offlineBannerMessage = 'No Internet Connection',
    this.blockInteractionWhenOffline = false,
  }) : super(key: key);

  @override
  State<NetworkAwarenessWrapper> createState() =>
      _NetworkAwarenessWrapperState();
}

class _NetworkAwarenessWrapperState extends State<NetworkAwarenessWrapper> {
  late final StreamSubscription<bool> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = NetworkManager().isConnected;
    _subscription = NetworkManager().connectionChange.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we have an offline screen and are not connected, show it
    if (widget.offlineScreen != null && !_isConnected) {
      return Column(
        children: [
          if (widget.showOfflineBanner)
            OfflineBanner(message: widget.offlineBannerMessage),
          Expanded(child: widget.offlineScreen!),
        ],
      );
    }

    // Otherwise, show the normal child with an optional banner
    return Column(
      children: [
        if (widget.showOfflineBanner && !_isConnected)
          OfflineBanner(message: widget.offlineBannerMessage),
        Expanded(
          child: widget.blockInteractionWhenOffline && !_isConnected
              ? AbsorbPointer(
                  absorbing: true,
                  child: Opacity(
                    opacity: 0.7,
                    child: widget.child,
                  ),
                )
              : widget.child,
        ),
      ],
    );
  }
}

/// Extension methods for BuildContext to make network-aware operations easier
extension NetworkAwareContext on BuildContext {
  /// Check if the device is currently connected to the internet
  bool get isConnected => NetworkManager().isConnected;

  /// Perform a network-dependent action
  /// Returns true if the action was performed, false if it was skipped due to no connectivity
  Future<bool> performNetworkAction(
    Future<void> Function() action, {
    String offlineMessage = 'This action requires an internet connection',
  }) async {
    if (NetworkManager().isConnected) {
      try {
        await action();
        return true;
      } catch (e) {
        ToastMessage().showToast(
          this,
          'Error: $e',
          '',
          ToastificationType.error,
        );
        return false;
      }
    } else {
      ToastMessage().showToast(
        this,
        offlineMessage,
        '',
        ToastificationType.warning,
      );
      return false;
    }
  }
}

/// Extension methods for State to make network-aware operations easier in StatefulWidgets
extension NetworkAwareState<T extends StatefulWidget> on State<T> {
  /// Check if the device is currently connected to the internet
  bool get isConnected => NetworkManager().isConnected;

  /// Perform a network-dependent action
  /// Returns true if the action was performed, false if it was skipped due to no connectivity
  Future<bool> performNetworkAction(
    Future<void> Function() action, {
    String offlineMessage = 'This action requires an internet connection',
  }) async {
    if (NetworkManager().isConnected) {
      try {
        await action();
        return true;
      } catch (e) {
        ToastMessage().showToast(
          context,
          'Error: $e',
          '',
          ToastificationType.error,
        );
        return false;
      }
    } else {
      ToastMessage().showToast(
        context,
        offlineMessage,
        '',
        ToastificationType.warning,
      );
      return false;
    }
  }
}

/// A network-aware button that handles offline state
class NetworkAwareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String offlineMessage;
  final BuildContext? toastContext;

  const NetworkAwareButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.offlineMessage = 'This action requires an internet connection',
    this.toastContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: NetworkManager().connectionChange,
      initialData: NetworkManager().isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        final ctx = toastContext ?? context;

        return AbsorbPointer(
          absorbing: !isConnected,
          child: GestureDetector(
            onTap: isConnected
                ? onPressed
                : () {
                    ToastMessage().showToast(
                      ctx,
                      offlineMessage,
                      '',
                      ToastificationType.warning,
                    );
                  },
            child: Opacity(
              opacity: isConnected ? 1.0 : 0.5,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
