// import 'package:camera_platform_interface/camera_platform_interface.dart';
// import 'package:flutter/material.dart';

// class CameraCaptureScreen extends StatefulWidget {
//   const CameraCaptureScreen({super.key});

//   @override
//   State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
// }

// class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
//   List<CameraDescription> _cameras = [];
//   int _cameraIndex = 0;
//   int _cameraId = -1;
//   bool _initialized = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsFlutterBinding.ensureInitialized();
//     _fetchCameras();
//   }

//   Future<void> _fetchCameras() async {
//     try {
//       final cameras = await CameraPlatform.instance.availableCameras();
//       print(cameras);
//       if (cameras.isNotEmpty) {
//         setState(() {
//           _cameras = cameras;
//         });
//       } else {
//         _showInSnackBar('No cameras found');
//       }
//     } catch (e) {
//       print(e);
//     }
//   }

//   Future<void> _initializeCamera() async {
//     if (_cameras.isEmpty) return;

//     final camera = _cameras[_cameraIndex];
//     try {
//       final cameraId = await CameraPlatform.instance.createCamera(
//         camera,
//         ResolutionPreset.high,
//       );

//       await CameraPlatform.instance.initializeCamera(cameraId);

//       setState(() {
//         _cameraId = cameraId;
//         _initialized = true;
//       });
//     } catch (e) {
//       _showInSnackBar('Error initializing camera: $e');
//     }
//   }

//   Future<void> _captureImage() async {
//     if (!_initialized || _cameraId < 0) return;

//     try {
//       final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
//       _showInSnackBar('Image saved at: ${file.path}');
//     } catch (e) {
//       _showInSnackBar('Error capturing image: $e');
//     }
//   }

//   void _showInSnackBar(String message) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   void dispose() {
//     if (_cameraId >= 0) {
//       CameraPlatform.instance.dispose(_cameraId);
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Camera Capture')),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (_cameras.isNotEmpty)
//             ElevatedButton(
//               onPressed: _initialized ? _captureImage : _initializeCamera,
//               child: Text(_initialized ? 'Capture Image' : 'Initialize Camera'),
//             ),
//           if (_initialized)
//             Container(
//               height: 300,
//               width: double.infinity,
//               child: CameraPlatform.instance.buildPreview(_cameraId),
//             ),
//         ],
//       ),
//     );
//   }
// }
