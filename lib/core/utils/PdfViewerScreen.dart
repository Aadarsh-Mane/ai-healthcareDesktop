// File: lib/widgets/common_pdf_viewer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';

// ==================== PDF STATE MANAGEMENT ====================

class PdfViewerState {
  final bool isVisible;
  final pdfx.PdfController? pdfController;
  final bool isLoading;
  final String? error;
  final Uint8List? pdfBytes;
  final int currentPage;
  final int totalPages;
  final String? currentUrl;
  final String? documentTitle;

  const PdfViewerState({
    this.isVisible = false,
    this.pdfController,
    this.isLoading = false,
    this.error,
    this.pdfBytes,
    this.currentPage = 1,
    this.totalPages = 0,
    this.currentUrl,
    this.documentTitle,
  });

  PdfViewerState copyWith({
    bool? isVisible,
    pdfx.PdfController? pdfController,
    bool? isLoading,
    String? error,
    Uint8List? pdfBytes,
    int? currentPage,
    int? totalPages,
    String? currentUrl,
    String? documentTitle,
  }) {
    return PdfViewerState(
      isVisible: isVisible ?? this.isVisible,
      pdfController: pdfController ?? this.pdfController,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentUrl: currentUrl ?? this.currentUrl,
      documentTitle: documentTitle ?? this.documentTitle,
    );
  }
}

class PdfViewerNotifier extends StateNotifier<PdfViewerState> {
  PdfViewerNotifier() : super(const PdfViewerState());

  static final Map<String, Uint8List> _globalPdfCache = {};

  @override
  void dispose() {
    state.pdfController?.dispose();
    super.dispose();
  }

  // ==================== PUBLIC METHODS ====================

  Future<void> loadAndShowPdf(String url, {String? title}) async {
    await loadPdf(url, title: title);
    if (state.pdfBytes != null) {
      show();
    }
  }

  void show() {
    state = state.copyWith(isVisible: true);
  }

  void hide() {
    state = state.copyWith(isVisible: false);
  }

  void toggle() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // ==================== PDF LOADING ====================

