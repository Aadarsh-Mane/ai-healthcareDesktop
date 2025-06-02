// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:pdfx/pdfx.dart';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:path/path.dart' as path;

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter PDF Viewer with pdfx',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: PdfScreen(),
//     );
//   }
// }

// class PdfScreen extends StatefulWidget {
//   @override
//   State<PdfScreen> createState() => _PdfScreenState();
// }

// class _PdfScreenState extends State<PdfScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('PDF Viewer with pdfx')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => PdfxViewer(
//                       pdfUrl:
//                           "https://res.cloudinary.com/dnznafp2a/image/upload/v1733926105/lab_reports/dyqwyz4njpexwnybbjni.pdf",
//                       title: "Cloudinary PDF",
//                     ),
//                   ),
//                 );
//               },
//               child: Text('Open Cloudinary PDF'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => PdfxViewer(
//                       pdfUrl:
//                           "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
//                       title: "Test PDF",
//                     ),
//                   ),
//                 );
//               },
//               child: Text('Open Test PDF'),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => PdfxViewer(
//                       pdfUrl:
//                           "https://drive.google.com/file/d/1RujrLpb7zt6LgUVC9mPMcYjYSZc637gd/view",
//                       title: "Google Drive PDF",
//                     ),
//                   ),
//                 );
//               },
//               child: Text('Open Google Drive PDF'),
//             ),
//             SizedBox(height: 40),
//             Text(
//               'Real PDF Rendering with pdfx',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class PdfxViewer extends StatefulWidget {
//   final String pdfUrl;
//   final String title;

//   const PdfxViewer({Key? key, required this.pdfUrl, this.title = "PDF Viewer"})
//       : super(key: key);

//   @override
//   State<PdfxViewer> createState() => _PdfxViewerState();
// }

// class _PdfxViewerState extends State<PdfxViewer> {
//   PdfController? pdfController;
//   bool isLoading = true;
//   String? errorMessage;
//   int currentPage = 1;
//   int totalPages = 0;
//   Uint8List? pdfBytes;
//   double pdfZoom = 1.0;
//   final Map<String, Uint8List> _pdfCache = {};

//   @override
//   void initState() {
//     super.initState();
//     loadPDF();
//   }

//   @override
//   void dispose() {
//     pdfController?.dispose();
//     super.dispose();
//   }

//   Future<void> loadPDF() async {
//     try {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });

//       print('Loading PDF from: ${widget.pdfUrl}');

//       String urlToLoad = widget.pdfUrl;

//       // Handle Google Drive URLs
//       if (widget.pdfUrl.contains('drive.google.com')) {
//         urlToLoad = convertGoogleDriveUrl(widget.pdfUrl);
//         print('Converted Google Drive URL: $urlToLoad');
//       }

//       // Check memory cache first
//       if (_pdfCache.containsKey(urlToLoad)) {
//         print('Using cached PDF from memory');
//         await _initializePdfController(_pdfCache[urlToLoad]!);
//         return;
//       }

//       final client = http.Client();
//       final response = await client.get(
//         Uri.parse(urlToLoad),
//         headers: {
//           'User-Agent': Platform.isWindows
//               ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
//               : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
//           'Accept': 'application/pdf,application/octet-stream,*/*',
//         },
//       );

//       print('Response status: ${response.statusCode}');
//       print('Content length: ${response.contentLength}');

//       if (response.statusCode == 200) {
//         final bytes = response.bodyBytes;
//         _pdfCache[urlToLoad] = bytes; // Cache in memory
//         await _initializePdfController(bytes);
//       } else {
//         throw Exception(
//             'Failed to download PDF. Status: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error loading PDF: $e');
//       setState(() {
//         isLoading = false;
//         errorMessage = 'Error loading PDF: ${e.toString()}';
//       });
//     }
//   }

