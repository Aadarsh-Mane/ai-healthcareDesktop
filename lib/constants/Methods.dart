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

  // Alternative method using system print command for desktop with timeout
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

        print('Temporary PDF saved at: ${tempFile.path}');

        // Use system print command with timeout
        ProcessResult result;

        if (Platform.isWindows) {
          // Windows: Multiple fallback methods
          try {
            // Method 1: CMD with start command (most reliable)
            result = await Process.run(
              'cmd',
              ['/c', 'start', '/min', '""', '/print', '"${tempFile.path}"'],
              runInShell: true,
            ).timeout(Duration(seconds: 15));

            print('Windows CMD print result: ${result.exitCode}');
            if (result.exitCode != 0) {
              print('Windows CMD stderr: ${result.stderr}');
              throw Exception(
                  'CMD print failed with exit code: ${result.exitCode}');
            }
          } catch (e) {
            print('CMD method failed, trying PowerShell: $e');

            // Method 2: PowerShell with Start-Process -Verb Print
            try {
              final powershellCommand =
                  'try { Start-Process -FilePath "${tempFile.path}" -Verb Print -WindowStyle Hidden; Write-Output "Success" } catch { Write-Error \$_.Exception.Message; exit 1 }';
              result = await Process.run(
                'powershell',
                ['-WindowStyle', 'Hidden', '-Command', powershellCommand],
                runInShell: true,
              ).timeout(Duration(seconds: 15));

              if (result.exitCode != 0) {
                throw Exception('PowerShell print failed: ${result.stderr}');
              }
            } catch (psError) {
              print('PowerShell method failed, trying rundll32: $psError');

              // Method 3: rundll32 printui.dll (Windows native printing)
              result = await Process.run(
                'rundll32',
                [
                  'shell32.dll,ShellExec_RunDLL',
                  '"${tempFile.path}"',
                  '',
                  '',
                  '1'
                ],
                runInShell: true,
              ).timeout(Duration(seconds: 15));

              if (result.exitCode != 0) {
                throw Exception('All Windows print methods failed');
              }
            }
          }
        } else if (Platform.isMacOS) {
          // Check if default printer exists first
          try {
            final printerCheckResult = await Process.run(
              'lpstat',
              ['-d'],
            ).timeout(Duration(seconds: 5));

            if (printerCheckResult.exitCode != 0 ||
                printerCheckResult.stdout
                    .toString()
                    .contains('no system default destination')) {
              throw Exception(
                  'No default printer configured. Please set up a default printer in System Preferences.');
            }
          } catch (e) {
            throw Exception(
                'No default printer found. Please configure a printer in System Preferences → Printers & Scanners.');
          }

          // Proceed with printing if default printer exists
          result = await Process.run(
            'lpr',
            [tempFile.path],
          ).timeout(Duration(seconds: 15));

          if (result.exitCode != 0) {
            throw Exception('macOS print failed: ${result.stderr}');
          }
        } else if (Platform.isLinux) {
          // Check for available printers first
          try {
            final printerCheckResult = await Process.run(
              'lpstat',
              ['-p'],
            ).timeout(Duration(seconds: 5));

            if (printerCheckResult.exitCode != 0 ||
                printerCheckResult.stdout.toString().trim().isEmpty) {
              throw Exception(
                  'No printers found. Please install and configure a printer.');
            }
          } catch (e) {
            throw Exception(
                'No printers available. Please set up a printer first.');
          }

          result = await Process.run(
            'lp',
            [tempFile.path],
          ).timeout(Duration(seconds: 15));

          if (result.exitCode != 0) {
            throw Exception('Linux print failed: ${result.stderr}');
          }
        } else {
          throw Exception('Unsupported platform for system printing');
        }

        print('Print command completed successfully');

        // Clean up temp file after a delay
        Future.delayed(Duration(seconds: 30), () {
          try {
            if (tempFile.existsSync()) {
              tempFile.deleteSync();
              print('Temporary file cleaned up');
            }
          } catch (e) {
            print('Error cleaning up temp file: $e');
          }
        });
      } else {
        throw Exception('Failed to download PDF content');
      }
    } catch (e) {
      print('Error printing via system: $e');
      rethrow;
    }
  }

  // Simple method to open PDF with default application (alternative approach)
  Future<void> openPdfForPrinting(String pdfUrl) async {
    try {
      final directUrl = _convertGoogleDriveUrl(pdfUrl);
      final pdfBytes = await _downloadPdf(directUrl);

      if (pdfBytes != null) {
        // Save PDF temporarily
        final tempDir = Directory.systemTemp;
        final tempFile = File(
            '${tempDir.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        // Open with default application
        if (Platform.isWindows) {
          await Process.run('start', [tempFile.path], runInShell: true)
              .timeout(Duration(seconds: 10));
        } else if (Platform.isMacOS) {
          await Process.run('open', [tempFile.path])
              .timeout(Duration(seconds: 10));
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [tempFile.path])
              .timeout(Duration(seconds: 10));
        }

        // Clean up temp file after a longer delay since user needs to print manually
        Future.delayed(Duration(minutes: 5), () {
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
      print('Error opening PDF for printing: $e');
      rethrow;
    }
  }

  void openEmailInBrowser(String email) {
    final url = 'https://mail.google.com/mail/?view=cm&fs=1&to=$email';

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