  Future<void> loadPdf(String url, {String? title}) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentUrl: url,
        documentTitle: title,
      );

      final processedUrl = _processUrl(url);

      // Check cache first
      if (_globalPdfCache.containsKey(processedUrl)) {
        await _initializePdfController(_globalPdfCache[processedUrl]!);
        return;
      }

      // Download PDF
      final bytes = await _downloadPdf(processedUrl);
      _globalPdfCache[processedUrl] = bytes;
      await _initializePdfController(bytes);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load PDF: ${e.toString()}',
      );
    }
  }

  String _processUrl(String url) {
    // Handle Google Drive URLs
    if (url.contains('drive.google.com')) {
      final RegExp regex = RegExp(r'\/file\/d\/([a-zA-Z0-9_-]+)');
      final match = regex.firstMatch(url);

      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }

      // Handle sharing URLs
      if (url.contains('sharing')) {
        final uri = Uri.parse(url);
        final fileId = uri.queryParameters['id'];
        if (fileId != null) {
          return 'https://drive.google.com/uc?export=download&id=$fileId';
        }
      }
    }
    return url;
  }

  Future<Uint8List> _downloadPdf(String url) async {
    final client = http.Client();
    final response = await client.get(
      Uri.parse(url),
      headers: {
        'User-Agent': Platform.isWindows
            ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'application/pdf,application/octet-stream,*/*',
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download PDF. Status: ${response.statusCode}');
    }
  }

  Future<void> _initializePdfController(Uint8List bytes) async {
    try {
      // Dispose previous controller
      state.pdfController?.dispose();

      // Verify PDF header
      if (!_isValidPdfHeader(bytes)) {
        print('Warning: File header does not match PDF signature');
      }

      final document = pdfx.PdfDocument.openData(bytes);
      final controller = pdfx.PdfController(
        document: document,
        initialPage: 1,
      );

      state = state.copyWith(
        pdfController: controller,
        pdfBytes: bytes,
        isLoading: false,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize PDF: ${e.toString()}',
      );
    }
  }

  bool _isValidPdfHeader(Uint8List bytes) {
    return bytes.length > 4 &&
        bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46; // F
  }

  // ==================== NAVIGATION ====================

  void goToPage(int page) {
    if (state.pdfController != null && page >= 1 && page <= state.totalPages) {
      state.pdfController!.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      goToPage(state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      goToPage(state.currentPage - 1);
    }
  }

  void onPageChanged(int page) {
    state = state.copyWith(currentPage: page);
  }

  // ==================== ACTIONS ====================

  Future<void> printPdf() async {
    if (state.pdfBytes == null) {
      state = state.copyWith(error: 'No PDF data available for printing');
      return;
    }

    try {
      if (kIsWeb) {
        state =
            state.copyWith(error: 'Printing is not supported on web platform');
        return;
      }

      bool canPrint = await Printing.info().then((info) => info.canPrint);
      if (!canPrint) {
        state = state.copyWith(
            error: 'No printer available or printing not supported');
        return;
      }

      await Printing.layoutPdf(
        onLayout: (format) async => state.pdfBytes!,
        name: state.documentTitle ??
            'Document_${DateTime.now().millisecondsSinceEpoch}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      String errorMessage = 'Printing failed';
      if (e.toString().contains('not support')) {
        errorMessage = 'Printing is not supported on this platform';
      } else if (e.toString().contains('No printer')) {
        errorMessage = 'No printer found. Please check printer connection';
      }

      state = state.copyWith(error: '$errorMessage: ${e.toString()}');
    }
  }

  Future<void> sharePdf() async {
    if (state.pdfBytes == null) return;

    try {
      await Printing.sharePdf(
        bytes: state.pdfBytes!,
        filename:
            '${state.documentTitle ?? 'Document'}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      state = state.copyWith(error: 'Share failed: $e');
    }
  }
}

// ==================== PROVIDER ====================

final pdfViewerProvider =
    StateNotifierProvider.autoDispose<PdfViewerNotifier, PdfViewerState>((ref) {
  return PdfViewerNotifier();
});

// ==================== REUSABLE WIDGETS ====================

class PdfViewerWidget extends ConsumerWidget {
  final Widget child;
  final Color? primaryColor;
  final String? appBarTitle;

  const PdfViewerWidget({
    Key? key,
    required this.child,
    this.primaryColor,
    this.appBarTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfViewerProvider);

    if (pdfState.isVisible) {
      return PdfViewerScreen(
        primaryColor: primaryColor,
        appBarTitle: appBarTitle,
      );
    }

    return child;
  }
}

class PdfViewerScreen extends ConsumerWidget {
  final Color? primaryColor;
  final String? appBarTitle;

  const PdfViewerScreen({
    Key? key,
    this.primaryColor,
    this.appBarTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfViewerProvider);
    final notifier = ref.read(pdfViewerProvider.notifier);
    final defaultColor = primaryColor ?? const Color(0xFF005F9E);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle ?? pdfState.documentTitle ?? 'PDF Viewer'),
        backgroundColor: defaultColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => notifier.hide(),
        ),
        actions: [
          if (pdfState.pdfBytes != null && !kIsWeb)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => notifier.printPdf(),
              tooltip: 'Print PDF',
            ),
          if (pdfState.pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => notifier.sharePdf(),
              tooltip: 'Share PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          // PDF Toolbar
          _PdfToolbar(primaryColor: defaultColor),

          // PDF Content
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: _buildPdfContent(context, pdfState, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfContent(BuildContext context, PdfViewerState pdfState,
      PdfViewerNotifier notifier) {
    if (pdfState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (pdfState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load PDF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pdfState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (pdfState.currentUrl != null) {
                    notifier.loadPdf(pdfState.currentUrl!,
                        title: pdfState.documentTitle);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => notifier.clearError(),
                child: const Text('Clear Error'),
              ),
            ],
          ),
        ),
      );
    }

    if (pdfState.pdfController != null) {
      return pdfx.PdfView(
        controller: pdfState.pdfController!,
        onPageChanged: (page) => notifier.onPageChanged(page),
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        builders: pdfx.PdfViewBuilders<pdfx.DefaultBuilderOptions>(
          options: const pdfx.DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return const Center(child: Text('No PDF loaded'));
  }
}

class _PdfToolbar extends ConsumerWidget {
  final Color primaryColor;

  const _PdfToolbar({required this.primaryColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfViewerProvider);
    final notifier = ref.read(pdfViewerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Page Navigation
          IconButton(
            onPressed:
                pdfState.currentPage > 1 ? () => notifier.previousPage() : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Page',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              'Page ${pdfState.currentPage} of ${pdfState.totalPages}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: pdfState.currentPage < pdfState.totalPages
                ? () => notifier.nextPage()
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Page',
          ),

          const Spacer(),

          // Actions
          if (!kIsWeb && pdfState.pdfBytes != null)
            IconButton(
              onPressed: () => notifier.printPdf(),
              icon: const Icon(Icons.print),
              tooltip: 'Print PDF',
            ),
          if (pdfState.pdfBytes != null)
            IconButton(
              onPressed: () => notifier.sharePdf(),
              icon: const Icon(Icons.share),
              tooltip: 'Share PDF',
            ),
          IconButton(
            onPressed: () => notifier.hide(),
            icon: const Icon(Icons.close),
            tooltip: 'Close PDF Preview',
          ),
        ],
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

class PdfStatusBar extends ConsumerWidget {
  final Color? errorColor;
  final Color? infoColor;

  const PdfStatusBar({
    Key? key,
    this.errorColor,
    this.infoColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfViewerProvider);
    final notifier = ref.read(pdfViewerProvider.notifier);

    if (!pdfState.isLoading && pdfState.error == null) {
      return const SizedBox.shrink();
    }

    final defaultErrorColor = errorColor ?? Colors.red;
    final defaultInfoColor = infoColor ?? const Color(0xFF005F9E);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pdfState.error != null
            ? defaultErrorColor.withOpacity(0.1)
            : defaultInfoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pdfState.error != null ? defaultErrorColor : defaultInfoColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (pdfState.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              pdfState.error != null ? Icons.error_outline : Icons.info_outline,
              size: 16,
              color:
                  pdfState.error != null ? defaultErrorColor : defaultInfoColor,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pdfState.isLoading ? 'Loading PDF...' : pdfState.error ?? '',
              style: TextStyle(
                fontSize: 12,
                color: pdfState.error != null
                    ? defaultErrorColor
                    : defaultInfoColor,
              ),
            ),
          ),
          if (pdfState.error != null)
            IconButton(
              onPressed: () => notifier.clearError(),
              icon: Icon(Icons.close, size: 16, color: defaultErrorColor),
            ),
        ],
      ),
    );
  }
}

class PdfActionButton extends ConsumerWidget {
  final String url;
  final String? title;
  final Widget child;
  final VoidCallback? onPressed;
  final bool autoShow;

  const PdfActionButton({
    Key? key,
    required this.url,
    this.title,
    required this.child,
    this.onPressed,
    this.autoShow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(pdfViewerProvider.notifier);

    return GestureDetector(
      onTap: () async {
        onPressed?.call();
        if (autoShow) {
          await notifier.loadAndShowPdf(url, title: title);
        } else {
          await notifier.loadPdf(url, title: title);
        }
      },
      child: child,
    );
  }
}
