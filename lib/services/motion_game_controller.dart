// lib/services/motion_control_game.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctordesktop/services/motion_control.dart';

// Game-specific motion data provider
final gameMotionDataProvider = StateProvider<Map<String, double>>((ref) => {
      'x': 0.0,
      'y': 0.0,
      'z': 0.0,
    });

// Extend the original MotionControlServer for game-specific functionality
class GameMotionControlServer extends MotionControlServer {
  final Function(double, double, double)? onMotionUpdate;
  final WidgetRef ref; // Store ref for our use

  GameMotionControlServer(
    this.ref, {
    Function(String)? onLog,
    Function(int)? onIndexChanged,
    Function()? onSelectCurrentOption,
    this.onMotionUpdate,
  }) : super(ref,
            onLog: onLog,
            onIndexChanged: onIndexChanged,
            onSelectCurrentOption: onSelectCurrentOption);

  @override
  void handleMotionData(Map<String, dynamic> data) {
    // Store the original motion data handling
    super.handleMotionData(data);

    // Additional game-specific motion data handling
    final double x = data['x'] ?? 0.0;
    final double y = data['y'] ?? 0.0;
    final double z = data['z'] ?? 0.0;

    // Update the game motion data provider
    ref.read(gameMotionDataProvider.notifier).state = {'x': x, 'y': y, 'z': z};

    // Call the callback if provided
    if (onMotionUpdate != null) {
      onMotionUpdate!(x, y, z);
    }
  }
}

// Function to modify our BirdGameScreen to use the enhanced motion control
void setupGameMotionControl(
    WidgetRef ref, Function(double, double, double) onMotionUpdate) {
  // Make sure to modify the BirdGameScreen to use this function
  final motionData = ref.watch(gameMotionDataProvider);

  // This would be called in the build method to automatically update
  onMotionUpdate(
      motionData['x'] ?? 0.0, motionData['y'] ?? 0.0, motionData['z'] ?? 0.0);
}
