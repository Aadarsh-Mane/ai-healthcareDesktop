import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

class PatientModel {
  // In a real app, you would have multiple angles of the patient image
  // Here we'll simulate rotation with a single image and transformation
  static const String assetPath = 'assets/images/pe.png';

  // For true 360-degree view, you would use multiple images at different angles
  static List<String> get multiAngleAssets => List.generate(
        36, // 36 angles (every 10 degrees)
        (index) => 'assets/patient_${index * 10}.png',
      );
}

class PatientDetailsScreen3 extends StatefulWidget {
  const PatientDetailsScreen3({Key? key}) : super(key: key);

  @override
  State<PatientDetailsScreen3> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen3>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  ui.Image? _patientImage;
  bool _isLoading = true;
  bool _isAutoRotating = true;
  double _manualRotation = 0.0;
  double _rotationVelocity = 0.0;
  Timer? _decelerationTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadPatientImage();
  }

  Future<void> _loadPatientImage() async {
    try {
      final ByteData data = await rootBundle.load(PatientModel.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      setState(() {
        _patientImage = fi.image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading patient image: $e');
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _decelerationTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoRotation() {
    setState(() {
      _isAutoRotating = !_isAutoRotating;
      if (_isAutoRotating) {
        _rotationController.repeat();
        _decelerationTimer?.cancel();
      } else {
        _rotationController.stop();
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isAutoRotating) return;
    _decelerationTimer?.cancel();
    _rotationVelocity = 0.0;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAutoRotating) return;
    setState(() {
      _manualRotation += details.delta.dx * 0.01;
      _rotationVelocity = details.delta.dx * 0.01;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAutoRotating) return;

    // Create inertia effect
    _decelerationTimer?.cancel();
    _decelerationTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_rotationVelocity.abs() < 0.0001) {
        timer.cancel();
        return;
      }

      setState(() {
        _manualRotation += _rotationVelocity;
        _rotationVelocity *= 0.95; // Slow down
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('Patient Model'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Hospital Patient',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Standard Hospital Gown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side icons
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildIconBox(
                                  icon: Icons.medical_services,
                                  color: Colors.red,
                                  label: 'Medical',
                                ),
                                _buildIconBox(
                                  icon: Icons.healing,
                                  color: Colors.blue,
                                  label: 'Treatment',
                                ),
                                _buildIconBox(
                                  icon: Icons.monitor_heart,
                                  color: Colors.green,
                                  label: 'Vitals',
                                ),
                                _buildIconBox(
                                  icon: Icons.person,
                                  color: Colors.purple,
                                  label: 'Patient',
                                ),
                              ],
                            ),
                          ),

                          // Patient model with rotation
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 0.7,
                              child: GestureDetector(
                                onTap: _toggleAutoRotation,
                                onPanStart: _handlePanStart,
                                onPanUpdate: _handlePanUpdate,
                                onPanEnd: _handlePanEnd,
                                child: Container(
                                  margin: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (_isLoading)
                                        const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      else
                                        Center(
                                          child: AnimatedBuilder(
                                            animation: _rotationController,
                                            builder: (context, child) {
                                              return Transform.rotate(
                                                angle: _isAutoRotating
                                                    ? _rotationController
                                                            .value *
                                                        2 *
                                                        math.pi
                                                    : _manualRotation,
                                                child: child,
                                              );
                                            },
                                            child: _patientImage != null
                                                ? RawImage(
                                                    image: _patientImage,
                                                    fit: BoxFit.contain,
                                                  )
                                                : const Icon(
                                                    Icons.broken_image,
                                                    size: 64,
                                                    color: Colors.grey,
                                                  ),
                                          ),
                                        ),

                                      // Controls overlay
                                      Positioned(
                                        bottom: 8,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.7),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              _isAutoRotating
                                                  ? 'Tap to control manually'
                                                  : 'Drag to rotate • Tap for auto-rotate',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.rotate_left,
                  label: 'Rotate Left',
                  onPressed: () {
                    if (!_isAutoRotating) {
                      setState(() {
                        _manualRotation -= 0.2;
                      });
                    }
                  },
                ),
                _buildControlButton(
                  icon: _isAutoRotating ? Icons.pause : Icons.play_arrow,
                  label: _isAutoRotating ? 'Pause' : 'Auto Rotate',
                  onPressed: _toggleAutoRotation,
                ),
                _buildControlButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate Right',
                  onPressed: () {
                    if (!_isAutoRotating) {
                      setState(() {
                        _manualRotation += 0.2;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Advanced implementation for true 360-degree viewing with multiple images
class MultiAnglePatientViewer extends StatefulWidget {
  const MultiAnglePatientViewer({Key? key}) : super(key: key);

  @override
  State<MultiAnglePatientViewer> createState() =>
      _MultiAnglePatientViewerState();
}

class _MultiAnglePatientViewerState extends State<MultiAnglePatientViewer> {
  int _currentIndex = 0;
  bool _isAutoRotating = true;
  Timer? _rotationTimer;
  double _dragStartX = 0.0;
  final int _totalAngles =
      36; // 36 frames for 360-degree rotation (every 10 degrees)

  @override
  void initState() {
    super.initState();
    _startAutoRotation();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _totalAngles;
      });
    });
  }

  void _stopAutoRotation() {
    _rotationTimer?.cancel();
  }

  void _toggleAutoRotation() {
    setState(() {
      _isAutoRotating = !_isAutoRotating;
      if (_isAutoRotating) {
        _startAutoRotation();
      } else {
        _stopAutoRotation();
      }
    });
  }

  void _handleDragStart(DragStartDetails details) {
    if (_isAutoRotating) {
      _toggleAutoRotation();
    }
    _dragStartX = details.globalPosition.dx;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAutoRotating) return;

    // Calculate how much to rotate based on drag distance
    final double dragDelta = details.globalPosition.dx - _dragStartX;
    if (dragDelta.abs() > 5) {
      // Threshold to avoid jitter
      final int frameChange =
          (dragDelta / 10).round(); // 10 pixels per frame change
      if (frameChange != 0) {
        setState(() {
          // Drag right (positive) -> Go to previous frame (counter-clockwise)
          // Drag left (negative) -> Go to next frame (clockwise)
          _currentIndex = (_currentIndex - frameChange) % _totalAngles;
          if (_currentIndex < 0) _currentIndex += _totalAngles;
          _dragStartX = details.globalPosition.dx;
        });
      }
    }
  }

  String _getImageAssetForAngle(int index) {
    // In a real app, you would have actual image assets for each angle
    // For this example, we pretend they exist
    return 'assets/patient_${index * 10}.png';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleAutoRotation,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Current frame image
            Center(
              child: Image.asset(
                _getImageAssetForAngle(_currentIndex),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback for missing assets in this example
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Patient Model View\n(Simulated 360° Rotation)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Control indicators
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isAutoRotating
                        ? 'Tap to control manually'
                        : 'Drag to rotate • Tap for auto-rotate',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Rotation indicator
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAutoRotating ? Icons.sync : Icons.touch_app,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
