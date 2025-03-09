import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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

// Function to extract the file ID from a Google Drive URL
  String? extractFileIdFromUrl(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1); // Return the file ID or null if not found
  }
}
