import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class Methods {
  void openPdf(String pdfUrl) {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        // Process.run('xdg-open', [pdfUrl]); // Linux
        Process.run('open', [pdfUrl]); // macOS
      } else if (Platform.isWindows) {
        Process.run('start', [pdfUrl], runInShell: true); // Windows
      }
    } catch (e) {
      print('Error opening PDF: $e');
    }
  }

  Future<void> printPdf(String pdfUrl) async {
    try {
      // Convert Google Drive share URL to direct download URL
      final directUrl = _convertGoogleDriveUrl(pdfUrl);

      // Download the PDF content
      final pdfBytes = await _downloadPdf(directUrl);

      if (pdfBytes != null) {
        // Print the PDF
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Prescription_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        throw Exception('Failed to download PDF content');
      }
    } catch (e) {
      print('Error printing PDF: $e');
      throw e;
    }
  }

  // Method to show print preview dialog
  Future<void> showPrintPreview(String pdfUrl) async {
    try {
      // Convert Google Drive share URL to direct download URL
      final directUrl = _convertGoogleDriveUrl(pdfUrl);

      // Download the PDF content
      final pdfBytes = await _downloadPdf(directUrl);

      if (pdfBytes != null) {
        // Show print preview
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Prescription_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } else {
        throw Exception('Failed to download PDF content');
      }
    } catch (e) {
      print('Error showing print preview: $e');
      throw e;
    }
  }

  // Convert Google Drive share URL to direct download URL
  String _convertGoogleDriveUrl(String shareUrl) {
    // Extract file ID from Google Drive share URL
    final RegExp regExp = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
    final match = regExp.firstMatch(shareUrl);

    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    // If it's already a direct URL, return as is
    return shareUrl;
  }

  // Download PDF content from URL
  Future<Uint8List?> _downloadPdf(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to download PDF: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      return null;
    }
  }

  // Method to check if printing is available
  static Future<bool> isPrintingAvailable() async {
    try {
      return await Printing.info() != null;
    } catch (e) {
      return false;
    }
  }

  // Method to get available printers
  static Future<List<Printer>> getAvailablePrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      print('Error getting printers: $e');
      return [];
    }
  }

  // Method to print to a specific printer with fallback
  Future<void> printToSpecificPrinter(String pdfUrl, String printerName) async {
    try {
      final directUrl = _convertGoogleDriveUrl(pdfUrl);
      final pdfBytes = await _downloadPdf(directUrl);

      if (pdfBytes != null) {
        // Try direct printing first
        try {
          final printers = await getAvailablePrinters();
          final targetPrinter = printers.firstWhere(
            (printer) => printer.name == printerName,
            orElse: () => throw Exception('Printer not found: $printerName'),
          );

          await Printing.directPrintPdf(
            printer: targetPrinter,
            onLayout: (format) async => pdfBytes,
            name: 'Prescription_${DateTime.now().millisecondsSinceEpoch}',
          );
        } catch (directPrintError) {
          // Fallback to regular print dialog if direct printing fails
          print(
              'Direct printing failed, falling back to print dialog: $directPrintError');
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'Prescription_${DateTime.now().millisecondsSinceEpoch}',
          );
        }
      }
    } catch (e) {
      print('Error printing: $e');
      throw e;
    }
  }

  // Alternative method using system print command for desktop
  Future<void> printPdfViaSystem(String pdfUrl) async {
    try {
      final directUrl = _convertGoogleDriveUrl(pdfUrl);
      final pdfBytes = await _downloadPdf(directUrl);

      if (pdfBytes != null) {
        // Save PDF temporarily
        final tempDir = Directory.systemTemp;
        final tempFile = File(
            '${tempDir.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        // Use system print command
        if (Platform.isWindows) {
          await Process.run(
              'powershell',
              [
                '-Command',
                'Start-Process',
                '-FilePath',
                '"${tempFile.path}"',
                '-Verb',
                'Print'
              ],
              runInShell: true);
        } else if (Platform.isMacOS) {
          await Process.run('lpr', [tempFile.path]);
        } else if (Platform.isLinux) {
          await Process.run('lp', [tempFile.path]);
        }

        // Clean up temp file after a delay
        Future.delayed(Duration(seconds: 30), () {
          try {
            if (tempFile.existsSync()) {
              tempFile.deleteSync();
            }
          } catch (e) {
            print('Error cleaning up temp file: $e');
          }
        });
      }
    } catch (e) {
      print('Error printing via system: $e');
      throw e;
    }
  }

  void openMail({
    String? to,
    String? subject,
    String? body,
  }) {
    // URL encode the parameters to handle special characters and spaces
    final encodedTo = to != null ? Uri.encodeComponent(to) : '';
    final encodedSubject = subject != null ? Uri.encodeComponent(subject) : '';
    final encodedBody = body != null ? Uri.encodeComponent(body) : '';

    // Build the Gmail URL with all parameters
    var url = 'https://mail.google.com/mail/?view=cm&fs=1';

    if (encodedTo.isNotEmpty) {
      url += '&to=$encodedTo';
    }
    if (encodedSubject.isNotEmpty) {
      url += '&su=$encodedSubject';
    }
    if (encodedBody.isNotEmpty) {
      url += '&body=$encodedBody';
    }

    try {
      if (Platform.isMacOS) {
        Process.run('open', [url]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      } else if (Platform.isWindows) {
        Process.run('start', [url], runInShell: true);
      }
    } catch (e) {
      print('Error opening email in browser: $e');
    }
  }

  /// Legacy method for backward compatibility
  void openEmailInBrowser(String email) {
    openMail(to: email);
  }

  // void openEmailInBrowser(String email) {
  //   final url = 'https://mail.google.com/mail/?view=cm&fs=1&to=$email';

  //   try {
  //     if (Platform.isMacOS) {
  //       Process.run('open', [url]);
  //     } else if (Platform.isLinux) {
  //       Process.run('xdg-open', [url]);
  //     } else if (Platform.isWindows) {
  //       Process.run('start', [url], runInShell: true);
  //     }
  //   } catch (e) {
  //     print('Error opening email in browser: $e');
  //   }
  // }

  String getGoogleDriveDirectLink(String imageUrl) {
    final regex = RegExp(r'd/([a-zA-Z0-9_-]+)/');
    final match = regex.firstMatch(imageUrl);
    if (match != null && match.groupCount == 1) {
      final fileId = match.group(1);
      print("this is $imageUrl");

      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return 'https://i.postimg.cc/nz0YBQcH/Logo-light.png"'; // Return the original URL if no match is found
  }

  Future<void> downloadFile(
      String url, String fileName, BuildContext context) async {
    try {
      // Extract the file ID from the Google Drive URL
      final fileId = extractFileIdFromUrl(url);
      if (fileId == null) {
        throw Exception('Invalid Google Drive URL');
      }

      // Construct the direct download URL
      final directUrl =
          'https://drive.google.com/uc?id=$fileId&export=download';

      // Send GET request to fetch file
      final response = await http.get(Uri.parse(directUrl));

      if (response.statusCode == 200) {
        // Get the local directory for downloads
        final directory = await getDownloadsDirectory();

        if (directory != null) {
          // Construct the file path in the downloads directory
          final filePath = '${directory.path}/$fileName';

          // Write the file to the specified location
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File downloaded: $filePath')),
          );
        } else {
          throw Exception('Unable to find downloads directory');
        }
      } else {
        throw Exception(
            'Failed to download file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

// Add this to your Methods class
  void openUrl(String url) {
    try {
      if (Platform.isMacOS) {
        Process.run('open', [url]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      } else if (Platform.isWindows) {
        Process.run('start', [url], runInShell: true);
      } else {
        // For other platforms, try url_launcher package
      }
    } catch (e) {
      print('Error opening URL in browser: $e');
    }
  }

// Function to extract the file ID from a Google Drive URL
  String? extractFileIdFromUrl(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1); // Return the file ID or null if not found
  }
}