//   bool _isValidPdfHeader(Uint8List bytes) {
//     return bytes.length > 4 &&
//         bytes[0] == 0x25 && // %
//         bytes[1] == 0x50 && // P
//         bytes[2] == 0x44 && // D
//         bytes[3] == 0x46; // F
//   }

//   Future<void> _initializePdfController(Uint8List bytes) async {
//     try {
//       pdfBytes = bytes;

//       // Verify it's a PDF
//       if (!_isValidPdfHeader(bytes)) {
//         print('Warning: File header does not match PDF signature');
//       }

//       final document = PdfDocument.openData(bytes);
//       // final pageCount = await document.pagesCount;
//       // print('PDF loaded successfully. Pages: $pageCount');

//       pdfController = PdfController(
//         document: document,
//         initialPage: 1,
//       );

//       setState(() {
//         // totalPages = pageCount;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('PDF initialization error: $e');
//       setState(() {
//         isLoading = false;
//         errorMessage = 'Failed to initialize PDF: ${e.toString()}';
//       });
//     }
//   }

//   String convertGoogleDriveUrl(String url) {
//     final RegExp regex = RegExp(r'\/file\/d\/([a-zA-Z0-9_-]+)');
//     final match = regex.firstMatch(url);

//     if (match != null && match.groupCount >= 1) {
//       final fileId = match.group(1);
//       return 'https://drive.google.com/uc?export=download&id=$fileId';
//     }

//     // Handle shareable links format
//     if (url.contains('sharing')) {
//       final uri = Uri.parse(url);
//       final fileId = uri.queryParameters['id'];
//       if (fileId != null) {
//         return 'https://drive.google.com/uc?export=download&id=$fileId';
//       }
//     }

//     return url;
//   }

//   void goToPage(int page) {
//     if (pdfController != null && page >= 1 && page <= totalPages) {
//       pdfController!.animateToPage(
//         page,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }

//   void nextPage() {
//     if (currentPage < totalPages) {
//       goToPage(currentPage + 1);
//     }
//   }

//   void previousPage() {
//     if (currentPage > 1) {
//       goToPage(currentPage - 1);
//     }
//   }

//   void zoomIn() {
//     setState(() {
//       pdfZoom += 0.2;
//       // pdfController?.setZoom(pdfZoom);
//     });
//   }

//   void zoomOut() {
//     setState(() {
//       if (pdfZoom > 0.4) {
//         pdfZoom -= 0.2;
//         // pdfController?.setZoom(pdfZoom);
//       }
//     });
//   }

//   void resetZoom() {
//     setState(() {
//       pdfZoom = 1.0;
//       // pdfController?.resetZoom();
//     });
//   }

//   Future<void> savePDF() async {
//     if (pdfBytes == null) return;

//     try {
//       // Platform-agnostic save path
//       String savePath = '${Directory.current.path}/downloads';
//       final saveDir = Directory(savePath);

//       if (!await saveDir.exists()) {
//         await saveDir.create(recursive: true);
//       }

//       final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final file = File('${saveDir.path}/$fileName');

