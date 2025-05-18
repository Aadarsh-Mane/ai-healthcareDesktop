import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctordesktop/services/snackbar_service.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();

  factory NetworkService() => _instance;

  NetworkService._internal();

  // Singleton instance
  static NetworkService get instance => _instance;

  // Check for internet connectivity with a timeout
  Future<bool> isConnected() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false; // No connectivity at all
      }

      // Use a timeout to prevent long waiting times
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print("Connectivity check error: $e");
      return false;
    }
  }

  // Check connectivity and show message
  Future<bool> checkConnectivity() async {
    bool isConnected = await this.isConnected();

    if (!isConnected) {
      SnackbarService.showErrorSnackbar(
          'No internet connection. Please check your network settings and try again.');
    }

    return isConnected;
  }
}
