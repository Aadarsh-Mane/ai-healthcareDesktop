import 'dart:io';
import 'package:flutter/material.dart';

class PdfViewerExample extends StatelessWidget {
  final String pdfUrl =
      "https://drive.google.com/file/d/1TV5tlwj-7kLlAFj0yJIt7IIGdcePqrNT/view";

  void openPdf() {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      Process.run('xdg-open', [pdfUrl]); // Linux
      Process.run('open', [pdfUrl]); // macOS
      Process.run('start', [pdfUrl], runInShell: true); // Windows
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Viewer Example")),
      body: Center(
        child: ElevatedButton(
          onPressed: openPdf,
          child: Text("Open PDF"),
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: PdfViewerExample()));