//       await file.writeAsBytes(pdfBytes!);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('PDF saved to: ${file.path}'),
//           duration: Duration(seconds: 3),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Save failed: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//         backgroundColor: Colors.blue[700],
//         foregroundColor: Colors.white,
//         actions: [
//           if (pdfController != null) ...[
//             IconButton(
//               icon: Icon(Icons.save),
//               onPressed: savePDF,
//               tooltip: 'Save PDF',
//             ),
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: loadPDF,
//               tooltip: 'Reload PDF',
//             ),
//           ],
//         ],
//       ),
//       body: isLoading
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Loading PDF...',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                   SizedBox(height: 8),
//                   LinearProgressIndicator(
//                     backgroundColor: Colors.grey[300],
//                     valueColor: AlwaysStoppedAnimation(Colors.blue),
//                     minHeight: 6,
//                   ),
//                   SizedBox(height: 8),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 32),
//                     child: Text(
//                       widget.pdfUrl,
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                       textAlign: TextAlign.center,
//                       maxLines: 3,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : errorMessage != null
//               ? Center(
//                   child: Padding(
//                     padding: EdgeInsets.all(24),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.error_outline, size: 64, color: Colors.red),
//                         SizedBox(height: 16),
//                         Text(
//                           'Failed to Load PDF',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red[700],
//                           ),
//                         ),
//                         SizedBox(height: 12),
//                         Text(
//                           errorMessage!,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                         SizedBox(height: 24),
//                         ElevatedButton.icon(
//                           onPressed: loadPDF,
//                           icon: Icon(Icons.refresh),
//                           label: Text('Retry'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         ElevatedButton.icon(
//                           onPressed: () {
//                             launchUrl(Uri.parse(widget.pdfUrl));
//                           },
//                           icon: Icon(Icons.open_in_browser),
//                           label: Text('Open in Browser'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               : Column(
//                   children: [
//                     // PDF Toolbar
//                     Container(
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         border: Border(
//                             bottom: BorderSide(color: Colors.grey[300]!)),
//                       ),
//                       child: Row(
//                         children: [
//                           // Page Navigation
//                           IconButton(
//                             onPressed: currentPage > 1 ? previousPage : null,
//                             icon: Icon(Icons.chevron_left),
//                             tooltip: 'Previous Page',
//                           ),
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(6),
//                               border: Border.all(color: Colors.grey[300]!),
//                             ),
//                             child: Text(
//                               'Page $currentPage of $totalPages',
//                               style: TextStyle(fontWeight: FontWeight.w500),
//                             ),
//                           ),
//                           IconButton(
//                             onPressed:
//                                 currentPage < totalPages ? nextPage : null,
//                             icon: Icon(Icons.chevron_right),
//                             tooltip: 'Next Page',
//                           ),

//                           Spacer(),

//                           // Zoom Controls
//                           IconButton(
//                             onPressed: zoomOut,
//                             icon: Icon(Icons.zoom_out),
//                             tooltip: 'Zoom Out',
//                           ),
//                           IconButton(
//                             onPressed: zoomIn,
//                             icon: Icon(Icons.zoom_in),
//                             tooltip: 'Zoom In',
//                           ),
//                           IconButton(
//                             onPressed: resetZoom,
//                             icon: Icon(Icons.center_focus_strong),
//                             tooltip: 'Reset Zoom',
//                           ),
//                         ],
//                       ),
//                     ),

//                     // PDF Viewer
//                     Expanded(
//                       child: Container(
//                         color: Colors.grey[200],
//                         child: PdfView(
//                           controller: pdfController!,
//                           onPageChanged: (page) {
//                             setState(() {
//                               currentPage = page;
//                             });
//                           },
//                           scrollDirection: Axis.vertical,
//                           physics: BouncingScrollPhysics(),
//                           builders: PdfViewBuilders<DefaultBuilderOptions>(
//                             options: const DefaultBuilderOptions(),
//                             documentLoaderBuilder: (_) => Center(
//                               child: CircularProgressIndicator(),
//                             ),
//                             pageLoaderBuilder: (_) => Center(
//                               child: CircularProgressIndicator(),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//       // Page Navigation Drawer
//       endDrawer: pdfController != null
//           ? Drawer(
//               child: Column(
//                 children: [
//                   DrawerHeader(
//                     decoration: BoxDecoration(color: Colors.blue[700]),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'PDF Navigation',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Total Pages: $totalPages',
//                           style: TextStyle(color: Colors.white70, fontSize: 14),
//                         ),
//                         if (pdfBytes != null)
//                           Text(
//                             'Size: ${(pdfBytes!.length / 1024).toStringAsFixed(1)} KB',
//                             style:
//                                 TextStyle(color: Colors.white70, fontSize: 14),
//                           ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Zoom: ${(pdfZoom * 100).toStringAsFixed(0)}%',
//                           style: TextStyle(color: Colors.white70, fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: totalPages,
//                       itemBuilder: (context, index) {
//                         final pageNum = index + 1;
//                         return ListTile(
//                           leading: Icon(
//                             Icons.picture_as_pdf,
//                             color: pageNum == currentPage
//                                 ? Colors.blue
//                                 : Colors.grey,
//                           ),
//                           title: Text('Page $pageNum'),
//                           selected: pageNum == currentPage,
//                           onTap: () {
//                             goToPage(pageNum);
//                             Navigator.pop(context);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       children: [
//                         ElevatedButton.icon(
//                           onPressed: savePDF,
//                           icon: Icon(Icons.save),
//                           label: Text('Save PDF'),
//                           style: ElevatedButton.styleFrom(
//                             minimumSize: Size(double.infinity, 40),
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         OutlinedButton.icon(
//                           onPressed: loadPDF,
//                           icon: Icon(Icons.refresh),
//                           label: Text('Reload'),
//                           style: OutlinedButton.styleFrom(
//                             minimumSize: Size(double.infinity, 40),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : null,

//       // Floating Action Button for quick navigation
//       floatingActionButton: pdfController != null
//           ? FloatingActionButton(
//               onPressed: () {
//                 Scaffold.of(context).openEndDrawer();
//               },
//               child: Icon(Icons.list),
//               tooltip: 'Page List',
//             )
//           : null,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter PDF Viewer with pdfx',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PdfScreen(),
    );
  }
}

class PdfScreen extends StatefulWidget {
  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer with pdfx')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfxViewer(
                      pdfUrl:
                          "https://res.cloudinary.com/dnznafp2a/image/upload/v1733926105/lab_reports/dyqwyz4njpexwnybbjni.pdf",
                      title: "Cloudinary PDF",
                    ),
                  ),
                );
              },
              child: Text('Open Cloudinary PDF'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfxViewer(
                      pdfUrl:
                          "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                      title: "Test PDF",
                    ),
                  ),
                );
              },
              child: Text('Open Test PDF'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfxViewer(
                      pdfUrl:
                          "https://drive.google.com/file/d/1RujrLpb7zt6LgUVC9mPMcYjYSZc637gd/view",
                      title: "Google Drive PDF",
                    ),
                  ),
                );
              },
              child: Text('Open Google Drive PDF'),
            ),
            SizedBox(height: 40),
            Text(
              'Real PDF Rendering with pdfx',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfxViewer extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfxViewer({Key? key, required this.pdfUrl, this.title = "PDF Viewer"})
      : super(key: key);

  @override
  State<PdfxViewer> createState() => _PdfxViewerState();
}

class _PdfxViewerState extends State<PdfxViewer> {
  pdfx.PdfController? pdfController;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 0;
  Uint8List? pdfBytes;
  double pdfZoom = 1.0;
  final Map<String, Uint8List> _pdfCache = {};

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  Future<void> loadPDF() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('Loading PDF from: ${widget.pdfUrl}');

      String urlToLoad = widget.pdfUrl;

      // Handle Google Drive URLs
      if (widget.pdfUrl.contains('drive.google.com')) {
        urlToLoad = convertGoogleDriveUrl(widget.pdfUrl);
        print('Converted Google Drive URL: $urlToLoad');
      }

      // Check memory cache first
      if (_pdfCache.containsKey(urlToLoad)) {
        print('Using cached PDF from memory');
        await _initializePdfController(_pdfCache[urlToLoad]!);
        return;
      }

      final client = http.Client();
      final response = await client.get(
        Uri.parse(urlToLoad),
        headers: {
          'User-Agent': Platform.isWindows
              ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
              : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/pdf,application/octet-stream,*/*',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Content length: ${response.contentLength}');

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _pdfCache[urlToLoad] = bytes; // Cache in memory
        await _initializePdfController(bytes);
      } else {
        throw Exception(
            'Failed to download PDF. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading PDF: ${e.toString()}';
      });
    }
  }

  bool _isValidPdfHeader(Uint8List bytes) {
    return bytes.length > 4 &&
        bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46; // F
  }

  Future<void> _initializePdfController(Uint8List bytes) async {
    try {
      pdfBytes = bytes;

      // Verify it's a PDF
      if (!_isValidPdfHeader(bytes)) {
        print('Warning: File header does not match PDF signature');
      }

      final document = pdfx.PdfDocument.openData(bytes);
      // final pageCount = await document.pagesCount; // Fixed: Get page count
      // print('PDF loaded successfully. Pages: $pageCount');

      pdfController = pdfx.PdfController(
        document: document,
        initialPage: 1,
      );

      setState(() {
        // totalPages = pageCount; // Fixed: Set total pages
        isLoading = false;
      });
    } catch (e) {
      print('PDF initialization error: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to initialize PDF: ${e.toString()}';
      });
    }
  }

  String convertGoogleDriveUrl(String url) {
    final RegExp regex = RegExp(r'\/file\/d\/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);

    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    // Handle shareable links format
    if (url.contains('sharing')) {
      final uri = Uri.parse(url);
      final fileId = uri.queryParameters['id'];
      if (fileId != null) {
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    return url;
  }

  void goToPage(int page) {
    if (pdfController != null && page >= 1 && page <= totalPages) {
      pdfController!.animateToPage(
        page,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void nextPage() {
    if (currentPage < totalPages) {
      goToPage(currentPage + 1);
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      goToPage(currentPage - 1);
    }
  }

  void zoomIn() {
    setState(() {
      pdfZoom += 0.2;
    });
  }

  void zoomOut() {
    setState(() {
      if (pdfZoom > 0.4) {
        pdfZoom -= 0.2;
      }
    });
  }

  void resetZoom() {
    setState(() {
      pdfZoom = 1.0;
    });
  }

  Future<void> savePDF() async {
    if (pdfBytes == null) return;

    try {
      // Platform-agnostic save path
      String savePath = '${Directory.current.path}/downloads';
      final saveDir = Directory(savePath);

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${saveDir.path}/$fileName');

      await file.writeAsBytes(pdfBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${file.path}'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  // Enhanced print function with better error handling and platform checks
  Future<void> printPDF() async {
    if (pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No PDF data available for printing')),
      );
      return;
    }

    try {
      // Check if printing is supported on current platform
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printing is not supported on web platform')),
        );
        return;
      }

      // Check if printing service is available
      bool canPrint = await Printing.info().then((info) => info.canPrint);

      if (!canPrint) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No printer available or printing not supported')),
        );
        return;
      }

      // Show loading indicator while preparing print
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing print...')
            ],
          ),
        ),
      );

      // Use Printing.layoutPdf for better compatibility
      await Printing.layoutPdf(
        onLayout: (format) async {
          return pdfBytes!;
        },
        name: widget.title.isNotEmpty ? widget.title : 'Document',
        format: PdfPageFormat.a4,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print dialog opened successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Printing error: $e');
      print('Stack trace: $stackTrace');

      String errorMessage = 'Printing failed';

      // Provide more specific error messages
      if (e.toString().contains('not support')) {
        errorMessage = 'Printing is not supported on this platform';
      } else if (e.toString().contains('No printer')) {
        errorMessage = 'No printer found. Please check printer connection';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Printing permission denied';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Try Save Instead',
            textColor: Colors.white,
            onPressed: savePDF,
          ),
        ),
      );
    }
  }

  // Alternative print method using share functionality
  Future<void> sharePDF() async {
    if (pdfBytes == null) return;

    try {
      await Printing.sharePdf(
        bytes: pdfBytes!,
        filename:
            widget.title.isNotEmpty ? '${widget.title}.pdf' : 'document.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (pdfController != null) ...[
            // Print button with platform check
            if (!kIsWeb)
              IconButton(
                icon: Icon(Icons.print),
                onPressed: printPDF,
                tooltip: 'Print PDF',
              ),
            // Share button as alternative
            IconButton(
              icon: Icon(Icons.share),
              onPressed: sharePDF,
              tooltip: 'Share PDF',
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: savePDF,
              tooltip: 'Save PDF',
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: loadPDF,
              tooltip: 'Reload PDF',
            ),
          ],
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                    minHeight: 6,
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.pdfUrl,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Failed to Load PDF',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: loadPDF,
                          icon: Icon(Icons.refresh),
                          label: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            launchUrl(Uri.parse(widget.pdfUrl));
                          },
                          icon: Icon(Icons.open_in_browser),
                          label: Text('Open in Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // PDF Toolbar
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        children: [
                          // Page Navigation
                          IconButton(
                            onPressed: currentPage > 1 ? previousPage : null,
                            icon: Icon(Icons.chevron_left),
                            tooltip: 'Previous Page',
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Page $currentPage of $totalPages',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                currentPage < totalPages ? nextPage : null,
                            icon: Icon(Icons.chevron_right),
                            tooltip: 'Next Page',
                          ),

                          Spacer(),

                          // Zoom Controls
                          IconButton(
                            onPressed: zoomOut,
                            icon: Icon(Icons.zoom_out),
                            tooltip: 'Zoom Out',
                          ),
                          IconButton(
                            onPressed: zoomIn,
                            icon: Icon(Icons.zoom_in),
                            tooltip: 'Zoom In',
                          ),
                          IconButton(
                            onPressed: resetZoom,
                            icon: Icon(Icons.center_focus_strong),
                            tooltip: 'Reset Zoom',
                          ),
                        ],
                      ),
                    ),

                    // PDF Viewer
                    Expanded(
                      child: Container(
                        color: Colors.grey[200],
                        child: pdfx.PdfView(
                          controller: pdfController!,
                          onPageChanged: (page) {
                            setState(() {
                              currentPage = page;
                            });
                          },
                          scrollDirection: Axis.vertical,
                          physics: BouncingScrollPhysics(),
                          builders:
                              pdfx.PdfViewBuilders<pdfx.DefaultBuilderOptions>(
                            options: const pdfx.DefaultBuilderOptions(),
                            documentLoaderBuilder: (_) => Center(
                              child: CircularProgressIndicator(),
                            ),
                            pageLoaderBuilder: (_) => Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

      // Page Navigation Drawer
      endDrawer: pdfController != null
          ? Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue[700]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Navigation',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Total Pages: $totalPages',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (pdfBytes != null)
                          Text(
                            'Size: ${(pdfBytes!.length / 1024).toStringAsFixed(1)} KB',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        SizedBox(height: 8),
                        Text(
                          'Zoom: ${(pdfZoom * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: totalPages,
                      itemBuilder: (context, index) {
                        final pageNum = index + 1;
                        return ListTile(
                          leading: Icon(
                            Icons.picture_as_pdf,
                            color: pageNum == currentPage
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          title: Text('Page $pageNum'),
                          selected: pageNum == currentPage,
                          onTap: () {
                            goToPage(pageNum);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!kIsWeb)
                          ElevatedButton.icon(
                            onPressed: printPDF,
                            icon: Icon(Icons.print),
                            label: Text('Print PDF'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 40),
                            ),
                          ),
                        if (!kIsWeb) SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: sharePDF,
                          icon: Icon(Icons.share),
                          label: Text('Share PDF'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 40),
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: savePDF,
                          icon: Icon(Icons.save),
                          label: Text('Save PDF'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 40),
                          ),
                        ),
                        SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: loadPDF,
                          icon: Icon(Icons.refresh),
                          label: Text('Reload'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,

      // Floating Action Button for quick navigation
      floatingActionButton: pdfController != null
          ? FloatingActionButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              child: Icon(Icons.list),
              tooltip: 'Page List',
            )
          : null,
    );
  }
}
